// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import {
    IPassivePerpProxyV2,
    FeeTierParameters,
    GlobalFeeParametersV2,
    GlobalConfigurationDataV2,
    MarketConfigurationDataV2
} from "../../../src/interfaces/IPassivePerpProxyV2.sol";
import { IOrdersGatewayProxyV2, OrdersGatewayConfigurationV2 } from "../../../src/interfaces/IOrdersGatewayProxyV2.sol";
import { PermissionsPerpOBForkCheck } from "../../reya_common/trade/PermissionsPerpOB.fork.c.sol";

contract PerpOBRuntimeForkTest is ReyaForkTest {
    uint128 internal constant ETH_MARKET_ID = 1;
    uint128 internal constant BTC_MARKET_ID = 2;

    function setUp() public override { }

    function test_MainnetPerpOB_SignedFillThroughOrdersGateway_ETH() public {
        check_PerpExecuteFill(ETH_MARKET_ID);
    }

    function test_MainnetPerpOB_SignedFillThroughOrdersGateway_BTC() public {
        check_PerpExecuteFill(BTC_MARKET_ID);
    }

    function test_MainnetPerpOB_PushAndReadMarkPrice_ETH() public {
        check_PushMarkPrice(ETH_MARKET_ID);
    }

    function test_MainnetPerpOB_PushAndReadFundingRate_ETH() public {
        check_PushFundingRate(ETH_MARKET_ID);
    }

    function test_MainnetPerpOB_PushAndReadFundingRate_BTC() public {
        check_PushFundingRate(BTC_MARKET_ID);
    }
}

contract PerpOBPermissionsForkTest is ReyaForkTest, PermissionsPerpOBForkCheck {
    uint128 internal constant ETH_MARKET_ID = 1;

    function setUp() public override { }

    function test_MainnetPerpOB_OraclePusherPermission() public {
        check_OraclePusherPermission(ETH_MARKET_ID);
    }

    function test_MainnetPerpOB_MatchingEnginePermission() public {
        check_MatchingEnginePermission(ETH_MARKET_ID);
    }

    function test_MainnetPerpOB_OraclePushersFeatureFlagState() public view {
        check_OraclePushersFeatureFlagState();
    }

    function test_MainnetPerpOB_MulticallFeatureFlagState() public view {
        check_MulticallFeatureFlagState();
    }
}

contract PerpOBConfigurationForkTest is ReyaForkTest {
    function setUp() public override { }

    function test_MainnetPerpOB_GlobalConfigurationReadback() public view {
        GlobalConfigurationDataV2 memory config = IPassivePerpProxyV2(sec.perp).getGlobalConfiguration();
        assertEq(config.coreProxy, sec.core, "PassivePerp core proxy");
        assertEq(config.exchangeProxy_DEPRECATED, sec.pool, "deprecated exchange proxy tombstone changed");
        assertEq(config.oracleManagerAddress, sec.oracleManager, "oracle manager");
        assertEq(config.maxAbsFundingRate, 0.1e18, "provisional max funding rate");
        assertEq(config.dustAccountId_DEPRECATED, 0, "deprecated PassivePerp dust account");

        OrdersGatewayConfigurationV2 memory gatewayConfig = IOrdersGatewayProxyV2(sec.ordersGateway).getConfiguration();
        assertEq(gatewayConfig.coreProxy, sec.core, "OrdersGateway core proxy");
        assertEq(gatewayConfig.passivePerpProxy, sec.perp, "OrdersGateway PassivePerp proxy");
        assertEq(
            gatewayConfig.oracleAdaptersProxy_DEPRECATED,
            sec.oracleAdaptersProxy,
            "deprecated oracle adapters proxy tombstone changed"
        );
        assertEq(gatewayConfig.dustAccountId, 0, "dust sink must remain unset until PRO-956");
    }

    function test_MainnetPerpOB_ActiveMarketConfigurationReadback() public view {
        _assertActiveMarketConfig(1, 4950e18, 0.01e18, 0.001e18);
        _assertActiveMarketConfig(2, 145e18, 0.001e18, 0.0001e18);
    }

    function test_MainnetPerpOB_FeeConfigurationReadback() public view {
        FeeTierParameters memory tier0 = IPassivePerpProxyV2(sec.perp).getFeeTierParameters(0);
        FeeTierParameters memory tier101 = IPassivePerpProxyV2(sec.perp).getFeeTierParameters(101);
        assertEq(tier0.takerFee, 0.0003e18, "tier 0 taker fee");
        assertEq(tier0.makerRebate_DEPRECATED, 0, "tier 0 deprecated maker rebate");
        assertEq(tier101.takerFee, 0.0001e18, "tier 101 taker fee");
        assertEq(tier101.makerRebate_DEPRECATED, 0, "tier 101 deprecated maker rebate");

        GlobalFeeParametersV2 memory fees = IPassivePerpProxyV2(sec.perp).getGlobalFeeParameters();
        assertEq(fees.ogRebateRate, 0.3e18, "OG rebate");
        assertEq(fees.refereeRebateRate, 0.1e18, "referee rebate");
        assertEq(fees.referrerRebate, 0.1e18, "referrer rebate");
        assertEq(fees.vltzRebateRate, 0.1e18, "VLTZ rebate");
        assertEq(fees.poolRebate, 0.2e18, "pool rebate");
        assertEq(fees.poolAccountId, 2, "pool account");
    }

    function _assertActiveMarketConfig(
        uint128 marketId,
        uint256 maxOpenBase,
        uint256 minimumOrderBase,
        uint256 baseSpacing
    )
        internal
        view
    {
        MarketConfigurationDataV2 memory config = IPassivePerpProxyV2(sec.perp).getMarketConfiguration(marketId);
        assertEq(config.maxOpenBase, maxOpenBase, "max open base");
        assertEq(config.minimumOrderBase, minimumOrderBase, "minimum order base");
        assertEq(config.baseSpacing, baseSpacing, "base spacing");
        assertEq(config.priceSpacing, 0.001e18, "price spacing");
        assertEq(config.markPriceMaxStaleDuration, 60, "mark stale duration");
        assertEq(config.fundingRateMaxStaleDuration, 600, "funding stale duration");
        assertEq(config.markPriceMaxDeviation, 0.05e18, "mark deviation");
        assertEq(config.fillPriceMaxDeviation, 0.05e18, "fill deviation");
        assertEq(config.minFundingInterval, 0, "minimum funding interval");
    }
}
