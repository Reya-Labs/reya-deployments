pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { PassivePoolForkCheck } from "../../reya_check/trade/PassivePool.fork.c.sol";

contract PassivePoolForkTest is ReyaForkTest, PassivePoolForkCheck {
    function test_PoolHealth() public {
        check_PoolHealth();
    }

    function testFuzz_PoolDepositWithdraw(address attacker) public {
        checkFuzz_PoolDepositWithdraw(attacker);
    }

    function test_PassivePoolWithWeth() public {
        check_PassivePoolWithWeth();
    }
}
