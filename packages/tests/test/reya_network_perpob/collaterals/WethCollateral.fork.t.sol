pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { WethCollateralPerpOBForkCheck } from "../../reya_common/collaterals/WethCollateralPerpOB.fork.c.sol";

contract WethCollateralForkTest is ReyaForkTest, WethCollateralPerpOBForkCheck {
    function setUp() public override { }

    function test_WethTradeWithWethCollateral() public {
        check_WethTradeWithWethCollateral_PerpOB(1);
    }
}
