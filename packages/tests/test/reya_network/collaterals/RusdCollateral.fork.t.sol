pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { RusdCollateralForkCheck } from "../../reya_common/collaterals/RusdCollateral.fork.c.sol";

contract RusdCollateralForkTest is ReyaForkTest, RusdCollateralForkCheck {
    function testFuzz_USDCMintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.usdc]);
        checkFuzz_USDCMintBurn(attacker);
    }

    function testFuzz_rUSD() public {
        checkFuzz_rUSD();
    }
}
