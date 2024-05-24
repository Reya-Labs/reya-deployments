pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";

import {
    ICoreProxy,
    CollateralConfig,
    ParentCollateralConfig,
    CachedCollateralConfig,
    MarginInfo,
    CollateralInfo
} from "../../../src/interfaces/ICoreProxy.sol";

import {
    IPeripheryProxy, DepositNewMAInputs, DepositExistingMAInputs
} from "../../../src/interfaces/IPeripheryProxy.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { IERC20TokenModule } from "../../../src/interfaces/IERC20TokenModule.sol";

import { sd, SD59x18, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract WethCollateralForkTest is ReyaForkTest {
    function testFuzz_WETHMintBurn(address attacker) public {
        vm.assume(attacker != socketController[weth]);

        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 10e18;

        uint256 totalSupplyBefore = IERC20TokenModule(weth).totalSupply();

        // mint
        vm.prank(socketController[weth]);
        IERC20TokenModule(weth).mint(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(weth).mint(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(weth).mint(user, amount);

        // burn
        vm.prank(socketController[weth]);
        IERC20TokenModule(weth).burn(user, amount);

        vm.prank(attacker);
        vm.expectRevert();
        IERC20TokenModule(weth).burn(user, amount);

        vm.prank(user);
        vm.expectRevert();
        IERC20TokenModule(weth).burn(user, amount);

        uint256 totalSupplyAfter = IERC20TokenModule(weth).totalSupply();
        assertEq(totalSupplyAfter, totalSupplyBefore);
    }

    function test_weth_view_functions() public {
        (user, userPk) = makeAddrAndKey("user");

        uint256 wethAmount = 1e18;

        // deposit new margin account
        deal(weth, address(periphery), wethAmount);
        mockBridgedAmount(socketExecutionHelper[weth], wethAmount);
        vm.prank(socketExecutionHelper[weth]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: weth }));

        vm.prank(user);
        ICoreProxy(core).activateFirstMarketForAccount(accountId, 1);

        NodeOutput.Data memory ethUsdcNodeOutput = IOracleManagerProxy(oracleManager).process(ethUsdcNodeId);

        CollateralConfig memory collateralConfig;
        ParentCollateralConfig memory parentCollateralConfig;
        CachedCollateralConfig memory cacheCollateralConfig;

        (collateralConfig, parentCollateralConfig, cacheCollateralConfig) =
            ICoreProxy(core).getCollateralConfig(1, weth);
        SD59x18 wethAmountInUSD = sd(int256(wethAmount)).mul(sd(int256(ethUsdcNodeOutput.price))).mul(
            UNIT_sd.sub(sd(int256(parentCollateralConfig.priceHaircut)))
        );

        MarginInfo memory accountUsdNodeMarginInfo = ICoreProxy(core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(accountUsdNodeMarginInfo.marginBalance, wethAmountInUSD.unwrap(), 0.000001e18, 18);

        CollateralInfo memory accountWethCollateralInfo = ICoreProxy(core).getCollateralInfo(accountId, weth);
        assertEq(accountWethCollateralInfo.netDeposits, int256(wethAmount));
        assertEq(accountWethCollateralInfo.marginBalance, int256(wethAmount));
        assertEq(accountWethCollateralInfo.realBalance, int256(wethAmount));

        uint256 usdcAmount = 1000e6;
        deal(usdc, address(periphery), usdcAmount);
        mockBridgedAmount(socketExecutionHelper[usdc], usdcAmount);
        vm.prank(socketExecutionHelper[usdc]);
        IPeripheryProxy(periphery).depositExistingMA(DepositExistingMAInputs({ accountId: accountId, token: usdc }));

        accountUsdNodeMarginInfo = ICoreProxy(core).getUsdNodeMarginInfo(accountId);
        assertApproxEqAbsDecimal(
            accountUsdNodeMarginInfo.marginBalance, wethAmountInUSD.unwrap() + 1000e18, 0.000001e18, 18
        );

        accountWethCollateralInfo = ICoreProxy(core).getCollateralInfo(accountId, weth);
        assertEq(accountWethCollateralInfo.netDeposits, int256(wethAmount));
        assertEq(accountWethCollateralInfo.marginBalance, int256(wethAmount));
        assertEq(accountWethCollateralInfo.realBalance, int256(wethAmount));
    }

    function test_weth_cap_exceeded() public {
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 501e18; // denominated in weth
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        uint256 collateralPoolWethBalance = ICoreProxy(core).getCollateralPoolBalance(1, weth);

        // deposit new margin account
        deal(weth, address(periphery), amount);
        mockBridgedAmount(socketExecutionHelper[weth], amount);
        vm.prank(socketExecutionHelper[weth]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(weth) }));

        vm.expectRevert(
            abi.encodeWithSelector(
                ICoreProxy.CollateralCapExceeded.selector, 1, weth, 500e18, collateralPoolWethBalance + amount
            )
        );
        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);
    }

    function test_weth_deposit_withdraw() public {
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 50e18; // denominated in weth

        // deposit new margin account
        deal(weth, address(periphery), amount);
        mockBridgedAmount(socketExecutionHelper[weth], amount);
        vm.prank(socketExecutionHelper[weth]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(weth) }));

        uint256 coreWethBalanceBefore = IERC20TokenModule(weth).balanceOf(core);
        uint256 peripheryWethBalanceBefore = IERC20TokenModule(weth).balanceOf(periphery);
        uint256 multisigWethBalanceBefore = IERC20TokenModule(weth).balanceOf(multisig);

        amount = 5e18;
        executePeripheryWithdrawMA(user, userPk, 1, accountId, weth, amount, arbitrumChainId);

        uint256 coreWethBalanceAfter = IERC20TokenModule(weth).balanceOf(core);
        uint256 peripheryWethBalanceAfter = IERC20TokenModule(weth).balanceOf(periphery);
        uint256 multisigWethBalanceAfter = IERC20TokenModule(weth).balanceOf(multisig);
        uint256 withdrawStaticFees =
            IPeripheryProxy(periphery).getTokenStaticWithdrawFee(weth, socketConnector[weth][arbitrumChainId]);

        assertEq(coreWethBalanceBefore - coreWethBalanceAfter, amount);
        assertEq(multisigWethBalanceAfter - multisigWethBalanceBefore, withdrawStaticFees);
        // we mock call to socket so funds remain in periphery
        assertEq(peripheryWethBalanceAfter - peripheryWethBalanceBefore, amount - withdrawStaticFees);
    }

    function test_trade_wethCollateral_depositWithdraw() public {
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 1e18; // denominated in weth
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        deal(weth, address(periphery), amount);
        mockBridgedAmount(socketExecutionHelper[weth], amount);
        vm.prank(socketExecutionHelper[weth]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(weth) }));

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        uint256 usdcAmount = 1000e6;
        deal(usdc, address(periphery), usdcAmount);
        mockBridgedAmount(socketExecutionHelper[usdc], usdcAmount);
        vm.prank(socketExecutionHelper[usdc]);
        IPeripheryProxy(periphery).depositExistingMA(DepositExistingMAInputs({ accountId: accountId, token: usdc }));

        amount = 0.1e18;
        executePeripheryWithdrawMA(user, userPk, 2, accountId, weth, amount, arbitrumChainId);

        checkPoolHealth();
    }

    function test_WethTradeWithWethCollateral() public {
        (user, userPk) = makeAddrAndKey("user");

        (, ParentCollateralConfig memory parentCollateralConfig,) = ICoreProxy(core).getCollateralConfig(1, weth);
        uint256 priceHaircut = parentCollateralConfig.priceHaircut;

        // deposit 1 + 10 / (1-haircut) wETH
        uint256 amount = 1e18 + 10e18 * 1e18 / (1e18 - priceHaircut);
        deal(weth, address(periphery), amount);
        mockBridgedAmount(socketExecutionHelper[weth], amount);
        vm.prank(socketExecutionHelper[weth]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(weth) }));

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
            uint256 currentPrice = IOracleManagerProxy(oracleManager).process(ethUsdcNodeId).price;
            fees = 10e6 * currentPrice / 1e18 * 0.0005e18 / 1e18;
        }

        // withdraw 1 wETH
        executePeripheryWithdrawMA(user, userPk, 1, accountId, weth, 1e18, arbitrumChainId);

        int256 marginBalance0 = ICoreProxy(core).getNodeMarginInfo(accountId, rusd).marginBalance;
        assertApproxEqAbsDecimal(marginBalance0 + int256(fees), 10e6 * int256(orderPrice.unwrap()) / 1e18, 0.1e6, 6);

        uint256[] memory randomPrices = new uint256[](4);
        randomPrices[0] = 3000e18;
        randomPrices[1] = 100_000e18;
        randomPrices[2] = orderPrice.unwrap() - 10e18;
        randomPrices[3] = orderPrice.unwrap() + 10e18;

        for (uint256 i = 0; i < 4; i++) {
            vm.mockCall(
                oracleManager,
                abi.encodeCall(IOracleManagerProxy.process, (ethUsdcNodeId)),
                abi.encode(NodeOutput.Data({ price: randomPrices[i], timestamp: block.timestamp }))
            );

            int256 marginBalance1 = ICoreProxy(core).getNodeMarginInfo(accountId, rusd).marginBalance;

            assertApproxEqAbsDecimal(marginBalance0, marginBalance1, 0.1e6, 6);
        }
    }
}
