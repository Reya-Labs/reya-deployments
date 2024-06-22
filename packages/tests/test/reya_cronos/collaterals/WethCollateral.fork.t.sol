pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { WethCollateralForkCheck } from "../../reya_common/collaterals/WethCollateral.fork.c.sol";

contract WethCollateralForkTest is ReyaForkTest, WethCollateralForkCheck {
    function testFuzz_Cronos_WETHMintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.weth]);
        checkFuzz_WETHMintBurn(attacker);
    }

    function test_Cronos_weth_view_functions() public {
        check_weth_view_functions();
    }

    // function test_Cronos_weth_deposit_withdraw() public {
    //     check_weth_deposit_withdraw();
    //  }

    // function test_Cronos_trade_wethCollateral_depositWithdraw() public {
    //     check_trade_wethCollateral_depositWithdraw();
    // }

    // function test_Cronos_WethTradeWithWethCollateral() public {
    //     check_WethTradeWithWethCollateral();
    // }
}
