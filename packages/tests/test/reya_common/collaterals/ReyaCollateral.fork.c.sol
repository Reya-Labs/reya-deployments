pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import {
    ICoreProxy,
    GlobalCollateralConfig,
    SpotMarketData,
    SpotMarketConfig
} from "../../../src/interfaces/ICoreProxy.sol";

struct ReyaSpotMarketConfigExpectations {
    uint128 spotMarketId;
    uint256 oracleDeviation;
    uint256 minimumOrderBase;
    uint256 baseSpacing;
    uint256 priceSpacing;
}

contract ReyaCollateralForkCheck is BaseReyaForkTest {
    function check_reya_global_collateral_config() internal view {
        (GlobalCollateralConfig memory globalConfig,) = ICoreProxy(sec.core).getGlobalCollateralConfig(sec.reya);

        assertEq(globalConfig.collateralAdapter, address(0), "REYA collateralAdapter should be zero address");
        assertGt(globalConfig.withdrawalWindowSize, 0, "REYA withdrawalWindowSize should be > 0");
        assertGt(globalConfig.withdrawalTvlPercentageLimit, 0, "REYA withdrawalTvlPercentageLimit should be > 0");
    }

    function check_reya_spot_market_config(ReyaSpotMarketConfigExpectations memory expected) internal view {
        SpotMarketData memory spotMarketData = ICoreProxy(sec.core).getSpotMarketData(expected.spotMarketId);

        assertEq(spotMarketData.baseToken, sec.reya, "baseToken should be REYA");
        assertEq(spotMarketData.quoteToken, sec.rusd, "quoteToken should be rUSD");

        SpotMarketConfig memory config = spotMarketData.config;
        assertEq(config.oracleDeviation, expected.oracleDeviation, "oracleDeviation mismatch");
        assertEq(config.minimumOrderBase, expected.minimumOrderBase, "minimumOrderBase mismatch");
        assertEq(config.baseSpacing, expected.baseSpacing, "baseSpacing mismatch");
        assertEq(config.priceSpacing, expected.priceSpacing, "priceSpacing mismatch");
    }

    function check_reya_spot_market_enabled(uint128 spotMarketId) internal view {
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("spotMarketEnabled")), spotMarketId));
        bool isEnabled = ICoreProxy(sec.core).getFeatureFlagAllowAll(flagId);
        assertTrue(isEnabled, "REYA spot market should be enabled");
    }
}
