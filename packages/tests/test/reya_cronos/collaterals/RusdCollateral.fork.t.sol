pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { RusdCollateralForkCheck } from "../../reya_common/collaterals/RusdCollateral.fork.c.sol";

contract RusdCollateralForkTest is ReyaForkTest, RusdCollateralForkCheck {
    function testFuzz_Cronos_USDCMintBurn(address attacker) public {
        // another minter on testnet
        address minter1 = 0x45556408e543158f74403e882E3C8c23eCD9f732;

        vm.assume(attacker != dec.socketController[sec.usdc]);
        vm.assume(attacker != sec.multisig);
        vm.assume(attacker != minter1);
        checkFuzz_USDCMintBurn(attacker);
    }

    function testFuzz_Cronos_rUSD() public {
        checkFuzz_rUSD();
    }
}
