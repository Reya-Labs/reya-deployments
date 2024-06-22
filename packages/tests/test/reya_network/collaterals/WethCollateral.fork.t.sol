pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import "../DataTypes.sol";

import {
    ICoreProxy,
    CollateralConfig,
    ParentCollateralConfig,
    CachedCollateralConfig,
    MarginInfo,
    CollateralInfo
} from "../../../src/interfaces/ICoreProxy.sol";

import {
    IPeripheryProxy, DepositNewMAInputs, DepositExistingMAInputs
} from "../../../src/interfaces/IPeripheryProxy.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { IERC20TokenModule } from "../../../src/interfaces/IERC20TokenModule.sol";

import { sd, SD59x18, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

import { WethCollateralForkCheck } from "../../reya_check/collaterals/WethCollateral.fork.c.sol";

contract WethCollateralForkTest is WethCollateralForkCheck {
    function testFuzz_WETHMintBurn(address attacker) public {
        checkFuzz_WETHMintBurn(attacker);
    }

    function test_weth_view_functions() public {
        check_weth_view_functions();
    }

    function test_weth_cap_exceeded() public {
        check_weth_cap_exceeded();
    }

    function test_weth_deposit_withdraw() public {
        check_weth_deposit_withdraw();
     }

    function test_trade_wethCollateral_depositWithdraw() public {
        check_trade_wethCollateral_depositWithdraw();
    }

    function test_WethTradeWithWethCollateral() public {
        check_WethTradeWithWethCollateral();
    }
}
