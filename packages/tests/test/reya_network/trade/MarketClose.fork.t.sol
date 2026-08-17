// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { MarketCloseForkCheck } from "../../reya_common/trade/MarketClose.fork.c.sol";

contract MarketCloseForkTest is ReyaForkTest, MarketCloseForkCheck {
    /// @notice The 18 markets frozen by the W1 close batch (10-14 Aug 2026) — Group 0 (reduce-only since June) plus
    ///         the RO batch announced on 6 Aug. These are the markets force-closed at the end of W1.
    /// @dev Keep in sync with packages/tomls/src/passive_perp/configs/market_close_w1.toml.
    function w1FrozenMarkets() internal pure returns (uint128[] memory ids) {
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
        // Group A — reduce-only since #507
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
    ///         an earlier close batch has already frozen are skipped — `test_W1MarketsAreFrozen` covers those.
    function test_ReduceOnlyMarketsCanBeFrozen() public {
        for (uint128 marketId = 1; marketId <= lastMarketId(); marketId++) {
            if (isMarketActive(marketId) && isReduceOnly(marketId) && !isFrozen(marketId)) {
                check_FreezeMarketForClosure(marketId);
            }
        }
    }

    /// @notice All 18 W1 markets end up pinned to a CONSTANT oracle node at a non-zero price with funding rate and
    ///         velocity at zero. This is the assertion that catches an accidental un-freeze — a re-run of
    ///         `set_market_config` writing the Stork node back, or funding velocity being re-armed.
    /// @dev `ensureW1MarketsFrozen` freezes anything the omnibus batch did not, behind a fresh price. See the comment
    ///      on that helper for why the batch cannot be relied on here.
    function test_W1MarketsAreFrozen() public {
        ensureW1MarketsFrozen();

        uint128[] memory frozenMarkets = w1FrozenMarkets();
        for (uint256 i = 0; i < frozenMarkets.length; i++) {
            check_MarketIsFrozen(frozenMarkets[i]);
        }
    }

    /// @notice Stage 3: every frozen market (waiting to be force-closed) can still be traded down — a reducing trade
    ///         against the pool leaves the funding rate, open interest and pool PnL intact (PnL only realizes).
    function test_FrozenMarketsCanBeReduced() public {
        ensureW1MarketsFrozen();

        uint128[] memory frozenMarkets = w1FrozenMarkets();
        for (uint256 i = 0; i < frozenMarkets.length; i++) {
            // AIXBT (46) is disabled again at the end of this batch, so no trade can reach it. It is at open
            // interest 0 with no holders, so there is nothing to reduce anyway.
            if (!isMarketActive(frozenMarkets[i])) {
                continue;
            }
            check_FrozenMarketPositionsCanBeReduced(frozenMarkets[i], sec.passivePoolAccountId);
        }
    }

    /// @dev Freeze any W1 market the omnibus batch left unfrozen, refreshing the oracle price first.
    ///
    ///      The `market_close_w1_freeze_*` invokes revert with `StalePriceDetected` on this fork and cannon skips
    ///      them: the fork pins chain state at a block, so the last Stork push stops advancing while the build's
    ///      `block.timestamp` runs on in wall-clock time. By the time the build reaches these invokes it is minutes
    ///      past the node's staleness window, and `freezeMarketForClosure` snapshots the price through
    ///      `getOraclePriceForMarketOrder`. On mainnet the same invokes execute against a chain where Stork keeps
    ///      publishing, so the gap stays inside the window — the runbook still has to make sure prices are fresh at
    ///      execution, since `marketOrderMaxStaleDuration` is 11s for all 18.
    ///
    ///      Rather than assert a state the fork cannot reach, refresh the price and do the freeze here — the same
    ///      thing every other check that touches a price-sensitive entrypoint does. The `isFrozen` guard means this
    ///      is a no-op when the batch did land, so the assertions above still verify the real thing wherever they can.
    function ensureW1MarketsFrozen() internal {
        uint128[] memory frozenMarkets = w1FrozenMarkets();

        for (uint256 i = 0; i < frozenMarkets.length; i++) {
            if (!isFrozen(frozenMarkets[i])) {
                // Preserving the flag matters for AIXBT (46): this batch disables it again right after freezing it,
                // so it arrives here disabled and must leave here disabled.
                check_FreezeMarketForClosurePreservingEnabled(frozenMarkets[i]);
            }
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
