pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";

import { ICoreProxy, RiskMultipliers, MarginInfo } from "../../../src/interfaces/ICoreProxy.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

import { LeverageForkCheck } from "../../reya_check/trade/Leverage.fork.c.sol";

contract LeverageForkTest is LeverageForkCheck {
    function test_trade_rusdCollateral_leverage_eth() public {
        check_trade_rusdCollateral_leverage_eth();
    }

    function test_trade_rusdCollateral_leverage_btc() public {
        check_trade_rusdCollateral_leverage_btc();
     }

    function test_trade_wethCollateral_leverage_eth() public {
        check_trade_wethCollateral_leverage_eth();
    }

    function test_trade_wethCollateral_leverage_btc() public {
        check_trade_wethCollateral_leverage_btc();
     }
}
