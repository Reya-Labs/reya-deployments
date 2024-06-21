pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { ReyaForkTest } from "../ReyaForkTest.sol";
import { ICoreProxy, TriggerAutoExchangeInput, AutoExchangeAmounts } from "../../../src/interfaces/ICoreProxy.sol";
import {
    IPeripheryProxy, DepositNewMAInputs, DepositExistingMAInputs
} from "../../../src/interfaces/IPeripheryProxy.sol";
import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

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

contract AutoExchangeForkTest is ReyaForkTest {
    State private state;

    function check_AutoExchange_wEth(uint256 userInitialRusdBalance) internal {
        (address user,) = makeAddrAndKey("user");
        state.userAccountId = 0;

        (state.liquidator,) = makeAddrAndKey("liquidator");
        state.liquidatorAccountId = 0;

        // deposit rUSD and ETH into user's account
        {
            deal(sec.weth, address(sec.periphery), 1e18);
            mockBridgedAmount(dec.socketExecutionHelper[sec.weth], 1e18);
            vm.prank(dec.socketExecutionHelper[sec.weth]);
            state.userAccountId = IPeripheryProxy(sec.periphery).depositNewMA(
                DepositNewMAInputs({ accountOwner: user, token: address(sec.weth) })
            );

            if (userInitialRusdBalance > 0) {
                deal(sec.usdc, address(sec.periphery), userInitialRusdBalance);
                mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], userInitialRusdBalance);
                vm.prank(dec.socketExecutionHelper[sec.usdc]);
                IPeripheryProxy(sec.periphery).depositExistingMA(
                    DepositExistingMAInputs({ accountId: state.userAccountId, token: address(sec.usdc) })
                );
            }
        }

        // deposit rUSD into liquidator's account
        {
            deal(sec.usdc, address(sec.periphery), 10_000e6);
            mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], 10_000e6);
            vm.prank(dec.socketExecutionHelper[sec.usdc]);
            state.liquidatorAccountId = IPeripheryProxy(sec.periphery).depositNewMA(
                DepositNewMAInputs({ accountOwner: state.liquidator, token: address(sec.usdc) })
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
        ICoreProxy(sec.core).activateFirstMarketForAccount(state.liquidatorAccountId, 1);

        // if initial rUSD balance is 0 (or small), the trading fees will make the rUSD balance
        // drop directly below 0 and making the account auto-exchangeable for that small gap

        if (userInitialRusdBalance > 0) {
            // attempt to auto-exchange but the tx reverts since account is not AE-able
            vm.prank(state.liquidator);
            vm.expectRevert(
                abi.encodeWithSelector(
                    ICoreProxy.AccountNotEligibleForAutoExchange.selector, state.userAccountId, sec.rusd
                )
            );
            ICoreProxy(sec.core).triggerAutoExchange(
                TriggerAutoExchangeInput({
                    accountId: state.userAccountId,
                    liquidatorAccountId: state.liquidatorAccountId,
                    requestedQuoteAmount: 400e6,
                    collateral: sec.weth,
                    inCollateral: sec.rusd
                })
            );
        }

        // price moves by 600 USD
        state.bumpedEthPrice = orderPrice.unwrap() + 600e18;
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcNodeId)),
            abi.encode(NodeOutput.Data({ price: state.bumpedEthPrice, timestamp: block.timestamp }))
        );

        // check that the account is AE-able but still healthy
        state.tbal0.userBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(state.userAccountId, sec.rusd).marginBalance;
        state.tbal0.userBalanceWeth =
            ICoreProxy(sec.core).getTokenMarginInfo(state.userAccountId, sec.weth).marginBalance;
        state.tbal0.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(state.liquidatorAccountId, sec.rusd).marginBalance;
        state.tbal0.liquidatorBalanceWeth =
            ICoreProxy(sec.core).getTokenMarginInfo(state.liquidatorAccountId, sec.weth).marginBalance;

        assertLt(state.tbal0.userBalanceRusd, -400e6);

        assertGt(ICoreProxy(sec.core).getNodeMarginInfo(state.userAccountId, sec.rusd).initialDelta, 0);

        // auto-exchange 400 rUSD
        vm.prank(state.liquidator);
        state.ae1 = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: state.userAccountId,
                liquidatorAccountId: state.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: sec.weth,
                inCollateral: sec.rusd
            })
        );

        assertEq(state.ae1.quoteAmountToIF, 4e6);
        assertEq(state.ae1.quoteAmountToAccount, 396e6);
        assertApproxEqAbsDecimal(
            state.ae1.collateralAmountToLiquidator, 400e18 * 1.01 * 1e18 / state.bumpedEthPrice, 0.001e18, 18
        );

        state.tbal1.userBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(state.userAccountId, sec.rusd).marginBalance;
        state.tbal1.userBalanceWeth =
            ICoreProxy(sec.core).getTokenMarginInfo(state.userAccountId, sec.weth).marginBalance;
        state.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(state.liquidatorAccountId, sec.rusd).marginBalance;
        state.tbal1.liquidatorBalanceWeth =
            ICoreProxy(sec.core).getTokenMarginInfo(state.liquidatorAccountId, sec.weth).marginBalance;

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

        state.tbal1.userBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(state.userAccountId, sec.rusd).marginBalance;
        state.tbal1.userBalanceWeth =
            ICoreProxy(sec.core).getTokenMarginInfo(state.userAccountId, sec.weth).marginBalance;
        state.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(state.liquidatorAccountId, sec.rusd).marginBalance;
        state.tbal1.liquidatorBalanceWeth =
            ICoreProxy(sec.core).getTokenMarginInfo(state.liquidatorAccountId, sec.weth).marginBalance;

        // auto-exchange the remaining amount (check that only the remaining part is AE)
        vm.prank(state.liquidator);
        state.ae2 = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: state.userAccountId,
                liquidatorAccountId: state.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: sec.weth,
                inCollateral: sec.rusd
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

        state.tbal2.userBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(state.userAccountId, sec.rusd).marginBalance;
        state.tbal2.userBalanceWeth =
            ICoreProxy(sec.core).getTokenMarginInfo(state.userAccountId, sec.weth).marginBalance;
        state.tbal2.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(state.liquidatorAccountId, sec.rusd).marginBalance;
        state.tbal2.liquidatorBalanceWeth =
            ICoreProxy(sec.core).getTokenMarginInfo(state.liquidatorAccountId, sec.weth).marginBalance;

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
