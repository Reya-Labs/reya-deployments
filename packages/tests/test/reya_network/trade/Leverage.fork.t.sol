pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";

import { ICoreProxy } from "../../../src/interfaces/ICoreProxy.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract LeverageForkTest is ReyaForkTest {
    function test_trade_rusdCollateral_leverage_eth() public {
        // general info
        // this tests 20x leverage is successful
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 3000e6; // denominated in rusd/usdc
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        deal(usdc, address(periphery), amount);
        mockBridgedAmount(socketExecutionHelper[usdc], amount);
        vm.prank(socketExecutionHelper[usdc]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(usdc) }));

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        riskMultipliers = ICoreProxy(core).getRiskMultipliers(1);
        liquidationMarginRequirement = ud(ICoreProxy(core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        imr = liquidationMarginRequirement.mul(ud(riskMultipliers.imMultiplier));
        nodeOutput = IOracleManagerProxy(oracleManager).process(ethUsdNodeId);
        price = ud(nodeOutput.price);
        absBase = base.abs().intoUD60x18();
        leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 20e18, 2e18, 18);

        checkPoolHealth();
    }

    function test_trade_rusdCollateral_leverage_btc() public {
        // general info
        // this tests 20x leverage is successful
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 60_000e6; // denominated in rusd/usdc
        uint128 marketId = 2; // btc
        exchangeId = 1; // passive pool
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(100_000e18);

        // deposit new margin account
        deal(usdc, address(periphery), amount);
        mockBridgedAmount(socketExecutionHelper[usdc], amount);
        vm.prank(socketExecutionHelper[usdc]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(usdc) }));

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        riskMultipliers = ICoreProxy(core).getRiskMultipliers(1);
        liquidationMarginRequirement = ud(ICoreProxy(core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        imr = liquidationMarginRequirement.mul(ud(riskMultipliers.imMultiplier));
        nodeOutput = IOracleManagerProxy(oracleManager).process(btcUsdNodeId);
        price = ud(nodeOutput.price);
        absBase = base.abs().intoUD60x18();
        leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 20e18, 2e18, 18);

        checkPoolHealth();
    }

    function test_trade_wethCollateral_leverage_eth() public {
        // general info
        // this tests 20x leverage is successful
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

        riskMultipliers = ICoreProxy(core).getRiskMultipliers(1);
        liquidationMarginRequirement = ud(ICoreProxy(core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        imr = liquidationMarginRequirement.mul(ud(riskMultipliers.imMultiplier));
        nodeOutput = IOracleManagerProxy(oracleManager).process(ethUsdNodeId);
        price = ud(nodeOutput.price);
        absBase = base.abs().intoUD60x18();
        leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 20e18, 2e18, 18);

        checkPoolHealth();
    }

    function test_trade_wethCollateral_leverage_btc() public {
        // general info
        // this tests 20x leverage is successful
        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 10e18; // denominated in weth
        uint128 marketId = 2; // btc
        exchangeId = 1; // passive pool
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(100_000e18);

        // deposit new margin account
        deal(weth, address(periphery), amount);
        mockBridgedAmount(socketExecutionHelper[weth], amount);
        vm.prank(socketExecutionHelper[weth]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(weth) }));

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        riskMultipliers = ICoreProxy(core).getRiskMultipliers(1);
        liquidationMarginRequirement = ud(ICoreProxy(core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        imr = liquidationMarginRequirement.mul(ud(riskMultipliers.imMultiplier));
        nodeOutput = IOracleManagerProxy(oracleManager).process(btcUsdNodeId);
        price = ud(nodeOutput.price);
        absBase = base.abs().intoUD60x18();
        leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 20e18, 2e18, 18);

        checkPoolHealth();
    }
}
