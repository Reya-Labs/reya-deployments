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

    function test_DepositRusdAndTradeAndSwapWeth_Periphery() public {
        check_DepositRusdAndTradeAndSwapWeth_Periphery();
    }

    function test_SwapAEAccount() public {
        check_SwapAEAccount();
    }

    function test_RevertWhen_DepositRusdAndTradeAndSwapWeth_AttemptBackstopLiquidation() public {
        check_RevertWhen_DepositRusdAndTradeAndSwapWeth_AttemptBackstopLiquidation();
    }

    function test_RevertWhen_DepositRusdAndSwapMore_NoCP() public {
        check_RevertWhen_DepositRusdAndSwapMore_NoCP();
    }

    function test_RevertWhen_DepositRusdAndTradeAndSwapUnsupportedTokenWbtc() public {
        check_RevertWhen_DepositRusdAndTradeAndSwapUnsupportedTokenWbtc();
    }

    function test_RevertWhen_YakRouterIsZero() public {
        check_RevertWhen_YakRouterIsZero();
    }

    function test_RevertWhen_MinAmountIsHigher() public {
        check_RevertWhen_MinAmountIsHigher();
    }

    function test_RevertWhen_WithdrawLimitIsBreached() public {
        check_RevertWhen_WithdrawLimitIsBreached();
    }

    // function test_RevertWhen_SwapAEAccount() public {
    //     check_RevertWhen_SwapAEAccount();
    // }

    function test_RevertWhen_SwapAndUnhealthyAccount() public {
        check_RevertWhen_SwapAndUnhealthyAccount();
    }
}
