pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { PoolStakeForkCheck } from "../../reya_common/trade/PoolStake.fork.c.sol";

contract PoolStakeForkTest is ReyaForkTest, PoolStakeForkCheck {
    function test_Cronos_StakeUnstakeCommand() public {
        check_StakeUnstakeCommand({ amount: 10e6, minShares: 2e30 });
    }
}
