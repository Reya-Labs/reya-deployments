pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { WethCollateralForkCheck } from "../../reya_common/collaterals/WethCollateral.fork.c.sol";
import "../../reya_common/DataTypes.sol";

contract WethCollateralForkTest is ReyaForkTest, WethCollateralForkCheck {
    function testFuzz_WETHMintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.weth]);
        checkFuzz_WETHMintBurn(attacker);
    }

    function test_weth_view_functions() public {
        check_weth_view_functions();
    }

    function test_weth_cap_exceeded() public {
        check_weth_cap_exceeded();
    }

    function test_weth_deposit_withdraw() public {
        check_weth_deposit_withdraw(arbitrumChainId);
    }

    function test_trade_wethCollateral_depositWithdraw() public {
        check_trade_wethCollateral_depositWithdraw(arbitrumChainId);
    }

    function test_WethTradeWithWethCollateral() public {
        check_WethTradeWithWethCollateral(arbitrumChainId);
    }
}
