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

    function test_Cronos_PassivePoolAutoRebalance_CurrentTargets() public {
        check_autoRebalance_currentTargets();
    }

    function test_Cronos_PassivePoolAutoRebalance_DifferentTargets() public {
        check_autoRebalance_differentTargets();
    }

    function test_Cronos_PassivePoolAutoRebalance_NoSharePriceChange() public {
        check_autoRebalance_noSharePriceChange();
    }

    function test_Cronos_PassivePoolAutoRebalance_MaxExposure() public {
        check_autoRebalance_maxExposure();
    }

    function test_Cronos_PassivePoolAutoRebalance_InstantaneousPrice() public {
        check_autoRebalance_instantaneousPrice();
    }

    function test_Cronos_PassivePoolAutoRebalance_SharePriceChangesWhenAssetPriceChanges() public {
        check_sharePriceChangesWhenAssetPriceChanges();
    }
}
