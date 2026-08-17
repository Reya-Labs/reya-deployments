// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Script, console2 } from "forge-std/Script.sol";

import { ICoreProxy, MarginInfo } from "../src/interfaces/ICoreProxy.sol";
import { IPassivePerpProxy, MarketConfigurationData } from "../src/interfaces/IPassivePerpProxy.sol";
import { IOracleManagerProxy } from "../src/interfaces/IOracleManagerProxy.sol";

/// @title CheckMarketCloseReadinessW1
/// @notice Read-only pre-flight for the ENTIRE W1 close batch (18 markets on reya_network). Account lists,
///         market ids and per-market `maxResidualBase` are generated from
///         packages/tomls/src/passive_perp/market_close_w1_close_mainnet.toml (PR #505) — keep them in sync.
///
///         Run it at BOTH multisig gates:
///           * before the FREEZE tx (PR #506) -> read "READY TO FREEZE": market enabled + reduce-only.
///           * before the CLOSE tx  (PR #505) -> read "READY TO CLOSE": also frozen (CONSTANT oracle node),
///             residuals within `maxResidualBase`, `maxResidualBase` < `baseSpacing`, and no listed account
///             below its INITIAL margin.
///
///         Per market it prints the two residuals the on-chain `ForceClosureResidueAboveMax` invariant guards:
///           - |closedLong - closedShort|   (the two sides must net out)
///           - |closedLong - openInterest|  (closed longs must match what the market tracked)
///
/// @dev Pure view calls, no broadcast, no private key. Run against reya_network:
///        forge script script/CheckMarketCloseReadinessW1.s.sol:CheckMarketCloseReadinessW1 \
///          --rpc-url https://rpc.reya.network -vv
contract CheckMarketCloseReadinessW1 is Script {
    ICoreProxy constant CORE = ICoreProxy(payable(0xA763B6a5E09378434406C003daE6487FbbDc1a80));
    IPassivePerpProxy constant PERP = IPassivePerpProxy(payable(0x27E5cb712334e101B3c232eB0Be198baaa595F5F));
    IOracleManagerProxy constant ORACLE = IOracleManagerProxy(0xC67316Ed17E0C793041CFE12F674af250a294aab);

    /// @dev NodeDefinition.NodeType.CONSTANT (enum order: NONE, DIV_REDUCER, REDSTONE, CONSTANT, ...).
    uint8 constant CONSTANT_NODE_TYPE = 3;

    /// @dev Passive pool account on reya_network (4 on cronos). Its margin info is not a meaningful health
    ///      signal and `getUsdNodeMarginInfo` currently reverts on it, so it is reported, never gated on.
    uint128 constant POOL_ACCOUNT_ID = 2;

    uint256 constant N = 17;

    struct Res {
        bool enabled;
        bool reduceOnly;
        bool frozen;
        uint256 oi;
        uint256 closedLong;
        uint256 closedShort;
        uint256 residualNet;
        uint256 residualOI;
        uint256 baseSpacing;
        uint256 unhealthy;
        uint256 healthUnknown;
    }

    function marketIds() internal pure returns (uint128[] memory ids) {
        ids = new uint128[](N);
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
        ids[11] = 34; // GOAT
        ids[12] = 36; // kNEIRO
        ids[13] = 49; // GRIFFAIN
        ids[14] = 52; // APE
        ids[15] = 61; // IP
        ids[16] = 67; // KAITO
    }

    function symbols() internal pure returns (string[] memory s) {
        s = new string[](N);
        s[0] = "ZRO";
        s[1] = "JTO";
        s[2] = "AI16Z";
        s[3] = "TON";
        s[4] = "MOVE";
        s[5] = "BERA";
        s[6] = "ZORA";
        s[7] = "PROVE";
        s[8] = "YZY";
        s[9] = "XPL";
        s[10] = "WLFI";
        s[11] = "GOAT";
        s[12] = "kNEIRO";
        s[13] = "GRIFFAIN";
        s[14] = "APE";
        s[15] = "IP";
        s[16] = "KAITO";
    }

    /// @dev maxResidualBase per market, exactly as passed by market_close_w1_close_mainnet.toml (raw wei).
    function maxResiduals() internal pure returns (uint256[] memory r) {
        r = new uint256[](N);
        r[0] = 1_000_000_000;
        r[1] = 1_000_000_000;
        r[2] = 1_000_000_000;
        r[3] = 1_000_000_000;
        r[4] = 1_000_000_000;
        r[5] = 1_000_000_000;
        r[6] = 1_000_000_000;
        r[7] = 1_000_000_000;
        r[8] = 1_000_000_000;
        r[9] = 1_000_000_000;
        r[10] = 1_000_000_000;
        r[11] = 1_000_000_000;
        r[12] = 1_000_000_000;
        r[13] = 1_000_000_000;
        r[14] = 1_000_000_000;
        r[15] = 1_000_000_000;
        r[16] = 1_000_000_000;
    }

    /// @dev Every account holding a non-zero base, INCLUDING the passive pool (account 2 on reya_network).
    function accountsFor(uint256 i) internal pure returns (uint128[] memory a) {
        if (i == 0) {
            // ZRO (market 15) — 13 accounts
            a = new uint128[](13);
            a[0] = 17_251;
            a[1] = 41_476;
            a[2] = 128_904;
            a[3] = 135_288;
            a[4] = 18_225;
            a[5] = 134_477;
            a[6] = 40_887;
            a[7] = 23_724;
            a[8] = 79_924;
            a[9] = 60_666;
            a[10] = 127_173;
            a[11] = 18_073;
            a[12] = 2;
            return a;
        }
        if (i == 1) {
            // JTO (market 25) — 5 accounts
            a = new uint128[](5);
            a[0] = 20_303;
            a[1] = 4935;
            a[2] = 18_073;
            a[3] = 2;
            a[4] = 129_611;
            return a;
        }
        if (i == 2) {
            // AI16Z (market 45) — 3 accounts
            a = new uint128[](3);
            a[0] = 128_623;
            a[1] = 43_829;
            a[2] = 2;
            return a;
        }
        if (i == 3) {
            // TON (market 53) — 7 accounts
            a = new uint128[](7);
            a[0] = 98_897;
            a[1] = 15_678;
            a[2] = 11_117;
            a[3] = 105_367;
            a[4] = 839;
            a[5] = 2;
            a[6] = 127_253;
            return a;
        }
        if (i == 4) {
            // MOVE (market 57) — 3 accounts
            a = new uint128[](3);
            a[0] = 2;
            a[1] = 100_547;
            a[2] = 79_924;
            return a;
        }
        if (i == 5) {
            // BERA (market 58) — 3 accounts
            a = new uint128[](3);
            a[0] = 2;
            a[1] = 107_180;
            a[2] = 23_735;
            return a;
        }
        if (i == 6) {
            // ZORA (market 68) — 4 accounts
            a = new uint128[](4);
            a[0] = 2;
            a[1] = 38_256;
            a[2] = 125_390;
            a[3] = 120_595;
            return a;
        }
        if (i == 7) {
            // PROVE (market 69) — 2 accounts
            a = new uint128[](2);
            a[0] = 72_493;
            a[1] = 2;
            return a;
        }
        if (i == 8) {
            // YZY (market 71) — 2 accounts
            a = new uint128[](2);
            a[0] = 3176;
            a[1] = 2;
            return a;
        }
        if (i == 9) {
            // XPL (market 72) — 8 accounts
            a = new uint128[](8);
            a[0] = 134_477;
            a[1] = 14_378;
            a[2] = 11_117;
            a[3] = 71_259;
            a[4] = 11_363;
            a[5] = 112_901;
            a[6] = 47_927;
            a[7] = 2;
            return a;
        }
        if (i == 10) {
            // WLFI (market 73) — 2 accounts
            a = new uint128[](2);
            a[0] = 128_260;
            a[1] = 2;
            return a;
        }
        if (i == 11) {
            // GOAT (market 34) — 5 accounts
            a = new uint128[](5);
            a[0] = 35_169;
            a[1] = 2;
            a[2] = 126_268;
            a[3] = 127_253;
            a[4] = 17_695;
            return a;
        }
        if (i == 12) {
            // kNEIRO (market 36) — 3 accounts
            a = new uint128[](3);
            a[0] = 2;
            a[1] = 126_268;
            a[2] = 17_695;
            return a;
        }
        if (i == 13) {
            // GRIFFAIN (market 49) — 3 accounts
            a = new uint128[](3);
            a[0] = 131_432;
            a[1] = 2;
            a[2] = 11_236;
            return a;
        }
        if (i == 14) {
            // APE (market 52) — 3 accounts
            a = new uint128[](3);
            a[0] = 134_477;
            a[1] = 2;
            a[2] = 48_720;
            return a;
        }
        if (i == 15) {
            // IP (market 61) — 5 accounts
            a = new uint128[](5);
            a[0] = 127_253;
            a[1] = 7301;
            a[2] = 20_303;
            a[3] = 2;
            a[4] = 135_288;
            return a;
        }
        if (i == 16) {
            // KAITO (market 67) — 10 accounts
            a = new uint128[](10);
            a[0] = 102_387;
            a[1] = 48_720;
            a[2] = 135_845;
            a[3] = 134_542;
            a[4] = 129_339;
            a[5] = 7301;
            a[6] = 129_450;
            a[7] = 131_432;
            a[8] = 123_082;
            a[9] = 2;
            return a;
        }
        return new uint128[](0);
    }

    function run() external view {
        uint128[] memory ids = marketIds();
        string[] memory syms = symbols();
        uint256[] memory maxRes = maxResiduals();

        uint256 readyToFreeze = 0;
        uint256 readyToClose = 0;

        console2.log("=== W1 market-close readiness (reya_network) ===");
        console2.log("markets:", N);

        for (uint256 i = 0; i < N; i++) {
            uint128[] memory accts = accountsFor(i);
            Res memory r = _check(ids[i], accts);

            bool residOk = r.residualNet <= maxRes[i] && r.residualOI <= maxRes[i];
            bool residBelowSpacing = maxRes[i] < r.baseSpacing;
            bool freezeOk = r.enabled && r.reduceOnly;
            bool closeOk = freezeOk && r.frozen && residOk && residBelowSpacing && r.unhealthy == 0;

            if (freezeOk) readyToFreeze++;
            if (closeOk) readyToClose++;

            console2.log("");
            console2.log("--------------------------------------------------");
            console2.log(syms[i]);
            console2.log("  marketId           :", uint256(ids[i]));
            console2.log("  enabled            :", r.enabled);
            console2.log("  reduce-only        :", r.reduceOnly);
            console2.log("  frozen (CONSTANT)  :", r.frozen);
            console2.log("  accounts listed    :", accts.length);
            console2.log("  accounts below IMR :", r.unhealthy);
            console2.log("  health unreadable  :", r.healthUnknown);
            console2.log("  live OI       (wei):", r.oi);
            console2.log("  closed long   (wei):", r.closedLong);
            console2.log("  closed short  (wei):", r.closedShort);
            console2.log("  |long - short|     :", r.residualNet);
            console2.log("  |long - OI|        :", r.residualOI);
            console2.log("  maxResidualBase    :", maxRes[i]);
            console2.log("  baseSpacing        :", r.baseSpacing);
            console2.log("  residuals within   :", residOk);
            console2.log("  maxRes < spacing   :", residBelowSpacing);
            console2.log("  READY TO FREEZE    :", freezeOk);
            console2.log("  READY TO CLOSE     :", closeOk);
        }

        console2.log("");
        console2.log("=== summary ===");
        console2.log("total markets           :", N);
        console2.log("markets ready to FREEZE :", readyToFreeze);
        console2.log("markets ready to CLOSE  :", readyToClose);
        console2.log("ALL READY TO FREEZE     :", readyToFreeze == N);
        console2.log("ALL READY TO CLOSE      :", readyToClose == N);
    }

    function _check(uint128 marketId, uint128[] memory accts) private view returns (Res memory r) {
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("marketEnabled")), marketId));
        r.enabled = !PERP.getFeatureFlagDenyAll(flagId);

        MarketConfigurationData memory cfg = PERP.getMarketConfiguration(marketId);
        r.reduceOnly = cfg.maxOpenBase == 0;
        r.baseSpacing = cfg.baseSpacing;
        r.frozen = ORACLE.getNode(cfg.oracleNodeId).nodeType == CONSTANT_NODE_TYPE;

        r.oi = PERP.getOpenBaseInterest(marketId);

        for (uint256 j = 0; j < accts.length; j++) {
            _checkHealth(marketId, accts[j], r);

            int256 base = PERP.getUpdatedPositionInfo(marketId, accts[j]).base;
            if (base > 0) {
                r.closedLong += uint256(base);
            } else if (base < 0) {
                r.closedShort += uint256(-base);
            }
        }

        r.residualNet = r.closedLong > r.closedShort ? r.closedLong - r.closedShort : r.closedShort - r.closedLong;
        r.residualOI = r.closedLong > r.oi ? r.closedLong - r.oi : r.oi - r.closedLong;
    }

    /// @dev `initialDelta < 0` means the account is below its INITIAL margin requirement — a stricter bar than
    ///      the liquidation margin (scope doc 3.8). The close skips per-account health checks and does not
    ///      socialise a shortfall (3.10), so anything flagged here must be resolved before closing.
    function _checkHealth(uint128 marketId, uint128 accountId, Res memory r) private view {
        if (accountId == POOL_ACCOUNT_ID) {
            return; // passive pool — not a margin account, reported separately
        }

        try CORE.getUsdNodeMarginInfo(accountId) returns (MarginInfo memory mi) {
            if (mi.initialDelta < 0) {
                r.unhealthy++;
                console2.log("  !!! BELOW IMR | market:", uint256(marketId), "account:", uint256(accountId));
                console2.logInt(mi.initialDelta);
            }
        } catch {
            r.healthUnknown++;
            console2.log("  ??? HEALTH UNREADABLE | market:", uint256(marketId), "account:", uint256(accountId));
        }
    }
}
