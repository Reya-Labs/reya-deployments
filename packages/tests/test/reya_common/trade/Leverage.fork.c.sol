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
    uint256 private constant pumpLeverage = 3e18;

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
        expectedLeverage.push(pumpLeverage);
    }

    function check_trade_leverage(uint128 marketId, address collateral) internal {
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
}
