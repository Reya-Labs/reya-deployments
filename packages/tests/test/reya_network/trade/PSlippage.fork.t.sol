pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { PSlippageForkCheck } from "../../reya_common/trade/PSlippage.fork.c.sol";

contract PSlippageForkTest is ReyaForkTest, PSlippageForkCheck {
    function test_trade_slippage_eth_long() public {
        check_trade_slippage_eth_long();
    }

    function test_trade_slippage_btc_long() public {
        check_trade_slippage_btc_long();
    }

    function test_trade_slippage_sol_long() public {
        check_trade_slippage_sol_long();
    }

    function test_trade_slippage_arb_long() public {
        check_trade_slippage_arb_long();
    }

    function test_trade_slippage_eth_short() public {
        check_trade_slippage_eth_short();
    }

    function test_trade_slippage_btc_short() public {
        check_trade_slippage_btc_short();
    }

    function test_trade_slippage_sol_short() public {
        check_trade_slippage_sol_short();
    }

    function test_trade_slippage_arb_short() public {
        check_trade_slippage_arb_short();
    }
}
