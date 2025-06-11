pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { PassivePoolForkCheck } from "../../reya_common/trade/PassivePool.fork.c.sol";
import { IPassivePoolProxy } from "../../../src/interfaces/IPassivePoolProxy.sol";

contract PassivePoolForkTest is ReyaForkTest, PassivePoolForkCheck {
    function test_PoolHealth() public {
        check_PoolHealth();
    }

    function testFuzz_PoolDepositWithdraw(address attacker) public {
        (address user,) = makeAddrAndKey("user");
        vm.assume(attacker != user);

        uint256 attackerSharesAmount = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, attacker);
        vm.assume(attackerSharesAmount == 0);

        checkFuzz_PoolDepositWithdraw(user, attacker, 100e6, 90e30);
    }

    function testFuzz_PoolDepositWithdrawTokenized(address attacker) public {
        (address user,) = makeAddrAndKey("user");
        vm.assume(attacker != user);

        uint256 attackerSharesAmount = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, attacker);
        vm.assume(attackerSharesAmount == 0);

        checkFuzz_PoolDepositWithdrawTokenized(user, attacker, 100e6, 90e30);
    }

    function test_PassivePoolWithWeth() public {
        check_PassivePoolWithToken(sec.weth);
    }

    function test_PassivePoolWithUsde() public {
        check_PassivePoolWithToken(sec.usde);
    }

    function test_PassivePoolWithSusde() public {
        check_PassivePoolWithToken(sec.susde);
    }

    function test_PassivePoolWithDeusd() public {
        check_PassivePoolWithToken(sec.deusd);
    }

    function test_PassivePoolWithSdeusd() public {
        check_PassivePoolWithToken(sec.sdeusd);
    }

    function test_PassivePoolWithRselini() public {
        check_PassivePoolWithToken(sec.rselini);
    }

    function test_PassivePoolWithRamber() public {
        check_PassivePoolWithToken(sec.ramber);
    }

    function test_PassivePoolWithRhedge() public {
        check_PassivePoolWithToken(sec.rhedge);
    }

    function test_PassivePoolAutoRebalance_CurrentTargets() public {
        check_autoRebalance_currentTargets(false);
    }

    function test_PassivePoolAutoRebalance_CurrentTargets_MintLmTokens() public {
        check_autoRebalance_currentTargets(true);
    }

    function test_PassivePoolAutoRebalance_DifferentTargets() public {
        check_autoRebalance_differentTargets(false, false);
    }

    function test_PassivePoolAutoRebalance_DifferentTargets_MintLmTokens() public {
        check_autoRebalance_differentTargets(false, true);
    }

    function test_PassivePoolAutoRebalance_DifferentTargets_Partial() public {
        check_autoRebalance_differentTargets(true, false);
    }

    function test_PassivePoolAutoRebalance_DifferentTargets_Partial_MintLmTokens() public {
        check_autoRebalance_differentTargets(true, true);
    }

    function test_PassivePoolAutoRebalance_NoSharePriceChange() public {
        check_autoRebalance_noSharePriceChange();
    }

    function test_PassivePoolAutoRebalance_MaxExposure() public {
        check_autoRebalance_maxExposure();
    }

    function test_PassivePoolAutoRebalance_InstantaneousPrice() public {
        check_autoRebalance_instantaneousPrice();
    }

    function test_PassivePoolAutoRebalance_SharePriceChangesWhenAssetPriceChanges() public {
        check_sharePriceChangesWhenAssetPriceChanges();
    }

    function test_PassivePoolAutoRebalance_RevertWhenSenderIsNotRebalancer() public {
        check_autoRebalance_revertWhenSenderIsNotRebalancer();
    }
}
