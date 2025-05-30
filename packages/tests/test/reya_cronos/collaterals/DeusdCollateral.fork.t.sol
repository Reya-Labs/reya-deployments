pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { DeusdCollateralForkCheck } from "../../reya_common/collaterals/DeusdCollateral.fork.c.sol";

contract DeusdCollateralForkTest is ReyaForkTest, DeusdCollateralForkCheck {
    function testFuzz_Cronos_DEUSDMintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.deusd]);
        checkFuzz_DEUSDMintBurn(attacker);
    }

    function test_Cronos_deusd_view_functions() public {
        check_deusd_view_functions();
    }
}
