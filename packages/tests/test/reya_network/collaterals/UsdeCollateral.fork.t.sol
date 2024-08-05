pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { UsdeCollateralForkCheck } from "../../reya_common/collaterals/UsdeCollateral.fork.c.sol";
import "../../reya_common/DataTypes.sol";

contract UsdeCollateralForkTest is ReyaForkTest, UsdeCollateralForkCheck {
    function testFuzz_USDEMintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.usde]);
        checkFuzz_USDEMintBurn(attacker);
    }

    function test_usde_view_functions() public {
        check_usde_view_functions();
    }

    function test_usde_cap_exceeded() public {
        check_usde_cap_exceeded();
    }

    function test_usde_deposit_withdraw() public {
        check_usde_deposit_withdraw();
    }

    function test_trade_usdeCollateral_depositWithdraw() public {
        check_trade_usdeCollateral_depositWithdraw();
    }
}
