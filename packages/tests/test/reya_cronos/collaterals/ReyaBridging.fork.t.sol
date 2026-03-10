pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { ReyaBridgingForkCheck } from "../../reya_common/collaterals/ReyaBridging.fork.c.sol";
import "../../reya_common/DataTypes.sol";

contract ReyaBridgingForkTest is ReyaForkTest, ReyaBridgingForkCheck {
    function test_Cronos_ReyaBridgeIntoSpotMA() public {
        check_ReyaBridgeIntoSpotMA();
    }

    function test_Cronos_ReyaBridgeIntoNormalMAFails() public {
        check_ReyaBridgeIntoNormalMAFails();
    }

    function test_Cronos_ReyaStaking() public {
        check_ReyaStaking();
    }

    function test_Cronos_ReyaUnstaking() public {
        check_ReyaUnstaking();
    }

    function test_Cronos_ReyaFailsToUnstakeWhenMinAssetAmountIsTooHigh() public {
        check_ReyaFailsToUnstakeWhenMinAssetAmountIsTooHigh();
    }

    function test_Cronos_ReyaFailsToStakeWhenMinShareAmountIsTooHigh() public {
        check_ReyaFailsToStakeWhenMinShareAmountIsTooHigh();
    }

    function test_Cronos_ReyaBridgingPermissions() public {
        check_ReyaBridgingPermissions();
    }

    function test_Cronos_ReyaStakingPermissions() public {
        check_ReyaStakingPermissions();
    }

    function test_Cronos_ReyaWithdrawMALZ() public {
        check_ReyaWithdrawMALZ();
    }

    function test_Cronos_ReyaWithdrawMALZFailsBelowSharedDecimals() public {
        check_ReyaWithdrawMALZFailsBelowSharedDecimals();
    }

    function test_Cronos_ReyaWithdrawMALZAboveSharedDecimals() public {
        check_ReyaWithdrawMALZAboveSharedDecimals();
    }

    function test_Cronos_ReyaWithdrawMALZFailsWhenNotEnoughFees() public {
        check_ReyaWithdrawMALZFailsWhenNotEnoughFees();
    }

    function test_Cronos_ReyaWithdrawMALZFailsForUnauthorizedOFT() public {
        check_ReyaWithdrawMALZFailsForUnauthorizedOFT();
    }

    function test_Cronos_ReyaWithdrawMALZWithdrawLimits() public {
        check_ReyaWithdrawMALZWithdrawLimits();
    }

    function test_Cronos_ReyaWithdrawMALZFailsWhenPaused() public {
        check_ReyaWithdrawMALZFailsWhenPaused();
    }

    function test_Cronos_ReyaViewFunctions() public {
        check_ReyaViewFunctions();
    }

    function test_Cronos_SreyaViewFunctions() public {
        check_SreyaViewFunctions();
    }
}
