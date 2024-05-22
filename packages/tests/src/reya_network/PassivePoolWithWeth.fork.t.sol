pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { ForkChecks } from "./ForkChecks.t.sol";
import {
    ICoreProxy,
    TriggerAutoExchangeInput,
    AutoExchangeAmounts,
    ParentCollateralConfig
} from "../interfaces/ICoreProxy.sol";
import { IPassivePoolProxy } from "../interfaces/IPassivePoolProxy.sol";
import {
    IPeripheryProxy,
    DepositNewMAInputs,
    DepositExistingMAInputs,
    DepositPassivePoolInputs
} from "../interfaces/IPeripheryProxy.sol";
import { IOracleManagerProxy, NodeOutput } from "../interfaces/IOracleManagerProxy.sol";
import { ISocketExecutionHelper } from "../interfaces/ISocketExecutionHelper.sol";

import { sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract PassivePoolWithWeth is ForkChecks {
    function test_PassivePoolWithWeth() public {
        (user, userPk) = makeAddrAndKey("user");

        uint256 sharePrice0 = IPassivePoolProxy(pool).getSharePrice(passivePoolId);

        // add 1 wETH to the passive pool directly
        deal(weth, address(periphery), 1e18);
        mockBridgedAmount(socketExecutionHelper[weth], 1e18);
        vm.prank(socketExecutionHelper[weth]);
        IPeripheryProxy(periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: passivePoolAccountId, token: address(weth) })
        );

        // check that the new 1 wETH does not influence the share price
        uint256 sharePrice1 = IPassivePoolProxy(pool).getSharePrice(passivePoolId);
        assertEq(sharePrice1, sharePrice0);

        // make sure that the passive pool deposit works
        deal(usdc, periphery, 10e6);
        vm.prank(socketExecutionHelper[usdc]);
        vm.mockCall(
            socketExecutionHelper[usdc], abi.encodeCall(ISocketExecutionHelper.bridgeAmount, ()), abi.encode(10e6)
        );
        IPeripheryProxy(periphery).depositPassivePool(
            DepositPassivePoolInputs({ poolId: passivePoolId, owner: user, minShares: 0 })
        );

        uint256 sharesIn = IPassivePoolProxy(pool).getAccountBalance(passivePoolId, user);

        // make sure that the passive pool withdrawal works
        vm.prank(user);
        uint256 amountOut = IPassivePoolProxy(pool).removeLiquidity(passivePoolId, sharesIn, 0);
        assertApproxEqAbsDecimal(amountOut, 10e6, 10, 6);

        // create new account and deposit 11 wETH in it
        deal(weth, address(periphery), 11e18);
        mockBridgedAmount(socketExecutionHelper[weth], 11e18);
        vm.prank(socketExecutionHelper[weth]);
        uint128 accountId =
            IPeripheryProxy(periphery).depositNewMA(DepositNewMAInputs({ accountOwner: user, token: address(weth) }));

        // user executes short trade on ETH
        executeCoreMatchOrder({ marketId: 1, sender: user, base: sd(-10e18), priceLimit: ud(0), accountId: accountId });

        // user closes the short trade on ETH and goes same long
        executeCoreMatchOrder({
            marketId: 1,
            sender: user,
            base: sd(20e18),
            priceLimit: ud(type(uint256).max),
            accountId: accountId
        });

        // withdraw 1 wETH from account
        executePeripheryWithdrawMA(user, userPk, 1, accountId, weth, 1e18, arbitrumChainId);
    }
}
