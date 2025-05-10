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

import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

contract LeverageForkCheck is BaseReyaForkTest {
    uint256 private constant ethLeverage = 25e18;
    uint256 private constant btcLeverage = 40e18;
    uint256 private constant solLeverage = 25e18;
    uint256 private constant arbLeverage = 20e18;
    uint256 private constant opLeverage = 20e18;
    uint256 private constant avaxLeverage = 20e18;
    uint256 private constant mkrLeverage = 25e18;
    uint256 private constant linkLeverage = 20e18;
    uint256 private constant aaveLeverage = 20e18;
    uint256 private constant crvLeverage = 15e18;
    uint256 private constant uniLeverage = 20e18;
    uint256 private constant suiLeverage = 20e18;
    uint256 private constant tiaLeverage = 15e18;
    uint256 private constant seiLeverage = 20e18;
    uint256 private constant zroLeverage = 15e18;
    uint256 private constant xrpLeverage = 15e18;
    uint256 private constant wifLeverage = 15e18;
    uint256 private constant pepe1kLeverage = 15e18;
    uint256 private constant popcatLeverage = 10e18;
    uint256 private constant dogeLeverage = 20e18;
    uint256 private constant kshibLeverage = 20e18;
    uint256 private constant kbonkLeverage = 15e18;
    uint256 private constant aptLeverage = 20e18;
    uint256 private constant bnbLeverage = 40e18;
    uint256 private constant jtoLeverage = 15e18;
    uint256 private constant adaLeverage = 15e18;
    uint256 private constant ldoLeverage = 15e18;
    uint256 private constant polLeverage = 20e18;
    uint256 private constant nearLeverage = 20e18;
    uint256 private constant ftmLeverage = 20e18;
    uint256 private constant enaLeverage = 15e18;
    uint256 private constant eigenLeverage = 15e18;
    uint256 private constant pendleLeverage = 15e18;
    uint256 private constant goatLeverage = 10e18;
    uint256 private constant grassLeverage = 15e18;
    uint256 private constant kneiroLeverage = 10e18;
    uint256 private constant dotLeverage = 25e18;
    uint256 private constant ltcLeverage = 25e18;
    uint256 private constant pythLeverage = 20e18;
    uint256 private constant jupLeverage = 20e18;
    uint256 private constant penguLeverage = 10e18;
    uint256 private constant trumpLeverage = 10e18;
    uint256 private constant hypeLeverage = 15e18;
    uint256 private constant virtualLeverage = 10e18;
    uint256 private constant ai16zLeverage = 10e18;
    uint256 private constant aixbtLeverage = 5e18;
    uint256 private constant sonicLeverage = 15e18;
    uint256 private constant fartcoinLeverage = 5e18;
    uint256 private constant griffainLeverage = 10e18;
    uint256 private constant wldLeverage = 20e18;
    uint256 private constant atomLeverage = 25e18;
    uint256 private constant apeLeverage = 15e18;
    uint256 private constant tonLeverage = 20e18;
    uint256 private constant ondoLeverage = 20e18;
    uint256 private constant trxLeverage = 20e18;
    uint256 private constant injLeverage = 20e18;
    uint256 private constant moveLeverage = 15e18;
    uint256 private constant beraLeverage = 15e18;
    uint256 private constant layerLeverage = 15e18;
    uint256 private constant taoLeverage = 20e18;
    uint256 private constant ipLeverage = 15e18;
    uint256 private constant meLeverage = 15e18;

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
        expectedLeverage.push(wifLeverage);
        expectedLeverage.push(pepe1kLeverage);
        expectedLeverage.push(popcatLeverage);
        expectedLeverage.push(dogeLeverage);
        expectedLeverage.push(kshibLeverage);
        expectedLeverage.push(kbonkLeverage);
        expectedLeverage.push(aptLeverage);
        expectedLeverage.push(bnbLeverage);
        expectedLeverage.push(jtoLeverage);
        expectedLeverage.push(adaLeverage);
        expectedLeverage.push(ldoLeverage);
        expectedLeverage.push(polLeverage);
        expectedLeverage.push(nearLeverage);
        expectedLeverage.push(ftmLeverage);
        expectedLeverage.push(enaLeverage);
        expectedLeverage.push(eigenLeverage);
        expectedLeverage.push(pendleLeverage);
        expectedLeverage.push(goatLeverage);
        expectedLeverage.push(grassLeverage);
        expectedLeverage.push(kneiroLeverage);
        expectedLeverage.push(dotLeverage);
        expectedLeverage.push(ltcLeverage);
        expectedLeverage.push(pythLeverage);
        expectedLeverage.push(jupLeverage);
        expectedLeverage.push(penguLeverage);
        expectedLeverage.push(trumpLeverage);
        expectedLeverage.push(hypeLeverage);
        expectedLeverage.push(virtualLeverage);
        expectedLeverage.push(ai16zLeverage);
        expectedLeverage.push(aixbtLeverage);
        expectedLeverage.push(sonicLeverage);
        expectedLeverage.push(fartcoinLeverage);
        expectedLeverage.push(griffainLeverage);
        expectedLeverage.push(wldLeverage);
        expectedLeverage.push(atomLeverage);
        expectedLeverage.push(apeLeverage);
        expectedLeverage.push(tonLeverage);
        expectedLeverage.push(ondoLeverage);
        expectedLeverage.push(trxLeverage);
        expectedLeverage.push(injLeverage);
        expectedLeverage.push(moveLeverage);
        expectedLeverage.push(beraLeverage);
        expectedLeverage.push(layerLeverage);
        expectedLeverage.push(taoLeverage);
        expectedLeverage.push(ipLeverage);
        expectedLeverage.push(meLeverage);
    }

    function check_trade_leverage_helper(uint128 marketId, address collateral) private {
        mockFreshPrices();
        if (collateral == sec.usdc) {
            removeCollateralCap(sec.rusd);
        } else {
            removeCollateralCap(collateral);
        }

        (user, userPk) = makeAddrAndKey("user");
        uint256 amount = 1_000_000 * 10 ** ITokenProxy(collateral).decimals();
        SD59x18 base = sd(1e18);
        UD60x18 priceLimit = ud(1_000_000e18);

        // deposit new margin account
        uint128 accountId = depositNewMA(user, collateral, amount);

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

    function check_trade_rusdCollateral_leverage_wif() public {
        check_trade_leverage_helper(17, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_pepe1k() public {
        check_trade_leverage_helper(18, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_popcat() public {
        check_trade_leverage_helper(19, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_doge() public {
        check_trade_leverage_helper(20, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_kshib() public {
        check_trade_leverage_helper(21, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_kbonk() public {
        check_trade_leverage_helper(22, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_apt() public {
        check_trade_leverage_helper(23, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_bnb() public {
        check_trade_leverage_helper(24, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_jto() public {
        check_trade_leverage_helper(25, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_ada() public {
        check_trade_leverage_helper(26, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_ldo() public {
        check_trade_leverage_helper(27, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_pol() public {
        check_trade_leverage_helper(28, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_near() public {
        check_trade_leverage_helper(29, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_ftm() public {
        check_trade_leverage_helper(30, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_ena() public {
        check_trade_leverage_helper(31, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_eigen() public {
        check_trade_leverage_helper(32, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_pendle() public {
        check_trade_leverage_helper(33, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_goat() public {
        check_trade_leverage_helper(34, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_grass() public {
        check_trade_leverage_helper(35, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_kneiro() public {
        check_trade_leverage_helper(36, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_dot() public {
        check_trade_leverage_helper(37, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_ltc() public {
        check_trade_leverage_helper(38, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_pyth() public {
        check_trade_leverage_helper(39, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_jup() public {
        check_trade_leverage_helper(40, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_pengu() public {
        check_trade_leverage_helper(41, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_trump() public {
        check_trade_leverage_helper(42, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_hype() public {
        check_trade_leverage_helper(43, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_virtual() public {
        check_trade_leverage_helper(44, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_ai16z() public {
        check_trade_leverage_helper(45, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_aixbt() public {
        check_trade_leverage_helper(46, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_sonic() public {
        check_trade_leverage_helper(47, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_fartcoin() public {
        check_trade_leverage_helper(48, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_griffain() public {
        check_trade_leverage_helper(49, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_wld() public {
        check_trade_leverage_helper(50, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_atom() public {
        check_trade_leverage_helper(51, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_ape() public {
        check_trade_leverage_helper(52, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_ton() public {
        check_trade_leverage_helper(53, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_ondo() public {
        check_trade_leverage_helper(54, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_trx() public {
        check_trade_leverage_helper(55, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_inj() public {
        check_trade_leverage_helper(56, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_move() public {
        check_trade_leverage_helper(57, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_bera() public {
        check_trade_leverage_helper(58, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_layer() public {
        check_trade_leverage_helper(59, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_tao() public {
        check_trade_leverage_helper(60, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_ip() public {
        check_trade_leverage_helper(61, sec.usdc);
    }

    function check_trade_rusdCollateral_leverage_me() public {
        check_trade_leverage_helper(62, sec.usdc);
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

    function check_trade_wethCollateral_leverage_wif() public {
        check_trade_leverage_helper(17, sec.weth);
    }

    function check_trade_wethCollateral_leverage_pepe1k() public {
        check_trade_leverage_helper(18, sec.weth);
    }

    function check_trade_wethCollateral_leverage_popcat() public {
        check_trade_leverage_helper(19, sec.weth);
    }

    function check_trade_wethCollateral_leverage_doge() public {
        check_trade_leverage_helper(20, sec.weth);
    }

    function check_trade_wethCollateral_leverage_kshib() public {
        check_trade_leverage_helper(21, sec.weth);
    }

    function check_trade_wethCollateral_leverage_kbonk() public {
        check_trade_leverage_helper(22, sec.weth);
    }

    function check_trade_wethCollateral_leverage_apt() public {
        check_trade_leverage_helper(23, sec.weth);
    }

    function check_trade_wethCollateral_leverage_bnb() public {
        check_trade_leverage_helper(24, sec.weth);
    }

    function check_trade_wethCollateral_leverage_jto() public {
        check_trade_leverage_helper(25, sec.weth);
    }

    function check_trade_wethCollateral_leverage_ada() public {
        check_trade_leverage_helper(26, sec.weth);
    }

    function check_trade_wethCollateral_leverage_ldo() public {
        check_trade_leverage_helper(27, sec.weth);
    }

    function check_trade_wethCollateral_leverage_pol() public {
        check_trade_leverage_helper(28, sec.weth);
    }

    function check_trade_wethCollateral_leverage_near() public {
        check_trade_leverage_helper(29, sec.weth);
    }

    function check_trade_wethCollateral_leverage_ftm() public {
        check_trade_leverage_helper(30, sec.weth);
    }

    function check_trade_wethCollateral_leverage_ena() public {
        check_trade_leverage_helper(31, sec.weth);
    }

    function check_trade_wethCollateral_leverage_eigen() public {
        check_trade_leverage_helper(32, sec.weth);
    }

    function check_trade_wethCollateral_leverage_pendle() public {
        check_trade_leverage_helper(33, sec.weth);
    }

    function check_trade_wethCollateral_leverage_goat() public {
        check_trade_leverage_helper(34, sec.weth);
    }

    function check_trade_wethCollateral_leverage_grass() public {
        check_trade_leverage_helper(35, sec.weth);
    }

    function check_trade_wethCollateral_leverage_kneiro() public {
        check_trade_leverage_helper(36, sec.weth);
    }

    function check_trade_wethCollateral_leverage_dot() public {
        check_trade_leverage_helper(37, sec.weth);
    }

    function check_trade_wethCollateral_leverage_ltc() public {
        check_trade_leverage_helper(38, sec.weth);
    }

    function check_trade_wethCollateral_leverage_pyth() public {
        check_trade_leverage_helper(39, sec.weth);
    }

    function check_trade_wethCollateral_leverage_jup() public {
        check_trade_leverage_helper(40, sec.weth);
    }

    function check_trade_wethCollateral_leverage_pengu() public {
        check_trade_leverage_helper(41, sec.weth);
    }

    function check_trade_wethCollateral_leverage_trump() public {
        check_trade_leverage_helper(42, sec.weth);
    }

    function check_trade_wethCollateral_leverage_hype() public {
        check_trade_leverage_helper(43, sec.weth);
    }

    function check_trade_wethCollateral_leverage_virtual() public {
        check_trade_leverage_helper(44, sec.weth);
    }

    function check_trade_wethCollateral_leverage_ai16z() public {
        check_trade_leverage_helper(45, sec.weth);
    }

    function check_trade_wethCollateral_leverage_aixbt() public {
        check_trade_leverage_helper(46, sec.weth);
    }

    function check_trade_wethCollateral_leverage_sonic() public {
        check_trade_leverage_helper(47, sec.weth);
    }

    function check_trade_wethCollateral_leverage_fartcoin() public {
        check_trade_leverage_helper(48, sec.weth);
    }

    function check_trade_wethCollateral_leverage_griffain() public {
        check_trade_leverage_helper(49, sec.weth);
    }

    function check_trade_wethCollateral_leverage_wld() public {
        check_trade_leverage_helper(50, sec.weth);
    }

    function check_trade_wethCollateral_leverage_atom() public {
        check_trade_leverage_helper(51, sec.weth);
    }

    function check_trade_wethCollateral_leverage_ape() public {
        check_trade_leverage_helper(52, sec.weth);
    }

    function check_trade_wethCollateral_leverage_ton() public {
        check_trade_leverage_helper(53, sec.weth);
    }

    function check_trade_wethCollateral_leverage_ondo() public {
        check_trade_leverage_helper(54, sec.weth);
    }

    function check_trade_wethCollateral_leverage_trx() public {
        check_trade_leverage_helper(55, sec.weth);
    }

    function check_trade_wethCollateral_leverage_inj() public {
        check_trade_leverage_helper(56, sec.weth);
    }

    function check_trade_wethCollateral_leverage_move() public {
        check_trade_leverage_helper(57, sec.weth);
    }

    function check_trade_wethCollateral_leverage_bera() public {
        check_trade_leverage_helper(58, sec.weth);
    }

    function check_trade_wethCollateral_leverage_layer() public {
        check_trade_leverage_helper(59, sec.weth);
    }

    function check_trade_wethCollateral_leverage_tao() public {
        check_trade_leverage_helper(60, sec.weth);
    }

    function check_trade_wethCollateral_leverage_ip() public {
        check_trade_leverage_helper(61, sec.weth);
    }

    function check_trade_wethCollateral_leverage_me() public {
        check_trade_leverage_helper(62, sec.weth);
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

    function check_trade_usdeCollateral_leverage_wif() public {
        check_trade_leverage_helper(17, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_pepe1k() public {
        check_trade_leverage_helper(18, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_popcat() public {
        check_trade_leverage_helper(19, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_doge() public {
        check_trade_leverage_helper(20, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_kshib() public {
        check_trade_leverage_helper(21, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_kbonk() public {
        check_trade_leverage_helper(22, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_apt() public {
        check_trade_leverage_helper(23, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_bnb() public {
        check_trade_leverage_helper(24, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_jto() public {
        check_trade_leverage_helper(25, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_ada() public {
        check_trade_leverage_helper(26, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_ldo() public {
        check_trade_leverage_helper(27, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_pol() public {
        check_trade_leverage_helper(28, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_near() public {
        check_trade_leverage_helper(29, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_ftm() public {
        check_trade_leverage_helper(30, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_ena() public {
        check_trade_leverage_helper(31, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_eigen() public {
        check_trade_leverage_helper(32, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_pendle() public {
        check_trade_leverage_helper(33, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_goat() public {
        check_trade_leverage_helper(34, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_grass() public {
        check_trade_leverage_helper(35, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_kneiro() public {
        check_trade_leverage_helper(36, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_dot() public {
        check_trade_leverage_helper(37, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_ltc() public {
        check_trade_leverage_helper(38, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_pyth() public {
        check_trade_leverage_helper(39, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_jup() public {
        check_trade_leverage_helper(40, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_pengu() public {
        check_trade_leverage_helper(41, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_trump() public {
        check_trade_leverage_helper(42, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_hype() public {
        check_trade_leverage_helper(43, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_virtual() public {
        check_trade_leverage_helper(44, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_ai16z() public {
        check_trade_leverage_helper(45, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_aixbt() public {
        check_trade_leverage_helper(46, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_sonic() public {
        check_trade_leverage_helper(47, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_fartcoin() public {
        check_trade_leverage_helper(48, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_griffain() public {
        check_trade_leverage_helper(49, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_wld() public {
        check_trade_leverage_helper(50, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_atom() public {
        check_trade_leverage_helper(51, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_ape() public {
        check_trade_leverage_helper(52, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_ton() public {
        check_trade_leverage_helper(53, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_ondo() public {
        check_trade_leverage_helper(54, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_trx() public {
        check_trade_leverage_helper(55, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_inj() public {
        check_trade_leverage_helper(56, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_move() public {
        check_trade_leverage_helper(57, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_bera() public {
        check_trade_leverage_helper(58, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_layer() public {
        check_trade_leverage_helper(59, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_tao() public {
        check_trade_leverage_helper(60, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_ip() public {
        check_trade_leverage_helper(61, sec.usde);
    }

    function check_trade_usdeCollateral_leverage_me() public {
        check_trade_leverage_helper(62, sec.usde);
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

    function check_trade_susdeCollateral_leverage_wif() public {
        check_trade_leverage_helper(17, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_pepe1k() public {
        check_trade_leverage_helper(18, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_popcat() public {
        check_trade_leverage_helper(19, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_doge() public {
        check_trade_leverage_helper(20, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_kshib() public {
        check_trade_leverage_helper(21, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_kbonk() public {
        check_trade_leverage_helper(22, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_apt() public {
        check_trade_leverage_helper(23, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_bnb() public {
        check_trade_leverage_helper(24, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_jto() public {
        check_trade_leverage_helper(25, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_ada() public {
        check_trade_leverage_helper(26, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_ldo() public {
        check_trade_leverage_helper(27, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_pol() public {
        check_trade_leverage_helper(28, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_near() public {
        check_trade_leverage_helper(29, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_ftm() public {
        check_trade_leverage_helper(30, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_ena() public {
        check_trade_leverage_helper(31, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_eigen() public {
        check_trade_leverage_helper(32, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_pendle() public {
        check_trade_leverage_helper(33, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_goat() public {
        check_trade_leverage_helper(34, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_grass() public {
        check_trade_leverage_helper(35, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_kneiro() public {
        check_trade_leverage_helper(36, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_dot() public {
        check_trade_leverage_helper(37, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_ltc() public {
        check_trade_leverage_helper(38, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_pyth() public {
        check_trade_leverage_helper(39, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_jup() public {
        check_trade_leverage_helper(40, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_pengu() public {
        check_trade_leverage_helper(41, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_trump() public {
        check_trade_leverage_helper(42, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_hype() public {
        check_trade_leverage_helper(43, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_virtual() public {
        check_trade_leverage_helper(44, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_ai16z() public {
        check_trade_leverage_helper(45, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_aixbt() public {
        check_trade_leverage_helper(46, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_sonic() public {
        check_trade_leverage_helper(47, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_fartcoin() public {
        check_trade_leverage_helper(48, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_griffain() public {
        check_trade_leverage_helper(49, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_wld() public {
        check_trade_leverage_helper(50, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_atom() public {
        check_trade_leverage_helper(51, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_ape() public {
        check_trade_leverage_helper(52, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_ton() public {
        check_trade_leverage_helper(53, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_ondo() public {
        check_trade_leverage_helper(54, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_trx() public {
        check_trade_leverage_helper(55, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_inj() public {
        check_trade_leverage_helper(56, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_move() public {
        check_trade_leverage_helper(57, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_bera() public {
        check_trade_leverage_helper(58, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_layer() public {
        check_trade_leverage_helper(59, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_tao() public {
        check_trade_leverage_helper(60, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_ip() public {
        check_trade_leverage_helper(61, sec.susde);
    }

    function check_trade_susdeCollateral_leverage_me() public {
        check_trade_leverage_helper(62, sec.susde);
    }

    function check_trade_deusdCollateral_leverage_eth() public {
        check_trade_leverage_helper(1, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_btc() public {
        check_trade_leverage_helper(2, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_sol() public {
        check_trade_leverage_helper(3, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_arb() public {
        check_trade_leverage_helper(4, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_op() public {
        check_trade_leverage_helper(5, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_avax() public {
        check_trade_leverage_helper(6, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_mkr() public {
        check_trade_leverage_helper(7, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_link() public {
        check_trade_leverage_helper(8, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_aave() public {
        check_trade_leverage_helper(9, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_crv() public {
        check_trade_leverage_helper(10, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_uni() public {
        check_trade_leverage_helper(11, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_sui() public {
        check_trade_leverage_helper(12, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_tia() public {
        check_trade_leverage_helper(13, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_sei() public {
        check_trade_leverage_helper(14, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_zro() public {
        check_trade_leverage_helper(15, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_xrp() public {
        check_trade_leverage_helper(16, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_wif() public {
        check_trade_leverage_helper(17, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_pepe1k() public {
        check_trade_leverage_helper(18, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_popcat() public {
        check_trade_leverage_helper(19, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_doge() public {
        check_trade_leverage_helper(20, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_kshib() public {
        check_trade_leverage_helper(21, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_kbonk() public {
        check_trade_leverage_helper(22, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_apt() public {
        check_trade_leverage_helper(23, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_bnb() public {
        check_trade_leverage_helper(24, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_jto() public {
        check_trade_leverage_helper(25, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_ada() public {
        check_trade_leverage_helper(26, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_ldo() public {
        check_trade_leverage_helper(27, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_pol() public {
        check_trade_leverage_helper(28, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_near() public {
        check_trade_leverage_helper(29, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_ftm() public {
        check_trade_leverage_helper(30, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_ena() public {
        check_trade_leverage_helper(31, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_eigen() public {
        check_trade_leverage_helper(32, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_pendle() public {
        check_trade_leverage_helper(33, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_goat() public {
        check_trade_leverage_helper(34, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_grass() public {
        check_trade_leverage_helper(35, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_kneiro() public {
        check_trade_leverage_helper(36, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_dot() public {
        check_trade_leverage_helper(37, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_ltc() public {
        check_trade_leverage_helper(38, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_pyth() public {
        check_trade_leverage_helper(39, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_jup() public {
        check_trade_leverage_helper(40, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_pengu() public {
        check_trade_leverage_helper(41, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_trump() public {
        check_trade_leverage_helper(42, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_hype() public {
        check_trade_leverage_helper(43, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_virtual() public {
        check_trade_leverage_helper(44, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_ai16z() public {
        check_trade_leverage_helper(45, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_aixbt() public {
        check_trade_leverage_helper(46, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_sonic() public {
        check_trade_leverage_helper(47, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_fartcoin() public {
        check_trade_leverage_helper(48, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_griffain() public {
        check_trade_leverage_helper(49, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_wld() public {
        check_trade_leverage_helper(50, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_atom() public {
        check_trade_leverage_helper(51, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_ape() public {
        check_trade_leverage_helper(52, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_ton() public {
        check_trade_leverage_helper(53, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_ondo() public {
        check_trade_leverage_helper(54, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_trx() public {
        check_trade_leverage_helper(55, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_inj() public {
        check_trade_leverage_helper(56, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_move() public {
        check_trade_leverage_helper(57, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_bera() public {
        check_trade_leverage_helper(58, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_layer() public {
        check_trade_leverage_helper(59, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_tao() public {
        check_trade_leverage_helper(60, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_ip() public {
        check_trade_leverage_helper(61, sec.deusd);
    }

    function check_trade_deusdCollateral_leverage_me() public {
        check_trade_leverage_helper(62, sec.deusd);
    }

    function check_trade_sdeusdCollateral_leverage_eth() public {
        check_trade_leverage_helper(1, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_btc() public {
        check_trade_leverage_helper(2, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_sol() public {
        check_trade_leverage_helper(3, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_arb() public {
        check_trade_leverage_helper(4, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_op() public {
        check_trade_leverage_helper(5, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_avax() public {
        check_trade_leverage_helper(6, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_mkr() public {
        check_trade_leverage_helper(7, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_link() public {
        check_trade_leverage_helper(8, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_aave() public {
        check_trade_leverage_helper(9, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_crv() public {
        check_trade_leverage_helper(10, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_uni() public {
        check_trade_leverage_helper(11, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_sui() public {
        check_trade_leverage_helper(12, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_tia() public {
        check_trade_leverage_helper(13, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_sei() public {
        check_trade_leverage_helper(14, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_zro() public {
        check_trade_leverage_helper(15, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_xrp() public {
        check_trade_leverage_helper(16, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_wif() public {
        check_trade_leverage_helper(17, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_pepe1k() public {
        check_trade_leverage_helper(18, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_popcat() public {
        check_trade_leverage_helper(19, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_doge() public {
        check_trade_leverage_helper(20, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_kshib() public {
        check_trade_leverage_helper(21, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_kbonk() public {
        check_trade_leverage_helper(22, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_apt() public {
        check_trade_leverage_helper(23, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_bnb() public {
        check_trade_leverage_helper(24, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_jto() public {
        check_trade_leverage_helper(25, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_ada() public {
        check_trade_leverage_helper(26, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_ldo() public {
        check_trade_leverage_helper(27, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_pol() public {
        check_trade_leverage_helper(28, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_near() public {
        check_trade_leverage_helper(29, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_ftm() public {
        check_trade_leverage_helper(30, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_ena() public {
        check_trade_leverage_helper(31, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_eigen() public {
        check_trade_leverage_helper(32, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_pendle() public {
        check_trade_leverage_helper(33, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_goat() public {
        check_trade_leverage_helper(34, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_grass() public {
        check_trade_leverage_helper(35, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_kneiro() public {
        check_trade_leverage_helper(36, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_dot() public {
        check_trade_leverage_helper(37, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_ltc() public {
        check_trade_leverage_helper(38, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_pyth() public {
        check_trade_leverage_helper(39, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_jup() public {
        check_trade_leverage_helper(40, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_pengu() public {
        check_trade_leverage_helper(41, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_trump() public {
        check_trade_leverage_helper(42, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_hype() public {
        check_trade_leverage_helper(43, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_virtual() public {
        check_trade_leverage_helper(44, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_ai16z() public {
        check_trade_leverage_helper(45, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_aixbt() public {
        check_trade_leverage_helper(46, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_sonic() public {
        check_trade_leverage_helper(47, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_fartcoin() public {
        check_trade_leverage_helper(48, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_griffain() public {
        check_trade_leverage_helper(49, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_wld() public {
        check_trade_leverage_helper(50, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_atom() public {
        check_trade_leverage_helper(51, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_ape() public {
        check_trade_leverage_helper(52, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_ton() public {
        check_trade_leverage_helper(53, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_ondo() public {
        check_trade_leverage_helper(54, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_trx() public {
        check_trade_leverage_helper(55, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_inj() public {
        check_trade_leverage_helper(56, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_move() public {
        check_trade_leverage_helper(57, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_bera() public {
        check_trade_leverage_helper(58, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_layer() public {
        check_trade_leverage_helper(59, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_tao() public {
        check_trade_leverage_helper(60, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_ip() public {
        check_trade_leverage_helper(61, sec.sdeusd);
    }

    function check_trade_sdeusdCollateral_leverage_me() public {
        check_trade_leverage_helper(62, sec.sdeusd);
    }

    function check_trade_rseliniCollateral_leverage_eth() public {
        check_trade_leverage_helper(1, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_btc() public {
        check_trade_leverage_helper(2, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_sol() public {
        check_trade_leverage_helper(3, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_arb() public {
        check_trade_leverage_helper(4, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_op() public {
        check_trade_leverage_helper(5, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_avax() public {
        check_trade_leverage_helper(6, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_mkr() public {
        check_trade_leverage_helper(7, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_link() public {
        check_trade_leverage_helper(8, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_aave() public {
        check_trade_leverage_helper(9, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_crv() public {
        check_trade_leverage_helper(10, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_uni() public {
        check_trade_leverage_helper(11, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_sui() public {
        check_trade_leverage_helper(12, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_tia() public {
        check_trade_leverage_helper(13, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_sei() public {
        check_trade_leverage_helper(14, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_zro() public {
        check_trade_leverage_helper(15, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_xrp() public {
        check_trade_leverage_helper(16, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_wif() public {
        check_trade_leverage_helper(17, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_pepe1k() public {
        check_trade_leverage_helper(18, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_popcat() public {
        check_trade_leverage_helper(19, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_doge() public {
        check_trade_leverage_helper(20, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_kshib() public {
        check_trade_leverage_helper(21, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_kbonk() public {
        check_trade_leverage_helper(22, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_apt() public {
        check_trade_leverage_helper(23, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_bnb() public {
        check_trade_leverage_helper(24, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_jto() public {
        check_trade_leverage_helper(25, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_ada() public {
        check_trade_leverage_helper(26, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_ldo() public {
        check_trade_leverage_helper(27, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_pol() public {
        check_trade_leverage_helper(28, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_near() public {
        check_trade_leverage_helper(29, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_ftm() public {
        check_trade_leverage_helper(30, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_ena() public {
        check_trade_leverage_helper(31, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_eigen() public {
        check_trade_leverage_helper(32, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_pendle() public {
        check_trade_leverage_helper(33, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_goat() public {
        check_trade_leverage_helper(34, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_grass() public {
        check_trade_leverage_helper(35, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_kneiro() public {
        check_trade_leverage_helper(36, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_dot() public {
        check_trade_leverage_helper(37, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_ltc() public {
        check_trade_leverage_helper(38, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_pyth() public {
        check_trade_leverage_helper(39, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_jup() public {
        check_trade_leverage_helper(40, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_pengu() public {
        check_trade_leverage_helper(41, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_trump() public {
        check_trade_leverage_helper(42, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_hype() public {
        check_trade_leverage_helper(43, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_virtual() public {
        check_trade_leverage_helper(44, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_ai16z() public {
        check_trade_leverage_helper(45, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_aixbt() public {
        check_trade_leverage_helper(46, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_sonic() public {
        check_trade_leverage_helper(47, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_fartcoin() public {
        check_trade_leverage_helper(48, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_griffain() public {
        check_trade_leverage_helper(49, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_wld() public {
        check_trade_leverage_helper(50, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_atom() public {
        check_trade_leverage_helper(51, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_ape() public {
        check_trade_leverage_helper(52, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_ton() public {
        check_trade_leverage_helper(53, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_ondo() public {
        check_trade_leverage_helper(54, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_trx() public {
        check_trade_leverage_helper(55, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_inj() public {
        check_trade_leverage_helper(56, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_move() public {
        check_trade_leverage_helper(57, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_bera() public {
        check_trade_leverage_helper(58, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_layer() public {
        check_trade_leverage_helper(59, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_tao() public {
        check_trade_leverage_helper(60, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_ip() public {
        check_trade_leverage_helper(61, sec.rselini);
    }

    function check_trade_rseliniCollateral_leverage_me() public {
        check_trade_leverage_helper(62, sec.rselini);
    }

    function check_trade_ramberCollateral_leverage_eth() public {
        check_trade_leverage_helper(1, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_btc() public {
        check_trade_leverage_helper(2, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_sol() public {
        check_trade_leverage_helper(3, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_arb() public {
        check_trade_leverage_helper(4, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_op() public {
        check_trade_leverage_helper(5, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_avax() public {
        check_trade_leverage_helper(6, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_mkr() public {
        check_trade_leverage_helper(7, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_link() public {
        check_trade_leverage_helper(8, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_aave() public {
        check_trade_leverage_helper(9, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_crv() public {
        check_trade_leverage_helper(10, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_uni() public {
        check_trade_leverage_helper(11, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_sui() public {
        check_trade_leverage_helper(12, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_tia() public {
        check_trade_leverage_helper(13, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_sei() public {
        check_trade_leverage_helper(14, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_zro() public {
        check_trade_leverage_helper(15, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_xrp() public {
        check_trade_leverage_helper(16, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_wif() public {
        check_trade_leverage_helper(17, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_pepe1k() public {
        check_trade_leverage_helper(18, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_popcat() public {
        check_trade_leverage_helper(19, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_doge() public {
        check_trade_leverage_helper(20, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_kshib() public {
        check_trade_leverage_helper(21, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_kbonk() public {
        check_trade_leverage_helper(22, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_apt() public {
        check_trade_leverage_helper(23, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_bnb() public {
        check_trade_leverage_helper(24, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_jto() public {
        check_trade_leverage_helper(25, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_ada() public {
        check_trade_leverage_helper(26, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_ldo() public {
        check_trade_leverage_helper(27, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_pol() public {
        check_trade_leverage_helper(28, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_near() public {
        check_trade_leverage_helper(29, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_ftm() public {
        check_trade_leverage_helper(30, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_ena() public {
        check_trade_leverage_helper(31, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_eigen() public {
        check_trade_leverage_helper(32, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_pendle() public {
        check_trade_leverage_helper(33, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_goat() public {
        check_trade_leverage_helper(34, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_grass() public {
        check_trade_leverage_helper(35, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_kneiro() public {
        check_trade_leverage_helper(36, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_dot() public {
        check_trade_leverage_helper(37, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_ltc() public {
        check_trade_leverage_helper(38, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_pyth() public {
        check_trade_leverage_helper(39, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_jup() public {
        check_trade_leverage_helper(40, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_pengu() public {
        check_trade_leverage_helper(41, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_trump() public {
        check_trade_leverage_helper(42, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_hype() public {
        check_trade_leverage_helper(43, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_virtual() public {
        check_trade_leverage_helper(44, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_ai16z() public {
        check_trade_leverage_helper(45, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_aixbt() public {
        check_trade_leverage_helper(46, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_sonic() public {
        check_trade_leverage_helper(47, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_fartcoin() public {
        check_trade_leverage_helper(48, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_griffain() public {
        check_trade_leverage_helper(49, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_wld() public {
        check_trade_leverage_helper(50, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_atom() public {
        check_trade_leverage_helper(51, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_ape() public {
        check_trade_leverage_helper(52, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_ton() public {
        check_trade_leverage_helper(53, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_ondo() public {
        check_trade_leverage_helper(54, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_trx() public {
        check_trade_leverage_helper(55, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_inj() public {
        check_trade_leverage_helper(56, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_move() public {
        check_trade_leverage_helper(57, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_bera() public {
        check_trade_leverage_helper(58, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_layer() public {
        check_trade_leverage_helper(59, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_tao() public {
        check_trade_leverage_helper(60, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_ip() public {
        check_trade_leverage_helper(61, sec.ramber);
    }

    function check_trade_ramberCollateral_leverage_me() public {
        check_trade_leverage_helper(62, sec.ramber);
    }

    function check_trade_srusdCollateral_leverage_eth() public {
        check_trade_leverage_helper(1, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_btc() public {
        check_trade_leverage_helper(2, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_sol() public {
        check_trade_leverage_helper(3, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_arb() public {
        check_trade_leverage_helper(4, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_op() public {
        check_trade_leverage_helper(5, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_avax() public {
        check_trade_leverage_helper(6, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_mkr() public {
        check_trade_leverage_helper(7, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_link() public {
        check_trade_leverage_helper(8, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_aave() public {
        check_trade_leverage_helper(9, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_crv() public {
        check_trade_leverage_helper(10, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_uni() public {
        check_trade_leverage_helper(11, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_sui() public {
        check_trade_leverage_helper(12, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_tia() public {
        check_trade_leverage_helper(13, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_sei() public {
        check_trade_leverage_helper(14, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_zro() public {
        check_trade_leverage_helper(15, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_xrp() public {
        check_trade_leverage_helper(16, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_wif() public {
        check_trade_leverage_helper(17, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_pepe1k() public {
        check_trade_leverage_helper(18, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_popcat() public {
        check_trade_leverage_helper(19, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_doge() public {
        check_trade_leverage_helper(20, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_kshib() public {
        check_trade_leverage_helper(21, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_kbonk() public {
        check_trade_leverage_helper(22, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_apt() public {
        check_trade_leverage_helper(23, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_bnb() public {
        check_trade_leverage_helper(24, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_jto() public {
        check_trade_leverage_helper(25, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_ada() public {
        check_trade_leverage_helper(26, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_ldo() public {
        check_trade_leverage_helper(27, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_pol() public {
        check_trade_leverage_helper(28, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_near() public {
        check_trade_leverage_helper(29, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_ftm() public {
        check_trade_leverage_helper(30, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_ena() public {
        check_trade_leverage_helper(31, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_eigen() public {
        check_trade_leverage_helper(32, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_pendle() public {
        check_trade_leverage_helper(33, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_goat() public {
        check_trade_leverage_helper(34, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_grass() public {
        check_trade_leverage_helper(35, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_kneiro() public {
        check_trade_leverage_helper(36, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_dot() public {
        check_trade_leverage_helper(37, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_ltc() public {
        check_trade_leverage_helper(38, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_pyth() public {
        check_trade_leverage_helper(39, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_jup() public {
        check_trade_leverage_helper(40, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_pengu() public {
        check_trade_leverage_helper(41, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_trump() public {
        check_trade_leverage_helper(42, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_hype() public {
        check_trade_leverage_helper(43, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_virtual() public {
        check_trade_leverage_helper(44, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_ai16z() public {
        check_trade_leverage_helper(45, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_aixbt() public {
        check_trade_leverage_helper(46, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_sonic() public {
        check_trade_leverage_helper(47, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_fartcoin() public {
        check_trade_leverage_helper(48, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_griffain() public {
        check_trade_leverage_helper(49, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_wld() public {
        check_trade_leverage_helper(50, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_atom() public {
        check_trade_leverage_helper(51, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_ape() public {
        check_trade_leverage_helper(52, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_ton() public {
        check_trade_leverage_helper(53, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_ondo() public {
        check_trade_leverage_helper(54, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_trx() public {
        check_trade_leverage_helper(55, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_inj() public {
        check_trade_leverage_helper(56, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_move() public {
        check_trade_leverage_helper(57, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_bera() public {
        check_trade_leverage_helper(58, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_layer() public {
        check_trade_leverage_helper(59, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_tao() public {
        check_trade_leverage_helper(60, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_ip() public {
        check_trade_leverage_helper(61, sec.srusd);
    }

    function check_trade_srusdCollateral_leverage_me() public {
        check_trade_leverage_helper(62, sec.srusd);
    }
}
