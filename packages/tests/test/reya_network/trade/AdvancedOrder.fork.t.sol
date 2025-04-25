pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { AdvancedOrderForkCheck } from "../../reya_common/trade/AdvancedOrder.fork.c.sol";

contract AdvancedOrderForkTest is ReyaForkTest, AdvancedOrderForkCheck {
    function test_Cronos_fullCloseOrderOnShortPosition() public {
        check_fullCloseOrderOnShortPosition();
    }

    function test_Cronos_partialCloseOrderOnShortPosition() public {
        check_partialCloseOrderOnShortPosition();
    }

    function test_Cronos_fullCloseOrderOnLongPosition() public {
        check_fullCloseOrderOnLongPosition();
    }

    function test_Cronos_partialCloseOrderOnLongPosition() public {
        check_partialCloseOrderOnLongPosition();
    }

    function test_Cronos_NotReduceOnlyOrderSkipped() public {
        check_NotReduceOnlyOrderSkipped();
    }

    function test_Cronos_NotReduceOnlyOrderThatFlipsShortIsSkipped() public {
        check_NotReduceOnlyOrderThatFlipsShortIsSkipped();
    }

    function test_Cronos_NotReduceOnlyOrderThatFlipsLongIsSkipped() public {
        check_NotReduceOnlyOrderThatFlipsLongIsSkipped();
    }

    function test_Cronos_NotReduceOnlyOrderThatExtendsLongIsSkipped() public {
        check_NotReduceOnlyOrderThatExtendsLongIsSkipped();
    }

    function test_Cronos_NotReduceOnlyOrderThatExtendsShortIsSkipped() public {
        check_NotReduceOnlyOrderThatExtendsShortIsSkipped();
    }
}
