// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import { console2 } from "forge-std/console2.sol";

import { IPassivePerpProxy, MarketConfigurationData, PnLComponents } from "../../../src/interfaces/IPassivePerpProxy.sol";
import { ICoreProxy, Command as Command_Core } from "../../../src/interfaces/ICoreProxy.sol";
import { IMarketCloseModule } from "../../../src/interfaces/IMarketCloseModule.sol";
import { IOracleManagerProxy } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18, ZERO as ZERO_ud } from "@prb/math/UD60x18.sol";

/**
 * @title Market-close fork check.
 * @notice Exercises the two-phase, owner/multisig-driven market closure on a mainnet fork. The flow is split into one
 *         check function per stage so each can be run independently against whatever stage a market currently sits at:
 *
 *           1. {check_EnterReduceOnly}        — set `maxOpenBase = 0` (Phase A) and prove an OI-increasing order
 *                                               against the pool reverts.
 *           2. {check_FreezeMarketForClosure} — snapshot the price into a CONSTANT node, freeze funding (Phase B.1),
 *                                               and assert funding is pinned to zero and the oracle node is CONSTANT.
 *           3. {check_ForceClose}             — unwind a fixed account list against account 0 (Phase B.2) and assert
 *                                               the market is emptied (OI zero, every base zero, funding state reset).
 *
 *         {check_MarketCloseFullFlow} chains all three for a market that is still live. {check_OnlyOwnerCanFreeze} and
 *         {check_OnlyOwnerCanForceClose} assert the access control on the two levers.
 *
 * @dev Assumes the passive-perp proxy has already been upgraded to bundle `MarketCloseModule`; the levers are called
 *      directly on `sec.perp` cast to {IMarketCloseModule}. The new module settles each account directly against
 *      account 0 — there is no dust/sink account — so position reads use the standard `getUpdatedPositionInfo`.
 */
contract MarketCloseForkCheck is BaseReyaForkTest {
    /// @dev `NodeDefinition.NodeType.CONSTANT` (enum order: NONE, DIV_REDUCER, REDSTONE, CONSTANT, ...).
    uint8 private constant CONSTANT_NODE_TYPE = 3;

    /// @notice True if `marketId` is in reduce-only mode (`maxOpenBase == 0`) — i.e. waiting to be frozen/closed.
    function isReduceOnly(uint128 marketId) internal view returns (bool) {
        return IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId).maxOpenBase == 0;
    }

    // ----------------------------------------------------------------------------------------------------------------
    // Phase A — reduce-only
    // ----------------------------------------------------------------------------------------------------------------

    /// @notice Flip `marketId` into reduce-only mode (`maxOpenBase = 0`) and prove no OI-increasing order can follow.
    function check_EnterReduceOnly(uint128 marketId, uint128 poolAccountId) internal {
        MarketConfigurationData memory cfg = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId);
        cfg.maxOpenBase = 0;

        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).setMarketConfiguration(marketId, cfg);

        assertEq(
            IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId).maxOpenBase, 0, "market is not reduce-only"
        );

        // On a reduce-only market, any order that increases open interest must revert. A fresh (flat) account trades
        // against the pool on the side that grows OI: pool long -> user sells; pool short or flat -> user buys (when
        // the pool is flat, either direction increases OI). The order is only asserted to revert, so no residual
        // position is left behind that would later corrupt the force-close account set.
        mockFreshPrices();

        int256 poolBase = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, poolAccountId).base;
        int256 unit = int256(cfg.minimumOrderBase);

        (address user,) = makeAddrAndKey(string.concat("userNoExtend_", vm.toString(marketId)));
        uint128 accountId = depositNewMA(user, sec.usdc, 1_000_000e6);

        SD59x18 increaseBase = poolBase > 0 ? sd(-unit) : sd(unit);
        UD60x18 increasePriceLimit = poolBase > 0 ? ud(0) : ud(1_000_000_000e18);

        Command_Core[] memory commands = new Command_Core[](1);
        commands[0] = getMatchOrderCoreCommand(marketId, increaseBase, increasePriceLimit);
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(IPassivePerpProxy.OpenInterestExceeded.selector, marketId));
        ICoreProxy(sec.core).execute(accountId, commands);
    }

    /// @notice Lock the close price (rewire the oracle to a CONSTANT node) and freeze funding. Owner-only.
    function check_FreezeMarketForClosure(uint128 marketId) internal {
        // The freeze snapshots the live oracle price and enforces the staleness window; keep the feed fresh on-fork.
        mockFreshPrices();

        vm.prank(sec.multisig);
        IMarketCloseModule(sec.perp).freezeMarketForClosure(marketId);

        assertEq(IPassivePerpProxy(sec.perp).getLatestFundingRate(marketId), 0, "funding rate not zero after freeze");
        assertEq(IPassivePerpProxy(sec.perp).getFundingVelocity(marketId), 0, "funding velocity not zero after freeze");

        // The price must now be pinned to a CONSTANT oracle node.
        bytes32 nodeId = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId).oracleNodeId;

        uint8 nodeType = IOracleManagerProxy(sec.oracleManager).getNode(nodeId).nodeType;
        assertEq(uint256(nodeType), uint256(CONSTANT_NODE_TYPE), "oracle node is not CONSTANT after freeze");

        uint256 priceBefore = IOracleManagerProxy(sec.oracleManager).process(nodeId).price;
        assertGt(priceBefore, 0, "constant oracle price is zero");
    }

    /// @notice A frozen market can still be wound down: positions remain reducible. A fresh account trades against the
    ///         pool to shrink the pool's base by one unit, and afterwards:
    ///           - the funding rate has not moved (it stays frozen at zero);
    ///           - open interest is unchanged — the base was transferred from the pool to the new account, not opened
    ///             net-new (OI counts long base on both sides, so a reduce against the pool nets to zero delta);
    ///           - the pool's total PnL is conserved: letting time pass accrues nothing (price and funding are frozen)
    ///             and the locked-price trade only realizes PnL (moves it out of unrealized), up to the small
    ///             pool-favourable slippage the pool pockets on the unit it closed.
    /// @dev Assumes `marketId` has already been frozen (oracle pinned to a CONSTANT node).
    function check_FrozenMarketPositionsCanBeReduced(uint128 marketId, uint128 poolAccountId) internal {
        mockFreshPrices();
        _assertFrozen(marketId);

        FrozenReduceSnapshot memory snap = _snapshotPool(marketId, poolAccountId);
        if (snap.poolBase == 0) {
            return; // nothing to reduce
        }

        // Let time pass: with price and funding frozen, nothing should accrue to the pool's PnL.
        vm.warp(block.timestamp + 1 days);
        mockFreshPrices(); // refresh the (mocked) collateral/oracle timestamps for the post-warp trade
        PnLComponents memory afterWarp = IPassivePerpProxy(sec.perp).getAccountPnLComponents(marketId, poolAccountId);
        assertEq(
            afterWarp.realizedPnL + afterWarp.unrealizedPnL, snap.totalPnLBefore, "frozen market accrued PnL over time"
        );

        _reducePoolByOneUnit(marketId, poolAccountId, snap.poolBase);

        // Funding rate / velocity did not move (still frozen at zero) ...
        assertEq(
            IPassivePerpProxy(sec.perp).getLatestFundingRate(marketId), snap.frBefore, "funding rate moved on frozen market"
        );
        assertEq(IPassivePerpProxy(sec.perp).getFundingVelocity(marketId), 0, "funding velocity moved on frozen market");

        // ... open interest is unchanged (base transferred from pool to the new account, not opened net-new) ...
        assertEq(
            IPassivePerpProxy(sec.perp).getOpenBaseInterest(marketId),
            snap.oiBefore,
            "open interest changed on a reducing trade"
        );

        // ... and the pool's total PnL is conserved: the locked-price trade only realizes PnL, within a small tolerance
        //     for the pool-favourable slippage it pockets on the unit it closed. Realization also shrinks |unrealized|.
        PnLComponents memory afterTrade = IPassivePerpProxy(sec.perp).getAccountPnLComponents(marketId, poolAccountId);
        assertApproxEqAbsDecimal(
            afterTrade.realizedPnL + afterTrade.unrealizedPnL,
            snap.totalPnLBefore,
            1e6,
            6,
            "pool total PnL changed beyond realization"
        );
        assertLe(
            _abs(afterTrade.unrealizedPnL),
            _abs(snap.unrealizedBefore),
            "pool unrealized PnL did not shrink on realization"
        );
    }

    /// @dev Snapshot of the pool's frozen-market state taken before the reducing trade.
    struct FrozenReduceSnapshot {
        int256 poolBase;
        int256 frBefore;
        uint256 oiBefore;
        int256 unrealizedBefore;
        int256 totalPnLBefore;
    }

    /// @dev Reverts unless `marketId`'s oracle is pinned to a CONSTANT node (i.e. the market has been frozen).
    function _assertFrozen(uint128 marketId) private view {
        bytes32 nodeId = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId).oracleNodeId;
        assertEq(
            uint256(IOracleManagerProxy(sec.oracleManager).getNode(nodeId).nodeType),
            uint256(CONSTANT_NODE_TYPE),
            "market is not frozen"
        );
    }

    function _snapshotPool(
        uint128 marketId,
        uint128 poolAccountId
    )
        private
        view
        returns (FrozenReduceSnapshot memory snap)
    {
        PnLComponents memory pnl = IPassivePerpProxy(sec.perp).getAccountPnLComponents(marketId, poolAccountId);
        snap = FrozenReduceSnapshot({
            poolBase: IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, poolAccountId).base,
            frBefore: IPassivePerpProxy(sec.perp).getLatestFundingRate(marketId),
            oiBefore: IPassivePerpProxy(sec.perp).getOpenBaseInterest(marketId),
            unrealizedBefore: pnl.unrealizedPnL,
            totalPnLBefore: pnl.realizedPnL + pnl.unrealizedPnL
        });
    }

    /// @dev A fresh account trades against the pool to shrink its base by one `minimumOrderBase` unit toward zero:
    ///      pool long -> user buys; pool short -> user sells. Asserts the pool base actually moved by that unit.
    function _reducePoolByOneUnit(uint128 marketId, uint128 poolAccountId, int256 poolBase) private {
        int256 unit = int256(IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId).minimumOrderBase);
        int256 reduceBase = poolBase > 0 ? unit : -unit;

        (address user,) = makeAddrAndKey(string.concat("userReduceFrozen_", vm.toString(marketId)));
        uint128 accountId = depositNewMA(user, sec.usdc, 1_000_000e6);

        executeCoreMatchOrder({
            marketId: marketId,
            sender: user,
            base: sd(reduceBase),
            priceLimit: poolBase > 0 ? ud(1_000_000_000e18) : ud(0),
            accountId: accountId
        });

        int256 poolBaseAfter = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, poolAccountId).base;
        assertEq(poolBaseAfter, poolBase - reduceBase, "pool base was not reduced by the traded unit");
    }

    function _abs(int256 x) private pure returns (int256) {
        return x < 0 ? -x : x;
    }

    /// @notice Force-close `marketId` against `accountIds` (which must cover every account with a non-zero base,
    ///         including the passive pool). Asserts the market is fully emptied: open interest and every passed base
    ///         go to zero, and the funding state is reset.
    function check_ForceClose(uint128 marketId, uint128[] memory accountIds) internal {
        // Tolerated residue: the close reverts with `ForceClosureResidueAboveMax` if the unwound longs/shorts and the
        // snapshotted open interest disagree by more than this. The production runbook must compute the exact dust;
        // this fixed bound just flags a materially incomplete account list on the fork.
        UD60x18 maxResidualBase = ud(1e6);

        // --- pre-close observation ---
        console2.log("market id:", marketId);
        console2.log("locked close price (1e18):", getMarketSpotPrice(marketId).unwrap());
        console2.log("OI before force close (1e18):", IPassivePerpProxy(sec.perp).getOpenBaseInterest(marketId));
        for (uint256 i = 0; i < accountIds.length; i++) {
            console2.log("  pre-close base | account:", accountIds[i]);
            console2.logInt(IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountIds[i]).base);
        }

        vm.prank(sec.multisig);
        IMarketCloseModule(sec.perp).forceCloseMarket(marketId, accountIds, maxResidualBase);

        // --- post-close assertions: market emptied, every base zero, funding state reset ---
        uint256 oiAfter = IPassivePerpProxy(sec.perp).getOpenBaseInterest(marketId);
        console2.log("OI after force close (1e18):", oiAfter);
        assertEq(oiAfter, 0, "OI not zero after force close");

        for (uint256 i = 0; i < accountIds.length; i++) {
            int256 baseAfter = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, accountIds[i]).base;
            assertEq(baseAfter, 0, "account base not zero after force close");
        }

        assertEq(IPassivePerpProxy(sec.perp).getLatestFundingRate(marketId), 0, "funding rate not zero after close");
        assertEq(IPassivePerpProxy(sec.perp).getFundingVelocity(marketId), 0, "funding velocity not zero after close");
    }

    // ----------------------------------------------------------------------------------------------------------------
    // Orchestration
    // ----------------------------------------------------------------------------------------------------------------

    /// @notice End-to-end close of a still-live market: reduce-only -> no-extend -> freeze -> assert frozen -> close.
    function check_MarketCloseFullFlow(
        uint128 marketId,
        uint128 poolAccountId,
        uint128[] memory accountIds
    )
        internal
    {
        check_EnterReduceOnly(marketId, poolAccountId);
        check_FreezeMarketForClosure(marketId);
        check_ForceClose(marketId, accountIds);
    }

    // ----------------------------------------------------------------------------------------------------------------
    // Access control
    // ----------------------------------------------------------------------------------------------------------------

    /// @notice Only the owner may freeze a market for closure; a non-owner reverts with `Unauthorized`. The market is
    ///         enabled (the only-owner gate is checked before reduce-only state), so this holds in any market stage.
    function check_OnlyOwnerCanFreeze(uint128 marketId, address attacker) internal {
        assertTrue(attacker != IPassivePerpProxy(sec.perp).owner(), "attacker must not be the owner");

        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(IPassivePerpProxy.Unauthorized.selector, attacker));
        IMarketCloseModule(sec.perp).freezeMarketForClosure(marketId);
    }

    /// @notice Only the owner may force-close a market; a non-owner reverts with `Unauthorized`.
    function check_OnlyOwnerCanForceClose(uint128 marketId, address attacker) internal {
        assertTrue(attacker != IPassivePerpProxy(sec.perp).owner(), "attacker must not be the owner");

        uint128[] memory accountIds = new uint128[](0);
        vm.prank(attacker);
        vm.expectRevert(abi.encodeWithSelector(IPassivePerpProxy.Unauthorized.selector, attacker));
        IMarketCloseModule(sec.perp).forceCloseMarket(marketId, accountIds, ZERO_ud);
    }
}
