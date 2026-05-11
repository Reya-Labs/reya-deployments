pragma solidity >=0.8.19 <0.9.0;

import { PerpFillForkCheck } from "../trade/PerpFill.fork.c.sol";
import "../DataTypes.sol";

import {
    ICoreProxy,
    CollateralConfig,
    ParentCollateralConfig,
    MarginInfo,
    CollateralInfo
} from "../../../src/interfaces/ICoreProxy.sol";

import { IPassivePerpProxy, PerpPosition } from "../../../src/interfaces/IPassivePerpProxy.sol";

import {
    IOrdersGatewayProxy,
    EIP712Signature,
    SignedMatchingEnginePayload
} from "../../../src/interfaces/IOrdersGatewayProxy.sol";
import {
    IOrdersGatewayProxyV2, OrderDetails, ExecuteFillInputV2
} from "../../../src/interfaces/IOrdersGatewayProxyV2.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

import { sd, SD59x18, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

/**
 * @title WethCollateralPerpOBForkCheck
 * @notice Fork tests for trading with wETH collateral in perpOB model
 * @dev Tests that wETH as collateral works correctly with fill-based execution.
 *      Legacy WethCollateralForkCheck is kept separately for cronos/mainnet.
 *
 *      Oracle architecture in perpOB:
 *        - Stork spot (ethUsdcStorkNodeId) -> wETH collateral valuation
 *        - Stork mark (ethUsdcStorkMarkNodeId) -> circuit breaker for pushed prices/fills
 *        - Pushed mark price (via pushMarkPrice) -> actual PnL and margin requirements
 */
contract WethCollateralPerpOBForkCheck is PerpFillForkCheck {
    /**
     * @notice Test trading ETH perp with wETH collateral (perfect hedge)
     * @dev Deposits enough wETH to perfectly hedge a short ETH position, accounting
     *      for the collateral haircut. Then verifies margin stability across price
     *      movements by updating all three oracle sources simultaneously:
     *        1. Stork spot oracle -> wETH collateral valuation
     *        2. Stork mark oracle -> circuit breaker consistency
     *        3. Pushed mark price -> PnL and margin requirements
     *
     *      Perfect hedge formula: wethAmount = shortSize / (1 - haircut)
     *      so that wethAmount * (1 - haircut) == shortSize, giving net delta = 0.
     */
    function check_WethTradeWithWethCollateral_PerpOB(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();

        uint256 entryPrice = 3000e18;

        // Mock Stork spot oracle (collateral valuation) and Stork mark oracle
        // (circuit breaker) to be consistent with pushed mark price BEFORE the fill.
        // mockFreshPrices() only covers market oracleNodeIds, not collateral oracles.
        mockFreshPrice(sec.ethUsdcStorkNodeId, entryPrice);
        mockFreshPrice(sec.ethUsdcStorkMarkNodeId, entryPrice);

        pushMarkPrice(marketId, entryPrice);
        pushFundingRate(marketId, 0);

        // Get haircut to calculate perfect hedge amount
        (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.weth);
        uint256 priceHaircut = parentCollateralConfig.priceHaircut;

        // Remove wETH collateral cap
        vm.prank(sec.multisig);
        collateralConfig.cap = type(uint256).max;
        ICoreProxy(sec.core).setCollateralConfig(1, sec.weth, collateralConfig, parentCollateralConfig);

        // Calculate wETH amount for a perfect hedge.
        // Effective collateral delta = wethAmount * (1 - haircut).
        // For delta-neutral: wethAmount * (1 - haircut) = shortSize
        //   -> wethAmount = shortSize / (1 - haircut)
        // This ensures marginBalance is constant across all price levels.
        uint256 shortSize = 10e18;
        uint256 wethAmount = shortSize * 1e18 / (1e18 - priceHaircut);

        uint128 shortAccountId = depositNewMA(perpBuyer, sec.weth, wethAmount);
        uint128 longAccountId = depositNewMA(perpSeller, sec.rusd, 100_000e6);

        // Open short position via fill at entry price.
        // perpBuyer -> short (wETH collateral), perpSeller -> long (rUSD collateral).
        {
            (OrderDetails memory longOrder, EIP712Signature memory longSig) = createLimitOrderPerp({
                accountId: longAccountId,
                marketId: marketId,
                baseDelta: int256(shortSize),
                price: entryPrice,
                nonce: 1,
                signer: perpSeller,
                signerPk: perpSellerPk
            });

            (OrderDetails memory shortOrder, EIP712Signature memory shortSig) = createLimitOrderPerp({
                accountId: shortAccountId,
                marketId: marketId,
                baseDelta: -int256(shortSize),
                price: entryPrice,
                nonce: 1,
                signer: perpBuyer,
                signerPk: perpBuyerPk
            });

            SignedMatchingEnginePayload memory mePayload = createPerpMatchingEnginePayload({
                price: entryPrice,
                baseDelta: shortSize,
                accountOrderId: 1,
                counterpartyOrderId: 2,
                nonce: 1
            });

            ExecuteFillInputV2 memory fillInput = ExecuteFillInputV2({
                accountOrder: longOrder,
                counterpartyOrder: shortOrder,
                accountSignature: longSig,
                counterpartySignature: shortSig,
                mePayload: mePayload
            });

            vm.prank(sec.coExecutionBot);
            IOrdersGatewayProxyV2(sec.ordersGateway).executeFill(fillInput);
        }

        // Verify short position opened
        PerpPosition memory shortPos = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, shortAccountId);
        assertEq(shortPos.base, -int256(shortSize), "Should be short");

        // Baseline margin (includes fee impact from fill)
        int256 marginBalance0 = ICoreProxy(sec.core).getNodeMarginInfo(shortAccountId, sec.rusd).marginBalance;

        // Test margin stability across price movements.
        // With perfect hedge, margin is invariant to price:
        //   collateralValue = wethAmount * price * (1-haircut) = shortSize * price
        //   unrealizedPnL   = -shortSize * (price - entryPrice)
        //   marginBalance   = shortSize * price - shortSize * (price - entryPrice)
        //                   = shortSize * entryPrice = constant
        uint256[] memory testPrices = new uint256[](4);
        testPrices[0] = 3000e18;
        testPrices[1] = 100_000e18;
        testPrices[2] = entryPrice - 10e18;
        testPrices[3] = entryPrice + 10e18;

        for (uint256 i = 0; i < testPrices.length; i++) {
            // Advance time so each pushed mark price has a fresh timestamp
            vm.warp(block.timestamp + 1);

            // 1. Stork spot oracle -> wETH collateral valuation
            mockFreshPrice(sec.ethUsdcStorkNodeId, testPrices[i]);

            // 2. Stork mark oracle -> circuit breaker for pushed prices
            mockFreshPrice(sec.ethUsdcStorkMarkNodeId, testPrices[i]);

            // 3. Pushed mark price -> actual PnL and margin requirements
            pushMarkPrice(marketId, testPrices[i]);

            int256 marginBalance1 = ICoreProxy(sec.core).getNodeMarginInfo(shortAccountId, sec.rusd).marginBalance;

            // Perfect hedge: margin should be stable across all prices.
            // Tolerance accounts for rounding and any margin requirement scaling.
            assertApproxEqAbsDecimal(marginBalance0, marginBalance1, 10e6, 6, "Hedged margin should be stable");
        }
    }
}
