pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { CoOrderForkCheck } from "../../reya_common/trade/CoOrder.fork.c.sol";

contract CoOrderForkTest is ReyaForkTest, CoOrderForkCheck {
    function test_slOrderOnShortPosition() public {
        check_slOrderOnShortPosition(1);
    }

    function test_slOrderOnLongPosition_BTC() public {
        check_slOrderOnLongPosition(2);
    }

    function test_tpOrderOnShortPosition() public {
        check_tpOrderOnShortPosition(1);
    }

    function test_tpOrderOnLongPosition_BTC() public {
        check_tpOrderOnLongPosition(2);
    }

    function test_shortLimitOrder() public {
        check_shortLimitOrder(1);
    }

    function test_longLimitOrder_BTC() public {
        check_longLimitOrder(2);
    }

    function test_extendingLongMarketOrder() public {
        check_extendingLongMarketOrder(1);
    }

    function test_flippingLongMarketOrder() public {
        check_flippingLongMarketOrder(1);
    }

    function test_extendingShortMarketOrder() public {
        check_extendingShortMarketOrder(1);
    }

    function test_flippingShortMarketOrder() public {
        check_flippingShortMarketOrder(1);
    }

    function test_partialReduceLongMarketOrder() public {
        check_partialReduceLongMarketOrder(1);
    }

    function test_partialReduceShortMarketOrder() public {
        check_partialReduceShortMarketOrder(1);
    }

    function test_fullReduceShortMarketOrder() public {
        check_fullReduceShortMarketOrder(1);
    }

    function test_fullReduceLongMarketOrder() public {
        check_fullReduceLongMarketOrder(1);
    }

    function test_revertWhenExtendingLongReduceMarketOrder() public {
        check_revertWhenExtendingLongReduceMarketOrder(1);
    }

    function test_revertWhenExtendingShortReduceMarketOrder() public {
        check_revertWhenExtendingShortReduceMarketOrder(1);
    }

    function test_revertWhenFlipLongReduceMarketOrder() public {
        check_revertWhenFlipLongReduceMarketOrder(1);
    }

    function test_revertWhenFlipShortReduceMarketOrder() public {
        check_revertWhenFlipShortReduceMarketOrder(1);
    }

    function test_specialOrderGatewayPermissionToExecuteInCore() public {
        check_specialOrderGatewayPermissionToExecuteInCore();
    }
}
