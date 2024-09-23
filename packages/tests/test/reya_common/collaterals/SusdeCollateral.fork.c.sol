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

contract SusdeCollateralForkCheck is BaseReyaForkTest {
    function checkFuzz_SUSDEMintBurn(address attacker) public {
        (address user,) = makeAddrAndKey("user");
        uint256 amount = 10e18;

        uint256 totalSupplyBefore = IERC20TokenModule(sec.susde).totalSupply();

        // mint
        vm.prank(dec.socketController[sec.susde]);
        IERC20TokenModule(sec.susde).mint(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(sec.susde).mint(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(sec.susde).mint(user, amount);

        // burn
        vm.prank(dec.socketController[sec.susde]);
        IERC20TokenModule(sec.susde).burn(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(sec.susde).burn(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(sec.susde).burn(user, amount);

        uint256 totalSupplyAfter = IERC20TokenModule(sec.susde).totalSupply();
        assertEq(totalSupplyAfter, totalSupplyBefore);
    }

    function check_susde_view_functions() public {
        (address user,) = makeAddrAndKey("user");

        uint256 susdeAmount = 1e18;

        // deposit new margin account
        deal(sec.susde, address(sec.periphery), susdeAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.susde], susdeAmount);
        vm.prank(dec.socketExecutionHelper[sec.susde]);
        uint128 accountId =
            IPeripheryProxy(sec.periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: sec.susde }));

        vm.prank(user);
        ICoreProxy(sec.core).activateFirstMarketForAccount(accountId, 1);

        NodeOutput.Data memory susdeUsdcNodeOutput =
            IOracleManagerProxy(sec.oracleManager).process(sec.susdeUsdcStorkNodeId);

        (, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.susde);
        SD59x18 susdeAmountInUSD = sd(int256(susdeAmount)).mul(sd(int256(susdeUsdcNodeOutput.price))).mul(
            UNIT_sd.sub(sd(int256(parentCollateralConfig.priceHaircut)))
        );

        MarginInfo memory accountUsdNodeMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(accountUsdNodeMarginInfo.marginBalance, susdeAmountInUSD.unwrap(), 0.000001e18, 18);

        CollateralInfo memory accountSusdeCollateralInfo = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.susde);
        assertEq(accountSusdeCollateralInfo.netDeposits, int256(susdeAmount));
        assertEq(accountSusdeCollateralInfo.marginBalance, int256(susdeAmount));
        assertEq(accountSusdeCollateralInfo.realBalance, int256(susdeAmount));

        uint256 usdcAmount = 1000e6;
        deal(sec.usdc, address(sec.periphery), usdcAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], usdcAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: accountId, token: sec.usdc })
        );

        accountUsdNodeMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(
            accountUsdNodeMarginInfo.marginBalance, susdeAmountInUSD.unwrap() + 1000e18, 0.000001e18, 18
        );

        accountSusdeCollateralInfo = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.susde);
        assertEq(accountSusdeCollateralInfo.netDeposits, int256(susdeAmount));
        assertEq(accountSusdeCollateralInfo.marginBalance, int256(susdeAmount));
        assertEq(accountSusdeCollateralInfo.realBalance, int256(susdeAmount));
    }

    function check_susde_cap_exceeded() public {
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 500_001e18; // denominated in susde
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        uint256 collateralPoolSusdeBalance = ICoreProxy(sec.core).getCollateralPoolBalance(1, sec.susde);

        // deposit new margin account
        deal(sec.susde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.susde], amount);
        vm.prank(dec.socketExecutionHelper[sec.susde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.susde) })
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                ICoreProxy.CollateralCapExceeded.selector, 1, sec.susde, 500_000e18, collateralPoolSusdeBalance + amount
            )
        );
        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);
    }

    function check_susde_deposit_withdraw() public {
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 1000e18; // denominated in susde

        // deposit new margin account
        deal(sec.susde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.susde], amount);
        vm.prank(dec.socketExecutionHelper[sec.susde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.susde) })
        );

        uint256 coreSusdeBalanceBefore = IERC20TokenModule(sec.susde).balanceOf(sec.core);
        uint256 peripherySusdeBalanceBefore = IERC20TokenModule(sec.susde).balanceOf(sec.periphery);
        uint256 multisigSusdeBalanceBefore = IERC20TokenModule(sec.susde).balanceOf(sec.multisig);

        amount = 100e18;
        executePeripheryWithdrawMA(user, userPk, 1, accountId, sec.susde, amount, ethereumChainId);

        uint256 coreSusdeBalanceAfter = IERC20TokenModule(sec.susde).balanceOf(sec.core);
        uint256 peripherySusdeBalanceAfter = IERC20TokenModule(sec.susde).balanceOf(sec.periphery);
        uint256 multisigSusdeBalanceAfter = IERC20TokenModule(sec.susde).balanceOf(sec.multisig);
        uint256 withdrawStaticFees = IPeripheryProxy(sec.periphery).getTokenStaticWithdrawFee(
            sec.susde, dec.socketConnector[sec.susde][ethereumChainId]
        );

        assertEq(coreSusdeBalanceBefore - coreSusdeBalanceAfter, amount);
        assertEq(multisigSusdeBalanceAfter - multisigSusdeBalanceBefore, withdrawStaticFees);
        // we mock call to socket so funds remain in periphery
        assertEq(peripherySusdeBalanceAfter - peripherySusdeBalanceBefore, amount - withdrawStaticFees);
    }

    function check_trade_susdeCollateral_depositWithdraw() public {
        mockFreshPrices();

        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 3000e18; // denominated in susde
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        deal(sec.susde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.susde], amount);
        vm.prank(dec.socketExecutionHelper[sec.susde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.susde) })
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
        executePeripheryWithdrawMA(user, userPk, 2, accountId, sec.susde, amount, ethereumChainId);

        checkPoolHealth();
    }
}
