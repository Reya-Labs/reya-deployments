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

        address whitelistedAddress = 0xC6fB022962e1426F4e0ec9D2F8861c57926E9f72;
        vm.assume(attacker != whitelistedAddress);

        uint256 attackerSharesAmount = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, attacker);
        vm.assume(attackerSharesAmount == 0);

        checkFuzz_PoolDepositWithdrawTokenized(user, attacker, 100e6, 1);
    }

    function test_Cronos_PassivePoolWithWeth() public {
        check_PassivePoolWithToken(sec.weth);
    }

    function test_Cronos_PassivePoolWithUsde() public {
        check_PassivePoolWithToken(sec.usde);
    }

    function test_Cronos_PassivePoolWithSusde() public {
        check_PassivePoolWithToken(sec.susde);
    }

    function test_Cronos_PassivePoolWithDeusd() public {
        check_PassivePoolWithToken(sec.deusd);
    }

    function test_Cronos_PassivePoolWithSdeusd() public {
        check_PassivePoolWithToken(sec.sdeusd);
    }

    function test_Cronos_PassivePoolWithRselini() public {
        check_PassivePoolWithToken(sec.rselini);
    }

    function test_Cronos_PassivePoolWithRamber() public {
        check_PassivePoolWithToken(sec.ramber);
    }

    function test_Cronos_PassivePoolWithRhedge() public {
        check_PassivePoolWithToken(sec.rhedge);
    }

    function test_Cronos_PassivePoolWithWsteth() public {
        check_PassivePoolWithToken(sec.wsteth);
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

    function testFuzz_Cronos_DepositWithdraw_NoSharePriceChange(int256[] memory amountsFuzz) public {
        checkFuzz_depositWithdraw_noSharePriceChange(amountsFuzz);
    }
}
