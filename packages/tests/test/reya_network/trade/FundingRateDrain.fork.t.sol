pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { FundingRateDrainForkCheck } from "../../reya_common/trade/FundingRateDrain.fork.c.sol";

contract FundingRateDrainForkTest is ReyaForkTest, FundingRateDrainForkCheck {
    function test_MaxPoolDrainInOneDay_eth() public {
        check_MaxPoolDrainInOneDay(1);
    }

    function test_MaxPoolDrainInOneDay_NegativeDirection_eth() public {
        check_MaxPoolDrainInOneDay_NegativeDirection(1);
    }

    function test_ExtremeFundingRateMultipleDays_eth() public {
        check_ExtremeFundingRateMultipleDays(1);
    }
}
