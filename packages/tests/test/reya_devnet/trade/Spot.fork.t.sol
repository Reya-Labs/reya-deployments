pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SpotForkCheck } from "../../reya_common/trade/Spot.fork.c.sol";

contract SpotForkTest is ReyaForkTest, SpotForkCheck {
    uint128 constant WETH_SPOT_MARKET_ID = 1;

    function test_Devnet_SpotExecuteFill_WETH() public {
        check_SpotExecuteFill_WETH(WETH_SPOT_MARKET_ID);
    }

    function test_Devnet_SpotBatchExecuteFill_WETH() public {
        check_SpotBatchExecuteFill_WETH(WETH_SPOT_MARKET_ID);
    }

    function test_Devnet_SpotExecuteFill_SmallQuantity_And_Price_WETH() public {
        check_SpotExecuteFill_SmallQuantity_And_Price_WETH(WETH_SPOT_MARKET_ID);
    }
}
