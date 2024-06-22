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

    function test_trade_slippage_eth_short() public {
        check_trade_slippage_eth_short();
    }

    function test_trade_slippage_btc_short() public {
        check_trade_slippage_btc_short();
    }

    function test_trade_wethCollateral_leverage_eth() public {
        check_trade_wethCollateral_leverage_eth();
    }

    function test_trade_wethCollateral_leverage_btc() public {
        check_trade_wethCollateral_leverage_btc();
    }
}
