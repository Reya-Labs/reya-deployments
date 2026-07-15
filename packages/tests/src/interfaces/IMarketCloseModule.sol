// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18 } from "@prb/math/UD60x18.sol";

/**
 * @title Passive Perp Market Closure interface (subset used by fork checks).
 * @notice The two owner/multisig levers that wind a perp market down to zero open interest at a single locked price:
 *         `freezeMarketForClosure` (price + funding freeze) and `forceCloseMarket` (single-sided unwind against
 *         account 0). The new module carries no dust/sink account — each account is settled directly — so position
 *         reads use the standard `IPassivePerpProxy.getUpdatedPositionInfo`.
 * @dev Cast the upgraded passive-perp proxy address to this interface (the proxy already bundles `MarketCloseModule`).
 */
interface IMarketCloseModule {
    /// @notice Snapshots the live oracle price into a CONSTANT node, rewires the market's `oracleNodeId` to it, and
    ///         freezes funding at zero. Requires the market enabled, in reduce-only mode, and the caller to be owner.
    function freezeMarketForClosure(uint128 marketId) external;

    /// @notice Unwinds every `accountIds` position single-sidedly against account 0 at the locked close price, then
    ///         resets funding/open-interest. `accountIds` must cover every account with a non-zero base (incl. the
    ///         passive pool). Reverts with `ForceClosureResidueAboveMax` unless closed longs/shorts balance and match
    ///         the snapshotted open interest, each within `maxResidualBase` (which must be `< baseSpacing`).
    ///         Owner-only.
    function forceCloseMarket(uint128 marketId, uint128[] calldata accountIds, UD60x18 maxResidualBase) external;
}
