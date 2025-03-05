pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import { ICoreProxy, ParentCollateralConfig, MarginInfo, CollateralInfo } from "../../../src/interfaces/ICoreProxy.sol";

import {
    IPeripheryProxy, DepositNewMAInputs, DepositExistingMAInputs
} from "../../../src/interfaces/IPeripheryProxy.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

import { sd, SD59x18, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract SdeusdCollateralForkCheck is BaseReyaForkTest {
    function checkFuzz_SDEUSDMintBurn(address attacker) public {
        (address user,) = makeAddrAndKey("user");
        uint256 amount = 10e18;

        uint256 totalSupplyBefore = ITokenProxy(sec.sdeusd).totalSupply();

        // mint
        vm.prank(dec.socketController[sec.sdeusd]);
        ITokenProxy(sec.sdeusd).mint(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        ITokenProxy(sec.sdeusd).mint(user, amount);

        vm.prank(user);
        vm.expectRevert();
        ITokenProxy(sec.sdeusd).mint(user, amount);

        // burn
        vm.prank(dec.socketController[sec.sdeusd]);
        ITokenProxy(sec.sdeusd).burn(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        ITokenProxy(sec.sdeusd).burn(user, amount);

        vm.prank(user);
        vm.expectRevert();
        ITokenProxy(sec.sdeusd).burn(user, amount);

        uint256 totalSupplyAfter = ITokenProxy(sec.sdeusd).totalSupply();
        assertEq(totalSupplyAfter, totalSupplyBefore);
    }

    function check_sdeusd_view_functions() public {
        (address user,) = makeAddrAndKey("user");

        uint256 sdeusdAmount = 1e18;

        // deposit new margin account
        deal(sec.sdeusd, address(sec.periphery), sdeusdAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.sdeusd], sdeusdAmount);
        vm.prank(dec.socketExecutionHelper[sec.sdeusd]);
        uint128 accountId =
            IPeripheryProxy(sec.periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: sec.sdeusd }));

        vm.prank(user);
        ICoreProxy(sec.core).activateFirstMarketForAccount(accountId, 1);

        NodeOutput.Data memory sdeusdUsdcNodeOutput =
            IOracleManagerProxy(sec.oracleManager).process(sec.sdeusdUsdcStorkNodeId);

        (, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.sdeusd);
        SD59x18 sdeusdAmountInUSD = sd(int256(sdeusdAmount)).mul(sd(int256(sdeusdUsdcNodeOutput.price))).mul(
            UNIT_sd.sub(sd(int256(parentCollateralConfig.priceHaircut)))
        );

        MarginInfo memory accountUsdNodeMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(accountUsdNodeMarginInfo.marginBalance, sdeusdAmountInUSD.unwrap(), 0.000001e18, 18);

        CollateralInfo memory accountSdeusdCollateralInfo =
            ICoreProxy(sec.core).getCollateralInfo(accountId, sec.sdeusd);
        assertEq(accountSdeusdCollateralInfo.netDeposits, int256(sdeusdAmount));
        assertEq(accountSdeusdCollateralInfo.marginBalance, int256(sdeusdAmount));
        assertEq(accountSdeusdCollateralInfo.realBalance, int256(sdeusdAmount));

        uint256 usdcAmount = 1000e6;
        deal(sec.usdc, address(sec.periphery), usdcAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], usdcAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: accountId, token: sec.usdc })
        );

        accountUsdNodeMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(
            accountUsdNodeMarginInfo.marginBalance, sdeusdAmountInUSD.unwrap() + 1000e18, 0.000001e18, 18
        );

        accountSdeusdCollateralInfo = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.sdeusd);
        assertEq(accountSdeusdCollateralInfo.netDeposits, int256(sdeusdAmount));
        assertEq(accountSdeusdCollateralInfo.marginBalance, int256(sdeusdAmount));
        assertEq(accountSdeusdCollateralInfo.realBalance, int256(sdeusdAmount));
    }

    function check_sdeusd_cap_exceeded() public {
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 50_000_001e18; // denominated in sdeusd
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        uint256 collateralPoolSdeusdBalance = ICoreProxy(sec.core).getCollateralPoolBalance(1, sec.sdeusd);

        // deposit new margin account
        deal(sec.sdeusd, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.sdeusd], amount);
        vm.prank(dec.socketExecutionHelper[sec.sdeusd]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.sdeusd) })
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                ICoreProxy.CollateralCapExceeded.selector,
                1,
                sec.sdeusd,
                50_000_000e18,
                collateralPoolSdeusdBalance + amount
            )
        );
        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);
    }

    function check_sdeusd_deposit_withdraw() public {
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 1000e18; // denominated in sdeusd

        // deposit new margin account
        deal(sec.sdeusd, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.sdeusd], amount);
        vm.prank(dec.socketExecutionHelper[sec.sdeusd]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.sdeusd) })
        );

        uint256 coreSdeusdBalanceBefore = ITokenProxy(sec.sdeusd).balanceOf(sec.core);
        uint256 peripherySdeusdBalanceBefore = ITokenProxy(sec.sdeusd).balanceOf(sec.periphery);
        uint256 multisigSdeusdBalanceBefore = ITokenProxy(sec.sdeusd).balanceOf(sec.multisig);

        amount = 100e18;
        executePeripheryWithdrawMA(user, userPk, 1, accountId, sec.sdeusd, amount, ethereumChainId);

        uint256 coreSdeusdBalanceAfter = ITokenProxy(sec.sdeusd).balanceOf(sec.core);
        uint256 peripherySdeusdBalanceAfter = ITokenProxy(sec.sdeusd).balanceOf(sec.periphery);
        uint256 multisigSdeusdBalanceAfter = ITokenProxy(sec.sdeusd).balanceOf(sec.multisig);
        uint256 withdrawStaticFees = IPeripheryProxy(sec.periphery).getTokenStaticWithdrawFee(
            sec.sdeusd, dec.socketConnector[sec.sdeusd][ethereumChainId]
        );

        assertEq(coreSdeusdBalanceBefore - coreSdeusdBalanceAfter, amount);
        assertEq(multisigSdeusdBalanceAfter - multisigSdeusdBalanceBefore, withdrawStaticFees);
        // we mock call to socket so funds remain in periphery
        assertEq(peripherySdeusdBalanceAfter - peripherySdeusdBalanceBefore, amount - withdrawStaticFees);
    }

    function check_trade_sdeusdCollateral_depositWithdraw() public {
        mockFreshPrices();

        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 3000e18; // denominated in sdeusd
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        deal(sec.sdeusd, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.sdeusd], amount);
        vm.prank(dec.socketExecutionHelper[sec.sdeusd]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.sdeusd) })
        );

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
        executePeripheryWithdrawMA(user, userPk, 2, accountId, sec.sdeusd, amount, ethereumChainId);

        checkPoolHealth();
    }
}
