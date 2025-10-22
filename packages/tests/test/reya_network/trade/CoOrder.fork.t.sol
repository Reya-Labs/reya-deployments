pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { CoOrderForkCheck } from "../../reya_common/trade/CoOrder.fork.c.sol";

contract CoOrderForkTest is ReyaForkTest, CoOrderForkCheck {
    function test_slOrderOnShortPosition() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_slOrderOnShortPosition(activeMarkets[i]);
        }
    }

    function test_slOrderOnLongPosition() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_slOrderOnLongPosition(activeMarkets[i]);
        }
    }

    function test_tpOrderOnShortPosition() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_tpOrderOnShortPosition(activeMarkets[i]);
        }
    }

    function test_tpOrderOnLongPosition() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_tpOrderOnLongPosition(activeMarkets[i]);
        }
    }

    function test_shortLimitOrder() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_shortLimitOrder(activeMarkets[i]);
        }
    }

    function test_longLimitOrder() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_longLimitOrder(activeMarkets[i]);
        }
    }

    function test_extendingLongMarketOrder() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_extendingLongMarketOrder(activeMarkets[i]);
        }
    }

    function test_flippingLongMarketOrder() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_flippingLongMarketOrder(activeMarkets[i]);
        }
    }

    function test_extendingShortMarketOrder() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_extendingShortMarketOrder(activeMarkets[i]);
        }
    }

    function test_flippingShortMarketOrder() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_flippingShortMarketOrder(activeMarkets[i]);
        }
    }

    function test_partialReduceLongMarketOrder() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_partialReduceLongMarketOrder(activeMarkets[i]);
        }
    }

    function test_partialReduceShortMarketOrder() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_partialReduceShortMarketOrder(activeMarkets[i]);
        }
    }

    function test_fullReduceShortMarketOrder() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_fullReduceShortMarketOrder(activeMarkets[i]);
        }
    }

    function test_fullReduceLongMarketOrder() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_fullReduceLongMarketOrder(activeMarkets[i]);
        }
    }

    function test_revertWhenExtendingLongReduceMarketOrder() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_revertWhenExtendingLongReduceMarketOrder(activeMarkets[i]);
        }
    }

    function test_revertWhenExtendingShortReduceMarketOrder() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_revertWhenExtendingShortReduceMarketOrder(activeMarkets[i]);
        }
    }

    function test_revertWhenFlipLongReduceMarketOrder() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_revertWhenFlipLongReduceMarketOrder(activeMarkets[i]);
        }
    }

    function test_revertWhenFlipShortReduceMarketOrder() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_revertWhenFlipShortReduceMarketOrder(activeMarkets[i]);
        }
    }

    function test_fullReduceLongOrder() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_fullReduceLongOrder(activeMarkets[i]);
        }
    }

    function test_fullReduceShortOrder() public {
        uint128[] memory activeMarkets = getActiveMarkets();
        for (uint256 i = 0; i < activeMarkets.length; i++) {
            check_fullReduceShortOrder(activeMarkets[i]);
        }
    }

    function test_specialOrderGatewayPermissionToExecuteInCore() public {
        check_specialOrderGatewayPermissionToExecuteInCore();
    }

    function test_batchExecute() public {
        check_batchExecute();
    }

    function test_updatePricesAndBatchExecute() public {
        check_updatePricesAndBatchExecute();
    }
}
