pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import { CollateralConfig, ParentCollateralConfig, ICoreProxy } from "../../../src/interfaces/ICoreProxy.sol";

import {
    IPassivePoolProxy,
    RebalanceAmounts,
    AutoRebalanceInput,
    AllocationConfigurationData
} from "../../../src/interfaces/IPassivePoolProxy.sol";
import {
    IPeripheryProxy,
    DepositNewMAInputs,
    DepositExistingMAInputs,
    DepositPassivePoolInputs
} from "../../../src/interfaces/IPeripheryProxy.sol";

import { ISocketExecutionHelper } from "../../../src/interfaces/ISocketExecutionHelper.sol";

import { IERC20TokenModule } from "../../../src/interfaces/IERC20TokenModule.sol";

import { sd } from "@prb/math/SD59x18.sol";
import { ud, convert as convert_ud } from "@prb/math/UD60x18.sol";

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
        mockFreshPrices();

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
        assertApproxEqRelDecimal(sharePrice1, sharePrice0, 0.005e18, 18);

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
        mockFreshPrices();

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
        assertApproxEqRelDecimal(sharePrice1, sharePrice0, 0.005e18, 18);

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

    function check_PassivePoolWithSusde() public {
        mockFreshPrices();

        (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.susde);

        vm.prank(sec.multisig);
        collateralConfig.cap = type(uint256).max;
        ICoreProxy(sec.core).setCollateralConfig(1, sec.susde, collateralConfig, parentCollateralConfig);

        (address user, uint256 userPk) = makeAddrAndKey("user");

        uint256 sharePrice0 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

        // add 3000 sUSDe to the passive pool directly
        deal(sec.susde, address(sec.periphery), 3000e18);
        mockBridgedAmount(dec.socketExecutionHelper[sec.susde], 3000e18);
        vm.prank(dec.socketExecutionHelper[sec.susde]);
        IPeripheryProxy(sec.periphery).depositExistingMA(
            DepositExistingMAInputs({ accountId: sec.passivePoolAccountId, token: address(sec.susde) })
        );

        // check that the new 3000 sUSDe does not influence the share price
        uint256 sharePrice1 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);
        assertApproxEqRelDecimal(sharePrice1, sharePrice0, 0.005e18, 18);

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

        // create new account and deposit 33000 sUSDe in it
        deal(sec.susde, address(sec.periphery), 33_000e18);
        mockBridgedAmount(dec.socketExecutionHelper[sec.susde], 33_000e18);
        vm.prank(dec.socketExecutionHelper[sec.susde]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.susde) })
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

        // withdraw 100 sUSDe from account
        executePeripheryWithdrawMA(user, userPk, 1, accountId, sec.susde, 100e18, sec.mainChainId);
    }

    function autoRebalancePool() internal {
        address quoteToken = sec.rusd;
        address[] memory supportingTokens = IPassivePoolProxy(sec.pool).getQuoteSupportingCollaterals(sec.passivePoolId);

        address[] memory allTokens = new address[](supportingTokens.length + 1);
        allTokens[0] = quoteToken;
        for (uint256 i = 0; i < supportingTokens.length; i++) {
            allTokens[i + 1] = supportingTokens[i];
        }

        for (uint256 i = 0; i < allTokens.length; i++) {
            for (uint256 j = 0; j < allTokens.length; j++) {
                if (i == j) {
                    continue;
                }

                address tokenIn = allTokens[i];
                address tokenOut = allTokens[j];

                uint256 amountIn = 100_000_000 * (10 ** IERC20TokenModule(tokenIn).decimals());

                RebalanceAmounts memory rebalanceAmounts =
                    IPassivePoolProxy(sec.pool).getRebalanceAmounts(sec.passivePoolId, tokenIn, tokenOut, amountIn);

                if (rebalanceAmounts.amountIn != 0) {
                    vm.prank(dec.socketController[tokenIn]);
                    IERC20TokenModule(tokenIn).mint(sec.rebalancer1, rebalanceAmounts.amountIn);

                    vm.prank(sec.rebalancer1);
                    IERC20TokenModule(tokenIn).approve(sec.pool, rebalanceAmounts.amountIn);

                    vm.prank(sec.rebalancer1);
                    IPassivePoolProxy(sec.pool).triggerAutoRebalance(
                        sec.passivePoolId,
                        AutoRebalanceInput({
                            tokenIn: tokenIn,
                            amountIn: rebalanceAmounts.amountIn,
                            tokenOut: tokenOut,
                            minPrice: rebalanceAmounts.priceInToOut,
                            receiverAddress: sec.periphery
                        })
                    );

                    vm.warp(block.timestamp + 1);
                }
            }
        }
    }

    function check_autoRebalance_currentTargets() public {
        autoRebalancePool();
    }

    function check_autoRebalance_differentTargets() public {
        vm.prank(sec.multisig);
        IPassivePoolProxy(sec.pool).setAllocationConfiguration(
            sec.passivePoolId, AllocationConfigurationData({ quoteTokenTargetRatio: 0.353535e18 })
        );

        address[] memory supportingCollaterals =
            IPassivePoolProxy(sec.pool).getQuoteSupportingCollaterals(sec.passivePoolId);
        uint256[] memory newSupportingCollateralsAllocations = new uint256[](supportingCollaterals.length);

        newSupportingCollateralsAllocations[newSupportingCollateralsAllocations.length - 2] = 0.454545e18;
        newSupportingCollateralsAllocations[newSupportingCollateralsAllocations.length - 1] = 1e18 - 0.454545e18;

        vm.prank(sec.multisig);
        IPassivePoolProxy(sec.pool).setAllocations(sec.passivePoolId, newSupportingCollateralsAllocations);

        autoRebalancePool();
    }
}
