pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { LiquidationForkCheck } from "../../reya_common/trade/Liquidation.fork.c.sol";

contract LiquidationForkTest is ReyaForkTest, LiquidationForkCheck {
    function test_DutchLiquidation() public {
        check_DutchLiquidation();
    }

    function test_BackstopLiquidation() public {
        check_BackstopLiquidation();
    }
}
