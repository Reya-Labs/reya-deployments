pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import "../DataTypes.sol";

import {
    CollateralConfig,
    ParentCollateralConfig,
    ICoreProxy,
    Action,
    ActionMetadata
} from "../../../src/interfaces/ICoreProxy.sol";

import { IPassivePoolProxy, RebalanceAmounts, AutoRebalanceInput } from "../../../src/interfaces/IPassivePoolProxy.sol";
import {
    IPeripheryProxy,
    DepositNewMAInputs,
    DepositExistingMAInputs,
    DepositPassivePoolInputs
} from "../../../src/interfaces/IPeripheryProxy.sol";

import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { ISocketExecutionHelper } from "../../../src/interfaces/ISocketExecutionHelper.sol";

import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { sd } from "@prb/math/SD59x18.sol";
import { ud } from "@prb/math/UD60x18.sol";

contract PassivePoolForkCheck is BaseReyaForkTest {
    function setUp() public {
        removeCollateralCap(sec.rselini);
        removeCollateralCap(sec.ramber);
        removeCollateralCap(sec.rhedge);

        removeCollateralWithdrawalLimit(sec.rselini);
        removeCollateralWithdrawalLimit(sec.ramber);
        removeCollateralWithdrawalLimit(sec.rhedge);

        fundPassivePool(2_000_000e6);
    }

    function check_PoolHealth() public {
        checkPoolHealth();
    }

    function checkFuzz_PoolDepositWithdraw(address user, address attacker, uint256 amount, uint256 minShares) public {
        deal(sec.usdc, sec.periphery, amount);
        DepositPassivePoolInputs memory inputs =
            DepositPassivePoolInputs({ poolId: sec.passivePoolId, owner: user, minShares: minShares });
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        vm.mockCall(
            dec.socketExecutionHelper[sec.usdc],
            abi.encodeCall(ISocketExecutionHelper.bridgeAmount, ()),
            abi.encode(amount)
        );
        IPeripheryProxy(sec.periphery).depositPassivePool(inputs);

        uint256 userSharesAmount = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, user);
        assert(userSharesAmount >= minShares);

        vm.prank(attacker);
        vm.expectRevert();
        IPassivePoolProxy(sec.pool).removeLiquidity(
            sec.passivePoolId, userSharesAmount, 0, ActionMetadata({ action: Action.Unstake, onBehalfOf: attacker })
        );

        vm.prank(user);
        IPassivePoolProxy(sec.pool).removeLiquidity(
            sec.passivePoolId, userSharesAmount, 0, ActionMetadata({ action: Action.Unstake, onBehalfOf: user })
        );
    }

    function checkFuzz_PoolDepositWithdrawTokenized(
        address user,
        address attacker,
        uint56 amount,
        uint256 minShares
    )
        public
    {
        (address alice,) = makeAddrAndKey("alice");

        vm.prank(sec.multisig);
        ITokenProxy(sec.srusd).addToFeatureFlagAllowlist(keccak256(bytes("authorizedHolder")), alice);

        uint256 sharePriceBefore = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

        deal(sec.rusd, alice, amount);
        vm.prank(alice);
        ITokenProxy(sec.rusd).approve(sec.pool, amount);
        vm.prank(alice);
        IPassivePoolProxy(sec.pool).addLiquidityTokenized(
            sec.passivePoolId,
            alice,
            amount,
            minShares,
            ActionMetadata({ action: Action.StakeTokenized, onBehalfOf: alice })
        );

        uint256 aliceSharesAmount = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, user);
        assertEq(aliceSharesAmount, 0);
        uint256 aliceSrusdAmount = ITokenProxy(sec.srusd).balanceOf(alice);
        assertGe(aliceSrusdAmount, minShares);
        assertEq(ITokenProxy(sec.usdc).balanceOf(alice), 0);

        vm.prank(attacker);
        vm.expectRevert();
        IPassivePoolProxy(sec.pool).removeLiquidityTokenized(
            sec.passivePoolId,
            aliceSrusdAmount,
            0,
            ActionMetadata({ action: Action.UnstakeTokenized, onBehalfOf: attacker })
        );

        vm.prank(alice);
        ITokenProxy(sec.srusd).approve(sec.pool, aliceSrusdAmount);
        vm.prank(alice);
        IPassivePoolProxy(sec.pool).removeLiquidityTokenized(
            sec.passivePoolId,
            aliceSrusdAmount,
            0,
            ActionMetadata({ action: Action.UnstakeTokenized, onBehalfOf: alice })
        );

        assertApproxEqAbsDecimal(ITokenProxy(sec.rusd).balanceOf(alice), amount, 0.001e6, 6);
        assertEq(ITokenProxy(sec.srusd).balanceOf(alice), 0);

        assertApproxEqAbsDecimal(
            IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId), sharePriceBefore, 0.0001e18, 18
        );
    }

    function check_PassivePoolWithToken(address token) public {
        mockFreshPrices();

        (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, token);

        vm.prank(sec.multisig);
        collateralConfig.cap = type(uint256).max;
        ICoreProxy(sec.core).setCollateralConfig(1, token, collateralConfig, parentCollateralConfig);

        (address user, uint256 userPk) = makeAddrAndKey("user");

        uint256 sharePrice0 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

        // add 3000 tokens to the passive pool directly
        deal(token, address(user), 3000e18);
        vm.prank(user);
        ITokenProxy(token).approve(sec.core, 3000e18);
        vm.prank(user);
        ICoreProxy(sec.core).deposit({ accountId: sec.passivePoolAccountId, collateral: token, amount: 3000e18 });

        // check that the new amount increases the share price
        uint256 sharePrice1 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);
        assertGt(sharePrice1, sharePrice0);

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
        uint256 amountOut = IPassivePoolProxy(sec.pool).removeLiquidity(
            sec.passivePoolId, sharesIn, 0, ActionMetadata({ action: Action.Unstake, onBehalfOf: user })
        );
        assertApproxEqAbsDecimal(amountOut, 10e6, 10, 6);

        // create new account and deposit tokens in it
        uint128 accountId = depositNewMA(user, token, 3_000_000e18);

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

        // withdraw 100 tokens from account
        if (isLmToken(token)) {
            withdrawMA(accountId, token, 100e18);
        } else {
            executePeripheryWithdrawMA(user, userPk, 1, accountId, token, 100e18, sec.destinationChainId);
        }
    }

    function autoRebalancePool(bool partialAutoRebalance, bool mintLmTokens) internal {
        removeCollateralWithdrawalLimit(sec.rusd);
        removeCollateralWithdrawalLimit(sec.deusd);
        removeCollateralWithdrawalLimit(sec.sdeusd);
        removeCollateralWithdrawalLimit(sec.rselini);
        removeCollateralWithdrawalLimit(sec.ramber);
        removeCollateralWithdrawalLimit(sec.rhedge);

        address quoteToken = sec.rusd;
        address[] memory supportingTokens = new address[](4);
        supportingTokens[0] = sec.susde;
        supportingTokens[1] = sec.ramber;
        supportingTokens[3] = sec.rselini;
        supportingTokens[2] = sec.rhedge;

        address[] memory allTokens = new address[](supportingTokens.length + 1);
        allTokens[0] = quoteToken;
        for (uint256 i = 0; i < supportingTokens.length; i++) {
            allTokens[i + 1] = supportingTokens[i];
        }

        for (uint256 i = 0; i < allTokens.length; i++) {
            removeCollateralCap(allTokens[i]);
        }

        for (uint256 i = 0; i < allTokens.length; i++) {
            for (uint256 j = 0; j < allTokens.length; j++) {
                if (i == j) {
                    continue;
                }

                address tokenIn = allTokens[i];
                address tokenOut = allTokens[j];

                uint256 minAmountIn = 1 * (10 ** ITokenProxy(tokenIn).decimals());
                uint256 maxAmountIn = 100_000_000 * (10 ** ITokenProxy(tokenIn).decimals());

                RebalanceAmounts memory rebalanceAmounts =
                    IPassivePoolProxy(sec.pool).getRebalanceAmounts(sec.passivePoolId, tokenIn, tokenOut, maxAmountIn);

                uint256 amountIn = rebalanceAmounts.amountIn;
                uint256 priceInToOut = rebalanceAmounts.priceInToOut;

                // if token out is rUSD, we can not rebalance all the margin balance because rUSD is needed to cover for
                // the uPnL and exposure
                if (tokenOut == sec.rusd) {
                    amountIn = amountIn * 9 / 10;
                }

                if (amountIn >= minAmountIn) {
                    uint256 sharePrice0 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

                    if (partialAutoRebalance) {
                        amountIn = amountIn / 2;
                    }

                    if (isLmToken(tokenIn) && mintLmTokens) {
                        vm.prank(sec.poolRebalancer);
                        ITokenProxy(tokenIn).mint(sec.poolRebalancer, amountIn);
                    } else {
                        deal(tokenIn, sec.poolRebalancer, amountIn);
                    }

                    vm.prank(sec.poolRebalancer);
                    ITokenProxy(tokenIn).approve(sec.pool, amountIn);

                    vm.prank(sec.poolRebalancer);
                    IPassivePoolProxy(sec.pool).triggerAutoRebalance(
                        sec.passivePoolId,
                        AutoRebalanceInput({
                            tokenIn: tokenIn,
                            amountIn: amountIn,
                            tokenOut: tokenOut,
                            minPrice: priceInToOut,
                            receiverAddress: sec.periphery
                        })
                    );

                    uint256 sharePrice1 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

                    assertLe(sharePrice0, sharePrice1 + 1e6);
                    assertApproxEqAbsDecimal(sharePrice0, sharePrice1, 1e11, 18);

                    if (partialAutoRebalance) {
                        return;
                    }

                    vm.warp(block.timestamp + 1);
                }
            }
        }
    }

    function check_autoRebalance_currentTargets(bool mintLmTokens) public {
        autoRebalancePool(false, mintLmTokens);
    }

    function check_autoRebalance_differentTargets(bool partialAutoRebalance, bool mintLmTokens) public {
        removeCollateralCap(sec.rselini);
        removeCollateralCap(sec.ramber);
        removeCollateralCap(sec.rhedge);

        autoRebalancePool(partialAutoRebalance, mintLmTokens);
    }

    function check_autoRebalance_noSharePriceChange() public {
        check_autoRebalance_differentTargets(false, false);
    }

    function check_autoRebalance_maxExposure() public {
        vm.warp(block.timestamp + 90);
        (uint256 maxExposureShort0, uint256 maxExposureLong0) =
            IPassivePerpProxy(sec.perp).getPoolMaxExposures(sec.passivePoolId);

        check_autoRebalance_differentTargets(false, false);

        (uint256 maxExposureShort1, uint256 maxExposureLong1) =
            IPassivePerpProxy(sec.perp).getPoolMaxExposures(sec.passivePoolId);

        assertNotEq(maxExposureShort0, maxExposureShort1);
        assertNotEq(maxExposureLong0, maxExposureLong1);
        assertApproxEqRelDecimal(maxExposureShort0, maxExposureShort1, 0.075e18, 18);
        assertApproxEqRelDecimal(maxExposureLong0, maxExposureLong1, 0.075e18, 18);
    }

    function check_autoRebalance_instantaneousPrice() public {
        vm.warp(block.timestamp + 90);

        uint128 marketId = 1;
        int256 baseDelta = 10_000e18;

        uint256 simulatedPrice0 = IPassivePerpProxy(sec.perp).getSimulatedPoolPrice(marketId, baseDelta);
        check_autoRebalance_differentTargets(false, false);
        uint256 simulatedPrice1 = IPassivePerpProxy(sec.perp).getSimulatedPoolPrice(marketId, baseDelta);

        assertNotEq(simulatedPrice0, simulatedPrice1);
        assertApproxEqRelDecimal(simulatedPrice0, simulatedPrice1, 0.075e18, 18);
    }

    function check_sharePriceChangesWhenAssetPriceChanges() public {
        vm.warp(block.timestamp + 90);
        autoRebalancePool(true, false);

        uint256 sharePrice0 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

        (, ParentCollateralConfig memory rseliniParentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.rselini);

        NodeOutput.Data memory rseliniOutput =
            IOracleManagerProxy(sec.oracleManager).process(rseliniParentCollateralConfig.oracleNodeId);
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (rseliniParentCollateralConfig.oracleNodeId)),
            abi.encode(
                NodeOutput.Data({ price: ud(rseliniOutput.price).mul(ud(0.99e18)).unwrap(), timestamp: block.timestamp })
            )
        );

        uint256 sharePrice1 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

        assertNotEq(sharePrice0, sharePrice1);
        assertApproxEqRelDecimal(sharePrice0, sharePrice1, 0.01e18, 18);
    }

    function check_autoRebalance_revertWhenSenderIsNotRebalancer() public {
        vm.prank(address(5555));
        vm.expectRevert(
            abi.encodeWithSelector(
                IPassivePoolProxy.FeatureUnavailable.selector,
                keccak256(abi.encode(keccak256(bytes("autoRebalance")), sec.passivePoolId))
            )
        );
        IPassivePoolProxy(sec.pool).triggerAutoRebalance(
            sec.passivePoolId,
            AutoRebalanceInput({
                tokenIn: address(0),
                amountIn: 0,
                tokenOut: address(0),
                minPrice: 0,
                receiverAddress: address(0)
            })
        );
    }

    function checkFuzz_depositWithdraw_noSharePriceChange(int256[] memory amountsFuzz) public {
        vm.assume(amountsFuzz.length <= 10);

        int256[] memory amounts = new int256[](amountsFuzz.length);
        address token = sec.rusd;

        for (uint256 i = 0; i < amountsFuzz.length; i++) {
            if (amountsFuzz[i] < 0) {
                if (amountsFuzz[i] == type(int256).min) {
                    amountsFuzz[i] += 1;
                }
                amounts[i] =
                    (-1000 + int256((uint256(-amountsFuzz[i]) % 1000))) * int256(10 ** ITokenProxy(token).decimals());
            } else {
                amounts[i] = int256((uint256(amountsFuzz[i]) % 1000)) * int256(10 ** ITokenProxy(token).decimals());
            }
        }

        address owner = vm.addr(333_222);
        vm.prank(sec.multisig);
        IPassivePoolProxy(sec.pool).addToFeatureFlagAllowlist(
            keccak256(abi.encode(keccak256(bytes("v2Liquidity")), sec.passivePoolId)), owner
        );

        for (uint256 i = 0; i < amountsFuzz.length; i++) {
            uint256 sharePrice0 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);
            if (amounts[i] > 0) {
                uint256 amount = uint256(amounts[i]);
                if (amount == 0) {
                    continue;
                }

                deal(token, owner, amount);
                vm.prank(owner);
                ITokenProxy(token).approve(sec.pool, amount);
                vm.prank(owner);
                IPassivePoolProxy(sec.pool).addLiquidity({
                    poolId: sec.passivePoolId,
                    owner: owner,
                    amount: amount,
                    minShares: 0,
                    actionMetadata: ActionMetadata({ action: Action.Stake, onBehalfOf: owner })
                });
            } else {
                uint256 amount = uint256(-amounts[i]);

                uint256 poolTokenBalance =
                    uint256(ICoreProxy(sec.core).getTokenMarginInfo(sec.passivePoolId, token).marginBalance);
                if (amount > poolTokenBalance) {
                    amount = poolTokenBalance;
                }

                uint256 sharesAmount = amount * 99 / 100 * 10 ** (30 - ITokenProxy(token).decimals());
                uint256 ownerSharesAmount = IPassivePoolProxy(sec.pool).getAccountBalance(sec.passivePoolId, owner);
                if (ownerSharesAmount < sharesAmount) {
                    sharesAmount = ownerSharesAmount;
                }

                if (sharesAmount == 0) {
                    continue;
                }

                vm.prank(owner);
                IPassivePoolProxy(sec.pool).removeLiquidity({
                    poolId: sec.passivePoolId,
                    sharesAmount: sharesAmount,
                    minOut: 0,
                    actionMetadata: ActionMetadata({ action: Action.Unstake, onBehalfOf: owner })
                });
            }

            uint256 sharePrice1 = IPassivePoolProxy(sec.pool).getSharePrice(sec.passivePoolId);

            assertLe(sharePrice0, sharePrice1);
            assertApproxEqRelDecimal(sharePrice0, sharePrice1, 1e12, 18);
        }
    }
}
