pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SlTpOrderForkCheck } from "../../reya_common/trade/SlTpOrder.fork.c.sol";

contract SlTpOrderForkTest is ReyaForkTest, SlTpOrderForkCheck {
    function test_slOrderOnShortPosition_ETH() public {
        check_slOrderOnShortPosition_ETH();
    }

    function test_slOrderOnLongPosition_BTC() public {
        check_slOrderOnLongPosition_BTC();
    }

    function test_slOrderOnShortPosition_SOL() public {
        check_slOrderOnShortPosition_SOL();
    }

    function test_slOrderOnShortPosition_ARB() public {
        check_slOrderOnShortPosition_ARB();
    }

    function test_slOrderOnShortPosition_OP() public {
        check_slOrderOnShortPosition_OP();
    }

    function test_slOrderOnShortPosition_AVAX() public {
        check_slOrderOnShortPosition_AVAX();
    }

    function test_tpOrderOnShortPosition_ETH() public {
        check_tpOrderOnShortPosition_ETH();
    }

    function test_tpOrderOnLongPosition_BTC() public {
        check_tpOrderOnLongPosition_BTC();
    }

    function test_tpOrderOnShortPosition_SOL() public {
        check_tpOrderOnShortPosition_SOL();
    }

    function test_tpOrderOnShortPosition_ARB() public {
        check_tpOrderOnShortPosition_ARB();
    }

    function test_tpOrderOnShortPosition_OP() public {
        check_tpOrderOnShortPosition_OP();
    }

    function test_tpOrderOnShortPosition_AVAX() public {
        check_tpOrderOnShortPosition_AVAX();
    }
}
