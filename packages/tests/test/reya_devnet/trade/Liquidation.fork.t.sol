pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { LiquidationPerpOBForkCheck } from "../../reya_common/trade/LiquidationPerpOB.fork.c.sol";

contract LiquidationForkTest is ReyaForkTest, LiquidationPerpOBForkCheck {
    uint128 constant ETH_MARKET_ID = 1;

    function test_Devnet_DutchLiquidation_ETH() public {
        check_DutchLiquidation_PerpOB(ETH_MARKET_ID);
    }

    function test_Devnet_BackstopLiquidation_ETH() public {
        check_BackstopLiquidation_PerpOB(ETH_MARKET_ID);
    }

    function test_Devnet_DutchLiquidation_RevertWhenHealthy_ETH() public {
        check_DutchLiquidation_RevertWhenHealthy_PerpOB(ETH_MARKET_ID);
    }

    function test_Devnet_BackstopLiquidation_RevertAboveAdl_ETH() public {
        check_BackstopLiquidation_RevertAboveAdl_PerpOB(ETH_MARKET_ID);
    }
}
