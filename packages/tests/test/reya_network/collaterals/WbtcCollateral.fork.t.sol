pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";

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

import { WbtcCollateralForkCheck } from "../../reya_check/collaterals/WbtcCollateral.fork.c.sol";

contract WbtcCollateralForkTest is WbtcCollateralForkCheck {
    function testFuzz_WBTCMintBurn(address attacker) public {
        checkFuzz_WBTCMintBurn(attacker);
    }
}
