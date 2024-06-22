pragma solidity >=0.8.19 <0.9.0;

import { RusdCollateralForkCheck } from "../../reya_check/collaterals/RusdCollateral.fork.c.sol";

import { IERC20TokenModule } from "../../../src/interfaces/IERC20TokenModule.sol";

import { IRUSDProxy } from "../../../src/interfaces/IRUSDProxy.sol";

contract RusdCollateralForkTest is RusdCollateralForkCheck {
    function testFuzz_USDCMintBurn(address attacker) public {
        checkFuzz_USDCMintBurn(attacker);
     }

    function testFuzz_rUSD() public {
        checkFuzz_rUSD();
     }
}
