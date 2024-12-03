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

        checkFuzz_PoolDepositWithdraw(user, attacker);
    }

    function test_PassivePoolWithWeth() public {
        check_PassivePoolWithWeth();
    }

    function test_PassivePoolWithUsde() public {
        check_PassivePoolWithUsde();
    }

    function test_PassivePoolWithSusde() public {
        check_PassivePoolWithSusde();
    }

    function test_PassivePoolWithDeusd() public {
        check_PassivePoolWithDeusd();
    }

    function test_PassivePoolWithSdeusd() public {
        check_PassivePoolWithSdeusd();
    }

    function test_PassivePoolAutoRebalance_CurrentTargets() public {
        check_autoRebalance_currentTargets();
    }

    function test_PassivePoolAutoRebalance_DifferentTargets() public {
        check_autoRebalance_differentTargets(false);
    }

    function test_PassivePoolAutoRebalance_DifferentTargets_Partial() public {
        check_autoRebalance_differentTargets(true);
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

    function testFuzz_PassivePoolDepositWithdrawV2_NoSharePriceChange(
        uint128[] memory tokensFuzz,
        int256[] memory amountsFuzz
    )
        public
    {
        checkFuzz_depositWithdrawV2_noSharePriceChange(tokensFuzz, amountsFuzz);
    }

    // function test_PassivePoolDepositWithdrawV2_RevertWhenOwnerIsNotAuthorized() public {
    //     check_depositWithdrawV2_revertWhenOwnerIsNotAuthorized();
    // }

    function test_PassivePoolDepositV2_RevertWhenTokenIsWETH() public {
        check_depositV2_revertWhenTokenHasZeroTargetRatio(sec.weth);
    }

    function test_PassivePoolDepositV2_RevertWhenTokenIsUsde() public {
        check_depositV2_revertWhenTokenHasZeroTargetRatio(sec.usde);
    }

    function test_PassivePoolDepositV2_RevertWhenTokenIsSusde() public {
        check_depositV2_revertWhenTokenHasZeroTargetRatio(sec.susde);
    }

    function test_PassivePoolDepositV2_RevertWhenTokenIsRselini() public {
        check_depositV2_revertWhenTokenHasZeroTargetRatio(sec.rselini);
    }

    function test_PassivePoolDepositV2_RevertWhenTokenIsRamber() public {
        check_depositV2_revertWhenTokenHasZeroTargetRatio(sec.ramber);
    }
}
