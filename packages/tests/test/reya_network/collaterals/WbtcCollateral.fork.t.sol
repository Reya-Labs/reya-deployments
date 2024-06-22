pragma solidity >=0.8.19 <0.9.0;

import { WbtcCollateralForkCheck } from "../../reya_check/collaterals/WbtcCollateral.fork.c.sol";

contract WbtcCollateralForkTest is WbtcCollateralForkCheck {
    function testFuzz_WBTCMintBurn(address attacker) public {
        checkFuzz_WBTCMintBurn(attacker);
    }
}
