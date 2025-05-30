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

    function test_extendingLongMarketOrder() public {
        check_extendingLongMarketOrder();
    }

    function test_flippingLongMarketOrder() public {
        check_flippingLongMarketOrder();
    }

    function test_extendingShortMarketOrder() public {
        check_extendingShortMarketOrder();
    }

    function test_flippingShortMarketOrder() public {
        check_flippingShortMarketOrder();
    }

    function test_partialReduceLongMarketOrder() public {
        check_partialReduceLongMarketOrder();
    }

    function test_partialReduceShortMarketOrder() public {
        check_partialReduceShortMarketOrder();
    }

    function test_fullReduceShortMarketOrder() public {
        check_fullReduceShortMarketOrder();
    }

    function test_fullReduceLongMarketOrder() public {
        check_fullReduceLongMarketOrder();
    }

    function test_revertWhenExtendingLongReduceMarketOrder() public {
        check_revertWhenExtendingLongReduceMarketOrder();
    }

    function test_revertWhenExtendingShortReduceMarketOrder() public {
        check_revertWhenExtendingShortReduceMarketOrder();
    }

    function test_revertWhenFlipLongReduceMarketOrder() public {
        check_revertWhenFlipLongReduceMarketOrder();
    }

    function test_revertWhenFlipShortReduceMarketOrder() public {
        check_revertWhenFlipShortReduceMarketOrder();
    }

    function test_specialOrderGatewayPermissionToExecuteInCore() public {
        check_specialOrderGatewayPermissionToExecuteInCore();
    }
}
