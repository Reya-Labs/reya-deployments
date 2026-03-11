pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import {
    IPassivePerpProxy,
    MarketConfigurationData,
    PerpPosition,
    PnLComponents
} from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";
import { ICoreProxy } from "../../../src/interfaces/ICoreProxy.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

/**
 * Stress-test: extreme funding velocity + time warp to verify max pool drain ≤ ~7%/day.
 *
 * MAX_FUNDING_RATE = 0.07 (7%/day). When the rate is pinned at the cap for a full day,
 * the funding area delta = 0.07 * 1 = 0.07, so the pool can lose at most 7% of its
 * position-value per day through funding alone.
 */
contract FundingRateDrainForkCheck is BaseReyaForkTest {
    int256 constant MAX_FUNDING_RATE = 0.07e18; // 7% per day

    function _createFundedAccount() private returns (address user, uint128 accountId) {
        (user,) = makeAddrAndKey("drainTestUser");
        deal(sec.usdc, address(sec.periphery), 10_000_000e6);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], 10_000_000e6);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: user, token: address(sec.usdc) })
        );
    }

    function _setExtremeVelocity(uint128 marketId) private {
        MarketConfigurationData memory config = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId);
        config.velocityMultiplier = 1000e18;
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).setMarketConfiguration(marketId, config);
    }

    function check_MaxPoolDrainInOneDay(uint128 marketId) public {
        mockFreshPrices();
        removeMarketsOILimit();

        int256 poolBase;
        {
            (address user, uint128 accountId) = _createFundedAccount();

            // trader goes long → pool goes net short
            executeCoreMatchOrder({
                marketId: marketId,
                sender: user,
                base: sd(1e18),
                priceLimit: ud(type(uint256).max),
                accountId: accountId
            });

            poolBase = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, sec.passivePoolAccountId).base;
            assertTrue(poolBase < 0, "pool should be net short");

            _setExtremeVelocity(marketId);

            // tiny trade to lock in velocity on-chain
            executeCoreMatchOrder({
                marketId: marketId,
                sender: user,
                base: sd(0.00001e18),
                priceLimit: ud(type(uint256).max),
                accountId: accountId
            });
        }

        // advance 1 hour so the rate saturates at MAX
        vm.warp(block.timestamp + 3600);
        mockFreshPrices();

        assertApproxEqAbsDecimal(
            IPassivePerpProxy(sec.perp).getLatestFundingRate(marketId),
            MAX_FUNDING_RATE,
            1e15,
            18,
            "funding rate should be clamped at MAX"
        );

        int256 totalPnlBefore;
        {
            PnLComponents memory pnlBefore =
                IPassivePerpProxy(sec.perp).getAccountPnLComponents(marketId, sec.passivePoolAccountId);
            totalPnlBefore = pnlBefore.realizedPnL + pnlBefore.unrealizedPnL;
        }

        vm.warp(block.timestamp + 86_400);
        mockFreshPrices();

        int256 fundingLoss;
        {
            PnLComponents memory pnlAfter =
                IPassivePerpProxy(sec.perp).getAccountPnLComponents(marketId, sec.passivePoolAccountId);
            fundingLoss = totalPnlBefore - (pnlAfter.realizedPnL + pnlAfter.unrealizedPnL);
        }

        {
            uint256 absPoolBase = poolBase < 0 ? uint256(-poolBase) : uint256(poolBase);
            // max drain = |poolBase| * spotPrice * MAX_FUNDING_RATE, scaled to 1e6
            int256 maxDrain =
                int256(ud(absPoolBase).mul(getMarketSpotPrice(marketId)).mul(ud(uint256(MAX_FUNDING_RATE))).unwrap())
                    / 1e12;

            assertTrue(fundingLoss <= (maxDrain * 101) / 100, "pool drain exceeds 7% of exposure in 1 day");
        }

        assertApproxEqAbsDecimal(
            IPassivePerpProxy(sec.perp).getLatestFundingRate(marketId),
            MAX_FUNDING_RATE,
            1e15,
            18,
            "funding rate should still be clamped at MAX after 1 day"
        );
    }

    function check_MaxPoolDrainInOneDay_NegativeDirection(uint128 marketId) public {
        mockFreshPrices();
        removeMarketsOILimit();

        int256 poolBase;
        {
            (address user, uint128 accountId) = _createFundedAccount();

            // trader goes short → pool goes net long
            executeCoreMatchOrder({
                marketId: marketId,
                sender: user,
                base: sd(-1e18),
                priceLimit: ud(0),
                accountId: accountId
            });

            poolBase = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, sec.passivePoolAccountId).base;
            assertTrue(poolBase > 0, "pool should be net long");

            _setExtremeVelocity(marketId);

            // tiny trade to lock in velocity
            executeCoreMatchOrder({
                marketId: marketId,
                sender: user,
                base: sd(-0.00001e18),
                priceLimit: ud(0),
                accountId: accountId
            });
        }

        // advance 1 hour so rate saturates at MIN
        vm.warp(block.timestamp + 3600);
        mockFreshPrices();

        assertApproxEqAbsDecimal(
            IPassivePerpProxy(sec.perp).getLatestFundingRate(marketId),
            -MAX_FUNDING_RATE,
            1e15,
            18,
            "funding rate should be clamped at MIN"
        );

        int256 totalPnlBefore;
        {
            PnLComponents memory pnlBefore =
                IPassivePerpProxy(sec.perp).getAccountPnLComponents(marketId, sec.passivePoolAccountId);
            totalPnlBefore = pnlBefore.realizedPnL + pnlBefore.unrealizedPnL;
        }

        vm.warp(block.timestamp + 86_400);
        mockFreshPrices();

        int256 fundingLoss;
        {
            PnLComponents memory pnlAfter =
                IPassivePerpProxy(sec.perp).getAccountPnLComponents(marketId, sec.passivePoolAccountId);
            fundingLoss = totalPnlBefore - (pnlAfter.realizedPnL + pnlAfter.unrealizedPnL);
        }

        {
            uint256 absPoolBase = poolBase < 0 ? uint256(-poolBase) : uint256(poolBase);
            int256 maxDrain =
                int256(ud(absPoolBase).mul(getMarketSpotPrice(marketId)).mul(ud(uint256(MAX_FUNDING_RATE))).unwrap())
                    / 1e12;

            assertTrue(
                fundingLoss <= (maxDrain * 101) / 100,
                "pool drain exceeds 7% of exposure in 1 day (negative direction)"
            );
        }

        assertApproxEqAbsDecimal(
            IPassivePerpProxy(sec.perp).getLatestFundingRate(marketId),
            -MAX_FUNDING_RATE,
            1e15,
            18,
            "funding rate should still be clamped at MIN after 1 day"
        );
    }

    function check_ExtremeFundingRateMultipleDays(uint128 marketId) public {
        mockFreshPrices();
        removeMarketsOILimit();

        int256 poolBase;
        {
            (address user, uint128 accountId) = _createFundedAccount();

            // trader goes long → pool net short
            executeCoreMatchOrder({
                marketId: marketId,
                sender: user,
                base: sd(1e18),
                priceLimit: ud(type(uint256).max),
                accountId: accountId
            });

            poolBase = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, sec.passivePoolAccountId).base;
            assertTrue(poolBase < 0, "pool should be net short");

            _setExtremeVelocity(marketId);

            // tiny trade to lock in velocity
            executeCoreMatchOrder({
                marketId: marketId,
                sender: user,
                base: sd(0.00001e18),
                priceLimit: ud(type(uint256).max),
                accountId: accountId
            });
        }

        // saturate the rate
        vm.warp(block.timestamp + 3600);
        mockFreshPrices();

        assertApproxEqAbsDecimal(
            IPassivePerpProxy(sec.perp).getLatestFundingRate(marketId),
            MAX_FUNDING_RATE,
            1e15,
            18,
            "funding rate should be clamped at MAX"
        );

        int256 totalPnlBefore;
        {
            PnLComponents memory pnlBefore =
                IPassivePerpProxy(sec.perp).getAccountPnLComponents(marketId, sec.passivePoolAccountId);
            totalPnlBefore = pnlBefore.realizedPnL + pnlBefore.unrealizedPnL;
        }

        uint256 numDays = 7;
        vm.warp(block.timestamp + 86_400 * numDays);
        mockFreshPrices();

        int256 fundingLoss;
        {
            PnLComponents memory pnlAfter =
                IPassivePerpProxy(sec.perp).getAccountPnLComponents(marketId, sec.passivePoolAccountId);
            fundingLoss = totalPnlBefore - (pnlAfter.realizedPnL + pnlAfter.unrealizedPnL);
        }

        {
            uint256 absPoolBase = poolBase < 0 ? uint256(-poolBase) : uint256(poolBase);
            int256 maxDrain =
                int256(ud(absPoolBase).mul(getMarketSpotPrice(marketId)).mul(ud(uint256(MAX_FUNDING_RATE))).unwrap())
                    * int256(numDays) / 1e12;

            assertTrue(fundingLoss <= (maxDrain * 101) / 100, "pool drain exceeds N*7% of exposure over 7 days");
        }

        assertApproxEqAbsDecimal(
            IPassivePerpProxy(sec.perp).getLatestFundingRate(marketId),
            MAX_FUNDING_RATE,
            1e15,
            18,
            "funding rate should still be clamped at MAX after 7 days"
        );
    }
}
