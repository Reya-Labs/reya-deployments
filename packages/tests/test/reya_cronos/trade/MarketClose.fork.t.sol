// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { MarketCloseForkCheck } from "../../reya_common/trade/MarketClose.fork.c.sol";

contract MarketCloseForkTest is ReyaForkTest, MarketCloseForkCheck {
    /// @notice The 17 markets frozen by the W1 close batch (10-14 Aug 2026) — Group 0 (reduce-only since June) plus
    ///         the RO batch announced on 6 Aug. Market ids are identical on cronos and reya_network.
    /// @dev Keep in sync with packages/tomls/src/passive_perp/configs/market_close_w1.toml.
    function w1FrozenMarkets() internal pure returns (uint128[] memory ids) {
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
        ids[13] = 46; // AIXBT
        ids[14] = 49; // GRIFFAIN
        ids[15] = 52; // APE
        ids[16] = 61; // IP
    }

    /// @dev Use this test as a script to check the full lifecycle of closing a market: reduce-only -> no-extend ->
    ///      freeze -> force close. Commented out because it actually unwinds every position and the account list is
    ///      deployment-specific — fill in a target market and the full set of accounts holding it before running.
    // function test_ForceClose_Market() public {
    //     uint128 marketId = <marketId>;
    //     uint128[] memory accountIds = new uint128[](0); // every account with a non-zero base, incl. the pool
    //     check_MarketCloseFullFlow(marketId, sec.passivePoolAccountId, accountIds);
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
    ///         the W1 batch has already frozen are skipped — `test_W1MarketsAreFrozen` covers those.
    function test_ReduceOnlyMarketsCanBeFrozen() public {
        for (uint128 marketId = 1; marketId <= lastMarketId(); marketId++) {
            if (isMarketActive(marketId) && isReduceOnly(marketId) && !isFrozen(marketId)) {
                check_FreezeMarketForClosure(marketId);
            }
        }
    }

    /// @notice The W1 batch actually landed: all 17 markets are pinned to a CONSTANT oracle node at a non-zero price
    ///         with funding rate and velocity at zero.
    function test_W1MarketsAreFrozen() public view {
        uint128[] memory frozenMarkets = w1FrozenMarkets();

        for (uint256 i = 0; i < frozenMarkets.length; i++) {
            check_MarketIsFrozen(frozenMarkets[i]);
        }
    }

    /// @notice Stage 3: every frozen market (waiting to be force-closed) can still be traded down — a reducing trade
    ///         against the pool leaves the funding rate, open interest and pool PnL intact (PnL only realizes).
    function test_FrozenMarketsCanBeReduced() public {
        uint128[] memory frozenMarkets = w1FrozenMarkets();

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
