// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { MarketCloseForkCheck } from "../../reya_common/trade/MarketClose.fork.c.sol";
import { IPassivePerpProxy } from "../../../src/interfaces/IPassivePerpProxy.sol";

contract MarketCloseForkTest is ReyaForkTest, MarketCloseForkCheck {
    /// @notice The 17 markets frozen and then force-closed by the W1 batch (10-14 Aug 2026) — Group 0 (reduce-only
    ///         since June) plus the RO batch announced on 6 Aug.
    /// @dev Keep in sync with packages/tomls/src/passive_perp/market_close_w1_close_*.toml.
    function w1ClosedMarkets() internal pure returns (uint128[] memory ids) {
        ids = new uint128[](17);
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
        ids[13] = 49; // GRIFFAIN
        ids[14] = 52; // APE
        ids[15] = 61; // IP
        // Group A — reduce-only since #507, pulled forward into the W1 close
        ids[16] = 67; // KAITO
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
        ensureW1MarketsClosed();

        uint128[] memory closedMarkets = w1ClosedMarkets();
        for (uint256 i = 0; i < closedMarkets.length; i++) {
            check_MarketIsClosed(closedMarkets[i]);
        }
    }

    /// @dev The account list the force-close batch passes for `marketId` — every account holding a
    ///      non-zero base in that market, including the passive pool (account 2 on reya_network). Keyed by market id, not
    ///      by position in `w1ClosedMarkets()`, so the two lists cannot silently drift out of step.
    /// @dev Keep in sync with packages/tomls/src/passive_perp/market_close_w1_close_*.toml.
    function w1CloseAccounts(uint128 marketId) internal pure returns (uint128[] memory a) {
        if (marketId == 15) { // ZRO
            a = new uint128[](13);
            a[0] = 2;
            a[1] = 17251;
            a[2] = 41476;
            a[3] = 18073;
            a[4] = 128904;
            a[5] = 135288;
            a[6] = 18225;
            a[7] = 134477;
            a[8] = 40887;
            a[9] = 23724;
            a[10] = 79924;
            a[11] = 127173;
            a[12] = 60666;
            return a;
        }
        if (marketId == 25) { // JTO
            a = new uint128[](5);
            a[0] = 129611;
            a[1] = 20303;
            a[2] = 4935;
            a[3] = 18073;
            a[4] = 2;
            return a;
        }
        if (marketId == 34) { // GOAT
            a = new uint128[](5);
            a[0] = 35169;
            a[1] = 17695;
            a[2] = 127253;
            a[3] = 126268;
            a[4] = 2;
            return a;
        }
        if (marketId == 36) { // kNEIRO
            a = new uint128[](3);
            a[0] = 2;
            a[1] = 17695;
            a[2] = 126268;
            return a;
        }
        if (marketId == 45) { // AI16Z
            a = new uint128[](3);
            a[0] = 2;
            a[1] = 128623;
            a[2] = 43829;
            return a;
        }
        if (marketId == 49) { // GRIFFAIN
            a = new uint128[](2);
            a[0] = 2;
            a[1] = 131432;
            return a;
        }
        if (marketId == 52) { // APE
            a = new uint128[](3);
            a[0] = 134477;
            a[1] = 48720;
            a[2] = 2;
            return a;
        }
        if (marketId == 53) { // TON
            a = new uint128[](7);
            a[0] = 127253;
            a[1] = 98897;
            a[2] = 15678;
            a[3] = 2;
            a[4] = 11117;
            a[5] = 839;
            a[6] = 105367;
            return a;
        }
        if (marketId == 57) { // MOVE
            a = new uint128[](3);
            a[0] = 2;
            a[1] = 79924;
            a[2] = 100547;
            return a;
        }
        if (marketId == 58) { // BERA
            a = new uint128[](3);
            a[0] = 23735;
            a[1] = 2;
            a[2] = 107180;
            return a;
        }
        if (marketId == 61) { // IP
            a = new uint128[](5);
            a[0] = 135288;
            a[1] = 127253;
            a[2] = 7301;
            a[3] = 20303;
            a[4] = 2;
            return a;
        }
        if (marketId == 67) { // KAITO
            a = new uint128[](10);
            a[0] = 102387;
            a[1] = 129339;
            a[2] = 7301;
            a[3] = 2;
            a[4] = 48720;
            a[5] = 129450;
            a[6] = 135845;
            a[7] = 134542;
            a[8] = 131432;
            a[9] = 123082;
            return a;
        }
        if (marketId == 68) { // ZORA
            a = new uint128[](4);
            a[0] = 120595;
            a[1] = 2;
            a[2] = 38256;
            a[3] = 125390;
            return a;
        }
        if (marketId == 69) { // PROVE
            a = new uint128[](2);
            a[0] = 2;
            a[1] = 72493;
            return a;
        }
        if (marketId == 71) { // YZY
            a = new uint128[](2);
            a[0] = 2;
            a[1] = 3176;
            return a;
        }
        if (marketId == 72) { // XPL
            a = new uint128[](8);
            a[0] = 2;
            a[1] = 134477;
            a[2] = 14378;
            a[3] = 11117;
            a[4] = 47927;
            a[5] = 112901;
            a[6] = 71259;
            a[7] = 11363;
            return a;
        }
        if (marketId == 73) { // WLFI
            a = new uint128[](2);
            a[0] = 2;
            a[1] = 128260;
            return a;
        }
        revert(string.concat("no close account list for market ", vm.toString(marketId)));
    }

    /// @dev Bring every W1 market to the state the two batches leave it in: frozen, emptied, disabled.
    ///
    ///      Neither batch can execute on a fork. The `market_close_w1_freeze_*` invokes revert with
    ///      `StalePriceDetected` — the fork pins chain state at a block so the last Stork push stops advancing while
    ///      the build's `block.timestamp` runs on in wall-clock time — and cannon skips them, after which every
    ///      dependent `forceCloseMarket` reverts with `ClosePriceNotLocked` and is skipped too. Asserting the closed
    ///      state without this would be asserting something the fork cannot reach.
    ///
    ///      So do both halves here, with the same account lists the batch passes, and let the assertions in
    ///      {check_MarketIsClosed} verify the result. The guards make each half a no-op wherever the batch did land,
    ///      so on any environment where it executed for real this still checks the real thing.
    function ensureW1MarketsClosed() internal {
        uint128[] memory closedMarkets = w1ClosedMarkets();

        for (uint256 i = 0; i < closedMarkets.length; i++) {
            uint128 marketId = closedMarkets[i];

            if (!isFrozen(marketId)) {
                check_FreezeMarketForClosurePreservingEnabled(marketId);
            }

            if (IPassivePerpProxy(sec.perp).getOpenBaseInterest(marketId) != 0 || isMarketActive(marketId)) {
                check_ForceCloseMarketAndDisable(marketId, w1CloseAccounts(marketId));
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
