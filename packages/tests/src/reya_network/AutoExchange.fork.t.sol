pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { ForkChecks } from "./ForkChecks.t.sol";
import { ICoreProxy, TriggerAutoExchangeInput, AutoExchangeAmounts } from "../interfaces/ICoreProxy.sol";
import {
    IPeripheryProxy,
    DepositNewMAInputs,
    DepositExistingMAInputs
} from "../interfaces/IPeripheryProxy.sol";
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

    State s;

    function test_AutoExchange_wEth() public {
        (user, userPk) = makeAddrAndKey("user");
        s.userAccountId = 0;

        (s.liquidator,) = makeAddrAndKey("user");
        s.liquidatorAccountId = 0;

        // deposit rUSD and ETH into user's account
        {
            deal(weth, address(periphery), 1e18);
            mockBridgedAmount(socketWethExecutionHelper, 1e18);
            vm.prank(socketWethExecutionHelper);
            s.userAccountId = IPeripheryProxy(periphery).depositNewMA(
                DepositNewMAInputs({ accountOwner: user, token: address(weth) })
            );

            deal(usdc, address(periphery), 100e6);
            mockBridgedAmount(socketUsdcExecutionHelper, 100e6);
            vm.prank(socketUsdcExecutionHelper);
            IPeripheryProxy(periphery).depositExistingMA(
                DepositExistingMAInputs({ accountId: s.userAccountId, token: address(usdc) })
            );
        }

        // deposit rUSD into liquidator's account
        {
            deal(usdc, address(periphery), 10_000e6);
            mockBridgedAmount(socketUsdcExecutionHelper, 10_000e6);
            vm.prank(socketUsdcExecutionHelper);
            s.liquidatorAccountId = IPeripheryProxy(periphery).depositNewMA(
                DepositNewMAInputs({ accountOwner: s.liquidator, token: address(usdc) })
            );
        }

        // user executes short trade on ETH
        (UD60x18 orderPrice,) = executeCoreMatchOrder({
            marketId: 1,
            sender: user,
            base: sd(-1e18),
            priceLimit: ud(0),
            accountId: s.userAccountId
        });

        // mark the liquidator account on the collateral pool 1
        vm.prank(s.liquidator);
        ICoreProxy(core).activateFirstMarketForAccount(s.liquidatorAccountId, 1);

        // attempt to auto-exchange but the tx reverts since account is not AE-able
        vm.prank(s.liquidator);
        vm.expectRevert(); // AccountNotEligibleForAutoExchange
        ICoreProxy(core).triggerAutoExchange(TriggerAutoExchangeInput({
            accountId: s.userAccountId,
            liquidatorAccountId: s.liquidatorAccountId,
            requestedQuoteAmount: 400e6,
            collateral: weth,
            inCollateral: rusd
        }));

        // price moves by 500 USD
        s.bumpedEthPrice = orderPrice.unwrap() + 500e18;
        vm.mockCall(
            oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (ethUsdcNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );

        // check that the account is AE-able but still healthy
        s.tbal0.userBalanceRusd = ICoreProxy(core).getTokenMarginInfo(s.userAccountId, rusd).marginBalance;
        s.tbal0.userBalanceWeth = ICoreProxy(core).getTokenMarginInfo(s.userAccountId, weth).marginBalance;
        s.tbal0.liquidatorBalanceRusd = ICoreProxy(core).getTokenMarginInfo(s.liquidatorAccountId, rusd).marginBalance;
        s.tbal0.liquidatorBalanceWeth = ICoreProxy(core).getTokenMarginInfo(s.liquidatorAccountId, weth).marginBalance;

        assertTrue(s.tbal0.userBalanceRusd < -400e6);

        assertTrue(
            ICoreProxy(core).getNodeMarginInfo(s.userAccountId, rusd).initialDelta > 0
        );

        // auto-exchange 400 rUSD
        vm.prank(s.liquidator);
        s.ae1 = ICoreProxy(core).triggerAutoExchange(TriggerAutoExchangeInput({
            accountId: s.userAccountId,
            liquidatorAccountId: s.liquidatorAccountId,
            requestedQuoteAmount: 400e6,
            collateral: weth,
            inCollateral: rusd
        }));

        assertEq(s.ae1.quoteAmountToIF, 4e6);
        assertEq(s.ae1.quoteAmountToAccount, 396e6);
        assertApproxEqAbsDecimal(s.ae1.collateralAmountToLiquidator, 400e18 * 1.01 * 1e18 / s.bumpedEthPrice, 0.0001e18, 18);

        s.tbal1.userBalanceRusd = ICoreProxy(core).getTokenMarginInfo(s.userAccountId, rusd).marginBalance;
        s.tbal1.userBalanceWeth = ICoreProxy(core).getTokenMarginInfo(s.userAccountId, weth).marginBalance;
        s.tbal1.liquidatorBalanceRusd = ICoreProxy(core).getTokenMarginInfo(s.liquidatorAccountId, rusd).marginBalance;
        s.tbal1.liquidatorBalanceWeth = ICoreProxy(core).getTokenMarginInfo(s.liquidatorAccountId, weth).marginBalance;

        assertEq(s.tbal1.userBalanceRusd, s.tbal0.userBalanceRusd + 396e6);
        assertEq(s.tbal1.liquidatorBalanceRusd, s.tbal0.liquidatorBalanceRusd - 400e6);
        assertEq(s.tbal1.userBalanceWeth, s.tbal0.userBalanceWeth - int256(s.ae1.collateralAmountToLiquidator));
        assertEq(s.tbal1.liquidatorBalanceWeth, s.tbal0.liquidatorBalanceWeth + int256(s.ae1.collateralAmountToLiquidator));

        // unwind the short trade (check that it's possible to perform trade even though rUSD balance is below 0 as long as ETH/other tokens support this)
        executeCoreMatchOrder({
            marketId: 1,
            sender: user,
            base: sd(1e18),
            priceLimit: ud(type(uint256).max),
            accountId: s.userAccountId
        });

        s.tbal1.userBalanceRusd = ICoreProxy(core).getTokenMarginInfo(s.userAccountId, rusd).marginBalance;
        s.tbal1.userBalanceWeth = ICoreProxy(core).getTokenMarginInfo(s.userAccountId, weth).marginBalance;
        s.tbal1.liquidatorBalanceRusd = ICoreProxy(core).getTokenMarginInfo(s.liquidatorAccountId, rusd).marginBalance;
        s.tbal1.liquidatorBalanceWeth = ICoreProxy(core).getTokenMarginInfo(s.liquidatorAccountId, weth).marginBalance;

        // auto-exchange the remaining amount (check that only the remaining part is AE)
        vm.prank(s.liquidator);
        s.ae2 = ICoreProxy(core).triggerAutoExchange(TriggerAutoExchangeInput({
            accountId: s.userAccountId,
            liquidatorAccountId: s.liquidatorAccountId,
            requestedQuoteAmount: 400e6,
            collateral: weth,
            inCollateral: rusd
        }));
        assertTrue(s.ae2.quoteAmountToAccount < 20e6);
        assertEq(int256(s.ae2.quoteAmountToAccount) + s.tbal1.userBalanceRusd, 0);
        assertApproxEqAbsDecimal(s.ae2.collateralAmountToLiquidator, s.ae2.quoteAmountToAccount * 1.01e12 * 1e18 / s.bumpedEthPrice, 0.0001e18, 18);

        s.tbal2.userBalanceRusd = ICoreProxy(core).getTokenMarginInfo(s.userAccountId, rusd).marginBalance;
        s.tbal2.userBalanceWeth = ICoreProxy(core).getTokenMarginInfo(s.userAccountId, weth).marginBalance;
        s.tbal2.liquidatorBalanceRusd = ICoreProxy(core).getTokenMarginInfo(s.liquidatorAccountId, rusd).marginBalance;
        s.tbal2.liquidatorBalanceWeth = ICoreProxy(core).getTokenMarginInfo(s.liquidatorAccountId, weth).marginBalance;

        assertEq(s.tbal2.userBalanceRusd, 0);
        assertEq(s.tbal2.liquidatorBalanceRusd, s.tbal1.liquidatorBalanceRusd - int256(s.ae2.quoteAmountToAccount + s.ae2.quoteAmountToIF));
        assertEq(s.tbal2.userBalanceWeth, s.tbal1.userBalanceWeth - int256(s.ae2.collateralAmountToLiquidator));
        assertEq(s.tbal2.liquidatorBalanceWeth, s.tbal1.liquidatorBalanceWeth + int256(s.ae2.collateralAmountToLiquidator));
    }
}
