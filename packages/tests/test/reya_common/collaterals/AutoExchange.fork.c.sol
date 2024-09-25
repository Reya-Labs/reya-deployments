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
import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

struct TokenBalances {
    int256 userBalanceWeth;
    int256 userBalanceRusd;
    int256 userBalanceUsde;
    int256 userBalanceSusde;
    int256 liquidatorBalanceWeth;
    int256 liquidatorBalanceRusd;
    int256 liquidatorBalanceUsde;
    int256 liquidatorBalanceSusde;
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
            s.ae1.collateralAmountToLiquidator, 400e18 * 1.02 * 1e18 / s.bumpedEthPrice, 0.001e18, 18
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
            0.001e18,
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
            0.001e18,
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
            0.001e18,
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
            0.001e18,
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
}
