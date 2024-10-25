pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import { ICoreProxy, ParentCollateralConfig, MarginInfo, CollateralInfo } from "../../../src/interfaces/ICoreProxy.sol";

import {
    IPeripheryProxy, DepositNewMAInputs, DepositExistingMAInputs
} from "../../../src/interfaces/IPeripheryProxy.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { IERC20TokenModule } from "../../../src/interfaces/IERC20TokenModule.sol";

import { sd, SD59x18, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract DeusdCollateralForkCheck is BaseReyaForkTest {
    function checkFuzz_DEUSDMintBurn(address attacker) public {
        (address user,) = makeAddrAndKey("user");
        uint256 amount = 10e18;

        uint256 totalSupplyBefore = IERC20TokenModule(sec.deusd).totalSupply();

        // mint
        vm.prank(dec.socketController[sec.deusd]);
        IERC20TokenModule(sec.deusd).mint(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(sec.deusd).mint(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(sec.deusd).mint(user, amount);

        // burn
        vm.prank(dec.socketController[sec.deusd]);
        IERC20TokenModule(sec.deusd).burn(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(sec.deusd).burn(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(sec.deusd).burn(user, amount);

        uint256 totalSupplyAfter = IERC20TokenModule(sec.deusd).totalSupply();
        assertEq(totalSupplyAfter, totalSupplyBefore);
    }

    function check_deusd_view_functions() public {
        (address user,) = makeAddrAndKey("user");

        uint256 deusdAmount = 1e18;

        // deposit new margin account
        deal(sec.deusd, address(sec.periphery), deusdAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.deusd], deusdAmount);
        vm.prank(dec.socketExecutionHelper[sec.deusd]);
        uint128 accountId =
            IPeripheryProxy(sec.periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: sec.deusd }));

        vm.prank(user);
        ICoreProxy(sec.core).activateFirstMarketForAccount(accountId, 1);

        NodeOutput.Data memory deusdUsdcNodeOutput =
            IOracleManagerProxy(sec.oracleManager).process(sec.deusdUsdcStorkNodeId);

        (, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.deusd);
        SD59x18 deusdAmountInUSD = sd(int256(deusdAmount)).mul(sd(int256(deusdUsdcNodeOutput.price))).mul(
            UNIT_sd.sub(sd(int256(parentCollateralConfig.priceHaircut)))
        );

        MarginInfo memory accountUsdNodeMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(accountUsdNodeMarginInfo.marginBalance, deusdAmountInUSD.unwrap(), 0.000001e18, 18);

        CollateralInfo memory accountDeusdCollateralInfo = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.deusd);
        assertEq(accountDeusdCollateralInfo.netDeposits, int256(deusdAmount));
        assertEq(accountDeusdCollateralInfo.marginBalance, int256(deusdAmount));
        assertEq(accountDeusdCollateralInfo.realBalance, int256(deusdAmount));

        uint256 usdcAmount = 1000e6;
        deal(sec.usdc, address(sec.periphery), usdcAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], usdcAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: accountId, token: sec.usdc })
        );

        accountUsdNodeMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(
            accountUsdNodeMarginInfo.marginBalance, deusdAmountInUSD.unwrap() + 1000e18, 0.000001e18, 18
        );

        accountDeusdCollateralInfo = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.deusd);
        assertEq(accountDeusdCollateralInfo.netDeposits, int256(deusdAmount));
        assertEq(accountDeusdCollateralInfo.marginBalance, int256(deusdAmount));
        assertEq(accountDeusdCollateralInfo.realBalance, int256(deusdAmount));
    }

    function check_deusd_cap_exceeded() public {
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 50_000_001e18; // denominated in deusd
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        uint256 collateralPoolDeusdBalance = ICoreProxy(sec.core).getCollateralPoolBalance(1, sec.deusd);

        // deposit new margin account
        deal(sec.deusd, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.deusd], amount);
        vm.prank(dec.socketExecutionHelper[sec.deusd]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.deusd) })
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                ICoreProxy.CollateralCapExceeded.selector,
                1,
                sec.deusd,
                50_000_000e18,
                collateralPoolDeusdBalance + amount
            )
        );
        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);
    }

    function check_deusd_deposit_withdraw() public {
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 1000e18; // denominated in deusd

        // deposit new margin account
        deal(sec.deusd, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.deusd], amount);
        vm.prank(dec.socketExecutionHelper[sec.deusd]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.deusd) })
        );

        uint256 coreDeusdBalanceBefore = IERC20TokenModule(sec.deusd).balanceOf(sec.core);
        uint256 peripheryDeusdBalanceBefore = IERC20TokenModule(sec.deusd).balanceOf(sec.periphery);
        uint256 multisigDeusdBalanceBefore = IERC20TokenModule(sec.deusd).balanceOf(sec.multisig);

        amount = 100e18;
        executePeripheryWithdrawMA(user, userPk, 1, accountId, sec.deusd, amount, ethereumChainId);

        uint256 coreDeusdBalanceAfter = IERC20TokenModule(sec.deusd).balanceOf(sec.core);
        uint256 peripheryDeusdBalanceAfter = IERC20TokenModule(sec.deusd).balanceOf(sec.periphery);
        uint256 multisigDeusdBalanceAfter = IERC20TokenModule(sec.deusd).balanceOf(sec.multisig);
        uint256 withdrawStaticFees = IPeripheryProxy(sec.periphery).getTokenStaticWithdrawFee(
            sec.deusd, dec.socketConnector[sec.deusd][ethereumChainId]
        );

        assertEq(coreDeusdBalanceBefore - coreDeusdBalanceAfter, amount);
        assertEq(multisigDeusdBalanceAfter - multisigDeusdBalanceBefore, withdrawStaticFees);
        // we mock call to socket so funds remain in periphery
        assertEq(peripheryDeusdBalanceAfter - peripheryDeusdBalanceBefore, amount - withdrawStaticFees);
    }

    function check_trade_deusdCollateral_depositWithdraw() public {
        mockFreshPrices();

        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 3000e18; // denominated in deusd
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        deal(sec.deusd, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.deusd], amount);
        vm.prank(dec.socketExecutionHelper[sec.deusd]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.deusd) })
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
        executePeripheryWithdrawMA(user, userPk, 2, accountId, sec.deusd, amount, ethereumChainId);

        checkPoolHealth();
    }
}
