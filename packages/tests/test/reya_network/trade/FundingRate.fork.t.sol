pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { FundingRateForkCheck } from "../../reya_common/trade/FundingRate.fork.c.sol";

contract FundingRateForkTest is ReyaForkTest, FundingRateForkCheck {
    function test_FundingVelocity() public {
        check_FundingVelocity(1);
    }
}
