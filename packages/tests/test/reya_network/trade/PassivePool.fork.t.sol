pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import "../DataTypes.sol";

import { IPassivePoolProxy } from "../../../src/interfaces/IPassivePoolProxy.sol";
import {
    IPeripheryProxy,
    DepositNewMAInputs,
    DepositExistingMAInputs,
    DepositPassivePoolInputs
} from "../../../src/interfaces/IPeripheryProxy.sol";

import { ISocketExecutionHelper } from "../../../src/interfaces/ISocketExecutionHelper.sol";

import { sd } from "@prb/math/SD59x18.sol";
import { ud } from "@prb/math/UD60x18.sol";

import { PassivePoolForkCheck } from "../../reya_check/trade/PassivePool.fork.c.sol";

contract PassivePoolForkTest is PassivePoolForkCheck {
    function test_PoolHealth() public {
        check_PoolHealth();
    }

    function testFuzz_PoolDepositWithdraw(address attacker) public {
        checkFuzz_PoolDepositWithdraw(attacker);
    }

    function test_PassivePoolWithWeth() public {
        check_PassivePoolWithWeth();
    }
}
