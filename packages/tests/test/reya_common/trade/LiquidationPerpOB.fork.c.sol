pragma solidity >=0.8.19 <0.9.0;

import { PerpFillForkCheck } from "./PerpFill.fork.c.sol";
import {
    ICoreProxy,
    MarginInfo,
    Command as Command_Core,
    CommandType,
    DutchLiquidationInput,
    BackstopLPConfig
} from "../../../src/interfaces/ICoreProxy.sol";
import { IPassivePerpProxy, PerpPosition } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

/**
 * @title LiquidationPerpOBForkCheck
 * @notice Fork tests for liquidation in the perpOB model
 * @dev Uses fill-based position opening (executePerpFill) and oracle-pushed mark prices.
 *      Dutch liquidation: liquidator absorbs the position via execute() command.
 *      Backstop liquidation: uses ADL to close both the underwater account and its
 *      counterparty. The backstop LP provides insurance/fee coverage.
 *      Legacy LiquidationForkCheck remains only for non-PerpOB wrappers.
 */
contract LiquidationPerpOBForkCheck is PerpFillForkCheck {
    uint128 private liqUserAccountId;
    uint128 private liqLiquidatorAccountId;
    uint128 private backstopAccountId;

    function _testBase(uint128 marketId) private pure returns (uint256) {
        return marketId == 2 ? uint256(0.03e18) : uint256(1e18);
    }

    function _initialPrice(uint128 marketId) private pure returns (uint256) {
        return marketId == 2 ? 100_000e18 : 3000e18;
    }

    function _dutchPrice(uint128 marketId) private pure returns (uint256) {
        // BTC's carried risk configuration has a slightly wider liquidation
        // requirement than ETH. 84.9% puts the same ~$3k test position below LMR
        // while retaining positive ADL headroom at the pinned fork block.
        return _initialPrice(marketId) * (marketId == 2 ? 849 : 855) / 1000;
    }

    function _backstopPrice(uint128 marketId) private pure returns (uint256) {
        return _initialPrice(marketId) * 7 / 10;
    }

    function setupLiquidationTest(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();

        uint256 testBase = _testBase(marketId);
        uint256 initialPrice = _initialPrice(marketId);

        // Use the same ~$3,000 notional for ETH and BTC.
        pushMarkPriceWithinCollar(marketId, initialPrice);
        pushFundingRate(marketId, 0); // zero funding to simplify

        // Create a backstop LP account for the collateral pool.
        // Backstop liquidation requires a funded account to absorb liquidated positions.
        // Devnet doesn't have a PassivePool linked to its Core, so we create one in-test.
        {
            (address backstopOwner,) = makeAddrAndKey("backstopOwner");
            backstopAccountId = depositNewMA(backstopOwner, sec.rusd, 100_000e6);

            vm.prank(backstopOwner);
            ICoreProxy(sec.core).activateFirstMarketForAccount(backstopAccountId, marketId);

            vm.prank(sec.multisig);
            ICoreProxy(sec.core).setBackstopLPConfig(
                1,
                BackstopLPConfig({
                    accountId: backstopAccountId,
                    liquidationFee: 0.15e18,
                    minFreeCollateralThresholdInUSD: 0,
                    withdrawCooldownDurationInSeconds_DEPRECATED: 0,
                    withdrawDurationInSeconds_DEPRECATED: 0
                })
            );
        }

        // Create accounts for perpBuyer (user to be liquidated) and perpSeller (counterparty / liquidator).
        // executePerpFill signs orders with perpBuyer/perpSeller keys, so account owners must match.
        liqUserAccountId = depositNewMA(perpBuyer, sec.rusd, 500e6);
        liqLiquidatorAccountId = depositNewMA(perpSeller, sec.rusd, 50_000e6);

        // Open a leveraged long position for the user via fill
        // User goes long ~$3,000 notional ($500 collateral = ~6x leverage).
        executePerpFill({
            buyerAccountId: liqUserAccountId,
            sellerAccountId: liqLiquidatorAccountId,
            marketId: marketId,
            baseDelta: testBase,
            price: initialPrice,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        // Verify position opened
        PerpPosition memory userPos = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, liqUserAccountId);
        assertEq(userPos.base, int256(testBase), "User should hold the expected long base");
    }

    /**
     * @notice Test Dutch liquidation in perpOB model
     * @dev Opens leveraged long, drops price to make account underwater,
     *      executes Dutch liquidation to transfer position to liquidator
     */
    function check_DutchLiquidation_PerpOB(uint128 marketId) internal {
        setupLiquidationTest(marketId);

        // Drop mark price to make user eligible for Dutch liquidation (but NOT below ADL threshold).
        // User has $500 collateral, long 1 ETH from $3000.
        // LMR ≈ P * 0.03077, ADL threshold = LMR * 0.65.
        // At $2565: PnL = -$435, remaining margin ≈ $65 — below LMR (~$79) but above ADL (~$51).
        uint256 testBase = _testBase(marketId);
        pushMarkPriceWithinCollar(marketId, _dutchPrice(marketId));
        mockFreshPrices();

        // Execute Dutch liquidation (perpSeller owns liqLiquidatorAccountId)
        {
            uint128[] memory marketIds = new uint128[](1);
            marketIds[0] = marketId;

            bytes[] memory inputs = new bytes[](1);
            inputs[0] = abi.encode(sd(-int256(testBase)), ud(0)); // close entire long

            Command_Core[] memory commands = new Command_Core[](1);
            commands[0] = Command_Core({
                commandType: uint8(CommandType.DutchLiquidation),
                inputs: abi.encode(
                    DutchLiquidationInput({
                        liquidatableAccountId: liqUserAccountId,
                        quoteCollateral: sec.rusd,
                        marketIds: marketIds,
                        inputs: inputs
                    })
                ),
                marketId: 0,
                exchangeId: 0
            });

            vm.prank(perpSeller);
            ICoreProxy(sec.core).execute(liqLiquidatorAccountId, commands);
        }

        // Verify post-liquidation state
        // User should have no position
        {
            MarginInfo memory userMargin = ICoreProxy(sec.core).getUsdNodeMarginInfo(liqUserAccountId);
            assertEq(userMargin.liquidationMarginRequirement, 0, "User LMR should be zero after liquidation");

            PerpPosition memory userPos = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, liqUserAccountId);
            assertEq(userPos.base, 0, "User position should be closed");
        }

        // Liquidator absorbed the user's long 1 ETH into their existing short 1 ETH → net 0.
        // This is correct: the positions cancel out.
        {
            PerpPosition memory liqPos =
                IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, liqLiquidatorAccountId);
            assertEq(liqPos.base, 0, "Liquidator position should net to zero");
        }
    }

    /**
     * @notice Test backstop liquidation in perpOB model
     * @dev In perpOB, backstop liquidation uses ADL (auto-deleveraging):
     *      - The underwater account's position is closed
     *      - The profitable counterparty is force-unwound (ADL'd)
     *      - The backstop LP account provides insurance/fee coverage
     *      - The keeper account receives a liquidation fee
     *      Unlike AMM-based backstop, no pool absorbs the position — both sides are closed.
     */
    function check_BackstopLiquidation_PerpOB(uint128 marketId) internal {
        setupLiquidationTest(marketId);

        // Drop price severely to trigger backstop eligibility
        // At $2100: unrealized PnL = -$900, total margin ~= -$400 -> deeply underwater
        uint256 testBase = _testBase(marketId);
        pushMarkPriceWithinCollar(marketId, _backstopPrice(marketId));
        mockFreshPrices();

        // Record state before backstop
        PerpPosition memory userPosBefore =
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, liqUserAccountId);
        assertEq(userPosBefore.base, int256(testBase), "User should still hold the long before backstop");

        PerpPosition memory counterpartyPosBefore =
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, liqLiquidatorAccountId);
        assertEq(
            counterpartyPosBefore.base,
            -int256(testBase),
            "Counterparty should hold the offsetting short before backstop"
        );

        // Snapshot market open interest before the backstop. ADL socializes the liquidated base
        // across ALL opposite-side OI proportionally — `ADL.sol::computeADLParams` computes
        // `adlMultiplier = |liquidatedBase| / openInterest`, scaling every short by `(1 - adlMultiplier)`.
        // This fork runs against LIVE devnet state, so `openInterest` includes positions beyond this
        // test's counterparty; the counterparty is therefore only PARTIALLY deleveraged, not fully to
        // zero. Asserting hard `== 0` only holds when the counterparty is the sole OI (see PRO-157).
        uint256 oiBeforeBackstop = IPassivePerpProxy(sec.perp).getMarketData(marketId).marketData.openInterest;

        // Execute backstop liquidation — keeper is perpSeller's account
        vm.prank(perpSeller);
        ICoreProxy(sec.core).executeBackstopLiquidation(liqUserAccountId, liqLiquidatorAccountId, sec.rusd, 1e18);

        // Verify user position is fully closed
        {
            MarginInfo memory userMargin = ICoreProxy(sec.core).getUsdNodeMarginInfo(liqUserAccountId);
            assertEq(userMargin.liquidationMarginRequirement, 0, "User LMR should be zero after backstop");

            PerpPosition memory userPos = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, liqUserAccountId);
            assertEq(userPos.base, 0, "User position should be closed");
        }

        // In perpOB backstop, the counterparty is ADL'd (force-unwound) — proportional to OI.
        {
            PerpPosition memory counterpartyPosAfter =
                IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, liqLiquidatorAccountId);

            // Expected residual = counterpartyBase × (1 − adlMultiplier)
            //                   = counterpartyBase × (openInterest − liquidatedBase) / openInterest,
            // where liquidatedBase is the user's long (1e18) closed by the backstop. On a pristine
            // market (counterparty == sole OI) this is exactly 0; with other OI present it's a residual.
            int256 expectedCounterpartyBase =
                counterpartyPosBefore.base * (int256(oiBeforeBackstop) - userPosBefore.base) / int256(oiBeforeBackstop);
            assertApproxEqAbs(
                counterpartyPosAfter.base,
                expectedCounterpartyBase,
                testBase / 1000,
                // Fork OI includes live accounts; allow 0.1% of the test base for proportional rounding.
                "Counterparty should be ADL'd proportional to market OI"
            );

            // At the live fork's OI the proportional close is small enough for realized PnL to
            // round to zero. It must never turn the profitable short into a realized loss.
            assertGe(counterpartyPosAfter.realizedPnL, 0, "Counterparty should not realize a loss");
        }
    }

    /**
     * @notice Test that a healthy account cannot be Dutch-liquidated
     * @dev Opens a position with ample margin, verifies Dutch liquidation reverts
     */
    function check_DutchLiquidation_RevertWhenHealthy_PerpOB(uint128 marketId) internal {
        setupLiquidationTest(marketId);

        uint256 testBase = _testBase(marketId);

        // Keep the initial price — user has $500 collateral and ~$3,000 notional.
        // LMR ≈ $3000 * 0.03077 ≈ $92. Margin = $500 >> $92. Account is healthy.

        // Attempt Dutch liquidation — should revert
        {
            uint128[] memory marketIds = new uint128[](1);
            marketIds[0] = marketId;

            bytes[] memory inputs = new bytes[](1);
            inputs[0] = abi.encode(sd(-int256(testBase)), ud(0));

            Command_Core[] memory commands = new Command_Core[](1);
            commands[0] = Command_Core({
                commandType: uint8(CommandType.DutchLiquidation),
                inputs: abi.encode(
                    DutchLiquidationInput({
                        liquidatableAccountId: liqUserAccountId,
                        quoteCollateral: sec.rusd,
                        marketIds: marketIds,
                        inputs: inputs
                    })
                ),
                marketId: 0,
                exchangeId: 0
            });

            vm.prank(perpSeller);
            try ICoreProxy(sec.core).execute(liqLiquidatorAccountId, commands) {
                revert("Expected AccountAboveLm revert for healthy account");
            } catch (bytes memory revertData) {
                assertEq(bytes4(revertData), ICoreProxy.AccountAboveLm.selector, "Should revert with AccountAboveLm");
            }
        }
    }

    /**
     * @notice Test that backstop liquidation (ADL) reverts when account is above ADL threshold
     * @dev Account is in Dutch liquidation territory (below LMR but above ADL).
     *      Backstop/ADL should only be available for deeply underwater accounts below ADL threshold.
     */
    function check_BackstopLiquidation_RevertAboveAdl_PerpOB(uint128 marketId) internal {
        setupLiquidationTest(marketId);

        // Drop price to Dutch territory (below LMR but above ADL threshold)
        // Same price as Dutch test: $2565
        // PnL = -$435, remaining margin ≈ $65 — below LMR (~$79) but above ADL (~$51)
        pushMarkPriceWithinCollar(marketId, _dutchPrice(marketId));
        mockFreshPrices();

        // Verify account IS eligible for Dutch liquidation (sanity check)
        MarginInfo memory margin = ICoreProxy(sec.core).getUsdNodeMarginInfo(liqUserAccountId);
        assertLt(margin.liquidationDelta, 0, "Account should be below LMR");
        assertGt(margin.adlDelta, 0, "Account should be above ADL threshold");

        // Backstop should revert — account is not deeply underwater enough for ADL
        vm.prank(perpSeller);
        try ICoreProxy(sec.core).executeBackstopLiquidation(liqUserAccountId, liqLiquidatorAccountId, sec.rusd, 1e18) {
            revert("Expected AccountAboveAdl revert");
        } catch (bytes memory revertData) {
            assertEq(bytes4(revertData), ICoreProxy.AccountAboveAdl.selector, "Should revert with AccountAboveAdl");
        }
    }
}
