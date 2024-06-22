pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud } from "@prb/math/UD60x18.sol";

import { FundingRateForkCheck } from "../../reya_check/trade/FundingRate.fork.c.sol";

contract FundingRateForkTest is FundingRateForkCheck {
    function test_FundingVelocity() public {
        check_FundingVelocity();
    }
}
