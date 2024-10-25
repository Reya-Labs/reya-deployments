pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { SdeusdCollateralForkCheck } from "../../reya_common/collaterals/SdeusdCollateral.fork.c.sol";

contract SdeusdCollateralForkTest is ReyaForkTest, SdeusdCollateralForkCheck {
    function testFuzz_SDEUSDMintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.sdeusd]);
        checkFuzz_SDEUSDMintBurn(attacker);
    }

    function test_sdeusd_view_functions() public {
        check_sdeusd_view_functions();
    }

    function test_sdeusd_cap_exceeded() public {
        check_sdeusd_cap_exceeded();
    }

    function test_sdeusd_deposit_withdraw() public {
        check_sdeusd_deposit_withdraw();
    }

    function test_trade_sdeusdCollateral_depositWithdraw() public {
        check_trade_sdeusdCollateral_depositWithdraw();
    }
}
