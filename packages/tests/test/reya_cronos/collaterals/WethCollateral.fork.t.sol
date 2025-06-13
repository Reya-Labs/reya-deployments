pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { WethCollateralForkCheck } from "../../reya_common/collaterals/WethCollateral.fork.c.sol";
import "../../reya_common/DataTypes.sol";

contract WethCollateralForkTest is ReyaForkTest, WethCollateralForkCheck {
    function test_Cronos_WethTradeWithWethCollateral() public {
        check_WethTradeWithWethCollateral();
    }
}
