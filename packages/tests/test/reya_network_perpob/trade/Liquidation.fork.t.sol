pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { LiquidationPerpOBForkCheck } from "../../reya_common/trade/LiquidationPerpOB.fork.c.sol";

contract LiquidationForkTest is ReyaForkTest, LiquidationPerpOBForkCheck {
    function setUp() public override { }

    function test_DutchLiquidation_ETH() public {
        check_DutchLiquidation_PerpOB(1);
    }

    function test_BackstopLiquidation_ETH() public {
        check_BackstopLiquidation_PerpOB(1);
    }

    function test_DutchLiquidationRejectsHealthyAccount_ETH() public {
        check_DutchLiquidation_RevertWhenHealthy_PerpOB(1);
    }

    function test_BackstopLiquidationRejectsAccountAboveAdl_ETH() public {
        check_BackstopLiquidation_RevertAboveAdl_PerpOB(1);
    }
}
