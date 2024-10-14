pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import {
    ICoreProxy,
    RiskMultipliers,
    MarginInfo,
    CollateralConfig,
    ParentCollateralConfig
} from "../../../src/interfaces/ICoreProxy.sol";

import { IPassivePerpProxy, MarketConfigurationData } from "../../../src/interfaces/IPassivePerpProxy.sol";

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
    uint256 private constant suiLeverage = 15e18;
    uint256 private constant tiaLeverage = 5e18;
    uint256 private constant seiLeverage = 15e18;
    uint256 private constant zroLeverage = 5e18;
    uint256 private constant xrpLeverage = 30e18;

    address private user;
    uint256 private userPk;

    uint256[] private expectedLeverage;

    function setUp() public {
        removeMarketsOILimit();

        expectedLeverage.push(0);
        expectedLeverage.push(ethLeverage);
        expectedLeverage.push(btcLeverage);
        expectedLeverage.push(solLeverage);
        expectedLeverage.push(arbLeverage);
        expectedLeverage.push(opLeverage);
        expectedLeverage.push(avaxLeverage);
        expectedLeverage.push(mkrLeverage);
        expectedLeverage.push(linkLeverage);
        expectedLeverage.push(aaveLeverage);
        expectedLeverage.push(crvLeverage);
        expectedLeverage.push(uniLeverage);
        expectedLeverage.push(suiLeverage);
        expectedLeverage.push(tiaLeverage);
        expectedLeverage.push(seiLeverage);
        expectedLeverage.push(zroLeverage);
        expectedLeverage.push(xrpLeverage);
    }

    function check_trade_leverage_helper(uint128 marketId, address collateral) private {
        mockFreshPrices();
        if (collateral == sec.usdc) {
            removeCollateralCap(sec.rusd);
        } else {
            removeCollateralCap(collateral);
        }

        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 1_000_000e18;
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(1_000_000e18);

        // deposit new margin account
        deal(collateral, address(sec.periphery), amount);
        mockBridgedAmount(dec.socketExecutionHelper[collateral], amount);
        vm.prank(dec.socketExecutionHelper[collateral]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(collateral) })
        );

        executePeripheryMatchOrder(userPk, 1, marketId, base, priceLimit, accountId);

        assertEq(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountId).base, base.unwrap());

        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        MarketConfigurationData memory marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(accountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(IOracleManagerProxy(sec.oracleManager).process(marketConfig.oracleNodeId).price);
        UD60x18 absBase = base.abs().intoUD60x18();
        UD60x18 leverage = absBase.mul(price).div(imr);
        assertApproxEqAbsDecimal(leverage.unwrap(), expectedLeverage[marketId], 2e18, 18);

        checkPoolHealth();
    }

    function check_trade_rusdCollateral_leverage_eth() public {
        check_trade_leverage_helper(1, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_btc() public {
        check_trade_leverage_helper(2, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_sol() public {
        check_trade_leverage_helper(3, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_arb() public {
        check_trade_leverage_helper(4, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_op() public {
        check_trade_leverage_helper(5, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_avax() public {
        check_trade_leverage_helper(6, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_mkr() public {
        check_trade_leverage_helper(7, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_link() public {
        check_trade_leverage_helper(8, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_aave() public {
        check_trade_leverage_helper(9, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_crv() public {
        check_trade_leverage_helper(10, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_uni() public {
        check_trade_leverage_helper(11, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_sui() public {
        check_trade_leverage_helper(12, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_tia() public {
        check_trade_leverage_helper(13, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_sei() public {
        check_trade_leverage_helper(14, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_zro() public {
        check_trade_leverage_helper(15, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_xrp() public {
        check_trade_leverage_helper(16, sec.usdc);
    }

    function check_trade_wethCollateral_leverage_eth() public {
        check_trade_leverage_helper(1, sec.weth);
    }

    function check_trade_wethCollateral_leverage_btc() public {
        check_trade_leverage_helper(2, sec.weth);
    }

    function check_trade_wethCollateral_leverage_sol() public {
        check_trade_leverage_helper(3, sec.weth);
    }

    function check_trade_wethCollateral_leverage_arb() public {
        check_trade_leverage_helper(4, sec.weth);
    }

    function check_trade_wethCollateral_leverage_op() public {
        check_trade_leverage_helper(5, sec.weth);
    }

    function check_trade_wethCollateral_leverage_avax() public {
        check_trade_leverage_helper(6, sec.weth);
    }

    function check_trade_wethCollateral_leverage_mkr() public {
        check_trade_leverage_helper(7, sec.weth);
    }

    function check_trade_wethCollateral_leverage_link() public {
        check_trade_leverage_helper(8, sec.weth);
    }

    function check_trade_wethCollateral_leverage_aave() public {
        check_trade_leverage_helper(9, sec.weth);
    }

    function check_trade_wethCollateral_leverage_crv() public {
        check_trade_leverage_helper(10, sec.weth);
    }

    function check_trade_wethCollateral_leverage_uni() public {
        check_trade_leverage_helper(11, sec.weth);
    }

    function check_trade_wethCollateral_leverage_sui() public {
        check_trade_leverage_helper(12, sec.weth);
    }

    function check_trade_wethCollateral_leverage_tia() public {
        check_trade_leverage_helper(13, sec.weth);
    }

    function check_trade_wethCollateral_leverage_sei() public {
        check_trade_leverage_helper(14, sec.weth);
    }

    function check_trade_wethCollateral_leverage_zro() public {
        check_trade_leverage_helper(15, sec.weth);
    }

    function check_trade_wethCollateral_leverage_xrp() public {
        check_trade_leverage_helper(16, sec.weth);
    }

    function check_trade_usdeCollateral_leverage_eth() public {
        check_trade_leverage_helper(1, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_btc() public {
        check_trade_leverage_helper(2, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_sol() public {
        check_trade_leverage_helper(3, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_arb() public {
        check_trade_leverage_helper(4, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_op() public {
        check_trade_leverage_helper(5, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_avax() public {
        check_trade_leverage_helper(6, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_mkr() public {
        check_trade_leverage_helper(7, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_link() public {
        check_trade_leverage_helper(8, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_aave() public {
        check_trade_leverage_helper(9, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_crv() public {
        check_trade_leverage_helper(10, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_uni() public {
        check_trade_leverage_helper(11, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_sui() public {
        check_trade_leverage_helper(12, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_tia() public {
        check_trade_leverage_helper(13, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_sei() public {
        check_trade_leverage_helper(14, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_zro() public {
        check_trade_leverage_helper(15, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_xrp() public {
        check_trade_leverage_helper(16, sec.usde);
    }

    function check_trade_susdeCollateral_leverage_eth() public {
        check_trade_leverage_helper(1, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_btc() public {
        check_trade_leverage_helper(2, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_sol() public {
        check_trade_leverage_helper(3, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_arb() public {
        check_trade_leverage_helper(4, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_op() public {
        check_trade_leverage_helper(5, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_avax() public {
        check_trade_leverage_helper(6, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_mkr() public {
        check_trade_leverage_helper(7, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_link() public {
        check_trade_leverage_helper(8, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_aave() public {
        check_trade_leverage_helper(9, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_crv() public {
        check_trade_leverage_helper(10, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_uni() public {
        check_trade_leverage_helper(11, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_sui() public {
        check_trade_leverage_helper(12, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_tia() public {
        check_trade_leverage_helper(13, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_sei() public {
        check_trade_leverage_helper(14, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_zro() public {
        check_trade_leverage_helper(15, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_xrp() public {
        check_trade_leverage_helper(16, sec.susde);
    }
}
