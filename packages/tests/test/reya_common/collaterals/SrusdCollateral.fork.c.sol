pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import { ICoreProxy, ParentCollateralConfig, MarginInfo, CollateralInfo } from "../../../src/interfaces/ICoreProxy.sol";

import { IPassivePoolProxy } from "../../../src/interfaces/IPassivePoolProxy.sol";

import {
    IPeripheryProxy, DepositNewMAInputs, DepositExistingMAInputs
} from "../../../src/interfaces/IPeripheryProxy.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

import { sd, SD59x18, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract SrusdCollateralForkCheck is BaseReyaForkTest {
    function checkFuzz_SRUSDMintBurn(address attacker) public {
        (address user,) = makeAddrAndKey("user");
        uint256 amount = 10e18;

        vm.prank(sec.multisig);
        ITokenProxy(sec.srusd).addToFeatureFlagAllowlist(keccak256(bytes("authorizedHolder")), user);

        uint256 totalSupplyBefore = ITokenProxy(sec.srusd).totalSupply();

        // mint
        vm.prank(sec.pool);
        ITokenProxy(sec.srusd).mint(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        ITokenProxy(sec.srusd).mint(user, amount);

        vm.prank(user);
        vm.expectRevert();
        ITokenProxy(sec.srusd).mint(user, amount);

        // burn
        vm.prank(sec.pool);
        ITokenProxy(sec.srusd).burn(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        ITokenProxy(sec.srusd).burn(user, amount);

        vm.prank(user);
        vm.expectRevert();
        ITokenProxy(sec.srusd).burn(user, amount);

        uint256 totalSupplyAfter = ITokenProxy(sec.srusd).totalSupply();
        assertEq(totalSupplyAfter, totalSupplyBefore);
    }

    function check_srusd_view_functions() public {
        (address user,) = makeAddrAndKey("user");

        uint256 srusdAmount = 1e30;

        // deposit new margin account
        uint128 accountId = depositNewMA(user, sec.srusd, srusdAmount);

        vm.prank(user);
        ICoreProxy(sec.core).activateFirstMarketForAccount(accountId, 1);

        (, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.srusd);

        NodeOutput.Data memory srusdUsdcNodeOutput =
            IOracleManagerProxy(sec.oracleManager).process(parentCollateralConfig.oracleNodeId);

        SD59x18 srusdAmountInUSD = sd(int256(srusdAmount)).mul(sd(int256(srusdUsdcNodeOutput.price))).mul(
            UNIT_sd.sub(sd(int256(parentCollateralConfig.priceHaircut)))
        ).div(sd(1e30));

        MarginInfo memory accountUsdNodeMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(accountUsdNodeMarginInfo.marginBalance, srusdAmountInUSD.unwrap(), 0.000001e18, 18);

        CollateralInfo memory accountSrusdCollateralInfo = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.srusd);
        assertEq(accountSrusdCollateralInfo.netDeposits, int256(srusdAmount));
        assertEq(accountSrusdCollateralInfo.marginBalance, int256(srusdAmount));
        assertEq(accountSrusdCollateralInfo.realBalance, int256(srusdAmount));

        uint256 usdcAmount = 1000e6;
        deal(sec.usdc, address(sec.periphery), usdcAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], usdcAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: accountId, token: sec.usdc })
        );

        accountUsdNodeMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(
            accountUsdNodeMarginInfo.marginBalance, srusdAmountInUSD.unwrap() + 1000e18, 0.000001e18, 18
        );

        accountSrusdCollateralInfo = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.srusd);
        assertEq(accountSrusdCollateralInfo.netDeposits, int256(srusdAmount));
        assertEq(accountSrusdCollateralInfo.marginBalance, int256(srusdAmount));
        assertEq(accountSrusdCollateralInfo.realBalance, int256(srusdAmount));
    }

    function check_srusd_cap_exceeded() public {
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 50_000_001e30; // denominated in srusd
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        uint256 collateralPoolSrusdBalance = ICoreProxy(sec.core).getCollateralPoolBalance(1, sec.srusd);

        // deposit new margin account
        uint128 accountId = depositNewMA(user, sec.srusd, amount);

        vm.expectRevert(
            abi.encodeWithSelector(
                ICoreProxy.CollateralCapExceeded.selector,
                1,
                sec.srusd,
                50_000_000e18,
                collateralPoolSrusdBalance + amount
            )
        );
        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);
    }

    function check_srusd_deposit_withdraw() public {
        removeCollateralWithdrawalLimit(sec.srusd);

        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 1000e30; // denominated in srusd

        // deposit new margin account
        uint128 accountId = depositNewMA(user, sec.srusd, amount);

        uint256 coreSrusdBalanceBefore = ITokenProxy(sec.srusd).balanceOf(sec.core);

        amount = 100e30;
        vm.prank(sec.multisig);
        ITokenProxy(sec.srusd).addToFeatureFlagAllowlist(keccak256(bytes("authorizedHolder")), user);
        withdrawMA(accountId, sec.srusd, amount);

        uint256 coreSrusdBalanceAfter = ITokenProxy(sec.srusd).balanceOf(sec.core);

        assertEq(coreSrusdBalanceBefore - coreSrusdBalanceAfter, amount);
    }

    function check_trade_srusdCollateral_depositWithdraw() public {
        mockFreshPrices();

        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 3000e30; // denominated in srusd
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        uint128 accountId = depositNewMA(user, sec.srusd, amount);

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
        vm.prank(sec.multisig);
        ITokenProxy(sec.srusd).addToFeatureFlagAllowlist(keccak256(bytes("authorizedHolder")), user);
        withdrawMA(accountId, sec.srusd, amount);

        checkPoolHealth();
    }

    function check_transfer_srusdCollateral() public {
        vm.prank(sec.pool);
        ITokenProxy(sec.srusd).mint(sec.pool, 100e30);

        vm.prank(sec.pool);
        ITokenProxy(sec.srusd).mint(sec.periphery, 100e30);

        vm.prank(sec.pool);
        ITokenProxy(sec.srusd).mint(sec.core, 100e30);

        (address user,) = makeAddrAndKey("user");

        vm.prank(sec.pool);
        vm.expectRevert(
            abi.encodeWithSelector(IPassivePoolProxy.FeatureUnavailable.selector, keccak256(bytes("authorizedHolder")))
        );
        ITokenProxy(sec.srusd).mint(user, 100e30);

        vm.prank(sec.core);
        vm.expectRevert(
            abi.encodeWithSelector(IPassivePoolProxy.FeatureUnavailable.selector, keccak256(bytes("authorizedHolder")))
        );
        ITokenProxy(sec.srusd).transfer(user, 100e30);
    }
}
