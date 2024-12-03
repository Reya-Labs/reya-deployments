pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { LmTokenCollateralForkCheck } from "../../reya_common/collaterals/LmTokenCollateral.fork.c.sol";
import "../../reya_common/DataTypes.sol";

contract LmTokenCollateralForkTest is ReyaForkTest, LmTokenCollateralForkCheck {
    function testFuzz_Cronos_rseliniMintBurn(address attacker) public {
        checkFuzz_rseliniMintBurn(attacker);
    }

    function testFuzz_Cronos_ramberMintBurn(address attacker) public {
        checkFuzz_ramberMintBurn(attacker);
    }

    function test_Cronos_rseliniRedemptionAndSubscription() public {
        check_rseliniRedemptionAndSubscription();
    }

    function test_Cronos_ramberRedemptionAndSubscription() public {
        check_ramberRedemptionAndSubscription();
    }

    function test_Cronos_rselini_view_functions() public {
        check_rselini_view_functions();
    }

    function test_Cronos_ramber_view_functions() public {
        check_ramber_view_functions();
    }

    // function test_Cronos_rselini_cap_exceeded() public {
    //     check_rselini_cap_exceeded();
    // }

    // function test_Cronos_ramber_cap_exceeded() public {
    //     check_ramber_cap_exceeded();
    // }

    function test_Cronos_rselini_deposit_withdraw() public {
        check_rselini_deposit_withdraw();
    }

    function test_Cronos_ramber_deposit_withdraw() public {
        check_ramber_deposit_withdraw();
    }

    function test_Cronos_trade_rseliniCollateral_depositWithdraw() public {
        check_trade_rseliniCollateral_depositWithdraw();
    }

    function test_Cronos_trade_ramberCollateral_depositWithdraw() public {
        check_trade_ramberCollateral_depositWithdraw();
    }
}
