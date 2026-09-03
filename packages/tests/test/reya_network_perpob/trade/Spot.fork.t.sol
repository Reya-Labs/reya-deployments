pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SpotPerpOBForkCheck } from "../../reya_common/trade/SpotPerpOB.fork.c.sol";

contract SpotForkTest is ReyaForkTest, SpotPerpOBForkCheck {
    uint128 internal constant WETH_SPOT_MARKET_ID = 5;

    function test_SignedSpotFill_WETH() public {
        check_SpotExecuteFill_WETH(WETH_SPOT_MARKET_ID);
    }

    function test_SignedSpotBatchFill_WETH() public {
        check_SpotBatchExecuteFill_WETH(WETH_SPOT_MARKET_ID);
    }

    function test_SignedSpotSmallQuantityAndPrice_WETH() public {
        check_SpotExecuteFill_SmallQuantity_And_Price_WETH(WETH_SPOT_MARKET_ID);
    }
}
