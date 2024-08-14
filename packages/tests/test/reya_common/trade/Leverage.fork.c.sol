pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import {
    ICoreProxy,
    RiskMultipliers,
    MarginInfo,
    CollateralConfig,
    ParentCollateralConfig
} from "../../../src/interfaces/ICoreProxy.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";

import { IOracleManagerProxy } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract LeverageForkCheck is BaseReyaForkTest {
    uint256 private constant ethLeverage = 35e18;
    uint256 private constant btcLeverage = 40e18;
    uint256 private constant solLeverage = 20e18;
    uint256 private constant arbLeverage = 20e18;
    uint256 private constant opLeverage = 20e18;
    uint256 private constant avaxLeverage = 20e18;
    uint256 private constant mkrLeverage = 25e18;
    uint256 private constant linkLeverage = 25e18;
    uint256 private constant aaveLeverage = 25e18;
    uint256 private constant crvLeverage = 25e18;
    uint256 private constant uniLeverage = 20e18;

    function check_trade_rusdCollateral_leverage_eth() public {
        mockFreshPrices();

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdStorkNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), ethLeverage, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_rusdCollateral_leverage_btc() public {
        mockFreshPrices();

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.btcUsdStorkNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), btcLeverage, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_rusdCollateral_leverage_sol() public {
        mockFreshPrices();

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.solUsdStorkNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), solLeverage, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_rusdCollateral_leverage_arb() public {
        mockFreshPrices();

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.arbUsdStorkNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), arbLeverage, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_rusdCollateral_leverage_op() public {
        mockFreshPrices();

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.opUsdStorkNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), opLeverage, 2e18, 18);
    }

    function check_trade_rusdCollateral_leverage_avax() public {
        mockFreshPrices();

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.avaxUsdStorkNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), avaxLeverage, 2e18, 18);
    }

    function check_trade_rusdCollateral_leverage_mkr() public {
        mockFreshPrices();

        // general info
        // this tests 15x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 2000e6; // denominated in rusd/usdc
        uint128 marketId = 7; // mkr
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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.mkrUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), mkrLeverage, 2e18, 18);
    }

    function check_trade_rusdCollateral_leverage_link() public {
        mockFreshPrices();

        // general info
        // this tests 15x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 15e6; // denominated in rusd/usdc
        uint128 marketId = 8; // link
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(100e18);

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.linkUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), linkLeverage, 2e18, 18);
    }

    function check_trade_rusdCollateral_leverage_aave() public {
        mockFreshPrices();

        // general info
        // this tests 15x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 150e6; // denominated in rusd/usdc
        uint128 marketId = 9; // aave
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(250e18);

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.aaveUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), aaveLeverage, 2e18, 18);
    }

    function check_trade_rusdCollateral_leverage_crv() public {
        mockFreshPrices();

        // general info
        // this tests 15x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 0.4e6; // denominated in rusd/usdc
        uint128 marketId = 10; // crv
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(1e18);

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.crvUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), crvLeverage, 2e18, 18);
    }

    function check_trade_rusdCollateral_leverage_uni() public {
        mockFreshPrices();

        // general info
        // this tests 10x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 7e6; // denominated in rusd/usdc
        uint128 marketId = 11; // uni
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(15e18);

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.uniUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), uniLeverage, 2e18, 18);
    }

    function check_trade_wethCollateral_leverage_eth() public {
        mockFreshPrices();
        removeCollateralCap(sec.weth);

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdStorkNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), ethLeverage, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_wethCollateral_leverage_btc() public {
        mockFreshPrices();
        removeCollateralCap(sec.weth);

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.btcUsdStorkNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), btcLeverage, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_wethCollateral_leverage_sol() public {
        mockFreshPrices();
        removeCollateralCap(sec.weth);

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.solUsdStorkNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), solLeverage, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_wethCollateral_leverage_arb() public {
        mockFreshPrices();
        removeCollateralCap(sec.weth);

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.arbUsdStorkNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), arbLeverage, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_wethCollateral_leverage_op() public {
        mockFreshPrices();
        removeCollateralCap(sec.weth);

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.opUsdStorkNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), opLeverage, 2e18, 18);
    }

    function check_trade_wethCollateral_leverage_avax() public {
        mockFreshPrices();
        removeCollateralCap(sec.weth);

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.avaxUsdStorkNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), avaxLeverage, 2e18, 18);
    }

    function check_trade_wethCollateral_leverage_mkr() public {
        mockFreshPrices();
        removeCollateralCap(sec.weth);

        // general info
        // this tests 15x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 1e18; // denominated in weth
        uint128 marketId = 7; // mkr
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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.mkrUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), mkrLeverage, 2e18, 18);
    }

    function check_trade_wethCollateral_leverage_link() public {
        mockFreshPrices();
        removeCollateralCap(sec.weth);

        // general info
        // this tests 15x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 0.004e18; // denominated in weth
        uint128 marketId = 8; // link
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(100e18);

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.linkUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), linkLeverage, 2e18, 18);
    }

    function check_trade_wethCollateral_leverage_aave() public {
        mockFreshPrices();
        removeCollateralCap(sec.weth);

        // general info
        // this tests 15x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 0.05e18; // denominated in weth
        uint128 marketId = 9; // aave
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(250e18);

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.aaveUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), aaveLeverage, 2e18, 18);
    }

    function check_trade_wethCollateral_leverage_crv() public {
        mockFreshPrices();
        removeCollateralCap(sec.weth);

        // general info
        // this tests 10x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 0.004e18; // denominated in weth
        uint128 marketId = 10; // crv
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(1e18);

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.crvUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), crvLeverage, 2e18, 18);
    }

    function check_trade_wethCollateral_leverage_uni() public {
        mockFreshPrices();
        removeCollateralCap(sec.weth);

        // general info
        // this tests 10x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 0.002e18; // denominated in weth
        uint128 marketId = 11; // uni
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(15e18);

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
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.uniUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), uniLeverage, 2e18, 18);
    }

    function check_trade_usdeCollateral_leverage_eth() public {
        mockFreshPrices();
        removeCollateralCap(sec.usde);

        // general info
        // this tests 20x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 3000e18; // denominated in usde
        uint128 marketId = 1; // eth
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        deal(sec.usde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], amount);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdStorkNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), ethLeverage, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_usdeCollateral_leverage_btc() public {
        mockFreshPrices();
        removeCollateralCap(sec.usde);

        // general info
        // this tests 20x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 60_000e18; // denominated in usde
        uint128 marketId = 2; // btc
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(100_000e18);

        // deposit new margin account
        deal(sec.usde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], amount);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.btcUsdStorkNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), btcLeverage, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_usdeCollateral_leverage_sol() public {
        mockFreshPrices();
        removeCollateralCap(sec.usde);

        // general info
        // this tests 13x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 150e18; // denominated in usde
        uint128 marketId = 3; // sol
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(200e18);

        // deposit new margin account
        deal(sec.usde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], amount);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.solUsdStorkNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), solLeverage, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_usdeCollateral_leverage_arb() public {
        mockFreshPrices();
        removeCollateralCap(sec.usde);

        // general info
        // this tests 13x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 0.7e18; // denominated in usde
        uint128 marketId = 4; // arb
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(1.5e18);

        // deposit new margin account
        deal(sec.usde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], amount);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.arbUsdStorkNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), arbLeverage, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_usdeCollateral_leverage_op() public {
        mockFreshPrices();
        removeCollateralCap(sec.usde);

        // general info
        // this tests 13x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 1.7e18; // denominated in usde
        uint128 marketId = 5; // op
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(3e18);

        // deposit new margin account
        deal(sec.usde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], amount);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.opUsdStorkNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), opLeverage, 2e18, 18);
    }

    function check_trade_usdeCollateral_leverage_avax() public {
        mockFreshPrices();
        removeCollateralCap(sec.usde);

        // general info
        // this tests 13x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 28e18; // denominated in usde
        uint128 marketId = 6; // avax
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(40e18);

        // deposit new margin account
        deal(sec.usde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], amount);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.avaxUsdStorkNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), avaxLeverage, 2e18, 18);
    }

    function check_trade_usdeCollateral_leverage_mkr() public {
        mockFreshPrices();
        removeCollateralCap(sec.usde);

        // general info
        // this tests 15x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 2000e18; // denominated in usde
        uint128 marketId = 7; // mkr
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        deal(sec.usde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], amount);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.mkrUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), mkrLeverage, 2e18, 18);
    }

    function check_trade_usdeCollateral_leverage_link() public {
        mockFreshPrices();
        removeCollateralCap(sec.usde);

        // general info
        // this tests 15x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 15e18; // denominated in usde
        uint128 marketId = 8; // link
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(100e18);

        // deposit new margin account
        deal(sec.usde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], amount);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.linkUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), linkLeverage, 2e18, 18);
    }

    function check_trade_usdeCollateral_leverage_aave() public {
        mockFreshPrices();
        removeCollateralCap(sec.usde);

        // general info
        // this tests 15x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 150e18; // denominated in usde
        uint128 marketId = 9; // aave
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(10_000e18);

        // deposit new margin account
        deal(sec.usde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], amount);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.aaveUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), aaveLeverage, 2e18, 18);
    }

    function check_trade_usdeCollateral_leverage_crv() public {
        mockFreshPrices();
        removeCollateralCap(sec.usde);

        // general info
        // this tests 15x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 0.4e18; // denominated in usde
        uint128 marketId = 10; // crv
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(1e18);

        // deposit new margin account
        deal(sec.usde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], amount);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.crvUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), crvLeverage, 2e18, 18);
    }

    function check_trade_usdeCollateral_leverage_uni() public {
        mockFreshPrices();
        removeCollateralCap(sec.usde);

        // general info
        // this tests 10x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 7e18; // denominated in usde
        uint128 marketId = 11; // uni
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(15e18);

        // deposit new margin account
        deal(sec.usde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], amount);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.uniUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), uniLeverage, 2e18, 18);
    }

    function check_trade_susdeCollateral_leverage_eth() public {
        mockFreshPrices();
        removeCollateralCap(sec.susde);

        // general info
        // this tests 20x leverage is successful
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

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.ethUsdNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), ethLeverage, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_susdeCollateral_leverage_btc() public {
        mockFreshPrices();
        removeCollateralCap(sec.susde);

        // general info
        // this tests 20x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 60_000e18; // denominated in susde
        uint128 marketId = 2; // btc
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(100_000e18);

        // deposit new margin account
        deal(sec.susde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.susde], amount);
        vm.prank(dec.socketExecutionHelper[sec.susde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.susde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.btcUsdNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), btcLeverage, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_susdeCollateral_leverage_sol() public {
        mockFreshPrices();
        removeCollateralCap(sec.susde);

        // general info
        // this tests 13x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 150e18; // denominated in susde
        uint128 marketId = 3; // sol
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(200e18);

        // deposit new margin account
        deal(sec.susde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.susde], amount);
        vm.prank(dec.socketExecutionHelper[sec.susde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.susde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.solUsdNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), solLeverage, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_susdeCollateral_leverage_arb() public {
        mockFreshPrices();
        removeCollateralCap(sec.susde);

        // general info
        // this tests 13x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 0.7e18; // denominated in susde
        uint128 marketId = 4; // arb
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(1.5e18);

        // deposit new margin account
        deal(sec.susde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.susde], amount);
        vm.prank(dec.socketExecutionHelper[sec.susde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.susde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.arbUsdNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), arbLeverage, 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_susdeCollateral_leverage_op() public {
        mockFreshPrices();
        removeCollateralCap(sec.susde);

        // general info
        // this tests 13x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 1.7e18; // denominated in susde
        uint128 marketId = 5; // op
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(3e18);

        // deposit new margin account
        deal(sec.susde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.susde], amount);
        vm.prank(dec.socketExecutionHelper[sec.susde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.susde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.opUsdNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), opLeverage, 2e18, 18);
    }

    function check_trade_susdeCollateral_leverage_avax() public {
        mockFreshPrices();
        removeCollateralCap(sec.susde);

        // general info
        // this tests 13x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 28e18; // denominated in susde
        uint128 marketId = 6; // avax
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(40e18);

        // deposit new margin account
        deal(sec.susde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.susde], amount);
        vm.prank(dec.socketExecutionHelper[sec.susde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.susde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.avaxUsdNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), avaxLeverage, 2e18, 18);
    }

    function check_trade_susdeCollateral_leverage_mkr() public {
        mockFreshPrices();
        removeCollateralCap(sec.susde);

        // general info
        // this tests 15x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 2000e18; // denominated in susde
        uint128 marketId = 7; // mkr
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

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.mkrUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), mkrLeverage, 2e18, 18);
    }

    function check_trade_susdeCollateral_leverage_link() public {
        mockFreshPrices();
        removeCollateralCap(sec.susde);

        // general info
        // this tests 15x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 15e18; // denominated in susde
        uint128 marketId = 8; // link
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(100e18);

        // deposit new margin account
        deal(sec.susde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.susde], amount);
        vm.prank(dec.socketExecutionHelper[sec.susde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.susde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.linkUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), linkLeverage, 2e18, 18);
    }

    function check_trade_susdeCollateral_leverage_aave() public {
        mockFreshPrices();
        removeCollateralCap(sec.susde);

        // general info
        // this tests 15x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 150e18; // denominated in susde
        uint128 marketId = 9; // aave
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

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.aaveUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), aaveLeverage, 2e18, 18);
    }

    function check_trade_susdeCollateral_leverage_crv() public {
        mockFreshPrices();
        removeCollateralCap(sec.susde);

        // general info
        // this tests 15x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 0.4e18; // denominated in susde
        uint128 marketId = 10; // crv
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(1e18);

        // deposit new margin account
        deal(sec.susde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.susde], amount);
        vm.prank(dec.socketExecutionHelper[sec.susde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.susde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.crvUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), crvLeverage, 2e18, 18);
    }

    function check_trade_susdeCollateral_leverage_uni() public {
        mockFreshPrices();
        removeCollateralCap(sec.susde);

        // general info
        // this tests 10x leverage is successful
        (address user, uint256 userPk) = makeAddrAndKey("user");
        uint256 amount = 7e18; // denominated in susde
        uint128 marketId = 11; // uni
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(15e18);

        // deposit new margin account
        deal(sec.susde, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.susde], amount);
        vm.prank(dec.socketExecutionHelper[sec.susde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.susde) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(sec.uniUsdcNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), uniLeverage, 2e18, 18);
    }
}
