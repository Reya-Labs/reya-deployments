// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Script, console2 } from "forge-std/Script.sol";

import { ICoreProxy, MarginInfo } from "../src/interfaces/ICoreProxy.sol";
import { IPassivePerpProxy } from "../src/interfaces/IPassivePerpProxy.sol";

/// @title CheckMarketCloseReadiness
/// @notice Read-only pre-flight check run immediately before `forceCloseMarket`, mirroring the runbook's Step-2/Step-3
///         fork checks (see agent-docs/market-close-scope.md §2). For a hardcoded market and account list it:
///
///           1. Account health — flags every account whose USD initial-margin delta is negative (i.e. below its
///              initial margin requirement). §3.8/§3.10: the close skips the per-account health check and does not
///              socialise shortfalls, so every account MUST be above margin at the locked price before closing.
///           2. Open interest — checks a hardcoded expected OI equals the market's live `getOpenBaseInterest`.
///           3. Dust — sums the closed long and short base across the accounts (exactly what `forceCloseMarket` does
///              internally) and prints the residuals the on-chain `ForceClosureResidueAboveMax` invariant guards:
///                - |closedLong - closedShort|  (the two sides must net out)
///                - |closedLong - openInterest|  (closed longs must match what the market tracked)
///              Use these to pick the exact `maxResidualBase` to pass to `forceCloseMarket`.
///
/// @dev Pure view calls — no broadcast needed. Run against a mainnet fork or live RPC:
///        forge script script/CheckMarketCloseReadiness.s.sol:CheckMarketCloseReadiness \
///          --rpc-url https://rpc.reya.network -vvv
///      The accounts array MUST cover every account holding a non-zero base in the market, including the passive pool.
contract CheckMarketCloseReadiness is Script {
    // Reya Network mainnet (chainId 1729).
    ICoreProxy constant CORE = ICoreProxy(payable(0xA763B6a5E09378434406C003daE6487FbbDc1a80));
    IPassivePerpProxy constant PERP = IPassivePerpProxy(payable(0x27E5cb712334e101B3c232eB0Be198baaa595F5F));

    // ---------------------------------------------------------------------------------------------
    // INPUTS — fill these in for the market being closed.
    // ---------------------------------------------------------------------------------------------

    /// @dev The market to be force-closed.
    uint128 constant MARKET_ID = 22; // e.g. kBONK — replace with the target market

    /// @dev Expected open interest (UD60x18, 1e18). Compared against the market's live OI.
    uint256 constant EXPECTED_OI = 0; // <-- hardcode the snapshotted OI

    /// @dev Maximum tolerated residue (UD60x18, 1e18) — the `maxResidualBase` you intend to pass to `forceCloseMarket`.
    ///      Both the net (long-short) and the OI residual must come in strictly below this. Must be < baseSpacing.
    uint256 constant MAX_RESIDUAL_BASE = 1e6;

    /// @dev Every account holding a non-zero base in the market, INCLUDING the passive pool account.
    function accountIds() internal pure returns (uint128[] memory ids) {
        ids = new uint128[](6);
        ids[0] = 21_229;
        ids[1] = 11_234;
        ids[2] = 105_367;
        ids[3] = 126_268;
        ids[4] = 2; // passive pool account
        ids[5] = 17_695;
    }

    function run() external view {
        uint128[] memory ids = accountIds();

        console2.log("=== Market close readiness check ===");
        console2.log("market id:", uint256(MARKET_ID));
        console2.log("accounts :", ids.length);

        // --- 1. account health: scream on anyone below their initial margin requirement ---
        console2.log("\n--- account health (initial margin) ---");
        uint256 unhealthy = 0;
        for (uint256 i = 0; i < ids.length; i++) {
            MarginInfo memory mi = CORE.getUsdNodeMarginInfo(ids[i]);
            // initialDelta = marginBalance - initialMarginRequirement; negative => below IMR.
            bool belowImr = mi.initialDelta < 0;
            if (belowImr) {
                unhealthy++;
                console2.log("  !!! BELOW IMR | account:", uint256(ids[i]));
                console2.log("      initialDelta (1e18):");
                console2.logInt(mi.initialDelta);
            } else {
                console2.log("  ok            | account:", uint256(ids[i]));
                console2.logInt(mi.initialDelta);
            }
        }
        console2.log("accounts below IMR:", unhealthy);

        // --- 2. open interest: hardcoded expected vs live market OI ---
        uint256 marketOI = PERP.getOpenBaseInterest(MARKET_ID);
        console2.log("\n--- open interest ---");
        console2.log("expected OI (1e18):", EXPECTED_OI);
        console2.log("market   OI (1e18):", marketOI);
        bool oiMatches = EXPECTED_OI == marketOI;
        console2.log("OI matches:", oiMatches);

        // --- 3. dust: sum closed long/short base, exactly as forceCloseMarket does ---
        int256 closedLong = 0;
        int256 closedShort = 0;
        console2.log("\n--- positions ---");
        for (uint256 i = 0; i < ids.length; i++) {
            int256 base = PERP.getUpdatedPositionInfo(MARKET_ID, ids[i]).base;
            console2.log("  account:", uint256(ids[i]));
            console2.logInt(base);
            if (base > 0) {
                closedLong += base;
            } else {
                closedShort += -base;
            }
        }

        int256 residualNet = _abs(closedLong - closedShort); // longs vs shorts must net out
        int256 residualOI = _abs(closedLong - int256(marketOI)); // closed longs must match market OI

        console2.log("\n--- dust ---");
        console2.log("closed long base  (1e18):");
        console2.logInt(closedLong);
        console2.log("closed short base (1e18):");
        console2.logInt(closedShort);
        console2.log("residual |long - short| (1e18):");
        console2.logInt(residualNet);
        console2.log("residual |long - OI|    (1e18):");
        console2.logInt(residualOI);
        console2.log("max residual base       (1e18):", MAX_RESIDUAL_BASE);

        bool dustOk = uint256(residualNet) < MAX_RESIDUAL_BASE && uint256(residualOI) < MAX_RESIDUAL_BASE;

        // --- summary ---
        console2.log("\n=== summary ===");
        console2.log("all accounts healthy:", unhealthy == 0);
        console2.log("OI matches expected :", oiMatches);
        console2.log("dust within max     :", dustOk);
        bool ready = unhealthy == 0 && oiMatches && dustOk;
        console2.log("READY TO FORCE CLOSE:", ready);
    }

    function _abs(int256 x) private pure returns (int256) {
        return x < 0 ? -x : x;
    }
}
