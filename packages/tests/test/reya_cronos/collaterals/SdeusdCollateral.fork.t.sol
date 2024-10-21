pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SdeusdCollateralForkCheck } from "../../reya_common/collaterals/SdeusdCollateral.fork.c.sol";

contract SdeusdCollateralForkTest is ReyaForkTest, SdeusdCollateralForkCheck {
    function testFuzz_Cronos_SDEUSDMintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.sdeusd]);
        checkFuzz_SDEUSDMintBurn(attacker);
    }
}
