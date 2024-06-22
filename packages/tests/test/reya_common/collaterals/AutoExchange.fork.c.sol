pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
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

struct LocalState {
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

contract AutoExchangeForkCheck is BaseReyaForkTest {
    LocalState private s;

    function check_AutoExchange_wEth(uint256 userInitialRusdBalance) private {
        (address user,) = makeAddrAndKey("user");
        s.userAccountId = 0;

        (s.liquidator,) = makeAddrAndKey("liquidator");
        s.liquidatorAccountId = 0;

        // deposit rUSD and ETH into user's account
        {
            deal(sec.weth, address(sec.periphery), 1e18);
            mockBridgedAmount(dec.socketExecutionHelper[sec.weth], 1e18);
            vm.prank(dec.socketExecutionHelper[sec.weth]);
            s.userAccountId = IPeripheryProxy(sec.periphery).depositNewMA(
                DepositNewMAInputs({ accountOwner: user, token: address(sec.weth) })
            );

            if (userInitialRusdBalance > 0) {
                deal(sec.usdc, address(sec.periphery), userInitialRusdBalance);
                mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], userInitialRusdBalance);
                vm.prank(dec.socketExecutionHelper[sec.usdc]);
                IPeripheryProxy(sec.periphery).depositExistingMA(
                    DepositExistingMAInputs({ accountId: s.userAccountId, token: address(sec.usdc) })
                );
            }
        }

        // deposit rUSD into liquidator's account
        {
            deal(sec.usdc, address(sec.periphery), 10_000e6);
            mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], 10_000e6);
            vm.prank(dec.socketExecutionHelper[sec.usdc]);
            s.liquidatorAccountId = IPeripheryProxy(sec.periphery).depositNewMA(
                DepositNewMAInputs({ accountOwner: s.liquidator, token: address(sec.usdc) })
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
        ICoreProxy(sec.core).activateFirstMarketForAccount(s.liquidatorAccountId, 1);

        // if initial rUSD balance is 0 (or small), the trading fees will make the rUSD balance
        // drop directly below 0 and making the account auto-exchangeable for that small gap

        if (userInitialRusdBalance > 0) {
            // attempt to auto-exchange but the tx reverts since account is not AE-able
            vm.prank(s.liquidator);
            vm.expectRevert(
                abi.encodeWithSelector(ICoreProxy.AccountNotEligibleForAutoExchange.selector, s.userAccountId, sec.rusd)
            );
            ICoreProxy(sec.core).triggerAutoExchange(
                TriggerAutoExchangeInput({
                    accountId: s.userAccountId,
                    liquidatorAccountId: s.liquidatorAccountId,
                    requestedQuoteAmount: 400e6,
                    collateral: sec.weth,
                    inCollateral: sec.rusd
                })
            );
        }

        // price moves by 600 USD
        s.bumpedEthPrice = orderPrice.unwrap() + 600e18;
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );

        // check that the account is AE-able but still healthy
        s.tbal0.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal0.userBalanceWeth = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.weth).marginBalance;
        s.tbal0.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal0.liquidatorBalanceWeth =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.weth).marginBalance;

        assertLt(s.tbal0.userBalanceRusd, -400e6);

        assertGt(ICoreProxy(sec.core).getNodeMarginInfo(s.userAccountId, sec.rusd).initialDelta, 0);

        // auto-exchange 400 rUSD
        vm.prank(s.liquidator);
        s.ae1 = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: s.userAccountId,
                liquidatorAccountId: s.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: sec.weth,
                inCollateral: sec.rusd
            })
        );

        assertEq(s.ae1.quoteAmountToIF, 4e6);
        assertEq(s.ae1.quoteAmountToAccount, 396e6);
        assertApproxEqAbsDecimal(
            s.ae1.collateralAmountToLiquidator, 400e18 * 1.01 * 1e18 / s.bumpedEthPrice, 0.001e18, 18
        );

        s.tbal1.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal1.userBalanceWeth = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.weth).marginBalance;
        s.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal1.liquidatorBalanceWeth =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.weth).marginBalance;

        assertEq(s.tbal1.userBalanceRusd, s.tbal0.userBalanceRusd + 396e6);
        assertEq(s.tbal1.liquidatorBalanceRusd, s.tbal0.liquidatorBalanceRusd - 400e6);
        assertEq(s.tbal1.userBalanceWeth, s.tbal0.userBalanceWeth - int256(s.ae1.collateralAmountToLiquidator));
        assertEq(
            s.tbal1.liquidatorBalanceWeth, s.tbal0.liquidatorBalanceWeth + int256(s.ae1.collateralAmountToLiquidator)
        );

        // unwind the short trade (check that it's possible to perform trade even though rUSD balance is below 0 as long
        // as ETH/other tokens support this)
        executeCoreMatchOrder({
            marketId: 1,
            sender: user,
            base: sd(1e18),
            priceLimit: ud(type(uint256).max),
            accountId: s.userAccountId
        });

        s.tbal1.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal1.userBalanceWeth = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.weth).marginBalance;
        s.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal1.liquidatorBalanceWeth =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.weth).marginBalance;

        // auto-exchange the remaining amount (check that only the remaining part is AE)
        vm.prank(s.liquidator);
        s.ae2 = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: s.userAccountId,
                liquidatorAccountId: s.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: sec.weth,
                inCollateral: sec.rusd
            })
        );

        assertLt(s.ae2.quoteAmountToAccount, 220e6);

        assertEq(int256(s.ae2.quoteAmountToAccount) + s.tbal1.userBalanceRusd, 0);
        assertApproxEqAbsDecimal(
            s.ae2.collateralAmountToLiquidator,
            s.ae2.quoteAmountToAccount * 1.01e12 * 1e18 / s.bumpedEthPrice,
            0.001e18,
            18
        );

        s.tbal2.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal2.userBalanceWeth = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.weth).marginBalance;
        s.tbal2.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal2.liquidatorBalanceWeth =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.weth).marginBalance;

        assertEq(s.tbal2.userBalanceRusd, 0);
        assertEq(
            s.tbal2.liquidatorBalanceRusd,
            s.tbal1.liquidatorBalanceRusd - int256(s.ae2.quoteAmountToAccount + s.ae2.quoteAmountToIF)
        );
        assertEq(s.tbal2.userBalanceWeth, s.tbal1.userBalanceWeth - int256(s.ae2.collateralAmountToLiquidator));
        assertEq(
            s.tbal2.liquidatorBalanceWeth, s.tbal1.liquidatorBalanceWeth + int256(s.ae2.collateralAmountToLiquidator)
        );
    }

    function check_AutoExchangeWeth_WhenUserHasOnlyWeth() public {
        check_AutoExchange_wEth(0);
    }

    function check_AutoExchangeWeth_WhenUserHasBothWethAndRusd() public {
        check_AutoExchange_wEth(100e6);
    }
}
