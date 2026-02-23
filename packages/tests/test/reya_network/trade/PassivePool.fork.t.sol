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
        vm.assume(attacker != sec.pool);
        vm.assume(attacker != sec.core);

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

    function test_PassivePoolWithWsteth() public {
        check_PassivePoolWithToken(sec.wsteth);
    }

    function test_DepositAndWithdrawalFeatureFlags_NotWhitelisted() public {
        check_DepositAndWithdrawalFeatureFlags(makeAddr("randomUser"), false);
    }

    function test_DepositAndWithdrawalFeatureFlags_Whitelisted() public {
        check_DepositAndWithdrawalFeatureFlags(0xaE173a960084903b1d278Ff9E3A81DeD82275556, true);
    }

    function test_PassivePoolAutoRebalance_partial_rUSD_for_rSelini() public {
        autoRebalancePool(sec.rusd, sec.rselini, true, false);
    }

    function test_PassivePoolAutoRebalance_full_rUSD_for_rSelini() public {
        autoRebalancePool(sec.rusd, sec.rselini, false, false);
    }

    function test_PassivePoolAutoRebalance_partial_rSelini_for_rUSD() public {
        autoRebalancePool(sec.rselini, sec.rusd, true, false);
    }

    function test_PassivePoolAutoRebalance_full_rSelini_for_rUSD() public {
        autoRebalancePool(sec.rselini, sec.rusd, false, false);
    }

    function test_PassivePoolAutoRebalance_full_rSelini_for_rUSD_and_mint() public {
        autoRebalancePool(sec.rselini, sec.rusd, false, true);
    }

    function test_PassivePoolAutoRebalance_partial_rUSD_for_rAmber() public {
        autoRebalancePool(sec.rusd, sec.ramber, true, false);
    }

    function test_PassivePoolAutoRebalance_full_rUSD_for_rAmber() public {
        autoRebalancePool(sec.rusd, sec.ramber, false, false);
    }

    function test_PassivePoolAutoRebalance_partial_rAmber_for_rUSD() public {
        autoRebalancePool(sec.ramber, sec.rusd, true, false);
    }

    function test_PassivePoolAutoRebalance_full_rAmber_for_rUSD() public {
        autoRebalancePool(sec.ramber, sec.rusd, false, false);
    }

    function test_PassivePoolAutoRebalance_full_rAmber_for_rUSD_and_mint() public {
        autoRebalancePool(sec.ramber, sec.rusd, false, true);
    }

    function test_PassivePoolAutoRebalance_partial_rUSD_for_rHedge() public {
        autoRebalancePool(sec.rusd, sec.rhedge, true, false);
    }

    function test_PassivePoolAutoRebalance_full_rUSD_for_rHedge() public {
        autoRebalancePool(sec.rusd, sec.rhedge, false, false);
    }

    function test_PassivePoolAutoRebalance_partial_rHedge_for_rUSD() public {
        autoRebalancePool(sec.rhedge, sec.rusd, true, false);
    }

    function test_PassivePoolAutoRebalance_full_rHedge_for_rUSD() public {
        autoRebalancePool(sec.rhedge, sec.rusd, false, false);
    }

    function test_PassivePoolAutoRebalance_full_rHedge_for_rUSD_and_mint() public {
        autoRebalancePool(sec.rhedge, sec.rusd, false, true);
    }

    function test_PassivePoolAutoRebalance_partial_rUSD_for_sUSDe() public {
        autoRebalancePool(sec.rusd, sec.susde, true, false);
    }

    function test_PassivePoolAutoRebalance_full_rUSD_for_sUSDe() public {
        autoRebalancePool(sec.rusd, sec.susde, false, false);
    }

    function test_PassivePoolAutoRebalance_partial_sUSDe_for_rUSD() public {
        autoRebalancePool(sec.susde, sec.rusd, true, false);
    }

    function test_PassivePoolAutoRebalance_full_sUSDe_for_rUSD() public {
        autoRebalancePool(sec.susde, sec.rusd, false, false);
    }

    function test_PassivePoolAutoRebalance_partial_rSelini_for_sUSDe() public {
        autoRebalancePool(sec.rselini, sec.susde, true, false);
    }

    function test_PassivePoolAutoRebalance_full_rSelini_for_sUSDe() public {
        autoRebalancePool(sec.rselini, sec.susde, false, false);
    }

    function test_PassivePoolAutoRebalance_partial_sUSDe_for_rSelini() public {
        autoRebalancePool(sec.susde, sec.rselini, true, false);
    }

    function test_PassivePoolAutoRebalance_full_sUSDe_for_rSelini() public {
        autoRebalancePool(sec.susde, sec.rselini, false, false);
    }

    function test_PassivePoolAutoRebalance_MaxExposure() public {
        check_autoRebalance_maxExposure();
    }

    function test_PassivePoolAutoRebalance_InstantaneousPrice() public {
        check_autoRebalance_instantaneousPrice();
    }

    function test_PassivePoolAutoRebalance_RevertWhenSenderIsNotRebalancer() public {
        check_autoRebalance_revertWhenSenderIsNotRebalancer();
    }

    function test_PassivePoolAutoRebalance_SharePriceChangesWhenAssetPriceChanges() public {
        check_sharePriceChangesWhenAssetPriceChanges();
    }

    function testFuzz_PassivePoolDepositWithdraw_NoSharePriceChange(int256[] memory amountsFuzz) public {
        checkFuzz_depositWithdraw_noSharePriceChange(amountsFuzz);
    }
}
