pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { CoOrderForkCheck } from "../../reya_common/trade/CoOrder.fork.c.sol";

contract CoOrderForkTest is ReyaForkTest, CoOrderForkCheck {
    function test_Cronos_slOrderOnShortPosition() public {
        check_slOrderOnShortPosition(1);
    }

    function test_Cronos_slOrderOnLongPosition_BTC() public {
        check_slOrderOnLongPosition(2);
    }

    function test_Cronos_tpOrderOnShortPosition() public {
        check_tpOrderOnShortPosition(1);
    }

    function test_Cronos_tpOrderOnLongPosition_BTC() public {
        check_tpOrderOnLongPosition(2);
    }

    function test_Cronos_shortLimitOrder() public {
        check_shortLimitOrder(1);
    }

    function test_Cronos_longLimitOrder_BTC() public {
        check_longLimitOrder(2);
    }

    function test_Cronos_extendingLongMarketOrder() public {
        check_extendingLongMarketOrder(1);
    }

    function test_Cronos_flippingLongMarketOrder() public {
        check_flippingLongMarketOrder(1);
    }

    function test_Cronos_extendingShortMarketOrder() public {
        check_extendingShortMarketOrder(1);
    }

    function test_Cronos_flippingShortMarketOrder() public {
        check_flippingShortMarketOrder(1);
    }

    function test_Cronos_partialReduceLongMarketOrder() public {
        check_partialReduceLongMarketOrder(1);
    }

    function test_Cronos_partialReduceShortMarketOrder() public {
        check_partialReduceShortMarketOrder(1);
    }

    function test_Cronos_fullReduceShortMarketOrder() public {
        check_fullReduceShortMarketOrder(1);
    }

    function test_Cronos_fullReduceLongMarketOrder() public {
        check_fullReduceLongMarketOrder(1);
    }

    function test_Cronos_revertWhenExtendingLongReduceMarketOrder() public {
        check_revertWhenExtendingLongReduceMarketOrder(1);
    }

    function test_Cronos_revertWhenExtendingShortReduceMarketOrder() public {
        check_revertWhenExtendingShortReduceMarketOrder(1);
    }

    function test_Cronos_revertWhenFlipLongReduceMarketOrder() public {
        check_revertWhenFlipLongReduceMarketOrder(1);
    }

    function test_Cronos_revertWhenFlipShortReduceMarketOrder() public {
        check_revertWhenFlipShortReduceMarketOrder(1);
    }

    function test_Cronos_specialOrderGatewayPermissionToExecuteInCore() public {
        check_specialOrderGatewayPermissionToExecuteInCore();
    }
}
