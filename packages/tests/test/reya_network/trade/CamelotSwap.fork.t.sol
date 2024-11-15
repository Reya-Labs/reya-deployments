pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { CamelotSwapForkCheck } from "../../reya_common/trade/CamelotSwap.fork.c.sol";

contract CamelotSwapForkTest is ReyaForkTest, CamelotSwapForkCheck {
    function test_DepositRusdAndSwapWeth_NoCP() public {
        check_DepositRusdAndSwapWeth_NoCP();
    }

    function test_DepositRusdAndTradeAndSwapWeth() public {
        check_DepositRusdAndTradeAndSwapWeth();
    }

    function test_RevertWhen_DepositRusdAndTradeAndSwapWeth_AttemptBackstopLiquidation() public {
        check_RevertWhen_DepositRusdAndTradeAndSwapWeth_AttemptBackstopLiquidation();
    }
}
