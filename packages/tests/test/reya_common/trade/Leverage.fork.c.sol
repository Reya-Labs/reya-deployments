pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import { ICoreProxy, RiskMultipliers, MarginInfo } from "../../../src/interfaces/ICoreProxy.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";

import { IOracleManagerProxy } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract LeverageForkCheck is BaseReyaForkTest {
    function check_trade_rusdCollateral_leverage_eth() public {
        // general info
        // this tests 20x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 3000e6; // denominated in rusd/usdc
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        deal(sec.usdc, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], amount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usdc) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 20e18, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_rusdCollateral_leverage_btc() public {
        // general info
        // this tests 20x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 60_000e6; // denominated in rusd/usdc
        uint128 marketId = 2; // btc
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(100_000e18);

        // deposit new margin account
        deal(sec.usdc, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], amount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usdc) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.btcUsdNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 20e18, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_rusdCollateral_leverage_sol() public {
        // general info
        // this tests 13x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 150e6; // denominated in rusd/usdc
        uint128 marketId = 3; // sol
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(200e18);

        // deposit new margin account
        deal(sec.usdc, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], amount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usdc) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.solUsdNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 15e18, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_rusdCollateral_leverage_arb() public {
        // general info
        // this tests 13x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 0.7e6; // denominated in rusd/usdc
        uint128 marketId = 4; // arb
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(1.5e18);

        // deposit new margin account
        deal(sec.usdc, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], amount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usdc) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.arbUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 10e18, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_rusdCollateral_leverage_op() public {
        // general info
        // this tests 13x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 1.7e6; // denominated in rusd/usdc
        uint128 marketId = 5; // op
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(3e18);

        // deposit new margin account
        deal(sec.usdc, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], amount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usdc) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.opUsdNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 10e18, 2e18, 18);
    }

    function check_trade_rusdCollateral_leverage_avax() public {
        // general info
        // this tests 13x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 28e6; // denominated in rusd/usdc
        uint128 marketId = 6; // avax
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(40e18);

        // deposit new margin account
        deal(sec.usdc, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], amount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usdc) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.avaxUsdNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 10e18, 2e18, 18);
    }

    function check_trade_wethCollateral_leverage_eth() public {
        // general info
        // this tests 20x leverage is successful
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

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 20e18, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_wethCollateral_leverage_btc() public {
        // general info
        // this tests 20x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 10e18; // denominated in weth
        uint128 marketId = 2; // btc
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(100_000e18);

        // deposit new margin account
        deal(sec.weth, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.weth], amount);
        vm.prank(dec.socketExecutionHelper[sec.weth]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.weth) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.btcUsdNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 20e18, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_wethCollateral_leverage_sol() public {
        // general info
        // this tests 20x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 0.05e18; // denominated in weth
        uint128 marketId = 3; // sol
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(200e18);

        // deposit new margin account
        deal(sec.weth, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.weth], amount);
        vm.prank(dec.socketExecutionHelper[sec.weth]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.weth) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.solUsdNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 15e18, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_wethCollateral_leverage_arb() public {
        // general info
        // this tests 20x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 0.0003e18; // denominated in weth
        uint128 marketId = 4; // arb
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(1.5e18);

        // deposit new margin account
        deal(sec.weth, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.weth], amount);
        vm.prank(dec.socketExecutionHelper[sec.weth]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.weth) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.arbUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 10e18, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_wethCollateral_leverage_op() public {
        // general info
        // this tests 13x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 0.00053e18; // denominated in weth
        uint128 marketId = 5; // op
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(3e18);

        // deposit new margin account
        deal(sec.weth, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.weth], amount);
        vm.prank(dec.socketExecutionHelper[sec.weth]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.weth) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.opUsdNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 10e18, 2e18, 18);
    }

    function check_trade_wethCollateral_leverage_avax() public {
        // general info
        // this tests 13x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 0.0087e18; // denominated in weth
        uint128 marketId = 6; // avax
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(40e18);

        // deposit new margin account
        deal(sec.weth, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.weth], amount);
        vm.prank(dec.socketExecutionHelper[sec.weth]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.weth) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.avaxUsdNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), 10e18, 2e18, 18);
    }
}
