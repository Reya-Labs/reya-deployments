pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import {
    ICoreProxy,
    GlobalCollateralConfig,
    SpotMarketData,
    SpotMarketConfig
} from "../../../src/interfaces/ICoreProxy.sol";

struct SreyaSpotMarketConfigExpectations {
    uint128 spotMarketId;
    uint256 oracleDeviation;
    uint256 minimumOrderBase;
    uint256 baseSpacing;
    uint256 priceSpacing;
}

contract SreyaCollateralForkCheck is BaseReyaForkTest {
    function check_sreya_global_collateral_config() internal view {
        (GlobalCollateralConfig memory globalConfig,) = ICoreProxy(sec.core).getGlobalCollateralConfig(sec.sreya);

        assertEq(globalConfig.collateralAdapter, address(0), "sREYA collateralAdapter should be zero address");
        assertGt(globalConfig.withdrawalWindowSize, 0, "sREYA withdrawalWindowSize should be > 0");
        assertGt(globalConfig.withdrawalTvlPercentageLimit, 0, "sREYA withdrawalTvlPercentageLimit should be > 0");
    }

    function check_sreya_spot_market_config(SreyaSpotMarketConfigExpectations memory expected) internal view {
        SpotMarketData memory spotMarketData = ICoreProxy(sec.core).getSpotMarketData(expected.spotMarketId);

        assertEq(spotMarketData.baseToken, sec.sreya, "baseToken should be sREYA");
        assertEq(spotMarketData.quoteToken, sec.rusd, "quoteToken should be rUSD");

        SpotMarketConfig memory config = spotMarketData.config;
        assertEq(config.oracleDeviation, expected.oracleDeviation, "oracleDeviation mismatch");
        assertEq(config.minimumOrderBase, expected.minimumOrderBase, "minimumOrderBase mismatch");
        assertEq(config.baseSpacing, expected.baseSpacing, "baseSpacing mismatch");
        assertEq(config.priceSpacing, expected.priceSpacing, "priceSpacing mismatch");
    }

    function check_sreya_spot_market_disabled(uint128 spotMarketId) internal view {
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("spotMarketEnabled")), spotMarketId));
        bool isEnabled = ICoreProxy(sec.core).getFeatureFlagAllowAll(flagId);
        assertFalse(isEnabled, "sREYA spot market should be disabled");
    }
}
