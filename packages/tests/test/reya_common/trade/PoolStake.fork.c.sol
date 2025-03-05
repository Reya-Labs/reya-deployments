pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

contract PoolStakeForkCheck is BaseReyaForkTest {
    address user;
    uint256 userPrivateKey;

    function setUp() public {
        (user, userPrivateKey) = makeAddrAndKey("user");
    }

    function check_StakeUnstakeCommand(uint256 amount, uint256 minShares) public {
        uint128 accountId = depositNewMA(user, sec.usdc, amount);

        executePeripheryStakeAccount(userPrivateKey, 1, sec.passivePoolId, amount, minShares, accountId);
    }
}
