pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { PerpFillForkCheck } from "../../reya_common/trade/PerpFill.fork.c.sol";

contract PerpFillForkTest is ReyaForkTest, PerpFillForkCheck {
    uint128 constant ETH_MARKET_ID = 1;

    function test_Devnet_PerpExecuteFill_ETH() public {
        check_PerpExecuteFill(ETH_MARKET_ID);
    }

    function test_Devnet_PerpMarkPriceStaleness_ETH() public {
        check_PerpMarkPriceStaleness(ETH_MARKET_ID);
    }

    function test_Devnet_PerpBatchExecuteFill_ETH() public {
        check_PerpBatchExecuteFill(ETH_MARKET_ID);
    }
}
