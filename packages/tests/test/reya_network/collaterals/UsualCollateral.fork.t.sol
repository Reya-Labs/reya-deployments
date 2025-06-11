pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { UsualCollateralForkCheck } from "../../reya_common/collaterals/UsualCollateral.fork.c.sol";

contract UsualCollateralForkTest is ReyaForkTest, UsualCollateralForkCheck {
    function testFuzz_deusd_MintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.deusd]);
        checkFuzz_deusd_MintBurn(attacker);
    }

    function test_deusd_ViewFunctions() public {
        check_deusd_ViewFunctions();
    }

    function test_deusd_CapExceeded() public {
        check_deusd_CapExceeded();
    }

    function test_deusd_DepositWithdraw() public {
        check_deusd_DepositWithdraw();
    }

    function test_trade_deusd_DepositWithdraw() public {
        check_trade_deusd_DepositWithdraw();
    }

    function testFuzz_sdeusd_MintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.sdeusd]);
        checkFuzz_sdeusd_MintBurn(attacker);
    }

    function test_sdeusd_ViewFunctions() public {
        check_sdeusd_ViewFunctions();
    }

    function test_sdeusd_CapExceeded() public {
        check_sdeusd_CapExceeded();
    }

    function test_sdeusd_DepositWithdraw() public {
        check_sdeusd_DepositWithdraw();
    }

    function test_trade_sdeusd_DepositWithdraw() public {
        check_trade_sdeusd_DepositWithdraw();
    }

    function testFuzz_susde_MintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.susde]);
        checkFuzz_susde_MintBurn(attacker);
    }

    function test_susde_ViewFunctions() public {
        check_susde_ViewFunctions();
    }

    function test_susde_CapExceeded() public {
        check_susde_CapExceeded();
    }

    function test_susde_DepositWithdraw() public {
        check_susde_DepositWithdraw();
    }

    function test_trade_susde_DepositWithdraw() public {
        check_trade_susde_DepositWithdraw();
    }

    function testFuzz_usde_MintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.usde]);
        checkFuzz_usde_MintBurn(attacker);
    }

    function test_usde_ViewFunctions() public {
        check_usde_ViewFunctions();
    }

    function test_usde_CapExceeded() public {
        check_usde_CapExceeded();
    }

    function test_usde_DepositWithdraw() public {
        check_usde_DepositWithdraw();
    }

    function test_trade_usde_DepositWithdraw() public {
        check_trade_usde_DepositWithdraw();
    }

    function testFuzz_wbtc_MintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.wbtc]);
        checkFuzz_wbtc_MintBurn(attacker);
    }

    function testFuzz_weth_MintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.weth]);
        checkFuzz_weth_MintBurn(attacker);
    }

    function test_weth_ViewFunctions() public {
        check_weth_ViewFunctions();
    }

    function test_weth_CapExceeded() public {
        check_weth_CapExceeded();
    }

    function test_weth_DepositWithdraw() public {
        check_weth_DepositWithdraw();
    }

    function test_trade_weth_DepositWithdraw() public {
        check_trade_weth_DepositWithdraw();
    }
}
