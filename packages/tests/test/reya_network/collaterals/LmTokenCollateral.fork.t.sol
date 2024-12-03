pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { LmTokenCollateralForkCheck } from "../../reya_common/collaterals/LmTokenCollateral.fork.c.sol";
import "../../reya_common/DataTypes.sol";

contract LmTokenCollateralForkTest is ReyaForkTest, LmTokenCollateralForkCheck {
    function test_rseliniRedemptionAndSubscription() public {
        check_rseliniRedemptionAndSubscription();
    }

    function test_ramberRedemptionAndSubscription() public {
        check_ramberRedemptionAndSubscription();
    }
}
