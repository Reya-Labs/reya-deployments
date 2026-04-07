pragma solidity >=0.8.19 <0.9.0;

import { PerpFillForkCheck } from "./PerpFill.fork.c.sol";

import {
    ICoreProxy,
    RiskMultipliers,
    MarginInfo,
    CollateralConfig,
    ParentCollateralConfig,
    CachedCollateralConfig
} from "../../../src/interfaces/ICoreProxy.sol";

import {
    IPassivePerpProxy,
    MarketConfigurationData,
    PerpPosition
} from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IOracleManagerProxy } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

/**
 * @title LeveragePerpOBForkCheck
 * @notice Fork tests for max leverage verification in perpOB model
 * @dev Opens a position via fill-based execution and checks that
 *      the achieved leverage matches expected risk matrix parameters.
 *      Legacy LeverageForkCheck is kept separately for cronos/mainnet.
 */
contract LeveragePerpOBForkCheck is PerpFillForkCheck {
    /**
     * @notice Test that max leverage is achievable for a given market
     * @param marketId The perp market ID
     * @param expectedLev The expected max leverage (18 decimal)
     * @param markPrice The mark price to push (18 decimal)
     * @param collateral The collateral token address
     */
    function check_trade_leverage_perpOB(
        uint128 marketId,
        uint256 expectedLev,
        uint256 markPrice,
        address collateral
    )
        internal
    {
        setupPerpTestActors();
        mockFreshPrices();

        // Push mark price and zero funding
        pushMarkPrice(marketId, markPrice);
        pushFundingRate(marketId, 0);

        // Remove collateral cap
        if (collateral == sec.usdc) {
            removeCollateralCap(sec.rusd);
        } else {
            try ICoreProxy(sec.core).getCollateralConfig(1, collateral) returns (
                CollateralConfig memory cfg, ParentCollateralConfig memory parentCfg, CachedCollateralConfig memory
            ) {
                if (cfg.cap < type(uint256).max) {
                    vm.prank(sec.multisig);
                    cfg.cap = type(uint256).max;
                    ICoreProxy(sec.core).setCollateralConfig(1, collateral, cfg, parentCfg);
                }
            } catch {
                // Collateral may not be configured in this pool — skip cap removal
            }
        }

        // Deposit generous collateral for both sides
        // Use smaller amounts for non-stablecoin collaterals to avoid arithmetic overflow
        uint8 decimals = ITokenProxy(collateral).decimals();
        uint256 amount = decimals <= 8 ? 1_000_000 * 10 ** decimals : 10 * 10 ** decimals;
        uint128 userAccountId = depositNewMA(perpBuyer, collateral, amount);
        uint128 counterpartyAccountId = depositNewMA(perpSeller, collateral, amount);

        // Open 1 unit long position
        executePerpFill({
            buyerAccountId: userAccountId,
            sellerAccountId: counterpartyAccountId,
            marketId: marketId,
            baseDelta: 1e18,
            price: markPrice,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        // Verify position
        PerpPosition memory pos = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, userAccountId);
        assertEq(pos.base, 1e18, "Position should be 1 unit long");

        // Check leverage = exposure / IMR
        RiskMultipliers memory riskMultipliers = ICoreProxy(sec.core).getRiskMultipliers(1);
        UD60x18 lmr = ud(ICoreProxy(sec.core).getUsdNodeMarginInfo(userAccountId).liquidationMarginRequirement);
        UD60x18 imr = lmr.mul(ud(riskMultipliers.imMultiplier));
        UD60x18 price = ud(markPrice);
        UD60x18 leverage = price.div(imr); // base=1, so exposure = price

        assertApproxEqAbsDecimal(leverage.unwrap(), expectedLev, 2e18, 18, "Leverage should match expected");
    }
}
