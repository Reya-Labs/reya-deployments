pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SreyaCollateralForkCheck } from "../../reya_common/collaterals/SreyaCollateral.fork.c.sol";

contract SreyaCollateralForkTest is ReyaForkTest, SreyaCollateralForkCheck {
    function test_sreya_global_collateral_config() public view {
        check_sreya_global_collateral_config();
    }
}
