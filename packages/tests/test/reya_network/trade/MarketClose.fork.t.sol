// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { MarketCloseForkCheck } from "../../reya_common/trade/MarketClose.fork.c.sol";

contract MarketCloseForkTest is ReyaForkTest, MarketCloseForkCheck {
    /// @dev Use this test as a script to check the full lifecycle of closing a market
    /// Full close flow for a market, e.g. market 22: reduce-only -> no-extend -> freeze -> force close. Commented out because
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

    /// @notice Stage 2: every market already in reduce-only (`maxOpenBase == 0`) can be frozen for closure.
    function test_ReduceOnlyMarketsCanBeFrozen() public {
        for (uint128 marketId = 1; marketId <= lastMarketId(); marketId++) {
            if (isMarketActive(marketId) && isReduceOnly(marketId)) {
                check_FreezeMarketForClosure(marketId);
            }
        }
    }

    /// @notice Stage 3: every frozen market (waiting to be force-closed) can still be traded down — a reducing trade
    ///         against the pool leaves the funding rate, open interest and pool PnL intact (PnL only realizes).
    function test_FrozenMarketsCanBeReduced() public {
        // TODO: populate with the markets currently frozen on-chain (oracle pinned to a CONSTANT node).
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
