pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { WbtcCollateralForkCheck } from "../../reya_check/collaterals/WbtcCollateral.fork.c.sol";

contract WbtcCollateralForkTest is ReyaForkTest, WbtcCollateralForkCheck {
    function testFuzz_WBTCMintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.wbtc]);
        checkFuzz_WBTCMintBurn(attacker);
    }
}
