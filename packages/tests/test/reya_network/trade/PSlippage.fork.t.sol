pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";

import { ICoreProxy, MarginInfo, RiskMultipliers } from "../../../src/interfaces/ICoreProxy.sol";

import { IPassivePerpProxy, MarketConfigurationData } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { sd, SD59x18, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

import { PSlippageForkCheck } from "../../reya_check/trade/PSlippage.fork.c.sol";

contract PSlippageForkTest is PSlippageForkCheck {
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
