pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { UsdeCollateralForkCheck } from "../../reya_common/collaterals/UsdeCollateral.fork.c.sol";

contract UsdeCollateralForkTest is ReyaForkTest, UsdeCollateralForkCheck {
    function testFuzz_Cronos_USDEMintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.usde]);
        checkFuzz_USDEMintBurn(attacker);
    }

    function test_Cronos_usde_view_functions() public {
        check_usde_view_functions();
    }
}
