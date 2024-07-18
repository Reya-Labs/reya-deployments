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

contract WethCollateralForkCheck is BaseReyaForkTest {
    function checkFuzz_WETHMintBurn(address attacker) public {
        (address user,) = makeAddrAndKey("user");
        uint256 amount = 10e18;

        uint256 totalSupplyBefore = IERC20TokenModule(sec.weth).totalSupply();

        // mint
        vm.prank(dec.socketController[sec.weth]);
        IERC20TokenModule(sec.weth).mint(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(sec.weth).mint(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(sec.weth).mint(user, amount);

        // burn
        vm.prank(dec.socketController[sec.weth]);
        IERC20TokenModule(sec.weth).burn(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(sec.weth).burn(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(sec.weth).burn(user, amount);

        uint256 totalSupplyAfter = IERC20TokenModule(sec.weth).totalSupply();
        assertEq(totalSupplyAfter, totalSupplyBefore);
    }

    function check_weth_view_functions() public {
        (address user,) = makeAddrAndKey("user");

        uint256 wethAmount = 1e18;

        // deposit new margin account
        deal(sec.weth, address(sec.periphery), wethAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.weth], wethAmount);
        vm.prank(dec.socketExecutionHelper[sec.weth]);
        uint128 accountId =
            IPeripheryProxy(sec.periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: sec.weth }));

        vm.prank(user);
        ICoreProxy(sec.core).activateFirstMarketForAccount(accountId, 1);

        NodeOutput.Data memory ethUsdcNodeOutput = IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdcNodeId);

        (, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.weth);
        SD59x18 wethAmountInUSD = sd(int256(wethAmount)).mul(sd(int256(ethUsdcNodeOutput.price))).mul(
            UNIT_sd.sub(sd(int256(parentCollateralConfig.priceHaircut)))
        );

        MarginInfo memory accountUsdNodeMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(accountUsdNodeMarginInfo.marginBalance, wethAmountInUSD.unwrap(), 0.000001e18, 18);

        CollateralInfo memory accountWethCollateralInfo = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.weth);
        assertEq(accountWethCollateralInfo.netDeposits, int256(wethAmount));
        assertEq(accountWethCollateralInfo.marginBalance, int256(wethAmount));
        assertEq(accountWethCollateralInfo.realBalance, int256(wethAmount));

        uint256 usdcAmount = 1000e6;
        deal(sec.usdc, address(sec.periphery), usdcAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], usdcAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: accountId, token: sec.usdc })
        );

        accountUsdNodeMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(
            accountUsdNodeMarginInfo.marginBalance, wethAmountInUSD.unwrap() + 1000e18, 0.000001e18, 18
        );

        accountWethCollateralInfo = ICoreProxy(sec.core).getCollateralInfo(accountId, sec.weth);
        assertEq(accountWethCollateralInfo.netDeposits, int256(wethAmount));
        assertEq(accountWethCollateralInfo.marginBalance, int256(wethAmount));
        assertEq(accountWethCollateralInfo.realBalance, int256(wethAmount));
    }

    function check_weth_cap_exceeded() public {
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 501e18; // denominated in weth
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        uint256 collateralPoolWethBalance = ICoreProxy(sec.core).getCollateralPoolBalance(1, sec.weth);

        // deposit new margin account
        deal(sec.weth, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.weth], amount);
        vm.prank(dec.socketExecutionHelper[sec.weth]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.weth) })
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                ICoreProxy.CollateralCapExceeded.selector, 1, sec.weth, 500e18, collateralPoolWethBalance + amount
            )
        );
        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);
    }

    function check_weth_deposit_withdraw() public {
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 50e18; // denominated in weth

        // deposit new margin account
        deal(sec.weth, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.weth], amount);
        vm.prank(dec.socketExecutionHelper[sec.weth]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.weth) })
        );

        uint256 coreWethBalanceBefore = IERC20TokenModule(sec.weth).balanceOf(sec.core);
        uint256 peripheryWethBalanceBefore = IERC20TokenModule(sec.weth).balanceOf(sec.periphery);
        uint256 multisigWethBalanceBefore = IERC20TokenModule(sec.weth).balanceOf(sec.multisig);

        amount = 5e18;
        executePeripheryWithdrawMA(user, userPk, 1, accountId, sec.weth, amount, arbitrumChainId);

        uint256 coreWethBalanceAfter = IERC20TokenModule(sec.weth).balanceOf(sec.core);
        uint256 peripheryWethBalanceAfter = IERC20TokenModule(sec.weth).balanceOf(sec.periphery);
        uint256 multisigWethBalanceAfter = IERC20TokenModule(sec.weth).balanceOf(sec.multisig);
        uint256 withdrawStaticFees = IPeripheryProxy(sec.periphery).getTokenStaticWithdrawFee(
            sec.weth, dec.socketConnector[sec.weth][arbitrumChainId]
        );

        assertEq(coreWethBalanceBefore - coreWethBalanceAfter, amount);
        assertEq(multisigWethBalanceAfter - multisigWethBalanceBefore, withdrawStaticFees);
        // we mock call to socket so funds remain in periphery
        assertEq(peripheryWethBalanceAfter - peripheryWethBalanceBefore, amount - withdrawStaticFees);
    }

    function check_trade_wethCollateral_depositWithdraw() public {
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 1e18; // denominated in weth
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        deal(sec.weth, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.weth], amount);
        vm.prank(dec.socketExecutionHelper[sec.weth]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.weth) })
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

        amount = 0.1e18;
        executePeripheryWithdrawMA(user, userPk, 2, accountId, sec.weth, amount, arbitrumChainId);

        checkPoolHealth();
    }

    function check_WethTradeWithWethCollateral() public {
        (address user, uint256 userPk) = makeAddrAndKey("user");

        (, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.weth);
        uint256 priceHaircut = parentCollateralConfig.priceHaircut;

        // deposit 1 + 10 / (1-haircut) wETH
        uint256 amount = 1e18 + 10e18 * 1e18 / (1e18 - priceHaircut);
        deal(sec.weth, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.weth], amount);
        vm.prank(dec.socketExecutionHelper[sec.weth]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.weth) })
        );

        // user executes short trade on ETH
        (UD60x18 orderPrice,) = executeCoreMatchOrder({
            marketId: 1,
            sender: user,
            base: sd(-10e18),
            priceLimit: ud(0),
            accountId: accountId
        });

        // compute fees paid in rUSD
        uint256 fees = 0;
        {
            uint256 currentPrice = IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdcNodeId).price;
            fees = 10e6 * currentPrice / 1e18 * 0.001e18 / 1e18;
        }

        // withdraw 1 wETH
        executePeripheryWithdrawMA(user, userPk, 1, accountId, sec.weth, 1e18, arbitrumChainId);

        int256 marginBalance0 = ICoreProxy(sec.core).getNodeMarginInfo(accountId, sec.rusd).marginBalance;
        // TODO: when collateral WETH price points to Stork, lower the acceptance to 10 * 0.01e6
        assertApproxEqAbsDecimal(marginBalance0 + int256(fees), 10e6 * int256(orderPrice.unwrap()) / 1e18, 10 * 10e6, 6);

        uint256[] memory randomPrices = new uint256[](4);
        randomPrices[0] = 3000e18;
        randomPrices[1] = 100_000e18;
        randomPrices[2] = orderPrice.unwrap() - 10e18;
        randomPrices[3] = orderPrice.unwrap() + 10e18;

        for (uint256 i = 0; i < 4; i++) {
            vm.mockCall(
                sec.oracleManager,
                abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcNodeId)),
                abi.encode(NodeOutput.Data({ price: randomPrices[i], timestamp: block.timestamp }))
            );

            vm.mockCall(
                sec.oracleManager,
                abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkFallbackNodeId)),
                abi.encode(NodeOutput.Data({ price: randomPrices[i], timestamp: block.timestamp }))
            );

            int256 marginBalance1 = ICoreProxy(sec.core).getNodeMarginInfo(accountId, sec.rusd).marginBalance;

            // TODO: when collateral WETH price points to Stork, lower the acceptance to 10 * 0.01e6
            assertApproxEqAbsDecimal(marginBalance0, marginBalance1, 10 * 10e6, 6);
        }
    }
}
