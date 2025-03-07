pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SrusdCollateralForkCheck } from "../../reya_common/collaterals/SrusdCollateral.fork.c.sol";

contract SrusdCollateralForkTest is ReyaForkTest, SrusdCollateralForkCheck {
    function testFuzz_SRUSDMintBurn(address attacker) public {
        vm.assume(attacker != sec.pool);
        checkFuzz_SRUSDMintBurn(attacker);
    }

    function test_srusd_view_functions() public {
        check_srusd_view_functions();
    }

    // function test_srusd_cap_exceeded() public {
    //     check_srusd_cap_exceeded();
    // }

    function test_srusd_deposit_withdraw() public {
        check_srusd_deposit_withdraw();
    }

    function test_trade_srusdCollateral_depositWithdraw() public {
        check_trade_srusdCollateral_depositWithdraw();
    }

    function test_srusd_transfer() public {
        check_transfer_srusdCollateral();
    }
}
