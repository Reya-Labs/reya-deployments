pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { CoOrderForkCheck } from "../../reya_common/trade/CoOrder.fork.c.sol";

contract CoOrderForkTest is ReyaForkTest, CoOrderForkCheck {
    function test_slOrderOnShortPosition() public {
        check_slOrderOnShortPosition();
    }

    function test_slOrderOnLongPosition_BTC() public {
        check_slOrderOnLongPosition_BTC();
    }

    function test_tpOrderOnShortPosition() public {
        check_tpOrderOnShortPosition();
    }

    function test_tpOrderOnLongPosition_BTC() public {
        check_tpOrderOnLongPosition_BTC();
    }

    function test_shortLimitOrder() public {
        check_shortLimitOrder();
    }

    function test_longLimitOrder_BTC() public {
        check_longLimitOrder_BTC();
    }
}
