pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import { IPassivePoolProxy } from "../../../src/interfaces/IPassivePoolProxy.sol";

import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

contract PoolStakeForkCheck is BaseReyaForkTest {
    address user;
    uint256 userPrivateKey;

    function setUp() public {
        (user, userPrivateKey) = makeAddrAndKey("user-pool-stake");
    }

    function check_StakeUnstakeCommand(uint256 amount, uint256 minShares) public {
        uint128 accountId = depositNewMA(user, sec.usdc, amount);

        executePeripheryStakeAccount(userPrivateKey, 1, sec.passivePoolId, amount, minShares, accountId);
        assertGe(uint256(getNetDeposits(accountId, sec.srusd)), minShares);
        assertEq(getNetDeposits(accountId, sec.rusd), 0);

        uint256 sharesAmount = uint256(getNetDeposits(accountId, sec.srusd));
        executePeripheryUnstakeAccount(userPrivateKey, 2, sec.passivePoolId, sharesAmount, 0, accountId);

        assertEq(uint256(getNetDeposits(accountId, sec.srusd)), 0);
        assertApproxEqAbsDecimal(uint256(getNetDeposits(accountId, sec.rusd)), amount, 0.001e6, 6);
    }

    function check_MoveLiquidity(uint256 amount, uint256 minShares) public {
        uint128 accountId = depositNewMA(user, sec.usdc, 10e6);

        executePeripheryAddLiquidity(user, amount, minShares);
        uint256 sharesAmount = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, user);
        assertGe(sharesAmount, minShares);

        executePeripheryDepositLiquidityToAccount(user, userPrivateKey, 1, sharesAmount, accountId);

        assertEq(getNetDeposits(accountId, sec.rusd), 10e6);
        assertApproxEqAbsDecimal(uint256(getNetDeposits(accountId, sec.srusd)), sharesAmount, 0.000001e30, 30);

        removeCollateralWithdrawalLimit(sec.srusd);

        sharesAmount = uint256(getNetDeposits(accountId, sec.srusd));

        assertEq(getNetDeposits(accountId, sec.srusd), 0);
        assertEq(getNetDeposits(accountId, sec.rusd), 10e6);

        assertApproxEqAbsDecimal(
            IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, user), sharesAmount, 0.000001e30, 30
        );

        assertEq(ITokenProxy(sec.srusd).balanceOf(sec.periphery), 0);
    }
}
