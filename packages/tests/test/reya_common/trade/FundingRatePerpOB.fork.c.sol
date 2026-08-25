pragma solidity >=0.8.19 <0.9.0;

import { PerpFillForkCheck } from "./PerpFill.fork.c.sol";

import {
    IPassivePerpProxy,
    PerpPosition,
    EIP712Signature as PerpEIP712Signature
} from "../../../src/interfaces/IPassivePerpProxy.sol";
import {
    IPassivePerpProxyV2,
    OracleDataPayload,
    OracleDataType,
    MarketDataResponseV2,
    MarketConfigurationDataV2
} from "../../../src/interfaces/IPassivePerpProxyV2.sol";
import { ICoreProxy, MarginInfo } from "../../../src/interfaces/ICoreProxy.sol";
import { OracleDataPayloadHashing } from "../../../src/utils/OracleDataPayloadHashing.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

/**
 * @title FundingRatePerpOBForkCheck
 * @notice Fork tests for push-based funding rates (perpOB model)
 * @dev Tests oracle-pushed funding rates via OraclePushModule.
 *      The legacy velocity-based FundingRateForkCheck is kept separately for cronos/mainnet.
 */
contract FundingRatePerpOBForkCheck is PerpFillForkCheck {
    address internal fundingPublisher;
    uint256 internal fundingPublisherPk;

    function setupFundingTestActors() internal {
        (fundingPublisher, fundingPublisherPk) = makeAddrAndKey("fundingPublisher");

        // Grant oracle pusher access (checks msg.sender)
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).addToFeatureFlagAllowlist(ORACLE_PUSHERS_FLAG, fundingPublisher);

        // Grant oracle publisher access (checks payload.publisher signature)
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).addToFeatureFlagAllowlist(ORACLE_PUBLISHERS_FLAG, fundingPublisher);
    }

    function _pushOracleData(uint128 marketId, OracleDataType dataType, bytes memory data) internal {
        _pushOracleDataAt(marketId, dataType, data, block.timestamp);
    }

    function _pushOracleDataAt(
        uint128 marketId,
        OracleDataType dataType,
        bytes memory data,
        uint256 payloadTimestamp
    )
        internal
    {
        OracleDataPayload memory payload = OracleDataPayload({
            marketId: marketId,
            timestamp: payloadTimestamp,
            dataType: dataType,
            data: data,
            publisher: fundingPublisher
        });

        uint256 deadline = block.timestamp + 3600;
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(fundingPublisherPk, OracleDataPayloadHashing.mockCalculateDigest(payload, deadline, sec.perp));

        PerpEIP712Signature memory sig = PerpEIP712Signature({ v: v, r: r, s: s, deadline: deadline });

        vm.prank(fundingPublisher);
        IPassivePerpProxyV2(sec.perp).pushOracleData(payload, sig);
    }

    /**
     * @notice Test pushing a funding rate and reading it back
     */
    function check_PushFundingRate(uint128 marketId) internal {
        setupFundingTestActors();
        // Also needed: pushMarkPriceWithinCollar signs with oraclePublisherPk,
        // which only setupPerpTestActors initialises.
        setupPerpTestActors();
        mockFreshPrices();

        // Push a fresh mark price first: funding pushes validate the STORED
        // mark price's age (MarkPriceStale, 60s), and without this the test
        // inherits whatever the live pusher last wrote before the fork pin —
        // making it fail whenever fork-pin age + accumulated anvil block time
        // exceeds the window (every extra deployment step costs a block).
        pushMarkPriceWithinCollar(marketId, 3000e18);

        // Push a positive funding rate (1% annualized = 1e16)
        int256 fundingRate = 1e16;
        _pushOracleData(marketId, OracleDataType.FundingRate, abi.encode(fundingRate));

        // Read back via getMarketData (standalone getters not on router)
        MarketDataResponseV2 memory mdr = IPassivePerpProxyV2(sec.perp).getMarketData(marketId);
        assertEq(mdr.marketData.fundingRate, fundingRate, "Stored funding rate should match pushed value");
        assertEq(mdr.marketData.fundingRateTimestamp, block.timestamp, "Funding rate timestamp should match");
    }

    /**
     * @notice Test that pushing a stale funding rate payload reverts.
     * @dev validateFundingRatePush (push-time check) reverts with FundingRateStale when
     *      blockTimestamp > payloadTimestamp + fundingRateMaxStaleDuration.
     *      Ordinary match-order execution has a separate read-side funding-staleness gate;
     *      liquidations and ADL deliberately bypass that gate so risk reduction remains live.
     */
    function check_FundingRateStaleness(uint128 marketId) internal {
        setupFundingTestActors();
        // Also needed: pushMarkPriceWithinCollar signs with oraclePublisherPk,
        // which only setupPerpTestActors initialises.
        setupPerpTestActors();
        mockFreshPrices();

        // Push a fresh mark price first: funding pushes validate the STORED
        // mark price's age (MarkPriceStale, 60s), and without this the test
        // inherits whatever the live pusher last wrote before the fork pin —
        // making it fail whenever fork-pin age + accumulated anvil block time
        // exceeds the window (every extra deployment step costs a block).
        pushMarkPriceWithinCollar(marketId, 3000e18);

        // Seed lastFundingTimestamp at the current block by pushing a fresh zero rate.
        _pushOracleData(marketId, OracleDataType.FundingRate, abi.encode(int256(0)));

        uint256 maxStaleDuration =
            IPassivePerpProxyV2(sec.perp).getMarketConfiguration(marketId).fundingRateMaxStaleDuration;

        // Construct a payload one second older than the configured maximum stale duration.
        uint256 stalePayloadTimestamp = block.timestamp - maxStaleDuration - 1;

        vm.expectRevert(
            abi.encodeWithSelector(
                IPassivePerpProxyV2.FundingRateStale.selector,
                marketId,
                stalePayloadTimestamp,
                block.timestamp,
                maxStaleDuration
            )
        );
        _pushOracleDataAt(marketId, OracleDataType.FundingRate, abi.encode(int256(1e16)), stalePayloadTimestamp);
    }

    /**
     * @notice Test that stale funding blocks an ordinary full close.
     * @dev The execution gate runs before the position delta is applied, so it blocks
     *      risk-reducing user closes as well as risk-increasing ordinary fills.
     */
    function check_FundingRateStalenessForTrade(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        uint256 fundingRateTimestamp = block.timestamp;
        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 10_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 10_000e6);

        executePerpFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 0.5e18,
            price: 3000e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        uint256 maxStaleDuration =
            IPassivePerpProxyV2(sec.perp).getMarketConfiguration(marketId).fundingRateMaxStaleDuration;
        vm.warp(block.timestamp + maxStaleDuration + 1);
        mockFreshPrices();
        pushMarkPriceWithinCollar(marketId, 3000e18);

        vm.expectRevert(
            abi.encodeWithSelector(
                IPassivePerpProxyV2.FundingRateStale.selector,
                marketId,
                fundingRateTimestamp,
                block.timestamp,
                maxStaleDuration
            )
        );
        executePerpClose({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 0.5e18,
            price: 3000e18,
            buyerNonce: 2,
            sellerNonce: 2,
            meNonce: 2
        });
    }

    /**
     * @notice Test pushing a mark price and reading it back
     */
    function check_PushMarkPrice(uint128 marketId) internal {
        setupFundingTestActors();
        mockFreshPrices();

        uint256 markPrice = 3000e18;
        MarketConfigurationDataV2 memory marketConfig = IPassivePerpProxyV2(sec.perp).getMarketConfiguration(marketId);
        mockFreshPrice(marketConfig.oracleNodeId, markPrice);
        _pushOracleData(marketId, OracleDataType.MarkPrice, abi.encode(markPrice));

        // Read back via getMarketData (standalone getters not on router)
        MarketDataResponseV2 memory mdr = IPassivePerpProxyV2(sec.perp).getMarketData(marketId);
        assertEq(mdr.marketData.markPrice, markPrice, "Stored mark price should match pushed value");
        assertEq(mdr.marketData.markPriceTimestamp, block.timestamp, "Mark price timestamp should match");
    }

    /**
     * @notice Test that funding rate accrues on open positions under the forward-looking model
     * @dev In the forward-looking funding model (v1.0.50+):
     *      - Funding is materialized ONLY when a new rate is pushed via pushFundingRate.
     *      - The NEWLY pushed rate is applied retroactively over the elapsed interval
     *        [lastFundingTimestamp, block.timestamp], then lastFundingTimestamp is stamped
     *        to block.timestamp.
     *      - pushMarkPrice does NOT accrue funding; trades/liquidations/ADL never touch
     *        market.fundingRate or market.lastFundingTimestamp.
     *      - getMarginInfo / getUpdatedPositionInfo read stored trackers verbatim — they do
     *        NOT forward-project. So funding is invisible until the next pushFundingRate.
     *
     *      Funding rate is denominated per-DAY (not per-year):
     *        fundingValueDelta = rate * markPrice * (secondsElapsed / 86400) * baseMultiplier
     *        positionFundingPnL = fundingValueDelta / oldBaseMultiplier * (-base)
     *
     *      For rate=0.1e18 (10%/day), markPrice=3000, elapsed=600s, base=+1e18:
     *        delta = 0.1 * 3000 * (600/86400) * 1 = 2.083333... USD
     *        long PnL is negative and short PnL is positive by the same amount.
     */
    function check_FundingRateAccrual(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();

        // Establish baseline: push mark price and zero funding at t0.
        // This stamps lastFundingTimestamp = t0 so the next push has a defined window.
        pushMarkPriceWithinCollar(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        // Open position: buyer goes long 1 ETH, seller goes short 1 ETH
        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 10_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 10_000e6);

        executePerpFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 1e18,
            price: 3000e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        // Record margin immediately after open (includes fees already, so funding PnL will
        // be visible as a pure delta from this baseline).
        MarginInfo memory buyerMarginAfterOpen = ICoreProxy(sec.core).getUsdNodeMarginInfo(buyerAccountId);
        MarginInfo memory sellerMarginAfterOpen = ICoreProxy(sec.core).getUsdNodeMarginInfo(sellerAccountId);

        // Stage the funding rate for the upcoming window. This pushes with elapsed=0 so no
        // accrual yet — it just stores the rate that will govern the next window.
        // 0.1e18 = 10% per DAY (the per-day rate is the native unit in passive-perp).
        int256 dailyRate = 0.1e18;
        pushFundingRate(marketId, dailyRate);

        // Accrue across the full configured funding-freshness window.
        uint256 elapsed = IPassivePerpProxyV2(sec.perp).getMarketConfiguration(marketId).fundingRateMaxStaleDuration;
        vm.warp(block.timestamp + elapsed);
        mockFreshPrices();

        // Keep the mark live under the configured staleness gate. Mark pushes do not
        // accrue funding, so the funding delta remains isolated to the next rate push.
        pushMarkPriceWithinCollar(marketId, 3000e18);

        // Push the SAME rate again at the new timestamp. This is the call that actually
        // accrues funding: it computes fundingValueDelta = dailyRate * markPrice * elapsed / one day
        // and adds it to both long and short trackers, then stamps lastFundingTimestamp.
        pushFundingRate(marketId, dailyRate);

        int256 expectedFundingDelta = dailyRate * int256(3000e18) / int256(1e18) * int256(elapsed) / int256(1 days);

        MarginInfo memory buyerMarginAfterFunding = ICoreProxy(sec.core).getUsdNodeMarginInfo(buyerAccountId);
        MarginInfo memory sellerMarginAfterFunding = ICoreProxy(sec.core).getUsdNodeMarginInfo(sellerAccountId);

        int256 buyerFundingPnL = buyerMarginAfterFunding.marginBalance - buyerMarginAfterOpen.marginBalance;
        int256 sellerFundingPnL = sellerMarginAfterFunding.marginBalance - sellerMarginAfterOpen.marginBalance;

        // Tolerance: 1e12 (1e-6 USD) to absorb fixed-point rounding in UD60x18/SD59x18 math.
        assertApproxEqAbsDecimal(
            buyerFundingPnL, -expectedFundingDelta, 1e12, 18, "Long funding PnL should match the configured window"
        );
        assertApproxEqAbsDecimal(
            sellerFundingPnL, expectedFundingDelta, 1e12, 18, "Short funding PnL should match the configured window"
        );
    }
}
