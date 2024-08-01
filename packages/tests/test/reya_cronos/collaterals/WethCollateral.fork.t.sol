pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { WethCollateralForkCheck } from "../../reya_common/collaterals/WethCollateral.fork.c.sol";
import "../../reya_common/DataTypes.sol";

contract WethCollateralForkTest is ReyaForkTest, WethCollateralForkCheck {
    function testFuzz_Cronos_WETHMintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.weth]);
        checkFuzz_WETHMintBurn(attacker);
    }

    function test_Cronos_weth_view_functions() public {
        check_weth_view_functions();
    }
}
