pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { RSeliniCollateralForkCheck } from "../../reya_common/collaterals/RSeliniCollateral.fork.c.sol";
import "../../reya_common/DataTypes.sol";

contract RSeliniCollateralForkTest is ReyaForkTest, RSeliniCollateralForkCheck {
    function test_rseliniRedemptionAndSubscription() public {
        check_rseliniRedemptionAndSubscription();
    }
}
