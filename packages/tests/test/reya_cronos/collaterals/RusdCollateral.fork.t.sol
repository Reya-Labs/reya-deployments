pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { RusdCollateralForkCheck } from "../../reya_check/collaterals/RusdCollateral.fork.c.sol";

contract RusdCollateralForkTest is ReyaForkTest, RusdCollateralForkCheck {
    function testFuzz_USDCMintBurn(address attacker) public {
        checkFuzz_USDCMintBurn(attacker);
     }

    function testFuzz_rUSD() public {
        checkFuzz_rUSD();
     }
}
