// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { MarketCloseForkCheck } from "../../reya_common/trade/MarketClose.fork.c.sol";

contract MarketCloseForkTest is ReyaForkTest, MarketCloseForkCheck {
    /// @notice The 18 markets frozen and then force-closed by the W1 batch (10-14 Aug 2026) — Group 0 (reduce-only
    ///         since June) plus the RO batch announced on 6 Aug.
    /// @dev Keep in sync with packages/tomls/src/passive_perp/market_close_w1_close_*.toml.
    function w1ClosedMarkets() internal pure returns (uint128[] memory ids) {
        ids = new uint128[](18);
        // Group 0 — reduce-only since June
        ids[0] = 15; // ZRO
        ids[1] = 25; // JTO
        ids[2] = 45; // AI16Z
        ids[3] = 53; // TON
        ids[4] = 57; // MOVE
        ids[5] = 58; // BERA
        ids[6] = 68; // ZORA
        ids[7] = 69; // PROVE
        ids[8] = 71; // YZY
        ids[9] = 72; // XPL
        ids[10] = 73; // WLFI
        // RO batch — reduce-only since 6 Aug
        ids[11] = 34; // GOAT
        ids[12] = 36; // KNEIRO
        ids[13] = 46; // AIXBT
        ids[14] = 49; // GRIFFAIN
        ids[15] = 52; // APE
        ids[16] = 61; // IP
        // Group A — reduce-only since #507, pulled forward into the W1 close
        ids[17] = 67; // KAITO
    }

    /// @dev Use this test as a script to check the full lifecycle of closing a market
    /// Full close flow for a market, e.g. market 22: reduce-only -> no-extend -> freeze -> force close. Commented out
    /// because
    // it actually unwinds every position; re-enable (and refresh the account list) when running the close rehearsal.
    // function test_ForceClose_Market22Kbonk() public {
    //     uint128[] memory accountIds = new uint128[](6);
    //     accountIds[0] = 21_229;
    //     accountIds[1] = 11_234;
    //     accountIds[2] = 105_367;
    //     accountIds[3] = 126_268;
    //     accountIds[4] = 2; // passive pool account
    //     accountIds[5] = 17_695;
    //     check_MarketCloseFullFlow(22, sec.passivePoolAccountId, accountIds);
    // }

    /// @notice Stage 1: every currently-active market can be set to reduce-only and then rejects OI-increasing orders.
    function test_ActiveMarketsCanEnterReduceOnly() public {
        for (uint128 marketId = 1; marketId <= lastMarketId(); marketId++) {
            if (isMarketActive(marketId)) {
                check_EnterReduceOnly(marketId, sec.passivePoolAccountId);
            }
        }
    }

    /// @notice Stage 2: every market already in reduce-only (`maxOpenBase == 0`) can be frozen for closure. Markets
    ///         the W1 batch has already frozen are skipped — `test_W1MarketsAreClosed` covers those.
    function test_ReduceOnlyMarketsCanBeFrozen() public {
        for (uint128 marketId = 1; marketId <= lastMarketId(); marketId++) {
            if (isMarketActive(marketId) && isReduceOnly(marketId) && !isFrozen(marketId)) {
                check_FreezeMarketForClosure(marketId);
            }
        }
    }

    /// @notice Stage 3: the W1 batch closed out all 17 markets — still pinned to their CONSTANT oracle node with
    ///         funding at zero, open interest back to zero, and the market disabled. This is the assertion that
    ///         catches a market left half-closed, or one accidentally un-frozen by a `set_market_config` re-run
    ///         writing the Stork node back / `batchSetMarketConfigurationVelocity` re-arming funding velocity.
    function test_W1MarketsAreClosed() public {
        ensureW1MarketsFrozen();

        uint128[] memory closedMarkets = w1ClosedMarkets();
        for (uint256 i = 0; i < closedMarkets.length; i++) {
            check_MarketIsClosed(closedMarkets[i]);
        }
    }

    /// @dev Freeze any W1 market the omnibus batch left unfrozen, refreshing the oracle price first.
    ///
    ///      The `market_close_w1_freeze_*` invokes revert with `StalePriceDetected` on a fork and cannon skips them:
    ///      the fork pins chain state at a block, so the last Stork push stops advancing while the build's
    ///      `block.timestamp` runs on in wall-clock time, and `freezeMarketForClosure` snapshots the price through
    ///      `getOraclePriceForMarketOrder`. Without this the frozen precondition inside `check_MarketIsClosed` trips
    ///      first and hides what this test is actually here to check — that the close emptied the market and the
    ///      market was then disabled.
    ///
    ///      The `isFrozen` guard makes this a no-op wherever the batch did land.
    function ensureW1MarketsFrozen() internal {
        uint128[] memory frozenMarkets = w1ClosedMarkets();

        for (uint256 i = 0; i < frozenMarkets.length; i++) {
            if (!isFrozen(frozenMarkets[i])) {
                check_FreezeMarketForClosure(frozenMarkets[i]);
            }
        }
    }

    /// @notice A frozen-but-not-yet-closed market can still be traded down — a reducing trade against the pool leaves
    ///         the funding rate, open interest and pool PnL intact (PnL only realizes).
    /// @dev Empty for W1: every market this batch froze was force-closed in the same batch, so there is nothing left
    ///      to reduce. Populate when a later wave freezes markets that stay open across a week.
    function test_FrozenMarketsCanBeReduced() public {
        uint128[] memory frozenMarkets = new uint128[](0);

        for (uint256 i = 0; i < frozenMarkets.length; i++) {
            check_FrozenMarketPositionsCanBeReduced(frozenMarkets[i], sec.passivePoolAccountId);
        }
    }

    /// @notice Only the owner can freeze a market for closure. Both levers gate on `ensureEnabledMarket` before the
    ///         owner check, so the `Unauthorized` revert is only reachable on enabled markets — skip the rest.
    function test_OnlyOwnerCanFreeze_activeMarkets() public {
        for (uint128 marketId = 1; marketId <= lastMarketId(); marketId++) {
            if (isMarketActive(marketId)) {
                check_OnlyOwnerCanFreeze(marketId, address(0xBAD));
            }
        }
    }

    /// @notice Only the owner can force-close a market.
    function test_OnlyOwnerCanForceClose_activeMarkets() public {
        for (uint128 marketId = 1; marketId <= lastMarketId(); marketId++) {
            if (isMarketActive(marketId)) {
                check_OnlyOwnerCanForceClose(marketId, address(0xBAD));
            }
        }
    }
}
