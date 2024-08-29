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

        checkFuzz_PoolDepositWithdraw(user, attacker);
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
}
