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
 *      Legacy LiquidationForkCheck is kept separately for cronos/mainnet.
 */
contract LiquidationPerpOBForkCheck is PerpFillForkCheck {
    uint128 private liqUserAccountId;
    uint128 private liqLiquidatorAccountId;
    uint128 private backstopAccountId;

    function setupLiquidationTest(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();

        // Push initial mark price at $3000
        pushMarkPrice(marketId, 3000e18);
        pushFundingRate(marketId, 0); // zero funding to simplify

        // Create a backstop LP account for the collateral pool.
        // Backstop liquidation requires a funded account to absorb liquidated positions.
        // Devnet doesn't have a PassivePool linked to its Core, so we create one in-test.
        {
            (address backstopOwner,) = makeAddrAndKey("backstopOwner");
            backstopAccountId = depositNewMA(backstopOwner, sec.rusd, 100_000e6);

            vm.prank(backstopOwner);
            ICoreProxy(sec.core).activateFirstMarketForAccount(backstopAccountId, 1);

            vm.prank(sec.multisig);
            ICoreProxy(sec.core)
                .setBackstopLPConfig(
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
        // User goes long 1 ETH at $3000 (~$3000 exposure, $500 collateral = ~6x leverage)
        executePerpFill({
            buyerAccountId: liqUserAccountId,
            sellerAccountId: liqLiquidatorAccountId,
            marketId: marketId,
            baseDelta: 1e18,
            price: 3000e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        // Verify position opened
        PerpPosition memory userPos = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, liqUserAccountId);
        assertEq(userPos.base, 1e18, "User should be long 1 ETH");
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
        pushMarkPrice(marketId, 2565e18);
        mockFreshPrices();

        // Execute Dutch liquidation (perpSeller owns liqLiquidatorAccountId)
        {
            uint128[] memory marketIds = new uint128[](1);
            marketIds[0] = marketId;

            bytes[] memory inputs = new bytes[](1);
            inputs[0] = abi.encode(sd(-1e18), ud(0)); // close entire long

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
        pushMarkPrice(marketId, 2100e18);
        mockFreshPrices();

        // Record state before backstop
        PerpPosition memory userPosBefore =
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, liqUserAccountId);
        assertEq(userPosBefore.base, 1e18, "User should still be long 1 ETH before backstop");

        PerpPosition memory counterpartyPosBefore =
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, liqLiquidatorAccountId);
        assertEq(counterpartyPosBefore.base, -1e18, "Counterparty should be short 1 ETH before backstop");

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

        // In perpOB backstop, the counterparty is ADL'd (force-unwound).
        // The counterparty had short 1 ETH; after ADL, their position is also closed.
        {
            PerpPosition memory counterpartyPosAfter =
                IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, liqLiquidatorAccountId);
            assertEq(counterpartyPosAfter.base, 0, "Counterparty should be ADL'd to zero");

            // Counterparty realizes profit from the price drop (bought at 3000, closed below 3000)
            assertGt(counterpartyPosAfter.realizedPnL, 0, "Counterparty should have positive realized PnL");
        }
    }

    /**
     * @notice Test that a healthy account cannot be Dutch-liquidated
     * @dev Opens a position with ample margin, verifies Dutch liquidation reverts
     */
    function check_DutchLiquidation_RevertWhenHealthy_PerpOB(uint128 marketId) internal {
        setupLiquidationTest(marketId);

        // Keep price at $3000 — user has $500 collateral, 1 ETH long
        // LMR ≈ $3000 * 0.03077 ≈ $92. Margin = $500 >> $92. Account is healthy.

        // Attempt Dutch liquidation — should revert
        {
            uint128[] memory marketIds = new uint128[](1);
            marketIds[0] = marketId;

            bytes[] memory inputs = new bytes[](1);
            inputs[0] = abi.encode(sd(-1e18), ud(0));

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
            vm.expectRevert();
            ICoreProxy(sec.core).execute(liqLiquidatorAccountId, commands);
        }
    }
}
