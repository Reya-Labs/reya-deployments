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

    function test_Cronos_PassivePoolWithDeusd() public {
        check_PassivePoolWithDeusd();
    }

    function test_Cronos_PassivePoolWithSdeusd() public {
        check_PassivePoolWithSdeusd();
    }

    function test_Cronos_PassivePoolAutoRebalance_CurrentTargets() public {
        check_autoRebalance_currentTargets();
    }

    function test_Cronos_PassivePoolAutoRebalance_DifferentTargets() public {
        check_autoRebalance_differentTargets(false);
    }

    function test_Cronos_PassivePoolAutoRebalance_DifferentTargets_Partial() public {
        check_autoRebalance_differentTargets(true);
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

    function test_Cronos_AutoRevalance_RevertWhenSenderIsNotRebalancer() public {
        check_autoRebalance_revertWhenSenderIsNotRebalancer();
    }

    function testFuzz_Cronos_DepositWithdrawV2_NoSharePriceChange(
        uint128[] memory tokensFuzz,
        int256[] memory amountsFuzz
    )
        public
    {
        // function testFuzz_Cronos_DepositWithdrawV2_NoSharePriceChange() public {
        // uint128[] memory tokensFuzz = new uint128[](3);
        // tokensFuzz[0] = 3467;
        // tokensFuzz[1] = 9844;
        // tokensFuzz[2] = 6897;

        // int256[] memory amountsFuzz = new int256[](3);
        // amountsFuzz[0] = 3479394634;
        // amountsFuzz[1] = 6740;
        // amountsFuzz[2] = -5551;
        checkFuzz_depositWithdrawV2_noSharePriceChange(tokensFuzz, amountsFuzz);
    }
}
