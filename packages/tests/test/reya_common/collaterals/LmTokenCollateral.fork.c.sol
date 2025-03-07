pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import { IShareTokenProxy, SubscriptionInputs, RedemptionInputs } from "../../../src/interfaces/IShareTokenProxy.sol";

import {
    ICoreProxy,
    ParentCollateralConfig,
    MarginInfo,
    CollateralInfo,
    Command,
    CommandType
} from "../../../src/interfaces/ICoreProxy.sol";

import {
    IPeripheryProxy, DepositNewMAInputs, DepositExistingMAInputs
} from "../../../src/interfaces/IPeripheryProxy.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

import { sd, SD59x18, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

struct LocalState {
    uint256 lmTokenTotalSupply;
    uint256 lmTokenRecipientBalance1;
    uint256 rUsdSubscriberBalance;
    uint256 rUsdCustodianBalance;
    uint256 rUsdRecipientBalance2;
}

contract LmTokenCollateralForkCheck is BaseReyaForkTest {
    LocalState private s0;
    LocalState private s1;

    // only attacker is fuzzed
    function checkFuzz_LmTokenMintBurn(
        address lmToken,
        address subscriber,
        address redeemer,
        address custodian,
        address attacker
    )
        private
    {
        vm.assume(attacker != subscriber);
        vm.assume(attacker != address(0));

        uint256 totalSupplyBefore = ITokenProxy(lmToken).totalSupply();

        (address user,) = makeAddrAndKey("user");

        // attacker cannot mint
        vm.prank(attacker);
        vm.expectRevert(
            abi.encodeWithSelector(ICoreProxy.FeatureUnavailable.selector, keccak256(bytes("subscription")))
        );
        IShareTokenProxy(lmToken).subscribe(
            SubscriptionInputs({
                recipient: attacker,
                custodian: custodian,
                tokenIn: sec.rusd,
                amountIn: 100e6,
                minSharesOut: 0
            })
        );

        // user cannot mint
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(ICoreProxy.FeatureUnavailable.selector, keccak256(bytes("subscription")))
        );
        IShareTokenProxy(lmToken).subscribe(
            SubscriptionInputs({
                recipient: attacker,
                custodian: custodian,
                tokenIn: sec.rusd,
                amountIn: 100e6,
                minSharesOut: 0
            })
        );

        // subscriber mints to attacker
        deal(sec.rusd, address(subscriber), 100e6);
        vm.prank(subscriber);
        ITokenProxy(sec.rusd).approve(lmToken, 100e6);
        vm.prank(subscriber);
        uint256 sharesOut = IShareTokenProxy(lmToken).subscribe(
            SubscriptionInputs({
                recipient: attacker,
                custodian: custodian,
                tokenIn: sec.rusd,
                amountIn: 100e6,
                minSharesOut: 0
            })
        );

        vm.prank(custodian);
        ITokenProxy(sec.rusd).transfer(lmToken, 100e6);

        // attacker cannot burn
        vm.prank(attacker);
        vm.expectRevert();
        IShareTokenProxy(lmToken).redeem(
            RedemptionInputs({ recipient: attacker, tokenOut: sec.rusd, sharesToRedeem: 50e18, minTokensOut: 0 })
        );

        // user cannot burn
        vm.prank(attacker);
        ITokenProxy(lmToken).transfer(user, 50e18);
        vm.prank(user);
        vm.expectRevert();
        IShareTokenProxy(lmToken).redeem(
            RedemptionInputs({ recipient: user, tokenOut: sec.rusd, sharesToRedeem: 50e18, minTokensOut: 0 })
        );

        // redeemer burns
        vm.prank(user);
        ITokenProxy(lmToken).transfer(redeemer, 50e18);
        vm.prank(redeemer);
        IShareTokenProxy(lmToken).redeem(
            RedemptionInputs({ recipient: user, tokenOut: sec.rusd, sharesToRedeem: 50e18, minTokensOut: 0 })
        );

        uint256 totalSupplyAfter = ITokenProxy(lmToken).totalSupply();
        assertEq(totalSupplyAfter, totalSupplyBefore + sharesOut - 50e18);
    }

    function check_LmToken_RedemptionAndSubscription(
        address lmToken,
        address subscriber,
        address redeemer,
        address custodian
    )
        private
    {
        address recipient1 = vm.addr(123);
        address recipient2 = vm.addr(456);

        // mint 100 rusd for the subscriber
        deal(sec.rusd, address(subscriber), 100e6);

        // subscriber approve 100 rusd to LM token
        vm.prank(subscriber);
        ITokenProxy(sec.rusd).approve(lmToken, 100e6);

        s0.lmTokenTotalSupply = IShareTokenProxy(lmToken).totalSupply();
        s0.lmTokenRecipientBalance1 = IShareTokenProxy(lmToken).balanceOf(recipient1);
        s0.rUsdSubscriberBalance = ITokenProxy(sec.rusd).balanceOf(subscriber);
        s0.rUsdCustodianBalance = ITokenProxy(sec.rusd).balanceOf(custodian);
        s0.rUsdRecipientBalance2 = ITokenProxy(sec.rusd).balanceOf(recipient2);

        // subscriber subscribes 100 rusd to rSelini and sends shares to custom recipient
        vm.prank(subscriber);
        uint256 sharesOut = IShareTokenProxy(lmToken).subscribe(
            SubscriptionInputs({
                recipient: recipient1,
                custodian: custodian,
                tokenIn: sec.rusd,
                amountIn: 100e6,
                minSharesOut: 0
            })
        );

        assertApproxEqAbsDecimal(sharesOut, 98e18, 1e18, 18);

        // check balances after subscription
        s1.lmTokenTotalSupply = IShareTokenProxy(lmToken).totalSupply();
        s1.lmTokenRecipientBalance1 = IShareTokenProxy(lmToken).balanceOf(recipient1);
        s1.rUsdSubscriberBalance = ITokenProxy(sec.rusd).balanceOf(subscriber);
        s1.rUsdCustodianBalance = ITokenProxy(sec.rusd).balanceOf(custodian);
        s1.rUsdRecipientBalance2 = ITokenProxy(sec.rusd).balanceOf(recipient2);

        assertEq(s1.lmTokenTotalSupply, s0.lmTokenTotalSupply + sharesOut);
        assertEq(s1.lmTokenRecipientBalance1, s0.lmTokenRecipientBalance1 + sharesOut);
        assertEq(s1.rUsdSubscriberBalance, s0.rUsdSubscriberBalance - 100e6);
        assertEq(s1.rUsdCustodianBalance, s0.rUsdCustodianBalance + 100e6);
        assertEq(s1.rUsdRecipientBalance2, s0.rUsdRecipientBalance2);

        s0 = s1;

        uint256 lmtokenRusdBalanceBefore = ITokenProxy(sec.rusd).balanceOf(lmToken);

        // custodian sends 51 rusd back to LM token
        vm.prank(custodian);
        ITokenProxy(sec.rusd).transfer(lmToken, 52e6);

        // recipient sends 50 LM tokens to redeemer
        vm.prank(recipient1);
        ITokenProxy(lmToken).transfer(redeemer, 50e18);

        // redeemer redeems 50 shares from LM token
        vm.prank(redeemer);
        uint256 tokenOut = IShareTokenProxy(lmToken).redeem(
            RedemptionInputs({ recipient: recipient2, tokenOut: sec.rusd, sharesToRedeem: 50e18, minTokensOut: 0 })
        );

        assertApproxEqAbsDecimal(tokenOut, 51e6, 1e6, 6);

        // check balances after redemption
        s1.lmTokenTotalSupply = IShareTokenProxy(lmToken).totalSupply();
        s1.lmTokenRecipientBalance1 = IShareTokenProxy(lmToken).balanceOf(recipient1);
        s1.rUsdSubscriberBalance = ITokenProxy(sec.rusd).balanceOf(subscriber);
        s1.rUsdCustodianBalance = ITokenProxy(sec.rusd).balanceOf(custodian);
        s1.rUsdRecipientBalance2 = ITokenProxy(sec.rusd).balanceOf(recipient2);

        assertEq(s1.lmTokenTotalSupply, s0.lmTokenTotalSupply - 50e18);
        assertEq(s1.lmTokenRecipientBalance1, s0.lmTokenRecipientBalance1 - 50e18);
        assertEq(s1.rUsdSubscriberBalance, s0.rUsdSubscriberBalance);
        assertEq(s1.rUsdCustodianBalance, s0.rUsdCustodianBalance - 52e6);
        assertEq(s1.rUsdRecipientBalance2, s0.rUsdRecipientBalance2 + tokenOut);
        assertEq(ITokenProxy(sec.rusd).balanceOf(lmToken), lmtokenRusdBalanceBefore + 52e6 - tokenOut);
    }

    function check_lmToken_view_functions(address lmToken, bytes32 lmTokenUsdcNodeId) private {
        (address user,) = makeAddrAndKey("user");

        uint256 lmTokenAmount = 1e18;

        // deposit new margin account
        uint128 accountId = depositNewMA(user, lmToken, lmTokenAmount);

        vm.prank(user);
        ICoreProxy(sec.core).activateFirstMarketForAccount(accountId, 1);

        NodeOutput.Data memory lmTokenUsdcNodeOutput = IOracleManagerProxy(sec.oracleManager).process(lmTokenUsdcNodeId);

        (, ParentCollateralConfig memory parentCollateralConfig,) = ICoreProxy(sec.core).getCollateralConfig(1, lmToken);
        SD59x18 lmTokenAmountInUSD = sd(int256(lmTokenAmount)).mul(sd(int256(lmTokenUsdcNodeOutput.price))).mul(
            UNIT_sd.sub(sd(int256(parentCollateralConfig.priceHaircut)))
        );

        MarginInfo memory accountUsdNodeMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(accountUsdNodeMarginInfo.marginBalance, lmTokenAmountInUSD.unwrap(), 0.000001e18, 18);

        CollateralInfo memory accountLmTokenCollateralInfo = ICoreProxy(sec.core).getCollateralInfo(accountId, lmToken);
        assertEq(accountLmTokenCollateralInfo.netDeposits, int256(lmTokenAmount));
        assertEq(accountLmTokenCollateralInfo.marginBalance, int256(lmTokenAmount));
        assertEq(accountLmTokenCollateralInfo.realBalance, int256(lmTokenAmount));

        uint256 usdcAmount = 1000e6;
        deal(sec.usdc, address(sec.periphery), usdcAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], usdcAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: accountId, token: sec.usdc })
        );

        accountUsdNodeMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(
            accountUsdNodeMarginInfo.marginBalance, lmTokenAmountInUSD.unwrap() + 1000e18, 0.000001e18, 18
        );

        accountLmTokenCollateralInfo = ICoreProxy(sec.core).getCollateralInfo(accountId, lmToken);
        assertEq(accountLmTokenCollateralInfo.netDeposits, int256(lmTokenAmount));
        assertEq(accountLmTokenCollateralInfo.marginBalance, int256(lmTokenAmount));
        assertEq(accountLmTokenCollateralInfo.realBalance, int256(lmTokenAmount));
    }

    function check_lmToken_cap_exceeded(address lmToken) private {
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 2_000_001e18; // denominated in lmToken
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        uint256 collateralPoolLmTokenBalance = ICoreProxy(sec.core).getCollateralPoolBalance(1, lmToken);

        // deposit new margin account
        uint128 accountId = depositNewMA(user, lmToken, amount);

        vm.expectRevert(
            abi.encodeWithSelector(
                ICoreProxy.CollateralCapExceeded.selector,
                1,
                lmToken,
                2_000_000e18,
                collateralPoolLmTokenBalance + amount
            )
        );
        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);
    }

    function check_lmToken_deposit_withdraw(address lmToken) private {
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 1000e18; // denominated in lmToken

        // deposit new margin account
        uint128 accountId = depositNewMA(user, lmToken, amount);

        uint256 coreLmTokenBalanceBefore = ITokenProxy(lmToken).balanceOf(sec.core);

        amount = 100e18;
        withdrawMA(accountId, lmToken, amount);

        uint256 coreLmTokenBalanceAfter = ITokenProxy(lmToken).balanceOf(sec.core);

        assertEq(coreLmTokenBalanceBefore - coreLmTokenBalanceAfter, amount);
    }

    function check_trade_lmTokenCollateral_depositWithdraw(address lmToken) private {
        mockFreshPrices();

        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 3000e18; // denominated in lmToken
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        uint128 accountId = depositNewMA(user, lmToken, amount);

        vm.prank(user);
        ICoreProxy(sec.core).activateFirstMarketForAccount(accountId, 1);

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        uint256 usdcAmount = 1000e6;
        deal(sec.usdc, address(sec.periphery), usdcAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], usdcAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: accountId, token: sec.usdc })
        );

        amount = 100e18;
        withdrawMA(accountId, lmToken, amount);

        checkPoolHealth();
    }

    function checkFuzz_rseliniMintBurn(address attacker) public {
        checkFuzz_LmTokenMintBurn(
            sec.rselini, sec.rseliniSubscriber, sec.rseliniRedeemer, sec.rseliniCustodian, attacker
        );
    }

    function checkFuzz_ramberMintBurn(address attacker) public {
        checkFuzz_LmTokenMintBurn(sec.ramber, sec.ramberSubscriber, sec.ramberRedeemer, sec.ramberCustodian, attacker);
    }

    function check_rseliniRedemptionAndSubscription() public {
        check_LmToken_RedemptionAndSubscription(
            sec.rselini, sec.rseliniSubscriber, sec.rseliniRedeemer, sec.rseliniCustodian
        );
    }

    function check_ramberRedemptionAndSubscription() public {
        check_LmToken_RedemptionAndSubscription(
            sec.ramber, sec.ramberSubscriber, sec.ramberRedeemer, sec.ramberCustodian
        );
    }

    function check_rselini_view_functions() public {
        removeCollateralCap(sec.rselini);
        check_lmToken_view_functions(sec.rselini, sec.rseliniUsdcReyaLmNodeId);
    }

    function check_ramber_view_functions() public {
        removeCollateralCap(sec.ramber);
        check_lmToken_view_functions(sec.ramber, sec.ramberUsdcReyaLmNodeId);
    }

    function check_rselini_cap_exceeded() public {
        check_lmToken_cap_exceeded(sec.rselini);
    }

    function check_ramber_cap_exceeded() public {
        check_lmToken_cap_exceeded(sec.ramber);
    }

    function check_rselini_deposit_withdraw() public {
        removeCollateralCap(sec.rselini);
        removeCollateralWithdrawalLimit(sec.rselini);
        check_lmToken_deposit_withdraw(sec.rselini);
    }

    function check_ramber_deposit_withdraw() public {
        removeCollateralCap(sec.ramber);
        removeCollateralWithdrawalLimit(sec.ramber);
        check_lmToken_deposit_withdraw(sec.ramber);
    }

    function check_trade_rseliniCollateral_depositWithdraw() public {
        removeCollateralCap(sec.rselini);
        removeCollateralWithdrawalLimit(sec.rselini);
        check_trade_lmTokenCollateral_depositWithdraw(sec.rselini);
    }

    function check_trade_ramberCollateral_depositWithdraw() public {
        removeCollateralCap(sec.ramber);
        removeCollateralWithdrawalLimit(sec.ramber);
        check_trade_lmTokenCollateral_depositWithdraw(sec.ramber);
    }
}
