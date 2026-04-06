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
    ConditionalOrderDetails,
    EIP712Signature,
    ExecuteFillInput,
    SignedMatchingEnginePayload,
    LimitOrderPerpDetails,
    OrderType
} from "../../../src/interfaces/IOrdersGatewayProxy.sol";

import { IOracleManagerProxy, NodeOutput } from "../../../src/interfaces/IOracleManagerProxy.sol";

import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";

import { sd, SD59x18, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

/**
 * @title WethCollateralPerpOBForkCheck
 * @notice Fork tests for trading with wETH collateral in perpOB model
 * @dev Tests that wETH as collateral works correctly with fill-based execution.
 *      Legacy WethCollateralForkCheck is kept separately for cronos/mainnet.
 */
contract WethCollateralPerpOBForkCheck is PerpFillForkCheck {
    /**
     * @notice Test trading ETH perp with wETH collateral
     * @dev Deposits wETH, opens a short ETH position via fill, verifies margin.
     *      Short ETH + hold wETH creates a hedged position where margin
     *      should be stable across price movements.
     */
    function check_WethTradeWithWethCollateral_PerpOB(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();

        uint256 markPrice = 3000e18;
        pushMarkPrice(marketId, markPrice);
        pushFundingRate(marketId, 0);

        // Remove wETH collateral cap
        (CollateralConfig memory collateralConfig, ParentCollateralConfig memory parentCollateralConfig,) =
            ICoreProxy(sec.core).getCollateralConfig(1, sec.weth);
        vm.prank(sec.multisig);
        collateralConfig.cap = type(uint256).max;
        ICoreProxy(sec.core).setCollateralConfig(1, sec.weth, collateralConfig, parentCollateralConfig);

        // Deposit wETH as collateral for buyer (who will go short)
        uint256 wethAmount = 10e18;
        deal(sec.weth, perpBuyer, wethAmount);
        vm.startPrank(perpBuyer);
        ITokenProxy(sec.weth).approve(sec.core, wethAmount);
        vm.stopPrank();

        uint128 shortAccountId = depositNewMA(perpBuyer, sec.weth, wethAmount);

        // Counterparty with rUSD collateral
        uint128 longAccountId = depositNewMA(perpSeller, sec.rusd, 50_000e6);

        // Open short 5 ETH position via fill at $3000
        // Seller goes short (negative baseDelta), buyer goes long (positive)
        // But here we want perpBuyer to go SHORT, so we need to swap roles in executePerpFill
        // executePerpFill expects buyerAccountId as the long side
        // So longAccountId is the "buyer" (long) and shortAccountId is the "seller" (short)

        // Create the fill manually with swapped roles
        {
            // Long order for counterparty
            (ConditionalOrderDetails memory longOrder, EIP712Signature memory longSig) = createLimitOrderPerp({
                accountId: longAccountId,
                marketId: marketId,
                baseDelta: int256(5e18),
                price: markPrice,
                nonce: 1,
                signer: perpSeller,
                signerPk: perpSellerPk
            });

            // Short order for wETH-collateralized user
            (ConditionalOrderDetails memory shortOrder, EIP712Signature memory shortSig) = createLimitOrderPerp({
                accountId: shortAccountId,
                marketId: marketId,
                baseDelta: -int256(5e18),
                price: markPrice,
                nonce: 1,
                signer: perpBuyer,
                signerPk: perpBuyerPk
            });

            SignedMatchingEnginePayload memory mePayload = createPerpMatchingEnginePayload({
                price: markPrice,
                baseDelta: 5e18,
                accountOrderId: 1,
                counterpartyOrderId: 2,
                nonce: 1
            });

            ExecuteFillInput memory fillInput = ExecuteFillInput({
                accountOrder: longOrder,
                counterpartyOrder: shortOrder,
                accountSignature: longSig,
                counterpartySignature: shortSig,
                mePayload: mePayload
            });

            vm.prank(sec.coExecutionBot);
            IOrdersGatewayProxy(sec.ordersGateway).executeFill(fillInput);
        }

        // Verify short position
        PerpPosition memory shortPos =
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, shortAccountId);
        assertEq(shortPos.base, -5e18, "Should be short 5 ETH");

        // Get initial margin balance (hedged: short ETH + hold wETH)
        int256 marginBalance0 = ICoreProxy(sec.core).getNodeMarginInfo(shortAccountId, sec.rusd).marginBalance;

        // Check margin stability across price movements
        // Short ETH + hold wETH should be approximately delta-neutral
        uint256[] memory testPrices = new uint256[](3);
        testPrices[0] = 2500e18;
        testPrices[1] = 3500e18;
        testPrices[2] = 3001e18;

        for (uint256 i = 0; i < testPrices.length; i++) {
            // Mock spot price for collateral valuation
            vm.mockCall(
                sec.oracleManager,
                abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkNodeId)),
                abi.encode(NodeOutput.Data({ price: testPrices[i], timestamp: block.timestamp }))
            );
            vm.mockCall(
                sec.oracleManager,
                abi.encodeCall(IOracleManagerProxy.process, (sec.ethUsdcStorkMarkNodeId)),
                abi.encode(NodeOutput.Data({ price: testPrices[i], timestamp: block.timestamp }))
            );

            int256 marginBalance1 = ICoreProxy(sec.core).getNodeMarginInfo(shortAccountId, sec.rusd).marginBalance;
            // Hedged position margin should be approximately stable
            // Allow larger tolerance due to haircut and price impact
            assertApproxEqAbsDecimal(marginBalance0, marginBalance1, 10 * 10e6, 6, "Margin should be stable");
        }
    }
}
