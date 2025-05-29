pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";
import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import {
    ICoreProxy,
    TriggerAutoExchangeInput,
    AutoExchangeAmounts,
    CollateralConfig,
    ParentCollateralConfig
} from "../../../src/interfaces/ICoreProxy.sol";
import {
    IPeripheryProxy, DepositNewMAInputs, DepositExistingMAInputs
} from "../../../src/interfaces/IPeripheryProxy.sol";

import { IPassivePoolProxy } from "../../../src/interfaces/IPassivePoolProxy.sol";
import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

struct TokenBalances {
    int256 userBalanceWeth;
    int256 userBalanceRusd;
    int256 userBalanceUsde;
    int256 userBalanceSusde;
    int256 userBalanceDeusd;
    int256 userBalanceSdeusd;
    int256 userBalanceRselini;
    int256 userBalanceRamber;
    int256 userBalanceRhedge;
    int256 userBalanceSrusd;
    int256 liquidatorBalanceWeth;
    int256 liquidatorBalanceRusd;
    int256 liquidatorBalanceUsde;
    int256 liquidatorBalanceSusde;
    int256 liquidatorBalanceDeusd;
    int256 liquidatorBalanceSdeusd;
    int256 liquidatorBalanceRselini;
    int256 liquidatorBalanceRamber;
    int256 liquidatorBalanceRhedge;
    int256 liquidatorBalanceSrusd;
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
        mockFreshPrices();
        removeCollateralCap(sec.weth);

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
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkMarkNodeId)),
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
            s.ae1.collateralAmountToLiquidator, 400e18 * 1.02 * 1e18 / s.bumpedEthPrice, 0.0015e18, 18
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
            s.ae2.quoteAmountToAccount * 1.02e12 * 1e18 / s.bumpedEthPrice,
            0.0015e18,
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

    function check_AutoExchange_USDe(uint256 userInitialRusdBalance) private {
        mockFreshPrices();
        removeCollateralCap(sec.usde);

        (address user,) = makeAddrAndKey("user");
        s.userAccountId = 0;

        (s.liquidator,) = makeAddrAndKey("liquidator");
        s.liquidatorAccountId = 0;

        // deposit rUSD and USDe into user's account
        {
            deal(sec.usde, address(sec.periphery), 2200e18);
            mockBridgedAmount(dec.socketExecutionHelper[sec.usde], 2200e18);
            vm.prank(dec.socketExecutionHelper[sec.usde]);
            s.userAccountId = IPeripheryProxy(sec.periphery).depositNewMA(
                DepositNewMAInputs({ accountOwner: user, token: address(sec.usde) })
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
                    collateral: sec.usde,
                    inCollateral: sec.rusd
                })
            );
        }

        // price moves by 600 USD
        s.bumpedEthPrice = orderPrice.unwrap() + 600e18;
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkMarkNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );

        // check that the account is AE-able but still healthy
        s.tbal0.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal0.userBalanceUsde = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.usde).marginBalance;
        s.tbal0.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal0.liquidatorBalanceUsde =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.usde).marginBalance;

        assertLt(s.tbal0.userBalanceRusd, -400e6);

        assertGt(ICoreProxy(sec.core).getNodeMarginInfo(s.userAccountId, sec.rusd).initialDelta, 0);

        // auto-exchange 400 rUSD
        vm.prank(s.liquidator);
        s.ae1 = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: s.userAccountId,
                liquidatorAccountId: s.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: sec.usde,
                inCollateral: sec.rusd
            })
        );

        assertEq(s.ae1.quoteAmountToIF, 4e6);
        assertEq(s.ae1.quoteAmountToAccount, 396e6);
        NodeOutput.Data memory usdeUsdcNodeOutput =
            IOracleManagerProxy(sec.oracleManager).process(sec.usdeUsdcStorkNodeId);
        assertApproxEqAbsDecimal(
            s.ae1.collateralAmountToLiquidator,
            ud(400e18).div(ud(1e18 - 0.01e18)).div(ud(usdeUsdcNodeOutput.price)).unwrap(),
            0.0015e18,
            18
        );

        s.tbal1.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal1.userBalanceUsde = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.usde).marginBalance;
        s.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal1.liquidatorBalanceUsde =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.usde).marginBalance;

        assertEq(s.tbal1.userBalanceRusd, s.tbal0.userBalanceRusd + 396e6);
        assertEq(s.tbal1.liquidatorBalanceRusd, s.tbal0.liquidatorBalanceRusd - 400e6);
        assertEq(s.tbal1.userBalanceUsde, s.tbal0.userBalanceUsde - int256(s.ae1.collateralAmountToLiquidator));
        assertEq(
            s.tbal1.liquidatorBalanceUsde, s.tbal0.liquidatorBalanceUsde + int256(s.ae1.collateralAmountToLiquidator)
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
        s.tbal1.userBalanceUsde = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.usde).marginBalance;
        s.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal1.liquidatorBalanceUsde =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.usde).marginBalance;

        // auto-exchange the remaining amount (check that only the remaining part is AE)
        vm.prank(s.liquidator);
        s.ae2 = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: s.userAccountId,
                liquidatorAccountId: s.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: sec.usde,
                inCollateral: sec.rusd
            })
        );

        assertLt(s.ae2.quoteAmountToAccount, 220e6);

        assertEq(int256(s.ae2.quoteAmountToAccount) + s.tbal1.userBalanceRusd, 0);
        assertApproxEqAbsDecimal(
            s.ae2.collateralAmountToLiquidator,
            ud((s.ae2.quoteAmountToAccount + s.ae2.quoteAmountToIF) * 1e12).div(ud(1e18 - 0.01e18)).div(
                ud(usdeUsdcNodeOutput.price)
            ).unwrap(),
            0.0015e18,
            18
        );

        s.tbal2.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal2.userBalanceUsde = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.usde).marginBalance;
        s.tbal2.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal2.liquidatorBalanceUsde =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.usde).marginBalance;

        assertEq(s.tbal2.userBalanceRusd, 0);
        assertEq(
            s.tbal2.liquidatorBalanceRusd,
            s.tbal1.liquidatorBalanceRusd - int256(s.ae2.quoteAmountToAccount + s.ae2.quoteAmountToIF)
        );
        assertEq(s.tbal2.userBalanceUsde, s.tbal1.userBalanceUsde - int256(s.ae2.collateralAmountToLiquidator));
        assertEq(
            s.tbal2.liquidatorBalanceUsde, s.tbal1.liquidatorBalanceUsde + int256(s.ae2.collateralAmountToLiquidator)
        );
    }

    function check_AutoExchangeUSDe_WhenUserHasOnlyUsde() public {
        check_AutoExchange_USDe(0);
    }

    function check_AutoExchangeUSDe_WhenUserHasBothUsdeAndRusd() public {
        check_AutoExchange_USDe(100e6);
    }

    function check_AutoExchange_sUSDe(uint256 userInitialRusdBalance) private {
        mockFreshPrices();

        (address user,) = makeAddrAndKey("user");
        s.userAccountId = 0;

        (s.liquidator,) = makeAddrAndKey("liquidator");
        s.liquidatorAccountId = 0;

        // deposit rUSD and sUSDe into user's account
        {
            deal(sec.susde, address(sec.periphery), 2200e18);
            mockBridgedAmount(dec.socketExecutionHelper[sec.susde], 2200e18);
            vm.prank(dec.socketExecutionHelper[sec.susde]);
            s.userAccountId = IPeripheryProxy(sec.periphery).depositNewMA(
                DepositNewMAInputs({ accountOwner: user, token: address(sec.susde) })
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
                    collateral: sec.susde,
                    inCollateral: sec.rusd
                })
            );
        }

        // price moves by 600 USD
        s.bumpedEthPrice = orderPrice.unwrap() + 600e18;
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkMarkNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );

        // check that the account is AE-able but still healthy
        s.tbal0.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal0.userBalanceSusde = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.susde).marginBalance;
        s.tbal0.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal0.liquidatorBalanceSusde =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.susde).marginBalance;

        assertLt(s.tbal0.userBalanceRusd, -400e6);

        assertGt(ICoreProxy(sec.core).getNodeMarginInfo(s.userAccountId, sec.rusd).initialDelta, 0);

        // auto-exchange 400 rUSD
        vm.prank(s.liquidator);
        s.ae1 = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: s.userAccountId,
                liquidatorAccountId: s.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: sec.susde,
                inCollateral: sec.rusd
            })
        );

        assertEq(s.ae1.quoteAmountToIF, 4e6);
        assertEq(s.ae1.quoteAmountToAccount, 396e6);
        NodeOutput.Data memory susdeUsdcNodeOutput =
            IOracleManagerProxy(sec.oracleManager).process(sec.susdeUsdcStorkNodeId);
        assertApproxEqAbsDecimal(
            s.ae1.collateralAmountToLiquidator,
            ud(400e18).div(ud(1e18 - 0.005e18)).div(ud(susdeUsdcNodeOutput.price)).unwrap(),
            0.0015e18,
            18
        );

        s.tbal1.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal1.userBalanceSusde = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.susde).marginBalance;
        s.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal1.liquidatorBalanceSusde =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.susde).marginBalance;

        assertEq(s.tbal1.userBalanceRusd, s.tbal0.userBalanceRusd + 396e6);
        assertEq(s.tbal1.liquidatorBalanceRusd, s.tbal0.liquidatorBalanceRusd - 400e6);
        assertEq(s.tbal1.userBalanceSusde, s.tbal0.userBalanceSusde - int256(s.ae1.collateralAmountToLiquidator));
        assertEq(
            s.tbal1.liquidatorBalanceSusde, s.tbal0.liquidatorBalanceSusde + int256(s.ae1.collateralAmountToLiquidator)
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
        s.tbal1.userBalanceSusde = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.susde).marginBalance;
        s.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal1.liquidatorBalanceSusde =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.susde).marginBalance;

        // auto-exchange the remaining amount (check that only the remaining part is AE)
        vm.prank(s.liquidator);
        s.ae2 = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: s.userAccountId,
                liquidatorAccountId: s.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: sec.susde,
                inCollateral: sec.rusd
            })
        );

        assertLt(s.ae2.quoteAmountToAccount, 220e6);

        assertEq(int256(s.ae2.quoteAmountToAccount) + s.tbal1.userBalanceRusd, 0);
        assertApproxEqAbsDecimal(
            s.ae2.collateralAmountToLiquidator,
            ud((s.ae2.quoteAmountToAccount + s.ae2.quoteAmountToIF) * 1e12).div(ud(1e18 - 0.005e18)).div(
                ud(susdeUsdcNodeOutput.price)
            ).unwrap(),
            0.0015e18,
            18
        );

        s.tbal2.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal2.userBalanceSusde = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.susde).marginBalance;
        s.tbal2.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal2.liquidatorBalanceSusde =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.susde).marginBalance;

        assertEq(s.tbal2.userBalanceRusd, 0);
        assertEq(
            s.tbal2.liquidatorBalanceRusd,
            s.tbal1.liquidatorBalanceRusd - int256(s.ae2.quoteAmountToAccount + s.ae2.quoteAmountToIF)
        );
        assertEq(s.tbal2.userBalanceSusde, s.tbal1.userBalanceSusde - int256(s.ae2.collateralAmountToLiquidator));
        assertEq(
            s.tbal2.liquidatorBalanceSusde, s.tbal1.liquidatorBalanceSusde + int256(s.ae2.collateralAmountToLiquidator)
        );
    }

    function check_AutoExchangeSUSDe_WhenUserHasOnlySusde() public {
        check_AutoExchange_sUSDe(0);
    }

    function check_AutoExchangeSUSDe_WhenUserHasBothSusdeAndRusd() public {
        check_AutoExchange_sUSDe(100e6);
    }

    function check_AutoExchange_deUSD(uint256 userInitialRusdBalance) private {
        mockFreshPrices();

        (address user,) = makeAddrAndKey("user");
        s.userAccountId = 0;

        (s.liquidator,) = makeAddrAndKey("liquidator");
        s.liquidatorAccountId = 0;

        // deposit rUSD and deUSD into user's account
        {
            deal(sec.deusd, address(sec.periphery), 2200e18);
            mockBridgedAmount(dec.socketExecutionHelper[sec.deusd], 2200e18);
            vm.prank(dec.socketExecutionHelper[sec.deusd]);
            s.userAccountId = IPeripheryProxy(sec.periphery).depositNewMA(
                DepositNewMAInputs({ accountOwner: user, token: address(sec.deusd) })
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
                    collateral: sec.deusd,
                    inCollateral: sec.rusd
                })
            );
        }

        // price moves by 600 USD
        s.bumpedEthPrice = orderPrice.unwrap() + 600e18;
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkMarkNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );

        // check that the account is AE-able but still healthy
        s.tbal0.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal0.userBalanceDeusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.deusd).marginBalance;
        s.tbal0.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal0.liquidatorBalanceDeusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.deusd).marginBalance;

        assertLt(s.tbal0.userBalanceRusd, -400e6);

        assertGt(ICoreProxy(sec.core).getNodeMarginInfo(s.userAccountId, sec.rusd).initialDelta, 0);

        // auto-exchange 400 rUSD
        vm.prank(s.liquidator);
        s.ae1 = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: s.userAccountId,
                liquidatorAccountId: s.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: sec.deusd,
                inCollateral: sec.rusd
            })
        );

        assertEq(s.ae1.quoteAmountToIF, 4e6);
        assertEq(s.ae1.quoteAmountToAccount, 396e6);
        NodeOutput.Data memory deusdUsdcNodeOutput =
            IOracleManagerProxy(sec.oracleManager).process(sec.deusdUsdcStorkNodeId);
        assertApproxEqAbsDecimal(
            s.ae1.collateralAmountToLiquidator,
            ud(400e18).div(ud(1e18 - 0.005e18)).div(ud(deusdUsdcNodeOutput.price)).unwrap(),
            0.0015e18,
            18
        );

        s.tbal1.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal1.userBalanceDeusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.deusd).marginBalance;
        s.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal1.liquidatorBalanceDeusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.deusd).marginBalance;

        assertEq(s.tbal1.userBalanceRusd, s.tbal0.userBalanceRusd + 396e6);
        assertEq(s.tbal1.liquidatorBalanceRusd, s.tbal0.liquidatorBalanceRusd - 400e6);
        assertEq(s.tbal1.userBalanceDeusd, s.tbal0.userBalanceDeusd - int256(s.ae1.collateralAmountToLiquidator));
        assertEq(
            s.tbal1.liquidatorBalanceDeusd, s.tbal0.liquidatorBalanceDeusd + int256(s.ae1.collateralAmountToLiquidator)
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
        s.tbal1.userBalanceDeusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.deusd).marginBalance;
        s.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal1.liquidatorBalanceDeusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.deusd).marginBalance;

        // auto-exchange the remaining amount (check that only the remaining part is AE)
        vm.prank(s.liquidator);
        s.ae2 = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: s.userAccountId,
                liquidatorAccountId: s.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: sec.deusd,
                inCollateral: sec.rusd
            })
        );

        assertLt(s.ae2.quoteAmountToAccount, 220e6);

        assertEq(int256(s.ae2.quoteAmountToAccount) + s.tbal1.userBalanceRusd, 0);
        assertApproxEqAbsDecimal(
            s.ae2.collateralAmountToLiquidator,
            ud((s.ae2.quoteAmountToAccount + s.ae2.quoteAmountToIF) * 1e12).div(ud(1e18 - 0.005e18)).div(
                ud(deusdUsdcNodeOutput.price)
            ).unwrap(),
            0.0015e18,
            18
        );

        s.tbal2.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal2.userBalanceDeusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.deusd).marginBalance;
        s.tbal2.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal2.liquidatorBalanceDeusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.deusd).marginBalance;

        assertEq(s.tbal2.userBalanceRusd, 0);
        assertEq(
            s.tbal2.liquidatorBalanceRusd,
            s.tbal1.liquidatorBalanceRusd - int256(s.ae2.quoteAmountToAccount + s.ae2.quoteAmountToIF)
        );
        assertEq(s.tbal2.userBalanceDeusd, s.tbal1.userBalanceDeusd - int256(s.ae2.collateralAmountToLiquidator));
        assertEq(
            s.tbal2.liquidatorBalanceDeusd, s.tbal1.liquidatorBalanceDeusd + int256(s.ae2.collateralAmountToLiquidator)
        );
    }

    function check_AutoExchangeDeusd_WhenUserHasOnlyDeusd() public {
        check_AutoExchange_deUSD(0);
    }

    function check_AutoExchangeDeusd_WhenUserHasBothDeusdAndRusd() public {
        check_AutoExchange_deUSD(100e6);
    }

    function check_AutoExchange_sdeUSD(uint256 userInitialRusdBalance) private {
        mockFreshPrices();

        (address user,) = makeAddrAndKey("user");
        s.userAccountId = 0;

        (s.liquidator,) = makeAddrAndKey("liquidator");
        s.liquidatorAccountId = 0;

        // deposit rUSD and sdeUSD into user's account
        {
            deal(sec.sdeusd, address(sec.periphery), 2200e18);
            mockBridgedAmount(dec.socketExecutionHelper[sec.sdeusd], 2200e18);
            vm.prank(dec.socketExecutionHelper[sec.sdeusd]);
            s.userAccountId = IPeripheryProxy(sec.periphery).depositNewMA(
                DepositNewMAInputs({ accountOwner: user, token: address(sec.sdeusd) })
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
                    collateral: sec.sdeusd,
                    inCollateral: sec.rusd
                })
            );
        }

        // price moves by 600 USD
        s.bumpedEthPrice = orderPrice.unwrap() + 600e18;
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkMarkNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );

        // check that the account is AE-able but still healthy
        s.tbal0.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal0.userBalanceSdeusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.sdeusd).marginBalance;
        s.tbal0.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal0.liquidatorBalanceSdeusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.sdeusd).marginBalance;

        assertLt(s.tbal0.userBalanceRusd, -400e6);

        assertGt(ICoreProxy(sec.core).getNodeMarginInfo(s.userAccountId, sec.rusd).initialDelta, 0);

        // auto-exchange 400 rUSD
        vm.prank(s.liquidator);
        s.ae1 = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: s.userAccountId,
                liquidatorAccountId: s.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: sec.sdeusd,
                inCollateral: sec.rusd
            })
        );

        assertEq(s.ae1.quoteAmountToIF, 4e6);
        assertEq(s.ae1.quoteAmountToAccount, 396e6);
        NodeOutput.Data memory sdeusdUsdcNodeOutput =
            IOracleManagerProxy(sec.oracleManager).process(sec.sdeusdUsdcStorkNodeId);
        assertApproxEqAbsDecimal(
            s.ae1.collateralAmountToLiquidator,
            ud(400e18).div(ud(1e18 - 0.005e18)).div(ud(sdeusdUsdcNodeOutput.price)).unwrap(),
            0.0015e18,
            18
        );

        s.tbal1.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal1.userBalanceSdeusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.sdeusd).marginBalance;
        s.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal1.liquidatorBalanceSdeusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.sdeusd).marginBalance;

        assertEq(s.tbal1.userBalanceRusd, s.tbal0.userBalanceRusd + 396e6);
        assertEq(s.tbal1.liquidatorBalanceRusd, s.tbal0.liquidatorBalanceRusd - 400e6);
        assertEq(s.tbal1.userBalanceSdeusd, s.tbal0.userBalanceSdeusd - int256(s.ae1.collateralAmountToLiquidator));
        assertEq(
            s.tbal1.liquidatorBalanceSdeusd,
            s.tbal0.liquidatorBalanceSdeusd + int256(s.ae1.collateralAmountToLiquidator)
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
        s.tbal1.userBalanceSdeusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.sdeusd).marginBalance;
        s.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal1.liquidatorBalanceSdeusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.sdeusd).marginBalance;

        // auto-exchange the remaining amount (check that only the remaining part is AE)
        vm.prank(s.liquidator);
        s.ae2 = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: s.userAccountId,
                liquidatorAccountId: s.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: sec.sdeusd,
                inCollateral: sec.rusd
            })
        );

        assertLt(s.ae2.quoteAmountToAccount, 220e6);

        assertEq(int256(s.ae2.quoteAmountToAccount) + s.tbal1.userBalanceRusd, 0);
        assertApproxEqAbsDecimal(
            s.ae2.collateralAmountToLiquidator,
            ud((s.ae2.quoteAmountToAccount + s.ae2.quoteAmountToIF) * 1e12).div(ud(1e18 - 0.005e18)).div(
                ud(sdeusdUsdcNodeOutput.price)
            ).unwrap(),
            0.0015e18,
            18
        );

        s.tbal2.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal2.userBalanceSdeusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.sdeusd).marginBalance;
        s.tbal2.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal2.liquidatorBalanceSdeusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.sdeusd).marginBalance;

        assertEq(s.tbal2.userBalanceRusd, 0);
        assertEq(
            s.tbal2.liquidatorBalanceRusd,
            s.tbal1.liquidatorBalanceRusd - int256(s.ae2.quoteAmountToAccount + s.ae2.quoteAmountToIF)
        );
        assertEq(s.tbal2.userBalanceSdeusd, s.tbal1.userBalanceSdeusd - int256(s.ae2.collateralAmountToLiquidator));
        assertEq(
            s.tbal2.liquidatorBalanceSdeusd,
            s.tbal1.liquidatorBalanceSdeusd + int256(s.ae2.collateralAmountToLiquidator)
        );
    }

    function check_AutoExchangeSdeusd_WhenUserHasOnlySdeusd() public {
        check_AutoExchange_sdeUSD(0);
    }

    function check_AutoExchangeSdeusd_WhenUserHasBothSdeusdAndRusd() public {
        check_AutoExchange_sdeUSD(100e6);
    }

    function check_AutoExchange_rSelini(uint256 userInitialRusdBalance) private {
        mockFreshPrices();
        removeCollateralCap(sec.rselini);

        (address user,) = makeAddrAndKey("user");
        s.userAccountId = 0;

        (s.liquidator,) = makeAddrAndKey("liquidator");
        s.liquidatorAccountId = 0;

        // deposit rUSD and rSelini into user's account
        {
            s.userAccountId = depositNewMA(user, sec.rselini, 2200e18);

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
                    collateral: sec.rselini,
                    inCollateral: sec.rusd
                })
            );
        }

        // price moves by 600 USD
        s.bumpedEthPrice = orderPrice.unwrap() + 600e18;
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkMarkNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );

        // check that the account is AE-able but still healthy
        s.tbal0.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal0.userBalanceRselini = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rselini).marginBalance;
        s.tbal0.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal0.liquidatorBalanceRselini =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rselini).marginBalance;

        assertLt(s.tbal0.userBalanceRusd, -400e6);

        assertGt(ICoreProxy(sec.core).getNodeMarginInfo(s.userAccountId, sec.rusd).initialDelta, 0);

        // auto-exchange 400 rUSD
        vm.prank(s.liquidator);
        s.ae1 = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: s.userAccountId,
                liquidatorAccountId: s.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: sec.rselini,
                inCollateral: sec.rusd
            })
        );

        assertEq(s.ae1.quoteAmountToIF, 4e6);
        assertEq(s.ae1.quoteAmountToAccount, 396e6);
        NodeOutput.Data memory rseliniUsdcNodeOutput =
            IOracleManagerProxy(sec.oracleManager).process(sec.rseliniUsdcReyaLmNodeId);
        assertApproxEqAbsDecimal(
            s.ae1.collateralAmountToLiquidator,
            ud(400e18).div(ud(1e18 - 0.005e18)).div(ud(rseliniUsdcNodeOutput.price)).unwrap(),
            0.0015e18,
            18
        );

        s.tbal1.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal1.userBalanceRselini = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rselini).marginBalance;
        s.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal1.liquidatorBalanceRselini =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rselini).marginBalance;

        assertEq(s.tbal1.userBalanceRusd, s.tbal0.userBalanceRusd + 396e6);
        assertEq(s.tbal1.liquidatorBalanceRusd, s.tbal0.liquidatorBalanceRusd - 400e6);
        assertEq(s.tbal1.userBalanceRselini, s.tbal0.userBalanceRselini - int256(s.ae1.collateralAmountToLiquidator));
        assertEq(
            s.tbal1.liquidatorBalanceRselini,
            s.tbal0.liquidatorBalanceRselini + int256(s.ae1.collateralAmountToLiquidator)
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
        s.tbal1.userBalanceRselini = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rselini).marginBalance;
        s.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal1.liquidatorBalanceRselini =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rselini).marginBalance;

        // auto-exchange the remaining amount (check that only the remaining part is AE)
        vm.prank(s.liquidator);
        s.ae2 = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: s.userAccountId,
                liquidatorAccountId: s.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: sec.rselini,
                inCollateral: sec.rusd
            })
        );

        assertLt(s.ae2.quoteAmountToAccount, 220e6);

        assertEq(int256(s.ae2.quoteAmountToAccount) + s.tbal1.userBalanceRusd, 0);
        assertApproxEqAbsDecimal(
            s.ae2.collateralAmountToLiquidator,
            ud((s.ae2.quoteAmountToAccount + s.ae2.quoteAmountToIF) * 1e12).div(ud(1e18 - 0.005e18)).div(
                ud(rseliniUsdcNodeOutput.price)
            ).unwrap(),
            0.0015e18,
            18
        );

        s.tbal2.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal2.userBalanceRselini = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rselini).marginBalance;
        s.tbal2.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal2.liquidatorBalanceRselini =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rselini).marginBalance;

        assertEq(s.tbal2.userBalanceRusd, 0);
        assertEq(
            s.tbal2.liquidatorBalanceRusd,
            s.tbal1.liquidatorBalanceRusd - int256(s.ae2.quoteAmountToAccount + s.ae2.quoteAmountToIF)
        );
        assertEq(s.tbal2.userBalanceRselini, s.tbal1.userBalanceRselini - int256(s.ae2.collateralAmountToLiquidator));
        assertEq(
            s.tbal2.liquidatorBalanceRselini,
            s.tbal1.liquidatorBalanceRselini + int256(s.ae2.collateralAmountToLiquidator)
        );
    }

    function check_AutoExchangeRselini_WhenUserHasOnlyRselini() public {
        check_AutoExchange_rSelini(0);
    }

    function check_AutoExchangeRselini_WhenUserHasBothRseliniAndRusd() public {
        check_AutoExchange_rSelini(100e6);
    }

    function check_AutoExchange_rAmber(uint256 userInitialRusdBalance) private {
        mockFreshPrices();
        removeCollateralCap(sec.ramber);

        (address user,) = makeAddrAndKey("user");
        s.userAccountId = 0;

        (s.liquidator,) = makeAddrAndKey("liquidator");
        s.liquidatorAccountId = 0;

        // deposit rUSD and rAmber into user's account
        {
            s.userAccountId = depositNewMA(user, sec.ramber, 2200e18);

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
                    collateral: sec.ramber,
                    inCollateral: sec.rusd
                })
            );
        }

        // price moves by 600 USD
        s.bumpedEthPrice = orderPrice.unwrap() + 600e18;
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkMarkNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );

        // check that the account is AE-able but still healthy
        s.tbal0.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal0.userBalanceRamber = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.ramber).marginBalance;
        s.tbal0.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal0.liquidatorBalanceRamber =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.ramber).marginBalance;

        assertLt(s.tbal0.userBalanceRusd, -400e6);

        assertGt(ICoreProxy(sec.core).getNodeMarginInfo(s.userAccountId, sec.rusd).initialDelta, 0);

        // auto-exchange 400 rUSD
        vm.prank(s.liquidator);
        s.ae1 = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: s.userAccountId,
                liquidatorAccountId: s.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: sec.ramber,
                inCollateral: sec.rusd
            })
        );

        assertEq(s.ae1.quoteAmountToIF, 4e6);
        assertEq(s.ae1.quoteAmountToAccount, 396e6);
        NodeOutput.Data memory ramberUsdcNodeOutput =
            IOracleManagerProxy(sec.oracleManager).process(sec.ramberUsdcReyaLmNodeId);
        assertApproxEqAbsDecimal(
            s.ae1.collateralAmountToLiquidator,
            ud(400e18).div(ud(1e18 - 0.005e18)).div(ud(ramberUsdcNodeOutput.price)).unwrap(),
            0.0015e18,
            18
        );

        s.tbal1.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal1.userBalanceRamber = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.ramber).marginBalance;
        s.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal1.liquidatorBalanceRamber =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.ramber).marginBalance;

        assertEq(s.tbal1.userBalanceRusd, s.tbal0.userBalanceRusd + 396e6);
        assertEq(s.tbal1.liquidatorBalanceRusd, s.tbal0.liquidatorBalanceRusd - 400e6);
        assertEq(s.tbal1.userBalanceRamber, s.tbal0.userBalanceRamber - int256(s.ae1.collateralAmountToLiquidator));
        assertEq(
            s.tbal1.liquidatorBalanceRamber,
            s.tbal0.liquidatorBalanceRamber + int256(s.ae1.collateralAmountToLiquidator)
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
        s.tbal1.userBalanceRamber = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.ramber).marginBalance;
        s.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal1.liquidatorBalanceRamber =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.ramber).marginBalance;

        // auto-exchange the remaining amount (check that only the remaining part is AE)
        vm.prank(s.liquidator);
        s.ae2 = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: s.userAccountId,
                liquidatorAccountId: s.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: sec.ramber,
                inCollateral: sec.rusd
            })
        );

        assertLt(s.ae2.quoteAmountToAccount, 220e6);

        assertEq(int256(s.ae2.quoteAmountToAccount) + s.tbal1.userBalanceRusd, 0);
        assertApproxEqAbsDecimal(
            s.ae2.collateralAmountToLiquidator,
            ud((s.ae2.quoteAmountToAccount + s.ae2.quoteAmountToIF) * 1e12).div(ud(1e18 - 0.005e18)).div(
                ud(ramberUsdcNodeOutput.price)
            ).unwrap(),
            0.0015e18,
            18
        );

        s.tbal2.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal2.userBalanceRamber = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.ramber).marginBalance;
        s.tbal2.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal2.liquidatorBalanceRamber =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.ramber).marginBalance;

        assertEq(s.tbal2.userBalanceRusd, 0);
        assertEq(
            s.tbal2.liquidatorBalanceRusd,
            s.tbal1.liquidatorBalanceRusd - int256(s.ae2.quoteAmountToAccount + s.ae2.quoteAmountToIF)
        );
        assertEq(s.tbal2.userBalanceRamber, s.tbal1.userBalanceRamber - int256(s.ae2.collateralAmountToLiquidator));
        assertEq(
            s.tbal2.liquidatorBalanceRamber,
            s.tbal1.liquidatorBalanceRamber + int256(s.ae2.collateralAmountToLiquidator)
        );
    }

    function check_AutoExchangeRamber_WhenUserHasOnlyRamber() public {
        check_AutoExchange_rAmber(0);
    }

    function check_AutoExchangeRamber_WhenUserHasBothRamberAndRusd() public {
        check_AutoExchange_rAmber(100e6);
    }

    function check_AutoExchange_srUSD(uint256 userInitialRusdBalance) private {
        mockFreshPrices();
        removeCollateralCap(sec.srusd);
        removeCollateralWithdrawalLimit(sec.srusd);

        (address user,) = makeAddrAndKey("user");
        s.userAccountId = 0;

        s.liquidator = sec.aeLiquidator1;

        // deposit rUSD and srUSD into user's account
        {
            s.userAccountId = depositNewMA(user, sec.srusd, 2200e30);

            if (userInitialRusdBalance > 0) {
                deal(sec.usdc, address(sec.periphery), userInitialRusdBalance);
                mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], userInitialRusdBalance);
                vm.prank(dec.socketExecutionHelper[sec.usdc]);
                IPeripheryProxy(sec.periphery).depositExistingMA(
                    DepositExistingMAInputs({ accountId: s.userAccountId, token: address(sec.usdc) })
                );
            }
        }

        // user executes short trade on ETH
        (UD60x18 orderPrice,) = executeCoreMatchOrder({
            marketId: 1,
            sender: user,
            base: sd(-1e18),
            priceLimit: ud(0),
            accountId: s.userAccountId
        });

        // if initial rUSD balance is 0 (or small), the trading fees will make the rUSD balance
        // drop directly below 0 and making the account auto-exchangeable for that small gap

        if (userInitialRusdBalance > 0) {
            // attempt to auto-exchange but the tx reverts since account is not AE-able
            vm.prank(s.liquidator);
            vm.expectRevert(abi.encodeWithSelector(IPassivePoolProxy.ZeroAutoExchangeAmount.selector));
            IPassivePoolProxy(sec.pool).triggerStakedAssetAutoExchange(1, s.userAccountId);
        }

        // price moves by 600 USD
        s.bumpedEthPrice = orderPrice.unwrap() + 600e18;
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkMarkNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );

        // check that the account is AE-able but still healthy
        s.tbal0.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal0.userBalanceSrusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.srusd).marginBalance;
        s.tbal0.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(sec.passivePoolAccountId, sec.rusd).marginBalance;
        s.tbal0.liquidatorBalanceSrusd =
            ICoreProxy(sec.core).getTokenMarginInfo(sec.passivePoolAccountId, sec.srusd).marginBalance;

        assertLt(s.tbal0.userBalanceRusd, -400e6);

        assertGt(ICoreProxy(sec.core).getNodeMarginInfo(s.userAccountId, sec.rusd).initialDelta, 0);

        uint256 maxQuoteToCover = ICoreProxy(sec.core).calculateMaxQuoteToCoverInAutoExchange(s.userAccountId, sec.rusd);
        assertGt(maxQuoteToCover, 400e6);
        assertLt(maxQuoteToCover, 700e6);

        vm.mockCall(
            sec.core,
            abi.encodeWithSelector(
                ICoreProxy.calculateMaxQuoteToCoverInAutoExchange.selector, s.userAccountId, sec.rusd
            ),
            abi.encode(400e6)
        );

        uint256 srUsdSupplyBefore = ITokenProxy(sec.srusd).totalSupply();

        uint256 sharePriceBefore = IPassivePoolProxy(sec.pool).getSharePrice(1);

        // auto-exchange 400 rUSD
        vm.prank(s.liquidator);
        s.ae1 = IPassivePoolProxy(sec.pool).triggerStakedAssetAutoExchange(1, s.userAccountId);

        assertEq(s.ae1.quoteAmountToIF, 4e6);
        assertEq(s.ae1.quoteAmountToAccount, 396e6);
        NodeOutput.Data memory srusdUsdcNodeOutput =
            IOracleManagerProxy(sec.oracleManager).process(sec.srusdUsdcPoolNodeId);
        assertApproxEqAbsDecimal(
            s.ae1.collateralAmountToLiquidator, ud(400e30).div(ud(srusdUsdcNodeOutput.price)).unwrap(), 0.001e30, 30
        );
        assertLe(sharePriceBefore, IPassivePoolProxy(sec.pool).getSharePrice(1));

        s.tbal1.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal1.userBalanceSrusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.srusd).marginBalance;
        s.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(sec.passivePoolAccountId, sec.rusd).marginBalance;
        s.tbal1.liquidatorBalanceSrusd =
            ICoreProxy(sec.core).getTokenMarginInfo(sec.passivePoolAccountId, sec.srusd).marginBalance;

        assertEq(s.tbal1.userBalanceRusd, s.tbal0.userBalanceRusd + 396e6);
        assertEq(s.tbal1.liquidatorBalanceRusd, s.tbal0.liquidatorBalanceRusd - 400e6);
        assertEq(s.tbal1.userBalanceSrusd, s.tbal0.userBalanceSrusd - int256(s.ae1.collateralAmountToLiquidator));
        assertEq(ITokenProxy(sec.srusd).totalSupply(), srUsdSupplyBefore - s.ae1.collateralAmountToLiquidator);
        assertEq(s.tbal1.liquidatorBalanceSrusd, 0);

        // unwind the short trade (check that it's possible to perform trade even though rUSD balance is below 0 as long
        // as ETH/other tokens support this)
        executeCoreMatchOrder({
            marketId: 1,
            sender: user,
            base: sd(1e18),
            priceLimit: ud(type(uint256).max),
            accountId: s.userAccountId
        });

        vm.clearMockedCalls();
        mockFreshPrices();
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkMarkNodeId)),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );

        s.tbal1.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal1.userBalanceSrusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.srusd).marginBalance;
        s.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(sec.passivePoolAccountId, sec.rusd).marginBalance;
        s.tbal1.liquidatorBalanceSrusd =
            ICoreProxy(sec.core).getTokenMarginInfo(sec.passivePoolAccountId, sec.srusd).marginBalance;

        srUsdSupplyBefore = ITokenProxy(sec.srusd).totalSupply();
        sharePriceBefore = IPassivePoolProxy(sec.pool).getSharePrice(1);

        // auto-exchange the remaining amount (check that only the remaining part is AE)
        vm.prank(s.liquidator);
        s.ae2 = IPassivePoolProxy(sec.pool).triggerStakedAssetAutoExchange(1, s.userAccountId);

        assertLt(s.ae2.quoteAmountToAccount, 220e6);

        assertEq(int256(s.ae2.quoteAmountToAccount) + s.tbal1.userBalanceRusd, 0);
        assertApproxEqAbsDecimal(
            s.ae2.collateralAmountToLiquidator,
            ud((s.ae2.quoteAmountToAccount + s.ae2.quoteAmountToIF) * 1e24).div(ud(srusdUsdcNodeOutput.price)).unwrap(),
            0.001e30,
            30
        );

        assertLe(sharePriceBefore, IPassivePoolProxy(sec.pool).getSharePrice(1));

        s.tbal2.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal2.userBalanceSrusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.srusd).marginBalance;
        s.tbal2.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(sec.passivePoolAccountId, sec.rusd).marginBalance;
        s.tbal2.liquidatorBalanceSrusd =
            ICoreProxy(sec.core).getTokenMarginInfo(sec.passivePoolAccountId, sec.srusd).marginBalance;

        assertEq(s.tbal2.userBalanceRusd, 0);
        assertEq(
            s.tbal2.liquidatorBalanceRusd,
            s.tbal1.liquidatorBalanceRusd - int256(s.ae2.quoteAmountToAccount + s.ae2.quoteAmountToIF)
        );
        assertEq(s.tbal2.userBalanceSrusd, s.tbal1.userBalanceSrusd - int256(s.ae2.collateralAmountToLiquidator));
        assertEq(ITokenProxy(sec.srusd).totalSupply(), srUsdSupplyBefore - s.ae2.collateralAmountToLiquidator);
        assertEq(s.tbal2.liquidatorBalanceSrusd, 0);

        assertEq(IPassivePoolProxy(sec.pool).getShareSupply(1), ITokenProxy(sec.srusd).balanceOf(sec.pool));
    }

    function check_AutoExchangeSrusd_WhenUserHasOnlySrusd() public {
        check_AutoExchange_srUSD(0);
    }

    function check_AutoExchangeSrusd_WhenUserHasBothSrusdAndRusd() public {
        check_AutoExchange_srUSD(100e6);
    }
}
