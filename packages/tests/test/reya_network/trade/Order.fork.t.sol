pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { OrderForkCheck } from "../../reya_common/trade/Order.fork.c.sol";

contract OrderForkTest is ReyaForkTest, OrderForkCheck {
    function test_MatchOrder_Fees_BTC_market() public {
        check_MatchOrder_Fees(2);
    }

    function test_MatchOrder_ZeroFees_BTC_market() public {
        check_MatchOrder_ZeroFees(2);
    }

    function test_MatchOrder_VltzFeeDiscounts_SOL_market() public {
        check_MatchOrder_FeeDiscounts(3, false, true);
    }

    function test_MatchOrder_OgAndVltzFeeDiscounts_SOL_market() public {
        check_MatchOrder_FeeDiscounts(3, true, true);
    }

    function test_MatchOrder_CachedPoolNodeMarginInfo() public {
        check_MatchOrder_CachedPoolNodeMarginInfo();
    }

    function test_MatchOrder_Spread_ETH_market() public {
        check_MatchOrder_Spread(1, 0.004e18);
    }

    function test_MatchOrder_Spread_BTC_market() public {
        check_MatchOrder_Spread(2, 0.6e18);
    }

    function test_MatchOrder_GasCost_ETH_market() public {
        // Open-trade ceiling tracks the current production-state path. The
        // observed cost reached 13_124_907 at block 219341392 after mainnet
        // configuration/state changes; 14M retains a bounded regression gate.
        check_MatchOrder_GasCost(1, 14_000_000, 2_000_000);
    }

    function test_MatchOrder_ReduceOnlyWhenMaxOiZero_all_markets() public {
        for (uint128 marketId = 1; marketId <= lastMarketId(); marketId++) {
            // Only enabled reduce-only markets: a fully-closed (disabled) market is also reduce-only
            // (maxOpenBase stays 0) but rejects every order with FeatureUnavailable, not OpenInterestExceeded.
            if (isMarketReduceOnly(marketId) && isMarketActive(marketId)) {
                check_MatchOrder_ReduceOnlyWhenMaxOiZero(marketId, sec.passivePoolAccountId);
            }
        }
    }
}
