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

    function test_Cronos_MatchOrder_VltzFeeDiscounts_SOL_market() public {
        check_MatchOrder_FeeDiscounts(3, false, true);
    }

    function test_Cronos_MatchOrder_OgAndVltzFeeDiscounts_SOL_market() public {
        check_MatchOrder_FeeDiscounts(3, true, true);
    }
}
