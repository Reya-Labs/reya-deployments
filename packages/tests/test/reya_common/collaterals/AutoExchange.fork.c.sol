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
    int256 userBalanceRusd;
    int256 userBalanceToken;
    int256 userBalanceSrusd;
    int256 liquidatorBalanceRusd;
    int256 liquidatorBalanceToken;
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

    function check_AutoExchange(
        address token,
        bytes32 tokenUsdcNodeId,
        uint256 tokenAeDiscount,
        uint256 userInitialRusdBalance
    )
        private
    {
        mockFreshPrices();
        removeCollateralCap(token);

        (address user,) = makeAddrAndKey("user");
        s.userAccountId = 0;

        (s.liquidator,) = makeAddrAndKey("liquidator");
        s.liquidatorAccountId = 0;

        // deposit rUSD and token into user's account
        {
            s.userAccountId = depositNewMA(user, token, 2200e18);

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
        deal(sec.usdc, address(sec.periphery), 10_000e6);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], 10_000e6);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        s.liquidatorAccountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: s.liquidator, token: address(sec.usdc) })
        );

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
                    collateral: token,
                    inCollateral: sec.rusd
                })
            );
        }

        // price moves by 600 USD
        s.bumpedEthPrice = orderPrice.unwrap() + 600e18;
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (dec.oracleNodes["ethUsdcStork"])),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (dec.oracleNodes["ethUsdcStorkMark"])),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );

        // check that the account is AE-able but still healthy
        s.tbal0.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal0.userBalanceToken = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, token).marginBalance;
        s.tbal0.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal0.liquidatorBalanceToken =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, token).marginBalance;

        assertLt(s.tbal0.userBalanceRusd, -400e6);
        assertGt(ICoreProxy(sec.core).getNodeMarginInfo(s.userAccountId, sec.rusd).initialDelta, 0);

        // auto-exchange 400 rUSD
        vm.prank(s.liquidator);

        s.ae1 = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: s.userAccountId,
                liquidatorAccountId: s.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: token,
                inCollateral: sec.rusd
            })
        );

        assertEq(s.ae1.quoteAmountToIF, 4e6);
        assertEq(s.ae1.quoteAmountToAccount, 396e6);
        NodeOutput.Data memory tokenUsdcNodeOutput = IOracleManagerProxy(sec.oracleManager).process(tokenUsdcNodeId);
        assertApproxEqAbsDecimal(
            s.ae1.collateralAmountToLiquidator,
            ud(400e18).div(ud(1e18 - tokenAeDiscount)).div(ud(tokenUsdcNodeOutput.price)).unwrap(),
            0.0015e18,
            18
        );

        s.tbal1.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal1.userBalanceToken = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, token).marginBalance;
        s.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal1.liquidatorBalanceToken =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, token).marginBalance;

        assertEq(s.tbal1.userBalanceRusd, s.tbal0.userBalanceRusd + 396e6);
        assertEq(s.tbal1.liquidatorBalanceRusd, s.tbal0.liquidatorBalanceRusd - 400e6);
        assertEq(s.tbal1.userBalanceToken, s.tbal0.userBalanceToken - int256(s.ae1.collateralAmountToLiquidator));
        assertEq(
            s.tbal1.liquidatorBalanceToken, s.tbal0.liquidatorBalanceToken + int256(s.ae1.collateralAmountToLiquidator)
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
        s.tbal1.userBalanceToken = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, token).marginBalance;
        s.tbal1.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal1.liquidatorBalanceToken =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, token).marginBalance;

        // auto-exchange the remaining amount (check that only the remaining part is AE)
        vm.prank(s.liquidator);
        s.ae2 = ICoreProxy(sec.core).triggerAutoExchange(
            TriggerAutoExchangeInput({
                accountId: s.userAccountId,
                liquidatorAccountId: s.liquidatorAccountId,
                requestedQuoteAmount: 400e6,
                collateral: token,
                inCollateral: sec.rusd
            })
        );

        assertLt(s.ae2.quoteAmountToAccount, 220e6);

        assertEq(int256(s.ae2.quoteAmountToAccount) + s.tbal1.userBalanceRusd, 0);
        assertApproxEqAbsDecimal(
            s.ae2.collateralAmountToLiquidator,
            ud((s.ae2.quoteAmountToAccount + s.ae2.quoteAmountToIF) * 1e12).div(ud(1e18 - tokenAeDiscount)).div(
                ud(tokenUsdcNodeOutput.price)
            ).unwrap(),
            0.0015e18,
            18
        );

        s.tbal2.userBalanceRusd = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, sec.rusd).marginBalance;
        s.tbal2.userBalanceToken = ICoreProxy(sec.core).getTokenMarginInfo(s.userAccountId, token).marginBalance;
        s.tbal2.liquidatorBalanceRusd =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, sec.rusd).marginBalance;
        s.tbal2.liquidatorBalanceToken =
            ICoreProxy(sec.core).getTokenMarginInfo(s.liquidatorAccountId, token).marginBalance;

        assertEq(s.tbal2.userBalanceRusd, 0);
        assertEq(
            s.tbal2.liquidatorBalanceRusd,
            s.tbal1.liquidatorBalanceRusd - int256(s.ae2.quoteAmountToAccount + s.ae2.quoteAmountToIF)
        );
        assertEq(s.tbal2.userBalanceToken, s.tbal1.userBalanceToken - int256(s.ae2.collateralAmountToLiquidator));
        assertEq(
            s.tbal2.liquidatorBalanceToken, s.tbal1.liquidatorBalanceToken + int256(s.ae2.collateralAmountToLiquidator)
        );
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
            abi.encodeCall(IOracleManagerProxy.process, (dec.oracleNodes["ethUsdcStork"])),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (dec.oracleNodes["ethUsdcStorkMark"])),
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
            IOracleManagerProxy(sec.oracleManager).process(dec.oracleNodes["srusdUsdcPool"]);
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
            abi.encodeCall(IOracleManagerProxy.process, (dec.oracleNodes["ethUsdcStork"])),
            abi.encode(NodeOutput.Data({ price: s.bumpedEthPrice, timestamp: block.timestamp }))
        );
        vm.mockCall(
            sec.oracleManager,
            abi.encodeCall(IOracleManagerProxy.process, (dec.oracleNodes["ethUsdcStorkMark"])),
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

    function check_AutoExchangeWeth_WhenUserHasOnlyWeth() public {
        check_AutoExchange({
            token: sec.weth,
            tokenUsdcNodeId: dec.oracleNodes["ethUsdcStork"],
            tokenAeDiscount: 0.02e18,
            userInitialRusdBalance: 0
        });
    }

    function check_AutoExchangeWeth_WhenUserHasBothWethAndRusd() public {
        check_AutoExchange({
            token: sec.weth,
            tokenUsdcNodeId: dec.oracleNodes["ethUsdcStork"],
            tokenAeDiscount: 0.02e18,
            userInitialRusdBalance: 100e6
        });
    }

    function check_AutoExchangeUSDe_WhenUserHasOnlyUsde() public {
        check_AutoExchange({
            token: sec.usde,
            tokenUsdcNodeId: dec.oracleNodes["usdeUsdcStork"],
            tokenAeDiscount: 0.01e18,
            userInitialRusdBalance: 0
        });
    }

    function check_AutoExchangeUSDe_WhenUserHasBothUsdeAndRusd() public {
        check_AutoExchange({
            token: sec.usde,
            tokenUsdcNodeId: dec.oracleNodes["usdeUsdcStork"],
            tokenAeDiscount: 0.01e18,
            userInitialRusdBalance: 100e6
        });
    }

    function check_AutoExchangeSUSDe_WhenUserHasOnlySusde() public {
        check_AutoExchange({
            token: sec.susde,
            tokenUsdcNodeId: dec.oracleNodes["susdeUsdcStork"],
            tokenAeDiscount: 0.005e18,
            userInitialRusdBalance: 0
        });
    }

    function check_AutoExchangeSUSDe_WhenUserHasBothSusdeAndRusd() public {
        check_AutoExchange({
            token: sec.susde,
            tokenUsdcNodeId: dec.oracleNodes["susdeUsdcStork"],
            tokenAeDiscount: 0.005e18,
            userInitialRusdBalance: 100e6
        });
    }

    function check_AutoExchangeDeusd_WhenUserHasOnlyDeusd() public {
        check_AutoExchange({
            token: sec.deusd,
            tokenUsdcNodeId: dec.oracleNodes["deusdUsdcStork"],
            tokenAeDiscount: 0.005e18,
            userInitialRusdBalance: 0
        });
    }

    function check_AutoExchangeDeusd_WhenUserHasBothDeusdAndRusd() public {
        check_AutoExchange({
            token: sec.deusd,
            tokenUsdcNodeId: dec.oracleNodes["deusdUsdcStork"],
            tokenAeDiscount: 0.005e18,
            userInitialRusdBalance: 100e6
        });
    }

    function check_AutoExchangeSdeusd_WhenUserHasOnlySdeusd() public {
        check_AutoExchange({
            token: sec.sdeusd,
            tokenUsdcNodeId: dec.oracleNodes["sdeusdUsdcStork"],
            tokenAeDiscount: 0.005e18,
            userInitialRusdBalance: 0
        });
    }

    function check_AutoExchangeSdeusd_WhenUserHasBothSdeusdAndRusd() public {
        check_AutoExchange({
            token: sec.sdeusd,
            tokenUsdcNodeId: dec.oracleNodes["sdeusdUsdcStork"],
            tokenAeDiscount: 0.005e18,
            userInitialRusdBalance: 100e6
        });
    }

    function check_AutoExchangeRselini_WhenUserHasOnlyRselini() public {
        check_AutoExchange({
            token: sec.rselini,
            tokenUsdcNodeId: dec.oracleNodes["rseliniUsdcReyaLm"],
            tokenAeDiscount: 0.005e18,
            userInitialRusdBalance: 0
        });
    }

    function check_AutoExchangeRselini_WhenUserHasBothRseliniAndRusd() public {
        check_AutoExchange({
            token: sec.rselini,
            tokenUsdcNodeId: dec.oracleNodes["rseliniUsdcReyaLm"],
            tokenAeDiscount: 0.005e18,
            userInitialRusdBalance: 100e6
        });
    }

    function check_AutoExchangeRamber_WhenUserHasOnlyRamber() public {
        check_AutoExchange({
            token: sec.ramber,
            tokenUsdcNodeId: dec.oracleNodes["ramberUsdcReyaLm"],
            tokenAeDiscount: 0.005e18,
            userInitialRusdBalance: 0
        });
    }

    function check_AutoExchangeRamber_WhenUserHasBothRamberAndRusd() public {
        check_AutoExchange({
            token: sec.ramber,
            tokenUsdcNodeId: dec.oracleNodes["ramberUsdcReyaLm"],
            tokenAeDiscount: 0.005e18,
            userInitialRusdBalance: 100e6
        });
    }

    function check_AutoExchangeRhedge_WhenUserHasOnlyRhedge() public {
        check_AutoExchange({
            token: sec.rhedge,
            tokenUsdcNodeId: dec.oracleNodes["rhedgeUsdcReyaLm"],
            tokenAeDiscount: 0.005e18,
            userInitialRusdBalance: 0
        });
    }

    function check_AutoExchangeRhedge_WhenUserHasBothRhedgeAndRusd() public {
        check_AutoExchange({
            token: sec.rhedge,
            tokenUsdcNodeId: dec.oracleNodes["rhedgeUsdcReyaLm"],
            tokenAeDiscount: 0.005e18,
            userInitialRusdBalance: 100e6
        });
    }

    function check_AutoExchangeSrusd_WhenUserHasOnlySrusd() public {
        check_AutoExchange_srUSD({ userInitialRusdBalance: 0 });
    }

    function check_AutoExchangeSrusd_WhenUserHasBothSrusdAndRusd() public {
        check_AutoExchange_srUSD({ userInitialRusdBalance: 100e6 });
    }

    function check_AutoExchangeWsteth_WhenUserHasOnlyWsteth() public {
        check_AutoExchange({
            token: sec.wsteth,
            tokenUsdcNodeId: dec.oracleNodes["wstethUsdcStork"],
            tokenAeDiscount: 0.01e18,
            userInitialRusdBalance: 0
        });
    }

    function check_AutoExchangeWsteth_WhenUserHasBothWstethAndRusd() public {
        check_AutoExchange({
            token: sec.wsteth,
            tokenUsdcNodeId: dec.oracleNodes["wstethUsdcStork"],
            tokenAeDiscount: 0.01e18,
            userInitialRusdBalance: 100e6
        });
    }
}
