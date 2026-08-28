pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { PassivePoolForkCheck } from "../../reya_common/trade/PassivePool.fork.c.sol";

contract PassivePoolForkTest is ReyaForkTest, PassivePoolForkCheck {
    function setUp() public override(ReyaForkTest, PassivePoolForkCheck) {
        PassivePoolForkCheck.setUp();
        ReyaForkTest.setUp();
    }

    function test_DepositAndWithdrawalFeatureFlags_NotWhitelisted() public {
        check_DepositAndWithdrawalFeatureFlags(makeAddr("randomUser"), false);
    }

    function test_PassivePoolAutoRebalance_RevertWhenSenderIsNotRebalancer() public {
        check_autoRebalance_revertWhenSenderIsNotRebalancer();
    }
}
