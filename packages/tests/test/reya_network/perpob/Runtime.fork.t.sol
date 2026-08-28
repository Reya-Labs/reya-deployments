// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { FundingRatePerpOBForkCheck } from "../../reya_common/trade/FundingRatePerpOB.fork.c.sol";
import { PermissionsPerpOBForkCheck } from "../../reya_common/trade/PermissionsPerpOB.fork.c.sol";

contract PerpOBRuntimeForkTest is ReyaForkTest, FundingRatePerpOBForkCheck {
    uint128 internal constant ETH_MARKET_ID = 1;
    uint128 internal constant BTC_MARKET_ID = 2;

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
