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

    function test_Cronos_PassivePoolWithRselini() public {
        check_PassivePoolWithRselini();
    }

    function test_Cronos_PassivePoolWithRamber() public {
        check_PassivePoolWithRamber();
    }

    // function test_Cronos_PassivePoolAutoRebalance_CurrentTargets() public {
    //     check_autoRebalance_currentTargets(false);
    // }

    // function test_Cronos_PassivePoolAutoRebalance_CurrentTargets_MintLmTokens() public {
    //     check_autoRebalance_currentTargets(true);
    // }

    // function test_Cronos_PassivePoolAutoRebalance_DifferentTargets() public {
    //     check_autoRebalance_differentTargets(false, false);
    // }

    // function test_Cronos_PassivePoolAutoRebalance_DifferentTargets_MintLmTokens() public {
    //     check_autoRebalance_differentTargets(false, true);
    // }

    function test_Cronos_PassivePoolAutoRebalance_DifferentTargets_Partial() public {
        check_autoRebalance_differentTargets(true, false);
    }

    function test_Cronos_PassivePoolAutoRebalance_DifferentTargets_Partial_MintLmTokens() public {
        check_autoRebalance_differentTargets(true, true);
    }

    // function test_Cronos_PassivePoolAutoRebalance_NoSharePriceChange() public {
    //     check_autoRebalance_noSharePriceChange();
    // }

    // function test_Cronos_PassivePoolAutoRebalance_MaxExposure() public {
    //     check_autoRebalance_maxExposure();
    // }

    // function test_Cronos_PassivePoolAutoRebalance_InstantaneousPrice() public {
    //     check_autoRebalance_instantaneousPrice();
    // }

    // function test_Cronos_PassivePoolAutoRebalance_SharePriceChangesWhenAssetPriceChanges() public {
    //     check_sharePriceChangesWhenAssetPriceChanges();
    // }

    function test_Cronos_AutoRebalance_RevertWhenSenderIsNotRebalancer() public {
        check_autoRebalance_revertWhenSenderIsNotRebalancer();
    }

    function testFuzz_Cronos_DepositWithdrawV2_NoSharePriceChange(
        uint128[] memory tokensFuzz,
        int256[] memory amountsFuzz
    )
        public
    {
        checkFuzz_depositWithdrawV2_noSharePriceChange(tokensFuzz, amountsFuzz);
    }

    // function test_Cronos_DepositWithdrawV2_RevertWhenOwnerIsNotAuthorized() public {
    //     check_depositWithdrawV2_revertWhenOwnerIsNotAuthorized();
    // }

    function test_Cronos_DepositV2_RevertWhenTokenIsWETH() public {
        check_depositV2_revertWhenTokenHasZeroTargetRatio(sec.weth);
    }

    function test_Cronos_DepositV2_RevertWhenTokenIsUsde() public {
        check_depositV2_revertWhenTokenHasZeroTargetRatio(sec.usde);
    }

    function test_Cronos_DepositV2_RevertWhenTokenIsSusde() public {
        check_depositV2_revertWhenTokenHasZeroTargetRatio(sec.susde);
    }

    function test_Cronos_SetTokenTargetRatio_RevertWhenWSTETH() public {
        check_setTokenTargetRatio_revertWhenTokenIsNotSupportingCollateral(0xDF52410A19298FE168c900513e762adaD00C42b1);
    }
}
