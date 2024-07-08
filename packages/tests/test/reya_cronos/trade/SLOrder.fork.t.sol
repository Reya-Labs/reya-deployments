pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SLOrderForkCheck } from "../../reya_common/trade/SLOrder.fork.c.sol";

contract SLOrderForkTest is ReyaForkTest, SLOrderForkCheck {
    function test_slOrderOnShortPosition_ETH() public {
        check_slOrderOnShortPosition_ETH();
    }

    function test_slOrderOnLongPosition_BTC() public {
        check_slOrderOnLongPosition_BTC();
    }

    function test_slOrderOnShortPosition_SOL() public {
        check_slOrderOnShortPosition_SOL();
    }
}
