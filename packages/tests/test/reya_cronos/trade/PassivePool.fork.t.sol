pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { PassivePoolForkCheck } from "../../reya_common/trade/PassivePool.fork.c.sol";
import { IPassivePoolProxy } from "../../../src/interfaces/IPassivePoolProxy.sol";

contract PassivePoolForkTest is ReyaForkTest, PassivePoolForkCheck {
    function test_Cronos_PoolHealth() public {
        check_PoolHealth();
    }

    function testFuzz_Cronos_PoolDepositWithdraw(address attacker) public {
        (address user,) = makeAddrAndKey("user");
        vm.assume(attacker != user);

        uint256 attackerSharesAmount = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, attacker);
        vm.assume(attackerSharesAmount == 0);

        checkFuzz_PoolDepositWithdraw(user, attacker, 100e6, 1);
    }

    function testFuzz_Cronos_PoolDepositWithdrawTokenized(address attacker) public {
        (address user,) = makeAddrAndKey("user");
        vm.assume(attacker != user);

        uint256 attackerSharesAmount = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, attacker);
        vm.assume(attackerSharesAmount == 0);

        checkFuzz_PoolDepositWithdrawTokenized(user, attacker, 100e6, 1);
    }

    function test_Cronos_PassivePoolWithWeth() public {
        check_PassivePoolWithWeth();
    }

    function test_Cronos_PassivePoolWithUsde() public {
        check_PassivePoolWithUsde();
    }

    function test_Cronos_PassivePoolWithSusde() public {
        check_PassivePoolWithSusde();
    }

    function test_Cronos_PassivePoolWithDeusd() public {
        check_PassivePoolWithDeusd();
    }

    function test_Cronos_PassivePoolWithSdeusd() public {
        check_PassivePoolWithSdeusd();
    }

    function test_Cronos_PassivePoolWithRselini() public {
        check_PassivePoolWithLmToken(sec.rselini);
    }

    function test_Cronos_PassivePoolWithRamber() public {
        check_PassivePoolWithLmToken(sec.ramber);
    }

    function test_Cronos_PassivePoolWithRhedge() public {
        check_PassivePoolWithLmToken(sec.rhedge);
    }

    function test_Cronos_PassivePoolAutoRebalance_DifferentTargets_Partial() public {
        check_autoRebalance_differentTargets(true, false);
    }

    function test_Cronos_PassivePoolAutoRebalance_DifferentTargets_Partial_MintLmTokens() public {
        check_autoRebalance_differentTargets(true, true);
    }

    function test_Cronos_AutoRebalance_RevertWhenSenderIsNotRebalancer() public {
        check_autoRebalance_revertWhenSenderIsNotRebalancer();
    }

    function test_Cronos_SetTokenTargetRatio_RevertWhenWSTETH() public {
        check_setTokenTargetRatio_revertWhenTokenIsNotSupportingCollateral(0xDF52410A19298FE168c900513e762adaD00C42b1);
    }
}
