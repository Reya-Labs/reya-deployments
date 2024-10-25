pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SusdeCollateralForkCheck } from "../../reya_common/collaterals/SusdeCollateral.fork.c.sol";

contract SusdeCollateralForkTest is ReyaForkTest, SusdeCollateralForkCheck {
    function testFuzz_Cronos_SUSDEMintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.susde]);
        checkFuzz_SUSDEMintBurn(attacker);
    }

    // function test_Cronos_susde_view_functions() public {
    //     check_susde_view_functions();
    // }
}
