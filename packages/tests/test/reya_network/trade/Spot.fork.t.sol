pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SpotForkCheck } from "../../reya_common/trade/Spot.fork.c.sol";

/**
 * @title SpotForkTest
 * @notice Fork tests for spot execution on reya_network
 * @dev The spot execution feature allows matching engine fills to be executed for spot markets.
 *      Currently only WETH/RUSD spot market (ID=5) is enabled.
 */
contract SpotForkTest is ReyaForkTest, SpotForkCheck {
    // WETH spot market ID is 5 (the only enabled spot market)
    uint128 constant WETH_SPOT_MARKET_ID = 5;
    // This is WSTETH which is currently disabled
    uint128 constant DISABLED_SPOT_MARKET_ID = 6;

    function test_SpotExecuteFill_WETH() public {
        check_SpotExecuteFill_WETH(WETH_SPOT_MARKET_ID);
    }

    function test_SpotBatchExecuteFill_WETH() public {
        check_SpotBatchExecuteFill_WETH(WETH_SPOT_MARKET_ID);
    }

    function test_SpotExecuteFill_RevertsWhenMarketDisabled() public {
        check_SpotExecuteFill_RevertsWhenMarketDisabled(DISABLED_SPOT_MARKET_ID);
    }

    function test_SpotBatchExecuteFill_PartialSuccess() public {
        check_SpotBatchExecuteFill_PartialSuccess(WETH_SPOT_MARKET_ID, DISABLED_SPOT_MARKET_ID);
    }
}
