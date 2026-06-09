pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { OrderForkCheck } from "../../reya_common/trade/Order.fork.c.sol";

contract OrderForkTest is ReyaForkTest, OrderForkCheck {
    function test_MatchOrder_Fees_ETH_market() public {
        check_MatchOrder_Fees(1);
    }

    function test_MatchOrder_ZeroFees_ETH_market() public {
        check_MatchOrder_ZeroFees(1);
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
        // Open-trade ceiling bumped from 11M to 11.5M: natural state drift on
        // forked mainnet has been crossing the prior tight ceiling by tens of
        // thousands of gas (e.g. 11_001_876 on PR #475's CI). 11.5M still
        // catches a real regression (~5% headroom) without flaking on drift.
        check_MatchOrder_GasCost(1, 11_500_000, 2_000_000);
    }

    function test_MatchOrder_ReduceOnlyWhenMaxOiZero_all_markets() public {
        for (uint128 marketId = 1; marketId <= lastMarketId(); marketId++) {
            if (isMarketReduceOnly(marketId)) {
                check_MatchOrder_ReduceOnlyWhenMaxOiZero(marketId, sec.passivePoolAccountId);
            }
        }
    }
}
