pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { ForkChecks } from "./ForkChecks.t.sol";
import { ICoreProxy, TriggerAutoExchangeInput, AutoExchangeAmounts } from "../interfaces/ICoreProxy.sol";
import { IPeripheryProxy, DepositNewMAInputs, DepositExistingMAInputs } from "../interfaces/IPeripheryProxy.sol";
import { IOracleManagerProxy, NodeOutput } from "../interfaces/IOracleManagerProxy.sol";

import { sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

contract AutoExchangeFork is ForkChecks {
    struct TokenBalances {
        int256 userBalanceWeth;
        int256 userBalanceRusd;
        int256 liquidatorBalanceWeth;
        int256 liquidatorBalanceRusd;
    }

    struct State {
        uint128 userAccountId;
        address liquidator;
        uint128 liquidatorAccountId;
        uint256 bumpedEthPrice;
        AutoExchangeAmounts ae1;
        AutoExchangeAmounts ae2;
        TokenBalances tbal0;
        TokenBalances tbal1;
        TokenBalances tbal2;
    }

    State state;

    function check_AutoExchange_wEth(uint256 userInitialRusdBalance) internal {
        (user, userPk) = makeAddrAndKey("user");
        state.userAccountId = 0;

        (state.liquidator,) = makeAddrAndKey("liquidator");
        state.liquidatorAccountId = 0;

        // deposit rUSD and ETH into user's account
        {
            deal(weth, address(periphery), 1e18);
            mockBridgedAmount(socketExecutionHelper[weth], 1e18);
            vm.prank(socketExecutionHelper[weth]);
            state.userAccountId = IPeripheryProxy(periphery).depositNewMA(
                DepositNewMAInputs({ accountOwner: user, token: address(weth) })
            );

            if (userInitialRusdBalance > 0) {
                deal(usdc, address(periphery), userInitialRusdBalance);
                mockBridgedAmount(socketExecutionHelper[usdc], userInitialRusdBalance);
                vm.prank(socketExecutionHelper[usdc]);
                IPeripheryProxy(periphery).depositExistingMA(
                    DepositExistingMAInputs({ accountId: state.userAccountId, token: address(usdc) })
                );
            }
        }

        // deposit rUSD into liquidator's account
        {
            deal(usdc, address(periphery), 10_000e6);
            mockBridgedAmount(socketExecutionHelper[usdc], 10_000e6);
            vm.prank(socketExecutionHelper[usdc]);
            state.liquidatorAccountId = IPeripheryProxy(periphery).depositNewMA(
                DepositNewMAInputs({ accountOwner: state.liquidator, token: address(usdc) })
            );
        }

        // user executes short trade on ETH
        (UD60x18 orderPrice,) = executeCoreMatchOrder({
            marketId: 1,
            sender: user,
            base: sd(-1e18),
            priceLimit: ud(0),
            accountId: state.userAccountId
        });

        // mark the liquidator account on the collateral pool 1
        vm.prank(state.liquidator);
        ICoreProxy(core).activateFirstMarketForAccount(state.liquidatorAccountId, 1);

        // if initial rUSD balance is 0 (or small), the trading fees will make the rUSD balance
        // drop directly below 0 and making the account auto-exchangeable for that small gap

        if (userInitialRusdBalance > 0) {
            // attempt to auto-exchange but the tx reverts since account is not AE-able
            vm.prank(state.liquidator);
            vm.expectRevert(
                abi.encodeWithSelector(ICoreProxy.AccountNotEligibleForAutoExchange.selector, state.userAccountId, rusd)
            );
            ICoreProxy(core).triggerAutoExchange(
                TriggerAutoExchangeInput({
                    accountId: state.userAccountId,
                    liquidatorAccountId: state.liquidatorAccountId,
                    requestedQuoteAmount: 400e6,
                    collateral: weth,
                    inCollateral: rusd
                })
            );
        }

        // price moves by 600 USD
        state.bumpedEthPrice = orderPrice.unwrap() + 600e18;
        vm.mockCall(
            oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (ethUsdcNodeId)),
            abi.encode(NodeOutput.Data({ price: state.bumpedEthPrice, timestamp: block.timestamp }))
        );

        // check that the account is AE-able but still healthy
        state.tbal0.userBalanceRusd = ICoreProxy(core).getTokenMarginInfo(state.userAccountId, rusd).marginBalance;
        state.tbal0.userBalanceWeth = ICoreProxy(core).getTokenMarginInfo(state.userAccountId, weth).marginBalance;
        state.tbal0.liquidatorBalanceRusd =
            ICoreProxy(core).getTokenMarginInfo(state.liquidatorAccountId, rusd).marginBalance;
        state.tbal0.liquidatorBalanceWeth =
            ICoreProxy(core).getTokenMarginInfo(state.liquidatorAccountId, weth).marginBalance;

        assertLt(state.tbal0.userBalanceRusd, -400e6);

        assertGt(ICoreProxy(core).getNodeMarginInfo(state.userAccountId, rusd).initialDelta, 0);

        // auto-exchange 400 rUSD
        vm.prank(state.liquidator);
        state.ae1 = ICoreProxy(core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: state.userAccountId,
                liquidatorAccountId: state.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: weth,
                inCollateral: rusd
            })
        );

        assertEq(state.ae1.quoteAmountToIF, 4e6);
        assertEq(state.ae1.quoteAmountToAccount, 396e6);
        assertApproxEqAbsDecimal(
            state.ae1.collateralAmountToLiquidator, 400e18 * 1.01 * 1e18 / state.bumpedEthPrice, 0.001e18, 18
        );

        state.tbal1.userBalanceRusd = ICoreProxy(core).getTokenMarginInfo(state.userAccountId, rusd).marginBalance;
        state.tbal1.userBalanceWeth = ICoreProxy(core).getTokenMarginInfo(state.userAccountId, weth).marginBalance;
        state.tbal1.liquidatorBalanceRusd =
            ICoreProxy(core).getTokenMarginInfo(state.liquidatorAccountId, rusd).marginBalance;
        state.tbal1.liquidatorBalanceWeth =
            ICoreProxy(core).getTokenMarginInfo(state.liquidatorAccountId, weth).marginBalance;

        assertEq(state.tbal1.userBalanceRusd, state.tbal0.userBalanceRusd + 396e6);
        assertEq(state.tbal1.liquidatorBalanceRusd, state.tbal0.liquidatorBalanceRusd - 400e6);
        assertEq(
            state.tbal1.userBalanceWeth, state.tbal0.userBalanceWeth - int256(state.ae1.collateralAmountToLiquidator)
        );
        assertEq(
            state.tbal1.liquidatorBalanceWeth,
            state.tbal0.liquidatorBalanceWeth + int256(state.ae1.collateralAmountToLiquidator)
        );

        // unwind the short trade (check that it's possible to perform trade even though rUSD balance is below 0 as long
        // as ETH/other tokens support this)
        executeCoreMatchOrder({
            marketId: 1,
            sender: user,
            base: sd(1e18),
            priceLimit: ud(type(uint256).max),
            accountId: state.userAccountId
        });

        state.tbal1.userBalanceRusd = ICoreProxy(core).getTokenMarginInfo(state.userAccountId, rusd).marginBalance;
        state.tbal1.userBalanceWeth = ICoreProxy(core).getTokenMarginInfo(state.userAccountId, weth).marginBalance;
        state.tbal1.liquidatorBalanceRusd =
            ICoreProxy(core).getTokenMarginInfo(state.liquidatorAccountId, rusd).marginBalance;
        state.tbal1.liquidatorBalanceWeth =
            ICoreProxy(core).getTokenMarginInfo(state.liquidatorAccountId, weth).marginBalance;

        // auto-exchange the remaining amount (check that only the remaining part is AE)
        vm.prank(state.liquidator);
        state.ae2 = ICoreProxy(core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: state.userAccountId,
                liquidatorAccountId: state.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: weth,
                inCollateral: rusd
            })
        );

        assertLt(state.ae2.quoteAmountToAccount, 220e6);

        assertEq(int256(state.ae2.quoteAmountToAccount) + state.tbal1.userBalanceRusd, 0);
        assertApproxEqAbsDecimal(
            state.ae2.collateralAmountToLiquidator,
            state.ae2.quoteAmountToAccount * 1.01e12 * 1e18 / state.bumpedEthPrice,
            0.001e18,
            18
        );

        state.tbal2.userBalanceRusd = ICoreProxy(core).getTokenMarginInfo(state.userAccountId, rusd).marginBalance;
        state.tbal2.userBalanceWeth = ICoreProxy(core).getTokenMarginInfo(state.userAccountId, weth).marginBalance;
        state.tbal2.liquidatorBalanceRusd =
            ICoreProxy(core).getTokenMarginInfo(state.liquidatorAccountId, rusd).marginBalance;
        state.tbal2.liquidatorBalanceWeth =
            ICoreProxy(core).getTokenMarginInfo(state.liquidatorAccountId, weth).marginBalance;

        assertEq(state.tbal2.userBalanceRusd, 0);
        assertEq(
            state.tbal2.liquidatorBalanceRusd,
            state.tbal1.liquidatorBalanceRusd - int256(state.ae2.quoteAmountToAccount + state.ae2.quoteAmountToIF)
        );
        assertEq(
            state.tbal2.userBalanceWeth, state.tbal1.userBalanceWeth - int256(state.ae2.collateralAmountToLiquidator)
        );
        assertEq(
            state.tbal2.liquidatorBalanceWeth,
            state.tbal1.liquidatorBalanceWeth + int256(state.ae2.collateralAmountToLiquidator)
        );
    }

    function test_AutoExchangeWeth_WhenUserHasOnlyWeth() public {
        check_AutoExchange_wEth(0);
    }

    function test_AutoExchangeWeth_WhenUserHasBothWethAndRusd() public {
        check_AutoExchange_wEth(100e6);
    }

    // TODO: add test when WETH does not cover auto-exchanged amount
}
