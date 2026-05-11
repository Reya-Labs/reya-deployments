pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { FundingRatePerpOBForkCheck } from "../../reya_common/trade/FundingRatePerpOB.fork.c.sol";

contract FundingRateForkTest is ReyaForkTest, FundingRatePerpOBForkCheck {
    uint128 constant ETH_MARKET_ID = 1;

    function test_Devnet_PushFundingRate_ETH() public {
        check_PushFundingRate(ETH_MARKET_ID);
    }

    function test_Devnet_FundingRateStaleness_ETH() public {
        check_FundingRateStaleness(ETH_MARKET_ID);
    }

    function test_Devnet_PushMarkPrice_ETH() public {
        check_PushMarkPrice(ETH_MARKET_ID);
    }

    function test_Devnet_FundingRateAccrual_ETH() public {
        check_FundingRateAccrual(ETH_MARKET_ID);
    }
}
