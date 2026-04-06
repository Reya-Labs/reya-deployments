pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { RusdCollateralForkCheck } from "../../reya_common/collaterals/RusdCollateral.fork.c.sol";

contract RusdCollateralForkTest is ReyaForkTest, RusdCollateralForkCheck {
    function test_Devnet_USDCMintBurn() public {
        checkFuzz_USDCMintBurn(address(0xdead));
    }

    function test_Devnet_rUSD() public {
        checkFuzz_rUSD();
    }
}
