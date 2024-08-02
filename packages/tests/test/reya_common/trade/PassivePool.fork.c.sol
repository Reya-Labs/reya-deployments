pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import { CollateralConfig, ParentCollateralConfig, ICoreProxy } from "../../../src/interfaces/ICoreProxy.sol";

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

contract PassivePoolForkCheck is BaseReyaForkTest {
    function check_PoolHealth() public {
        checkPoolHealth();
    }

    function checkFuzz_PoolDepositWithdraw(address user, address attacker) public {
        uint256 amount = 100e6;
        deal(sec.usdc, sec.periphery, amount);
        DepositPassivePoolInputs memory inputs =
            DepositPassivePoolInputs({ poolId: sec.passivePoolId, owner: user, minShares: 0 });
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        vm.mockCall(
            dec.socketExecutionHelper[sec.usdc],
            abi.encodeCall(ISocketExecutionHelper.bridgeAmount, ()),
            abi.encode(amount)
        );
        IPeripheryProxy(sec.periphery).depositPassivePool(inputs);

        uint256 userSharesAmount = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, user);
        assert(userSharesAmount > 0);

        vm.prank(attacker);
        vm.expectRevert();
        IPassivePoolProxy(sec.pool).removeLiquidity(sec.passivePoolId, userSharesAmount, 0);

        vm.prank(user);
        IPassivePoolProxy(sec.pool).removeLiquidity(sec.passivePoolId, userSharesAmount, 0);
    }

    function check_PassivePoolWithWeth() public {
        (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.weth);

        vm.prank(sec.multisig);
        collateralConfig.cap = type(uint256).max;
        ICoreProxy(sec.core).setCollateralConfig(1, sec.weth, collateralConfig, parentCollateralConfig);

        (address user, uint256 userPk) = makeAddrAndKey("user");

        uint256 sharePrice0 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

        // add 1 wETH to the passive pool directly
        deal(sec.weth, address(sec.periphery), 1e18);
        mockBridgedAmount(dec.socketExecutionHelper[sec.weth], 1e18);
        vm.prank(dec.socketExecutionHelper[sec.weth]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: sec.passivePoolAccountId, token: address(sec.weth) })
        );

        // check that the new 1 wETH does not influence the share price
        uint256 sharePrice1 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);
        assertEq(sharePrice1, sharePrice0);

        // make sure that the passive pool deposit works
        deal(sec.usdc, sec.periphery, 10e6);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        vm.mockCall(
            dec.socketExecutionHelper[sec.usdc],
            abi.encodeCall(ISocketExecutionHelper.bridgeAmount, ()),
            abi.encode(10e6)
        );
        IPeripheryProxy(sec.periphery).depositPassivePool(
            DepositPassivePoolInputs({ poolId: sec.passivePoolId, owner: user, minShares: 0 })
        );

        uint256 sharesIn = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, user);

        // make sure that the passive pool withdrawal works
        vm.prank(user);
        uint256 amountOut = IPassivePoolProxy(sec.pool).removeLiquidity(sec.passivePoolId, sharesIn, 0);
        assertApproxEqAbsDecimal(amountOut, 10e6, 10, 6);

        // create new account and deposit 11 wETH in it
        deal(sec.weth, address(sec.periphery), 11e18);
        mockBridgedAmount(dec.socketExecutionHelper[sec.weth], 11e18);
        vm.prank(dec.socketExecutionHelper[sec.weth]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.weth) })
        );

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
        executePeripheryWithdrawMA(user, userPk, 1, accountId, sec.weth, 1e18, sec.mainChainId);
    }

    function check_PassivePoolWithUsde() public {
        (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.usde);

        vm.prank(sec.multisig);
        collateralConfig.cap = type(uint256).max;
        ICoreProxy(sec.core).setCollateralConfig(1, sec.usde, collateralConfig, parentCollateralConfig);

        (address user, uint256 userPk) = makeAddrAndKey("user");

        uint256 sharePrice0 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

        // add 3000 USDe to the passive pool directly
        deal(sec.usde, address(sec.periphery), 3000e18);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], 3000e18);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: sec.passivePoolAccountId, token: address(sec.usde) })
        );

        // check that the new 3000 USDe does not influence the share price
        uint256 sharePrice1 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);
        assertEq(sharePrice1, sharePrice0);

        // make sure that the passive pool deposit works
        deal(sec.usdc, sec.periphery, 10e6);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        vm.mockCall(
            dec.socketExecutionHelper[sec.usdc],
            abi.encodeCall(ISocketExecutionHelper.bridgeAmount, ()),
            abi.encode(10e6)
        );
        IPeripheryProxy(sec.periphery).depositPassivePool(
            DepositPassivePoolInputs({ poolId: sec.passivePoolId, owner: user, minShares: 0 })
        );

        uint256 sharesIn = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, user);

        // make sure that the passive pool withdrawal works
        vm.prank(user);
        uint256 amountOut = IPassivePoolProxy(sec.pool).removeLiquidity(sec.passivePoolId, sharesIn, 0);
        assertApproxEqAbsDecimal(amountOut, 10e6, 10, 6);

        // create new account and deposit 33000 USDe in it
        deal(sec.usde, address(sec.periphery), 33_000e18);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usde], 33_000e18);
        vm.prank(dec.socketExecutionHelper[sec.usde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usde) })
        );

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

        // withdraw 100 USDe from account
        executePeripheryWithdrawMA(user, userPk, 1, accountId, sec.usde, 100e18, sec.mainChainId);
    }
}
