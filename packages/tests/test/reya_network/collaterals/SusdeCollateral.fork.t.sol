pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SusdeCollateralForkCheck } from "../../reya_common/collaterals/SusdeCollateral.fork.c.sol";
import "../../reya_common/DataTypes.sol";

contract SusdeCollateralForkTest is ReyaForkTest, SusdeCollateralForkCheck {
    function testFuzz_SUSDEMintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.susde]);
        checkFuzz_SUSDEMintBurn(attacker);
    }

    function test_susde_view_functions() public {
        check_susde_view_functions();
    }

    function test_susde_cap_exceeded() public {
        check_susde_cap_exceeded();
    }

    function test_susde_deposit_withdraw() public {
        check_susde_deposit_withdraw();
    }

    function test_trade_susdeCollateral_depositWithdraw() public {
        check_trade_susdeCollateral_depositWithdraw();
    }
}
