pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { ReyaBridgingForkCheck } from "../../reya_common/collaterals/ReyaBridging.fork.c.sol";
import "../../reya_common/DataTypes.sol";

contract ReyaBridgingForkTest is ReyaForkTest, ReyaBridgingForkCheck {
    function test_Network_ReyaBridgeIntoSpotMA() public {
        check_ReyaBridgeIntoSpotMA();
    }

    function test_Network_ReyaBridgeIntoNormalMAFails() public {
        check_ReyaBridgeIntoNormalMAFails();
    }

    function test_Network_ReyaStaking() public {
        check_ReyaStaking();
    }

    function test_Network_ReyaUnstaking() public {
        check_ReyaUnstaking();
    }

    function test_Network_ReyaFailsToUnstakeWhenMinAssetAmountIsTooHigh() public {
        check_ReyaFailsToUnstakeWhenMinAssetAmountIsTooHigh();
    }

    function test_Network_ReyaFailsToStakeWhenMinShareAmountIsTooHigh() public {
        check_ReyaFailsToStakeWhenMinShareAmountIsTooHigh();
    }

    function test_Network_ReyaWithdrawLimitInWindowSizes() public {
        check_ReyaWithdrawLimitInWindowSizes();
    }

    function test_Network_StakedReyaWithdrawLimitInWindowSizes() public {
        check_StakedReyaWithdrawLimitInWindowSizes();
    }

    function test_Network_ReyaBridgingPermissions() public {
        check_ReyaBridgingPermissions();
    }

    function test_Network_ReyaStakingPermissions() public {
        check_ReyaStakingPermissions();
    }
}
