pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import {
    ICoreProxy,
    CollateralConfig,
    ParentCollateralConfig,
    GlobalCollateralConfig,
    GlobalCachedCollateralConfig,
    SpotMarketData,
    SpotMarketConfig
} from "../../../src/interfaces/ICoreProxy.sol";

struct WbtcCollateralConfigExpectations {
    bool depositingEnabled;
    uint256 cap;
    uint256 autoExchangeThreshold;
    uint256 autoExchangeInsuranceFee;
    uint256 autoExchangeDustThreshold;
    uint256 priceHaircut;
    uint256 autoExchangeDiscount;
}

struct WbtcSpotMarketConfigExpectations {
    uint128 spotMarketId;
    uint256 oracleDeviation;
    uint256 minimumOrderBase;
    uint256 baseSpacing;
    uint256 priceSpacing;
}

contract WbtcCollateralForkCheck is BaseReyaForkTest {
    function check_wbtc_collateral_config(WbtcCollateralConfigExpectations memory expected) internal view {
        (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.wbtc);

        assertEq(collateralConfig.depositingEnabled, expected.depositingEnabled, "depositingEnabled mismatch");
        assertEq(collateralConfig.cap, expected.cap, "cap mismatch");
        assertEq(collateralConfig.autoExchangeThreshold, expected.autoExchangeThreshold, "autoExchangeThreshold mismatch");
        assertEq(collateralConfig.autoExchangeInsuranceFee, expected.autoExchangeInsuranceFee, "autoExchangeInsuranceFee mismatch");
        assertEq(collateralConfig.autoExchangeDustThreshold, expected.autoExchangeDustThreshold, "autoExchangeDustThreshold mismatch");

        assertEq(parentCollateralConfig.collateralAddress, sec.rusd, "parent collateral should be rUSD");
        assertEq(parentCollateralConfig.priceHaircut, expected.priceHaircut, "priceHaircut mismatch");
        assertEq(parentCollateralConfig.autoExchangeDiscount, expected.autoExchangeDiscount, "autoExchangeDiscount mismatch");
    }

    function check_wbtc_global_collateral_config() internal view {
        (GlobalCollateralConfig memory globalConfig,) = ICoreProxy(sec.core).getGlobalCollateralConfig(sec.wbtc);

        assertEq(globalConfig.collateralAdapter, address(0), "collateralAdapter should be zero address");
        assertEq(globalConfig.withdrawalWindowSize, 1, "withdrawalWindowSize mismatch");
        assertEq(globalConfig.withdrawalTvlPercentageLimit, 1e18, "withdrawalTvlPercentageLimit mismatch");
    }

    function check_wbtc_spot_market_config(WbtcSpotMarketConfigExpectations memory expected) internal view {
        SpotMarketData memory spotMarketData = ICoreProxy(sec.core).getSpotMarketData(expected.spotMarketId);

        assertEq(spotMarketData.baseToken, sec.wbtc, "baseToken should be WBTC");
        assertEq(spotMarketData.quoteToken, sec.rusd, "quoteToken should be rUSD");

        SpotMarketConfig memory config = spotMarketData.config;
        assertEq(config.oracleDeviation, expected.oracleDeviation, "oracleDeviation mismatch");
        assertEq(config.minimumOrderBase, expected.minimumOrderBase, "minimumOrderBase mismatch");
        assertEq(config.baseSpacing, expected.baseSpacing, "baseSpacing mismatch");
        assertEq(config.priceSpacing, expected.priceSpacing, "priceSpacing mismatch");
    }

    function check_wbtc_spot_market_enabled(uint128 spotMarketId) internal view {
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("spotMarketEnabled")), spotMarketId));
        bool isEnabled = ICoreProxy(sec.core).getFeatureFlagAllowAll(flagId);
        assertTrue(isEnabled, "WBTC spot market should be enabled");
    }

    function check_wbtc_auto_exchange_enabled() internal view {
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("autoExchange")), sec.wbtc));
        bool isEnabled = ICoreProxy(sec.core).getFeatureFlagAllowAll(flagId);
        assertTrue(isEnabled, "WBTC auto exchange should be enabled");
    }
}
