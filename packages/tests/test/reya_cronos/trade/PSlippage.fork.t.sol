pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { PSlippageForkCheck } from "../../reya_common/trade/PSlippage.fork.c.sol";

contract PSlippageForkTest is ReyaForkTest, PSlippageForkCheck {
    function test_Cronos_trade_slippage_eth_long() public {
        check_trade_slippage_eth_long();
    }

    function test_Cronos_trade_slippage_btc_long() public {
        check_trade_slippage_btc_long();
    }

    function test_Cronos_trade_slippage_sol_long() public {
        check_trade_slippage_sol_long();
    }

    function test_Cronos_trade_slippage_arb_long() public {
        check_trade_slippage_arb_long();
    }

    function test_Cronos_trade_slippage_op_long() public {
        check_trade_slippage_op_long();
    }

    function test_Cronos_trade_slippage_avax_long() public {
        check_trade_slippage_avax_long();
    }

    function test_Cronos_trade_slippage_mkr_long() public {
        check_trade_slippage_mkr_long();
    }

    function test_Cronos_trade_slippage_link_long() public {
        check_trade_slippage_link_long();
    }

    function test_Cronos_trade_slippage_aave_long() public {
        check_trade_slippage_aave_long();
    }

    function test_Cronos_trade_slippage_crv_long() public {
        check_trade_slippage_crv_long();
    }

    function test_Cronos_trade_slippage_uni_long() public {
        check_trade_slippage_uni_long();
    }

    function test_Cronos_trade_slippage_eth_short() public {
        check_trade_slippage_eth_short();
    }

    function test_Cronos_trade_slippage_btc_short() public {
        check_trade_slippage_btc_short();
    }

    function test_Cronos_trade_slippage_sol_short() public {
        check_trade_slippage_sol_short();
    }

    function test_Cronos_trade_slippage_arb_short() public {
        check_trade_slippage_arb_short();
    }

    function test_Cronos_trade_slippage_op_short() public {
        check_trade_slippage_op_short();
    }

    function test_Cronos_trade_slippage_avax_short() public {
        check_trade_slippage_avax_short();
    }

    function test_Cronos_trade_slippage_mkr_short() public {
        check_trade_slippage_mkr_short();
    }

    function test_Cronos_trade_slippage_link_short() public {
        check_trade_slippage_link_short();
    }

    function test_Cronos_trade_slippage_aave_short() public {
        check_trade_slippage_aave_short();
    }

    function test_Cronos_trade_slippage_crv_short() public {
        check_trade_slippage_crv_short();
    }

    function test_Cronos_trade_slippage_uni_short() public {
        check_trade_slippage_uni_short();
    }
}
