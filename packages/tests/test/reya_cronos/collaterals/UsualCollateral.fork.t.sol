pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { UsualCollateralForkCheck } from "../../reya_common/collaterals/UsualCollateral.fork.c.sol";

contract UsualCollateralForkTest is ReyaForkTest, UsualCollateralForkCheck {
    function testFuzz_Cronos_deusd_MintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.deusd]);
        checkFuzz_deusd_MintBurn(attacker);
    }

    function test_Cronos_deusd_ViewFunctions() public {
        check_deusd_ViewFunctions();
    }

    function test_Cronos_deusd_DepositWithdraw() public {
        check_deusd_DepositWithdraw();
    }

    function test_Cronos_trade_deusd_DepositWithdraw() public {
        check_trade_deusd_DepositWithdraw();
    }

    function testFuzz_Cronos_sdeusd_MintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.sdeusd]);
        checkFuzz_sdeusd_MintBurn(attacker);
    }

    function test_Cronos_sdeusd_ViewFunctions() public {
        check_sdeusd_ViewFunctions();
    }

    function test_Cronos_sdeusd_DepositWithdraw() public {
        check_sdeusd_DepositWithdraw();
    }

    function test_Cronos_trade_sdeusd_DepositWithdraw() public {
        check_trade_sdeusd_DepositWithdraw();
    }

    function testFuzz_Cronos_susde_MintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.susde]);
        checkFuzz_susde_MintBurn(attacker);
    }

    function test_Cronos_susde_ViewFunctions() public {
        check_susde_ViewFunctions();
    }

    function test_Cronos_susde_DepositWithdraw() public {
        check_susde_DepositWithdraw();
    }

    function test_Cronos_trade_susde_DepositWithdraw() public {
        check_trade_susde_DepositWithdraw();
    }

    function testFuzz_Cronos_usde_MintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.usde]);
        checkFuzz_usde_MintBurn(attacker);
    }

    function test_Cronos_usde_ViewFunctions() public {
        check_usde_ViewFunctions();
    }

    function test_Cronos_usde_DepositWithdraw() public {
        check_usde_DepositWithdraw();
    }

    function test_Cronos_trade_usde_DepositWithdraw() public {
        check_trade_usde_DepositWithdraw();
    }

    function testFuzz_Cronos_wbtc_MintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.wbtc]);
        checkFuzz_wbtc_MintBurn(attacker);
    }

    function testFuzz_Cronos_weth_MintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.weth]);
        checkFuzz_weth_MintBurn(attacker);
    }

    function test_Cronos_weth_ViewFunctions() public {
        check_weth_ViewFunctions();
    }

    function test_Cronos_weth_DepositWithdraw() public {
        check_weth_DepositWithdraw();
    }

    function test_Cronos_trade_weth_DepositWithdraw() public {
        check_trade_weth_DepositWithdraw();
    }

    function testFuzz_Cronos_wsteth_MintBurn(address attacker) public {
        vm.assume(attacker != dec.socketController[sec.wsteth]);
        checkFuzz_wsteth_MintBurn(attacker);
    }

    function test_Cronos_wsteth_ViewFunctions() public {
        check_wsteth_ViewFunctions();
    }

    function test_Cronos_wsteth_DepositWithdraw() public {
        check_wsteth_DepositWithdraw();
    }

    function test_Cronos_trade_wsteth_DepositWithdraw() public {
        check_trade_wsteth_DepositWithdraw();
    }
}
