pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SpotForkCheck } from "../../reya_common/trade/Spot.fork.c.sol";

/**
 * @title SpotForkTest
 * @notice Fork tests for spot execution on reya_cronos
 * @dev The spot execution feature allows matching engine fills to be executed for spot markets.
 *      Currently only WETH/RUSD spot market (ID=5) is enabled.
 */
contract SpotForkTest is ReyaForkTest, SpotForkCheck {
    // WETH spot market ID is 5 (the only enabled spot market)
    uint128 constant WETH_SPOT_MARKET_ID = 5;

    function test_SpotExecuteFill_WETH() public {
        check_SpotExecuteFill_WETH(WETH_SPOT_MARKET_ID);
    }

    function test_SpotBatchExecuteFill_WETH() public {
        check_SpotBatchExecuteFill_WETH(WETH_SPOT_MARKET_ID);
    }
}
