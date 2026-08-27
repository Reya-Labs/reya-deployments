// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ReyaForkTest } from "../ReyaForkTest.sol";
import { ICoreProxy } from "../../../src/interfaces/ICoreProxy.sol";
import { IPassivePerpProxy, MarketConfigurationData } from "../../../src/interfaces/IPassivePerpProxy.sol";

/**
 * @title MarketMirrorForkTest
 * @notice Pins the mainnet market mirror: all 75 registered, only 30 able to
 *         take exposure.
 * @dev devnet mirrors mainnet's full market list on-chain so contract state
 *      matches production and id -> symbol resolves the same in both
 *      environments, but activates only a subset off-chain. The other 45 are
 *      held at maxOpenBase == 0, which is the contract's REDUCE-ONLY state:
 *      MarketCloseModule refuses to force-close a market unless it holds
 *      (MarketNotInReduceOnly), and Market.sol reverts once openInterest
 *      exceeds the cap. At zero, no exposure can be opened at all.
 *
 *      That invariant is the reason this file exists. A market that is
 *      registered but NOT meant to trade is indistinguishable from an
 *      activated one by every other readback -- same flags, same oracle node,
 *      same risk block -- so maxOpenBase is the only thing separating "mirrors
 *      mainnet" from "45 unintended venues". Nothing else in the suite would
 *      notice a stray non-zero cap.
 *
 *      Expected values mirror omnibus/reya_devnet.toml; when the activated set
 *      changes there, this file is the paired change.
 */
contract MarketMirrorForkTest is ReyaForkTest {
    /// Every mainnet perp market is registered on devnet, in mainnet id order.
    uint128 internal constant MAINNET_MARKET_COUNT = 75;

    /// Derived, not a window. The rule: every mainnet market that can still
    /// take exposure (maxOpenBase > 0 there), minus the two priced off a
    /// frozen constant node (30 FTM, 59 LAYER). 43 of mainnet's 75 markets are
    /// already reduce-only in production, so only 32 can take exposure at all
    /// -- which is why this lands on exactly 30 with no arbitrary cut.
    ///
    /// The ids therefore run past 30 (31 ENA through 74 LINEA); an "ids 1-30"
    /// window would silently drop eleven markets that CAN trade purely because
    /// of where their id sits. The ten mainnet already holds reduce-only
    /// (7, 9, 10, 14, 15, 17, 19, 21, 22, 25) are excluded by the rule itself.
    function activatedMarketIds() internal pure returns (uint128[] memory ids) {
        ids = new uint128[](30);
        uint128[30] memory raw = [
            uint128(1), // ETH
            2, // BTC
            3, // SOL
            4, // ARB
            5, // OP
            6, // AVAX
            8, // LINK
            11, // UNI
            12, // SUI
            13, // TIA
            16, // XRP
            18, // kPEPE
            20, // DOGE
            23, // APT
            24, // BNB
            26, // ADA
            27, // LDO
            28, // POL
            29, // NEAR
            31, // ENA
            33, // PENDLE
            35, // GRASS
            37, // DOT
            38, // LTC
            43, // HYPE
            50, // WLD
            62, // ME
            66, // AERO
            70, // PAXG
            74 // LINEA
        ];
        for (uint256 i = 0; i < raw.length; i++) {
            ids[i] = raw[i];
        }
    }

    function isActivated(uint128 marketId) internal pure returns (bool) {
        uint128[] memory ids = activatedMarketIds();
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == marketId) return true;
        }
        return false;
    }

    /// The mirror is complete: mainnet's whole market list exists on devnet.
    /// Reads Core's own counter rather than probing ids, so a partially
    /// applied deployment (cannon skips a failing step with a warning) fails
    /// here instead of silently leaving a short market list.
    function test_Devnet_MarketMirror_AllMainnetMarketsRegistered() public view {
        require(
            lastMarketId() == MAINNET_MARKET_COUNT,
            "market mirror: lastMarketId != 75 (mirror incomplete or a create step was skipped)"
        );
    }

    /// Every market carries an oracle node. The config-closure walk proves
    /// those nodes PRICE; this proves none was left unset, which is a
    /// cheaper and more specific failure to read when a settings block is
    /// missing.
    function test_Devnet_MarketMirror_EveryMarketHasAnOracleNode() public view {
        for (uint128 marketId = 1; marketId <= MAINNET_MARKET_COUNT; marketId++) {
            MarketConfigurationData memory cfg = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId);
            require(
                cfg.oracleNodeId != bytes32(0),
                string.concat("market mirror: zero oracle node for market ", vm.toString(uint256(marketId)))
            );
        }
    }

    /// No market may carry a zero Dutch liquidation floor.
    ///
    /// The perpOB router rejects it at config time (InvalidMarketConfiguration
    /// "DMINB"), but the reason is a liquidation property, not a config nit:
    /// the Dutch cap is max(|netBase|/lambda, minBase), so with no floor and
    /// lambda > 1 every bite is strictly smaller than the position it is taken
    /// from -- the position converges on a sub-baseSpacing residual that base
    /// alignment makes unclosable on that path entirely.
    ///
    /// Asserted across ALL mirrored markets, not just the activated ones: a
    /// reduce-only market still liquidates. Mainnet carries 0 for ids 1 and 2
    /// (its two oldest markets) and its router has no such validation, so this
    /// is exactly the value most likely to be copied in again by a future
    /// mirror.
    function test_Devnet_MarketMirror_NoZeroDutchFloor() public view {
        for (uint128 marketId = 1; marketId <= MAINNET_MARKET_COUNT; marketId++) {
            MarketConfigurationData memory cfg = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId);
            require(
                cfg.dutchConfig.minBase > 0,
                string.concat(
                    "market mirror: market ",
                    vm.toString(uint256(marketId)),
                    " has a zero Dutch minBase -- small positions become unclosable"
                )
            );
        }
    }

    /// THE invariant: exactly the activated 30 can take exposure, and every
    /// other mirrored market is in reduce-only.
    ///
    /// Both directions matter. A non-activated market with a non-zero cap is
    /// a venue nobody is watching -- no off-chain market config, no mark
    /// pusher entry, no ME book -- that can still accumulate on-chain
    /// exposure. An activated market pinned at zero is the opposite failure:
    /// it looks live and silently rejects every fill, which is how an earlier
    /// cut of the activated set went wrong (it was ranked by open interest,
    /// and OI persists in a wound-down market, so it selected 7 markets
    /// mainnet had already retired).
    function test_Devnet_MarketMirror_NonActivatedMarketsAreReduceOnly() public view {
        uint256 activatedSeen;

        for (uint128 marketId = 1; marketId <= MAINNET_MARKET_COUNT; marketId++) {
            uint256 maxOpenBase = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId).maxOpenBase;

            if (isActivated(marketId)) {
                require(
                    maxOpenBase > 0,
                    string.concat(
                        "market mirror: activated market ",
                        vm.toString(uint256(marketId)),
                        " is in reduce-only (maxOpenBase == 0) and will reject every fill"
                    )
                );
                activatedSeen++;
            } else {
                require(
                    maxOpenBase == 0,
                    string.concat(
                        "market mirror: NON-activated market ",
                        vm.toString(uint256(marketId)),
                        " can take exposure (maxOpenBase != 0) but has no off-chain config"
                    )
                );
            }
        }

        require(activatedSeen == 30, "market mirror: activated market count != 30");
    }
}
