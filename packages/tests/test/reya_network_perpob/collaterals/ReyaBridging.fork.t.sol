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

    function test_Network_ReyaBridgingPermissions() public {
        check_ReyaBridgingPermissions();
    }

    function test_Network_ReyaStakingPermissions() public {
        check_ReyaStakingPermissions();
    }

    function test_Network_ReyaWithdrawMALZ() public {
        check_ReyaWithdrawMALZ();
    }

    function test_Network_ReyaWithdrawMALZFailsWhenNotEnoughFees() public {
        check_ReyaWithdrawMALZFailsWhenNotEnoughFees();
    }

    function test_Network_ReyaWithdrawMALZFailsBelowSharedDecimals() public {
        check_ReyaWithdrawMALZFailsBelowSharedDecimals();
    }

    function test_Network_ReyaWithdrawMALZAboveSharedDecimals() public {
        check_ReyaWithdrawMALZAboveSharedDecimals();
    }

    function test_Network_ReyaWithdrawMALZFailsForUnauthorizedOFT() public {
        check_ReyaWithdrawMALZFailsForUnauthorizedOFT();
    }

    function test_Network_ReyaWithdrawMALZFailsWhenPaused() public {
        check_ReyaWithdrawMALZFailsWhenPaused();
    }

    function test_Network_ReyaViewFunctions() public {
        check_ReyaViewFunctions();
    }

    function test_Network_SreyaViewFunctions() public {
        check_SreyaViewFunctions();
    }
}
