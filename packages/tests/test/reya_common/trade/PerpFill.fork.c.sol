pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import { ICoreProxy, MarginInfo, RiskMultipliers, CollateralInfo } from "../../../src/interfaces/ICoreProxy.sol";
import {
    IPassivePerpProxy,
    PerpPosition,
    EIP712Signature as PerpEIP712Signature
} from "../../../src/interfaces/IPassivePerpProxy.sol";
import {
    IPassivePerpProxyV2,
    OracleDataPayload,
    OracleDataType,
    FeeTierParameters,
    GlobalFeeParametersV2,
    MarketConfigurationDataV2
} from "../../../src/interfaces/IPassivePerpProxyV2.sol";
import {
    IOrdersGatewayProxy,
    EIP712Signature,
    SignedMatchingEnginePayload,
    FillDetails
} from "../../../src/interfaces/IOrdersGatewayProxy.sol";
import {
    IOrdersGatewayProxyV2,
    OrderDetails,
    OrderTypeV2,
    SignedOrderV2,
    ExecuteFillInputV2
} from "../../../src/interfaces/IOrdersGatewayProxyV2.sol";
import { OrderDetailsHashing } from "../../../src/utils/OrderDetailsHashing.sol";
import { FillHashingV2 } from "../../../src/utils/FillHashingV2.sol";
import { OracleDataPayloadHashing } from "../../../src/utils/OracleDataPayloadHashing.sol";

import { sd, SD59x18, UNIT as ONE_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

/**
 * @title PerpFillForkCheck
 * @notice Fork tests for perpetual fill execution (perpOB model)
 * @dev Tests executeFill via the Orders Gateway for perp markets using
 *      LimitOrderPerp order type and oracle-pushed mark prices/funding rates.
 *      Follows the same pattern as SpotForkCheck but for perp markets.
 */
contract PerpFillForkCheck is BaseReyaForkTest {
    // Test actors
    address internal perpBuyer;
    uint256 internal perpBuyerPk;
    address internal perpSeller;
    uint256 internal perpSellerPk;
    address internal perpMatchingEngine;
    uint256 internal perpMatchingEnginePk;
    address internal oraclePublisher;
    uint256 internal oraclePublisherPk;

    // Feature flag constants
    bytes32 internal constant MATCHING_ENGINE_PUBLISHER_FLAG = keccak256(bytes("matching_engine_publisher"));
    bytes32 internal constant ORACLE_PUSHERS_FLAG = keccak256(bytes("oraclePushers"));
    bytes32 internal constant ORACLE_PUBLISHERS_FLAG = keccak256(bytes("oraclePublishers"));

    function setupPerpTestActors() internal {
        (perpBuyer, perpBuyerPk) = makeAddrAndKey("perpBuyer");
        (perpSeller, perpSellerPk) = makeAddrAndKey("perpSeller");
        (perpMatchingEngine, perpMatchingEnginePk) = makeAddrAndKey("perpMatchingEngine");
        (oraclePublisher, oraclePublisherPk) = makeAddrAndKey("oraclePublisher");

        // Grant matching engine publisher access on Orders Gateway
        vm.prank(sec.multisig);
        IOrdersGatewayProxy(sec.ordersGateway).addToFeatureFlagAllowlist(
            MATCHING_ENGINE_PUBLISHER_FLAG, perpMatchingEngine
        );

        // Grant oracle pusher access on PassivePerp (checks msg.sender)
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).addToFeatureFlagAllowlist(ORACLE_PUSHERS_FLAG, oraclePublisher);

        // Grant oracle publisher access on PassivePerp (checks payload.publisher signature)
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).addToFeatureFlagAllowlist(ORACLE_PUBLISHERS_FLAG, oraclePublisher);
    }

    function createLimitOrderPerp(
        uint128 accountId,
        uint128 marketId,
        int256 baseDelta,
        uint256 price,
        uint256 nonce,
        address signer,
        uint256 signerPk
    )
        internal
        view
        returns (OrderDetails memory order, EIP712Signature memory sig)
    {
        order = OrderDetails({
            accountId: accountId,
            marketId: marketId,
            exchangeId: 1,
            orderType: OrderTypeV2.Limit,
            quantity: baseDelta,
            limitPrice: price,
            triggerPrice: 0,
            timeInForce: 0,
            clientOrderId: 0,
            reduceOnly: false,
            postOnly: false,
            expiresAfter: 0,
            signer: signer,
            nonce: nonce
        });

        uint256 deadline = block.timestamp + 3600;
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(signerPk, OrderDetailsHashing.mockCalculateDigest(order, deadline, sec.ordersGateway));

        sig = EIP712Signature({ v: v, r: r, s: s, deadline: deadline });
    }

    function createPerpMatchingEnginePayload(
        OrderDetails memory accountOrder,
        OrderDetails memory counterpartyOrder,
        uint256 price,
        uint256 baseDelta,
        uint256 nonce,
        bytes memory metadata
    )
        internal
        view
        returns (SignedMatchingEnginePayload memory)
    {
        FillDetails memory fillDetails = FillDetails({
            accountOrderId: uint64(nonce * 2 - 1),
            counterpartyOrderId: uint64(nonce * 2),
            baseDelta: baseDelta,
            price: price,
            nonce: nonce
        });

        uint256 deadline = block.timestamp + 3600;
        bytes32 digest = calculatePerpFillDigest(fillDetails, deadline, accountOrder, counterpartyOrder, metadata);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(perpMatchingEnginePk, digest);

        EIP712Signature memory sig = EIP712Signature({ v: v, r: r, s: s, deadline: deadline });

        return SignedMatchingEnginePayload({ fillDetails: fillDetails, signature: sig });
    }

    function calculatePerpFillDigest(
        FillDetails memory fillDetails,
        uint256 deadline,
        OrderDetails memory accountOrder,
        OrderDetails memory counterpartyOrder,
        bytes memory metadata
    )
        internal
        view
        returns (bytes32)
    {
        bytes32 accountOrderHash = OrderDetailsHashing.hashOrderDetails(accountOrder);
        bytes32 counterpartyOrderHash = OrderDetailsHashing.hashOrderDetails(counterpartyOrder);
        return FillHashingV2.mockCalculateDigest(
            fillDetails, deadline, accountOrderHash, counterpartyOrderHash, metadata, sec.ordersGateway
        );
    }

    function createPerpFillInput(
        OrderDetails memory accountOrder,
        EIP712Signature memory accountSignature,
        OrderDetails memory counterpartyOrder,
        EIP712Signature memory counterpartySignature,
        uint256 price,
        uint256 baseDelta,
        uint256 nonce
    )
        internal
        view
        returns (ExecuteFillInputV2 memory)
    {
        bytes memory metadata = new bytes(0);
        SignedMatchingEnginePayload memory mePayload = createPerpMatchingEnginePayload({
            accountOrder: accountOrder,
            counterpartyOrder: counterpartyOrder,
            price: price,
            baseDelta: baseDelta,
            nonce: nonce,
            metadata: metadata
        });

        return ExecuteFillInputV2({
            accountOrder: SignedOrderV2({ orderDetails: accountOrder, signature: accountSignature }),
            counterpartyOrder: SignedOrderV2({ orderDetails: counterpartyOrder, signature: counterpartySignature }),
            mePayload: mePayload,
            metadata: metadata
        });
    }

    function pushMarkPriceWithinCollar(uint128 marketId, uint256 price) internal {
        MarketConfigurationDataV2 memory marketConfig = IPassivePerpProxyV2(sec.perp).getMarketConfiguration(marketId);
        mockFreshPrice(marketConfig.oracleNodeId, price);

        OracleDataPayload memory payload = OracleDataPayload({
            marketId: marketId,
            timestamp: block.timestamp,
            dataType: OracleDataType.MarkPrice,
            data: abi.encode(price),
            publisher: oraclePublisher
        });

        uint256 deadline = block.timestamp + 3600;
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(oraclePublisherPk, OracleDataPayloadHashing.mockCalculateDigest(payload, deadline, sec.perp));

        PerpEIP712Signature memory sig = PerpEIP712Signature({ v: v, r: r, s: s, deadline: deadline });

        vm.prank(oraclePublisher);
        IPassivePerpProxyV2(sec.perp).pushOracleData(payload, sig);
    }

    function pushFundingRate(uint128 marketId, int256 rate) internal {
        OracleDataPayload memory payload = OracleDataPayload({
            marketId: marketId,
            timestamp: block.timestamp,
            dataType: OracleDataType.FundingRate,
            data: abi.encode(rate),
            publisher: oraclePublisher
        });

        uint256 deadline = block.timestamp + 3600;
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(oraclePublisherPk, OracleDataPayloadHashing.mockCalculateDigest(payload, deadline, sec.perp));

        PerpEIP712Signature memory sig = PerpEIP712Signature({ v: v, r: r, s: s, deadline: deadline });

        vm.prank(oraclePublisher);
        IPassivePerpProxyV2(sec.perp).pushOracleData(payload, sig);
    }

    function executePerpFill(
        uint128 buyerAccountId,
        uint128 sellerAccountId,
        uint128 marketId,
        uint256 baseDelta,
        uint256 price,
        uint256 buyerNonce,
        uint256 sellerNonce,
        uint256 meNonce
    )
        internal
    {
        // Buyer order (positive baseDelta = long)
        (OrderDetails memory buyerOrder, EIP712Signature memory buyerSig) = createLimitOrderPerp({
            accountId: buyerAccountId,
            marketId: marketId,
            baseDelta: int256(baseDelta),
            price: price,
            nonce: buyerNonce,
            signer: perpBuyer,
            signerPk: perpBuyerPk
        });

        // Seller order (negative baseDelta = short)
        (OrderDetails memory sellerOrder, EIP712Signature memory sellerSig) = createLimitOrderPerp({
            accountId: sellerAccountId,
            marketId: marketId,
            baseDelta: -int256(baseDelta),
            price: price,
            nonce: sellerNonce,
            signer: perpSeller,
            signerPk: perpSellerPk
        });

        ExecuteFillInputV2 memory fillInput = createPerpFillInput({
            accountOrder: buyerOrder,
            accountSignature: buyerSig,
            counterpartyOrder: sellerOrder,
            counterpartySignature: sellerSig,
            price: price,
            baseDelta: baseDelta,
            nonce: meNonce
        });

        vm.prank(sec.coExecutionBot);
        IOrdersGatewayProxyV2(sec.ordersGateway).executeFill(fillInput);
    }

    function executePerpClose(
        uint128 buyerAccountId,
        uint128 sellerAccountId,
        uint128 marketId,
        uint256 baseDelta,
        uint256 price,
        uint256 buyerNonce,
        uint256 sellerNonce,
        uint256 meNonce
    )
        internal
    {
        (OrderDetails memory buyerCloseOrder, EIP712Signature memory buyerCloseSig) = createLimitOrderPerp({
            accountId: buyerAccountId,
            marketId: marketId,
            baseDelta: -int256(baseDelta),
            price: price,
            nonce: buyerNonce,
            signer: perpBuyer,
            signerPk: perpBuyerPk
        });

        (OrderDetails memory sellerCloseOrder, EIP712Signature memory sellerCloseSig) = createLimitOrderPerp({
            accountId: sellerAccountId,
            marketId: marketId,
            baseDelta: int256(baseDelta),
            price: price,
            nonce: sellerNonce,
            signer: perpSeller,
            signerPk: perpSellerPk
        });

        ExecuteFillInputV2 memory fillInput = createPerpFillInput({
            accountOrder: sellerCloseOrder,
            accountSignature: sellerCloseSig,
            counterpartyOrder: buyerCloseOrder,
            counterpartySignature: buyerCloseSig,
            price: price,
            baseDelta: baseDelta,
            nonce: meNonce
        });

        vm.prank(sec.coExecutionBot);
        IOrdersGatewayProxyV2(sec.ordersGateway).executeFill(fillInput);
    }

    /**
     * @notice Public wrapper for executePerpFill, callable via this.executePerpFillExternal()
     *         so it can be used in try-catch blocks (which require external calls).
     */
    function executePerpFillExternal(
        uint128 buyerAccountId,
        uint128 sellerAccountId,
        uint128 marketId,
        uint256 baseDelta,
        uint256 price,
        uint256 buyerNonce,
        uint256 sellerNonce,
        uint256 meNonce
    )
        public
    {
        executePerpFill(buyerAccountId, sellerAccountId, marketId, baseDelta, price, buyerNonce, sellerNonce, meNonce);
    }

    /**
     * @notice Test basic perp fill execution for ETH market
     * @dev Opens a long/short position between buyer and seller, verifies positions
     */
    function check_PerpExecuteFill(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();

        // Push mark price before trade
        uint256 markPrice = 3000e18;
        pushMarkPriceWithinCollar(marketId, markPrice);
        pushFundingRate(marketId, 0);

        // Create margin accounts with collateral
        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 10_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 10_000e6);

        // Execute perp fill: 0.1 ETH at $3000
        uint256 baseDelta = 0.1e18;
        uint256 fillPrice = 3000e18;

        executePerpFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: baseDelta,
            price: fillPrice,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        // Verify positions
        PerpPosition memory buyerPosition = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, buyerAccountId);
        PerpPosition memory sellerPosition =
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, sellerAccountId);

        assertEq(buyerPosition.base, int256(baseDelta), "Buyer should be long");
        assertEq(sellerPosition.base, -int256(baseDelta), "Seller should be short");
    }

    /**
     * @notice Verify that the deployed Orders Gateway binds the exact metadata bytes into the ME signature.
     * @dev The input is signed with empty metadata, then mutated before submission. A router that still uses
     *      the pre-binding digest would accept it; the current router must reject the recovered ME signer.
     */
    function check_PerpFillMetadataBinding(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 10_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 10_000e6);

        ExecuteFillInputV2 memory fillInput;
        {
            (OrderDetails memory buyerOrder, EIP712Signature memory buyerSig) = createLimitOrderPerp({
                accountId: buyerAccountId,
                marketId: marketId,
                baseDelta: int256(0.1e18),
                price: 3000e18,
                nonce: 1,
                signer: perpBuyer,
                signerPk: perpBuyerPk
            });

            (OrderDetails memory sellerOrder, EIP712Signature memory sellerSig) = createLimitOrderPerp({
                accountId: sellerAccountId,
                marketId: marketId,
                baseDelta: -int256(0.1e18),
                price: 3000e18,
                nonce: 1,
                signer: perpSeller,
                signerPk: perpSellerPk
            });

            fillInput = createPerpFillInput({
                accountOrder: buyerOrder,
                accountSignature: buyerSig,
                counterpartyOrder: sellerOrder,
                counterpartySignature: sellerSig,
                price: 3000e18,
                baseDelta: 0.1e18,
                nonce: 1
            });
        }

        fillInput.metadata = hex"01";

        vm.prank(sec.coExecutionBot);
        try IOrdersGatewayProxyV2(sec.ordersGateway).executeFill(fillInput) {
            revert("Expected metadata-bound matching-engine signature to fail");
        } catch (bytes memory revertData) {
            assertEq(
                bytes4(revertData),
                IOrdersGatewayProxy.UnauthorizedMatchingEnginePublisher.selector,
                "Should reject the mutated metadata signature"
            );
        }
    }

    /**
     * @notice Test that mark price staleness is enforced
     * @dev Pushes a mark price, warps forward past max stale duration, verifies fill reverts
     */
    function check_PerpMarkPriceStaleness(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();

        // Push mark price
        pushMarkPriceWithinCollar(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        // Create accounts
        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 10_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 10_000e6);

        uint256 maxStaleDuration =
            IPassivePerpProxyV2(sec.perp).getMarketConfiguration(marketId).markPriceMaxStaleDuration;

        // Warp forward one second past the configured maximum stale duration.
        vm.warp(block.timestamp + maxStaleDuration + 1);
        mockFreshPrices();

        // Attempt fill should revert due to stale mark price
        try this.executePerpFillExternal({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 0.1e18,
            price: 3000e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        }) {
            revert("Expected MarkPriceStale revert");
        } catch (bytes memory revertData) {
            assertEq(
                bytes4(revertData), IPassivePerpProxyV2.MarkPriceStale.selector, "Should revert with MarkPriceStale"
            );
        }
    }

    /**
     * @notice Test batch perp fill execution
     * @dev Executes multiple fills in a single transaction
     */
    function check_PerpBatchExecuteFill(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        // Create accounts with sufficient collateral
        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 50_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 50_000e6);

        // Create two fill inputs
        ExecuteFillInputV2[] memory fills = new ExecuteFillInputV2[](2);

        // Fill 1: 0.1 ETH at $3000
        {
            (OrderDetails memory buyerOrder1, EIP712Signature memory buyerSig1) = createLimitOrderPerp({
                accountId: buyerAccountId,
                marketId: marketId,
                baseDelta: int256(0.1e18),
                price: 3000e18,
                nonce: 1,
                signer: perpBuyer,
                signerPk: perpBuyerPk
            });

            (OrderDetails memory sellerOrder1, EIP712Signature memory sellerSig1) = createLimitOrderPerp({
                accountId: sellerAccountId,
                marketId: marketId,
                baseDelta: -int256(0.1e18),
                price: 3000e18,
                nonce: 1,
                signer: perpSeller,
                signerPk: perpSellerPk
            });

            fills[0] = createPerpFillInput({
                accountOrder: buyerOrder1,
                accountSignature: buyerSig1,
                counterpartyOrder: sellerOrder1,
                counterpartySignature: sellerSig1,
                price: 3000e18,
                baseDelta: 0.1e18,
                nonce: 1
            });
        }

        // Fill 2: 0.2 ETH at $3010
        {
            (OrderDetails memory buyerOrder2, EIP712Signature memory buyerSig2) = createLimitOrderPerp({
                accountId: buyerAccountId,
                marketId: marketId,
                baseDelta: int256(0.2e18),
                price: 3010e18,
                nonce: 2,
                signer: perpBuyer,
                signerPk: perpBuyerPk
            });

            (OrderDetails memory sellerOrder2, EIP712Signature memory sellerSig2) = createLimitOrderPerp({
                accountId: sellerAccountId,
                marketId: marketId,
                baseDelta: -int256(0.2e18),
                price: 3010e18,
                nonce: 2,
                signer: perpSeller,
                signerPk: perpSellerPk
            });

            fills[1] = createPerpFillInput({
                accountOrder: buyerOrder2,
                accountSignature: buyerSig2,
                counterpartyOrder: sellerOrder2,
                counterpartySignature: sellerSig2,
                price: 3010e18,
                baseDelta: 0.2e18,
                nonce: 2
            });
        }

        vm.prank(sec.coExecutionBot);
        IOrdersGatewayProxyV2(sec.ordersGateway).batchExecuteFill(fills);

        // Verify combined position
        PerpPosition memory buyerPosition = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, buyerAccountId);
        assertEq(buyerPosition.base, int256(0.3e18), "Buyer should have 0.3 ETH long");

        PerpPosition memory sellerPosition =
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, sellerAccountId);
        assertEq(sellerPosition.base, -int256(0.3e18), "Seller should have 0.3 ETH short");
    }

    /**
     * @notice Test that margin is consumed after opening a position
     * @dev Verifies that:
     *      - LMR is non-zero after opening a position
     *      - Both buyer and seller have correct margin impact (symmetric LMR)
     *      - Margin balance remains positive
     */
    function check_PerpFillMarginImpact(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 10_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 10_000e6);

        // Execute fill: 1 ETH at $3000
        executePerpFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 1e18,
            price: 3000e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        // After trade: both accounts should have non-zero LMR
        MarginInfo memory buyerMarginAfter = ICoreProxy(sec.core).getUsdNodeMarginInfo(buyerAccountId);
        MarginInfo memory sellerMarginAfter = ICoreProxy(sec.core).getUsdNodeMarginInfo(sellerAccountId);

        assertGt(buyerMarginAfter.liquidationMarginRequirement, 0, "Buyer LMR should be non-zero after trade");
        assertGt(sellerMarginAfter.liquidationMarginRequirement, 0, "Seller LMR should be non-zero after trade");

        // Both sides should have same LMR (symmetric positions)
        assertEq(
            buyerMarginAfter.liquidationMarginRequirement,
            sellerMarginAfter.liquidationMarginRequirement,
            "Buyer and seller LMR should be equal (symmetric)"
        );

        // Margin balance should be positive (10k deposit minus small fees)
        assertGt(buyerMarginAfter.marginBalance, 0, "Buyer margin balance should be positive");
        assertGt(sellerMarginAfter.marginBalance, 0, "Seller margin balance should be positive");
    }

    /**
     * @notice Test that nonce replay is rejected
     * @dev Executes a fill, then tries to reuse the same nonces — should revert
     */
    function check_PerpFillNonceReplay(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 50_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 50_000e6);

        // First fill succeeds
        executePerpFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 0.1e18,
            price: 3000e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        // Replay with same nonces should revert
        try this.executePerpFillExternal({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 0.1e18,
            price: 3000e18,
            buyerNonce: 1, // same nonce
            sellerNonce: 1, // same nonce
            meNonce: 1 // same nonce
         }) {
            revert("Expected SignerNonceAlreadyUsed revert");
        } catch (bytes memory revertData) {
            assertEq(
                bytes4(revertData),
                IOrdersGatewayProxy.SignerNonceAlreadyUsed.selector,
                "Should revert with SignerNonceAlreadyUsed"
            );
        }
    }

    /**
     * @notice Test that a position can be closed by filling in the opposite direction
     * @dev Opens a long, then closes it with a short of equal size. Verifies position is zeroed.
     *      To close, the buyer sells (negative baseDelta) and the seller buys (positive baseDelta).
     *      We must construct orders manually since executePerpFill always assigns perpBuyer=long.
     */
    function check_PerpFillClosePosition(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 10_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 10_000e6);

        // Open: buyer goes long 0.5 ETH
        executePerpFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 0.5e18,
            price: 3000e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        PerpPosition memory buyerPos = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, buyerAccountId);
        assertEq(buyerPos.base, int256(0.5e18), "Buyer should be long 0.5 ETH");

        // Close: buyer sells 0.5 ETH (negative baseDelta), seller buys 0.5 ETH (positive baseDelta).
        executePerpClose({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 0.5e18,
            price: 3000e18,
            buyerNonce: 2,
            sellerNonce: 2,
            meNonce: 2
        });

        // Both should be flat
        PerpPosition memory buyerPosAfter = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, buyerAccountId);
        PerpPosition memory sellerPosAfter =
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, sellerAccountId);

        assertEq(buyerPosAfter.base, 0, "Buyer position should be closed");
        assertEq(sellerPosAfter.base, 0, "Seller position should be closed");
    }

    /**
     * @notice Test that mark price changes affect margin balance
     * @dev Opens a position, changes mark price, verifies margin balance moves accordingly
     */
    function check_PerpMarkPriceImpactsMargin(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 10_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 10_000e6);

        executePerpFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 1e18,
            price: 3000e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        MarginInfo memory buyerMarginAtOpen = ICoreProxy(sec.core).getUsdNodeMarginInfo(buyerAccountId);
        MarginInfo memory sellerMarginAtOpen = ICoreProxy(sec.core).getUsdNodeMarginInfo(sellerAccountId);

        // Price goes up $100 — long gains, short loses
        pushMarkPriceWithinCollar(marketId, 3100e18);
        mockFreshPrices();

        MarginInfo memory buyerMarginAfterUp = ICoreProxy(sec.core).getUsdNodeMarginInfo(buyerAccountId);
        MarginInfo memory sellerMarginAfterUp = ICoreProxy(sec.core).getUsdNodeMarginInfo(sellerAccountId);

        assertGt(
            buyerMarginAfterUp.marginBalance,
            buyerMarginAtOpen.marginBalance,
            "Buyer (long) margin should increase when price goes up"
        );
        assertLt(
            sellerMarginAfterUp.marginBalance,
            sellerMarginAtOpen.marginBalance,
            "Seller (short) margin should decrease when price goes up"
        );

        // Price goes down $200 from initial (to $2800) — long loses, short gains
        pushMarkPriceWithinCollar(marketId, 2800e18);
        mockFreshPrices();

        MarginInfo memory buyerMarginAfterDown = ICoreProxy(sec.core).getUsdNodeMarginInfo(buyerAccountId);
        MarginInfo memory sellerMarginAfterDown = ICoreProxy(sec.core).getUsdNodeMarginInfo(sellerAccountId);

        assertLt(
            buyerMarginAfterDown.marginBalance,
            buyerMarginAtOpen.marginBalance,
            "Buyer (long) margin should decrease when price drops below entry"
        );
        assertGt(
            sellerMarginAfterDown.marginBalance,
            sellerMarginAtOpen.marginBalance,
            "Seller (short) margin should increase when price drops below entry"
        );
    }

    /**
     * @notice Test that the taker fee is deducted and the maker is fee-neutral on a perp fill
     * @dev Devnet fee config: tier0 taker=0.03%.
     *      Taker fee = |baseDelta| * markPrice * 0.0003.
     *      We verify by checking getCollateralInfo(accountId, rusd).realBalance before/after.
     *      Unrealized PnL only affects marginBalance, not realBalance, so only fees change realBalance.
     */
    function check_PerpFillFees(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 100_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 100_000e6);

        int256 buyerBalBefore = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).realBalance;
        int256 sellerBalBefore = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).realBalance;

        executePerpFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 1e18,
            price: 3010e18, // Differ from mark price to prove fee exposure uses the mark price.
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        int256 buyerBalAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).realBalance;
        int256 sellerBalAfter = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).realBalance;

        int256 buyerPaid = buyerBalBefore - buyerBalAfter;
        int256 sellerPaid = sellerBalBefore - sellerBalAfter;

        // Expected taker fee = 1 ETH * $3000 * 0.0003 = $0.90 = 0.9e6 rUSD
        int256 expectedFee = 0.9e6;

        assertEq(buyerPaid, expectedFee, "Buyer should pay exactly 3bps taker fee");
        assertEq(sellerPaid, 0, "Maker should be fee-neutral");
        assertGt(buyerPaid, 0, "Buyer fee should be positive");
    }

    /**
     * @notice Test that the deprecated market zero-fee flag cannot bypass taker fees
     * @dev Existing flag state remains readable after the upgrade, but fee model V3 no longer consults it.
     */
    function check_PerpFillDeprecatedMarketZeroFeesFlag(uint128 marketId, address zeroFeeBot) internal {
        setupPerpTestActors();
        mockFreshPrices();

        // Enable zero fees for this market
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("marketZeroFees")), marketId));
        vm.prank(zeroFeeBot);
        IPassivePerpProxy(sec.perp).setFeatureFlagAllowAll(flagId, true);

        pushMarkPriceWithinCollar(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 100_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 100_000e6);

        int256 buyerBalBefore = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).realBalance;
        int256 sellerBalBefore = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).realBalance;

        executePerpFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 1e18,
            price: 3000e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        int256 buyerPaid = buyerBalBefore - ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).realBalance;
        int256 sellerPaid =
            sellerBalBefore - ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).realBalance;

        assertEq(buyerPaid, int256(0.9e6), "Deprecated market flag must not bypass taker fee");
        assertEq(sellerPaid, 0, "Maker should remain fee-neutral");

        // Restore default (fees on)
        vm.prank(zeroFeeBot);
        IPassivePerpProxy(sec.perp).setFeatureFlagAllowAll(flagId, false);
    }

    /**
     * @notice Test that insufficient liquidation margin blocks a perp fill
     * @dev Attempts to open a position larger than what the margin can support.
     *      With $10 deposit and 1 ETH at $3000 → ~300x leverage, well beyond the 25x limit.
     *      Verifies that the revert is specifically AccountBelowLm for the buyer's account
     *      (the seller has $100k collateral and should not be the one failing).
     */
    function check_PerpFillInsufficientMargin(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        // Tiny collateral: $10 rUSD
        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 10e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 100_000e6);

        // Build fill input in scoped blocks to avoid stack-too-deep
        ExecuteFillInputV2 memory fillInput;
        {
            (OrderDetails memory buyerOrder, EIP712Signature memory buyerSig) = createLimitOrderPerp({
                accountId: buyerAccountId,
                marketId: marketId,
                baseDelta: int256(1e18),
                price: 3000e18,
                nonce: 1,
                signer: perpBuyer,
                signerPk: perpBuyerPk
            });

            (OrderDetails memory sellerOrder, EIP712Signature memory sellerSig) = createLimitOrderPerp({
                accountId: sellerAccountId,
                marketId: marketId,
                baseDelta: -int256(1e18),
                price: 3000e18,
                nonce: 1,
                signer: perpSeller,
                signerPk: perpSellerPk
            });

            fillInput = createPerpFillInput({
                accountOrder: buyerOrder,
                accountSignature: buyerSig,
                counterpartyOrder: sellerOrder,
                counterpartySignature: sellerSig,
                price: 3000e18,
                baseDelta: 1e18,
                nonce: 1
            });
        }

        // Execute and verify the revert is AccountBelowLm for the buyer's account specifically
        vm.prank(sec.coExecutionBot);
        try IOrdersGatewayProxyV2(sec.ordersGateway).executeFill(fillInput) {
            revert("Expected AccountBelowLm revert for underfunded buyer");
        } catch (bytes memory revertData) {
            assertEq(bytes4(revertData), ICoreProxy.AccountBelowLm.selector, "Should revert with AccountBelowLm");

            // Decode accountId: AccountBelowLm(uint128 accountId, int256 delta)
            uint128 failedAccountId;
            assembly {
                failedAccountId := mload(add(revertData, 36))
            }
            assertEq(failedAccountId, buyerAccountId, "IM failure should be on buyer (underfunded), not seller");
        }
    }

    /**
     * @notice Test that a reduce-only order can close an existing position
     * @dev Opens a long position, then uses ReduceOnlyPerp to close it
     */
    function check_PerpFillReduceOnly(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 10_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 10_000e6);

        // Open: buyer goes long 0.5 ETH
        executePerpFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 0.5e18,
            price: 3000e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        // Verify position is open
        PerpPosition memory buyerPos = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, buyerAccountId);
        assertEq(buyerPos.base, int256(0.5e18), "Buyer should be long 0.5 ETH");

        // Close using ReduceOnlyPerp: buyer sells 0.5 ETH
        {
            // Buyer's reduce-only sell order
            OrderDetails memory reduceOrder = OrderDetails({
                accountId: buyerAccountId,
                marketId: marketId,
                exchangeId: 1,
                orderType: OrderTypeV2.Limit,
                quantity: -int256(0.5e18),
                limitPrice: 3000e18,
                triggerPrice: 0,
                timeInForce: 0,
                clientOrderId: 0,
                reduceOnly: true,
                postOnly: false,
                expiresAfter: 0,
                signer: perpBuyer,
                nonce: 2
            });

            uint256 deadline = block.timestamp + 3600;
            (uint8 v, bytes32 r, bytes32 s) =
                vm.sign(perpBuyerPk, OrderDetailsHashing.mockCalculateDigest(reduceOrder, deadline, sec.ordersGateway));
            EIP712Signature memory reduceSig = EIP712Signature({ v: v, r: r, s: s, deadline: deadline });

            // Seller's regular buy order (counterparty)
            (OrderDetails memory sellerOrder, EIP712Signature memory sellerSig) = createLimitOrderPerp({
                accountId: sellerAccountId,
                marketId: marketId,
                baseDelta: int256(0.5e18),
                price: 3000e18,
                nonce: 2,
                signer: perpSeller,
                signerPk: perpSellerPk
            });

            ExecuteFillInputV2 memory fillInput = createPerpFillInput({
                accountOrder: reduceOrder,
                accountSignature: reduceSig,
                counterpartyOrder: sellerOrder,
                counterpartySignature: sellerSig,
                price: 3000e18,
                baseDelta: 0.5e18,
                nonce: 2
            });

            vm.prank(sec.coExecutionBot);
            IOrdersGatewayProxyV2(sec.ordersGateway).executeFill(fillInput);
        }

        // Verify position is closed
        PerpPosition memory buyerPosAfter = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, buyerAccountId);
        assertEq(buyerPosAfter.base, 0, "Buyer position should be closed via reduce-only");
    }

    /**
     * @notice Test partial withdrawal with an open position
     * @dev Opens a position (1 ETH at $3000, $10k deposit), withdraws $5k,
     *      verifies margin and position are both correctly tracked.
     */
    function check_WithdrawWithOpenPosition(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 10_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 10_000e6);

        // Open position: 1 ETH long
        executePerpFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 1e18,
            price: 3000e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        MarginInfo memory marginBefore = ICoreProxy(sec.core).getUsdNodeMarginInfo(buyerAccountId);

        // Partial withdrawal: $5k out of ~$10k
        withdrawMA(buyerAccountId, sec.rusd, 5000e6);

        // Verify margin decreased by approximately $5k
        MarginInfo memory marginAfter = ICoreProxy(sec.core).getUsdNodeMarginInfo(buyerAccountId);
        int256 marginDrop = marginBefore.marginBalance - marginAfter.marginBalance;
        assertApproxEqAbs(marginDrop, 5000e18, 1e18, "Margin should decrease by ~$5k");

        // Position should be unchanged
        PerpPosition memory pos = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, buyerAccountId);
        assertEq(pos.base, 1e18, "Position should still be 1 ETH long");

        // LMR should be unchanged (same position size)
        assertEq(
            marginAfter.liquidationMarginRequirement,
            marginBefore.liquidationMarginRequirement,
            "LMR should be unchanged after withdrawal"
        );
    }

    /**
     * @notice Test that a reduce-only order cannot increase a position (wrong direction)
     * @dev Opens a long, then tries to use ReduceOnlyPerp to go further long — should revert.
     */
    function check_PerpFillReduceOnlyRevert(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 10_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 10_000e6);

        // Open: buyer goes long 0.5 ETH
        executePerpFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 0.5e18,
            price: 3000e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        // Try to increase with ReduceOnlyPerp: buyer tries to buy MORE (same direction) → should revert
        // Build fill input in scoped block to avoid stack-too-deep
        ExecuteFillInputV2 memory fillInput;
        {
            OrderDetails memory reduceOrder = OrderDetails({
                accountId: buyerAccountId,
                marketId: marketId,
                exchangeId: 1,
                orderType: OrderTypeV2.Limit,
                quantity: int256(0.5e18),
                limitPrice: 3000e18,
                triggerPrice: 0,
                timeInForce: 0,
                clientOrderId: 0,
                reduceOnly: true,
                postOnly: false,
                expiresAfter: 0,
                signer: perpBuyer,
                nonce: 2
            });

            uint256 deadline = block.timestamp + 3600;
            (uint8 v, bytes32 r, bytes32 s) =
                vm.sign(perpBuyerPk, OrderDetailsHashing.mockCalculateDigest(reduceOrder, deadline, sec.ordersGateway));
            EIP712Signature memory reduceSig = EIP712Signature({ v: v, r: r, s: s, deadline: deadline });

            (OrderDetails memory sellerOrder, EIP712Signature memory sellerSig) = createLimitOrderPerp({
                accountId: sellerAccountId,
                marketId: marketId,
                baseDelta: -int256(0.5e18),
                price: 3000e18,
                nonce: 2,
                signer: perpSeller,
                signerPk: perpSellerPk
            });

            fillInput = createPerpFillInput({
                accountOrder: reduceOrder,
                accountSignature: reduceSig,
                counterpartyOrder: sellerOrder,
                counterpartySignature: sellerSig,
                price: 3000e18,
                baseDelta: 0.5e18,
                nonce: 2
            });
        }

        // Verify revert is ReduceOnlyConditionFailed for the correct market and account
        vm.prank(sec.coExecutionBot);
        vm.expectRevert(
            abi.encodeWithSelector(IOrdersGatewayProxy.ReduceOnlyConditionFailed.selector, marketId, buyerAccountId)
        );
        IOrdersGatewayProxyV2(sec.ordersGateway).executeFill(fillInput);
    }

    /*//////////////////////////////////////////////////////////////
                        FEE MODEL CHECKS
    //////////////////////////////////////////////////////////////*/

    int256 private constant BASIC_TIER_FEE_PERCENTAGE = 0.0003e18;

    /**
     * @notice Test that OG/VLTZ taker rebates apply to perpOB fills
     * @dev Applies OG and/or VLTZ status to the buyer and verifies the multiplicative net fee.
     *      The seller is the maker and remains fee-neutral.
     */
    function check_PerpFillTakerRebates(uint128 marketId, bool ogRebate, bool vltzRebate) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        IPassivePerpProxy perp = IPassivePerpProxy(sec.perp);

        // Set up fee config bot with configureFees permission
        (address feeBot,) = makeAddrAndKey("feeBot");
        vm.prank(sec.multisig);
        perp.addToFeatureFlagAllowlist(keccak256(bytes("configureFees")), feeBot);

        // Preserve the appended pool fee fields while configuring the taker's rebate rates.
        GlobalFeeParametersV2 memory config = IPassivePerpProxyV2(sec.perp).getGlobalFeeParameters();
        config.ogRebateRate = ogRebate ? 0.2e18 : 0;
        config.vltzRebateRate = vltzRebate ? 0.1e18 : 0;
        vm.prank(sec.multisig);
        IPassivePerpProxyV2(sec.perp).setGlobalFeeParameters(config);

        // Apply rebate statuses to the taker only.
        vm.prank(feeBot);
        perp.setAccountOwnerOgStatusFeeConfig(perpBuyer, true);
        vm.prank(feeBot);
        perp.setAccountOwnerVltzStatusFeeConfig(perpBuyer, true);

        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 100_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 100_000e6);

        int256 buyerBalBefore = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).realBalance;
        int256 sellerBalBefore = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).realBalance;

        executePerpFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 1e18,
            price: 3000e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        int256 buyerPaid = buyerBalBefore - ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).realBalance;
        int256 sellerPaid =
            sellerBalBefore - ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).realBalance;

        // Compute the expected net fee after the taker's compounded rebates.
        // Base fee = 1 ETH * $3000 * 0.0003 = $0.90 = 0.9e6 rUSD
        SD59x18 feeRate = sd(BASIC_TIER_FEE_PERCENTAGE);
        if (ogRebate) feeRate = feeRate.mul(ONE_sd.sub(sd(0.2e18)));
        if (vltzRebate) feeRate = feeRate.mul(ONE_sd.sub(sd(0.1e18)));
        int256 expectedBuyerFee = sd(3000e18).mul(sd(1e18)).mul(feeRate).unwrap() / 1e12;

        assertEq(buyerPaid, expectedBuyerFee, "Buyer should pay net fee after taker rebates");
        assertEq(sellerPaid, 0, "Maker should be fee-neutral");

        if (ogRebate || vltzRebate) {
            assertLt(buyerPaid, int256(0.9e6), "Taker rebate should reduce the buyer's net fee");
        }
    }

    /**
     * @notice Test that the deprecated exchange zero-fee flag cannot bypass taker fees
     * @dev PerpOB fills use exchangeId=1. The flag remains in storage but is no longer consulted.
     */
    function check_PerpFillDeprecatedExchangeZeroFeesFlag(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        // Enable zero fees for exchange 1 (used by all perpOB fills)
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("exchangeZeroFees")), uint128(1)));
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).setFeatureFlagAllowAll(flagId, true);

        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 100_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 100_000e6);

        int256 buyerBalBefore = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).realBalance;
        int256 sellerBalBefore = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).realBalance;

        executePerpFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 1e18,
            price: 3000e18,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        int256 buyerPaid = buyerBalBefore - ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).realBalance;
        int256 sellerPaid =
            sellerBalBefore - ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).realBalance;

        assertEq(buyerPaid, int256(0.9e6), "Deprecated exchange flag must not bypass taker fee");
        assertEq(sellerPaid, 0, "Maker should remain fee-neutral");

        // Restore default (fees on)
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).setFeatureFlagAllowAll(flagId, false);
    }

    /**
     * @notice Test that deprecated maker parameters remain stored but do not affect settlement
     * @dev Existing deployments may contain non-zero values in these slots. The upgrade must preserve
     *      them without charging or crediting the maker.
     */
    function check_PerpFillDeprecatedMakerParametersIgnored(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPriceWithinCollar(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        // Configure a 4bps taker fee and deliberately non-zero deprecated maker fields.
        FeeTierParameters memory originalTier0 = IPassivePerpProxyV2(sec.perp).getFeeTierParameters(0);
        vm.prank(sec.multisig);
        IPassivePerpProxyV2(sec.perp).setFeeTierParameters(
            0, FeeTierParameters({ takerFee: 4e14, makerFee_DEPRECATED: 4e14, makerRebate_DEPRECATED: 5e17 })
        );

        FeeTierParameters memory configuredTier0 = IPassivePerpProxyV2(sec.perp).getFeeTierParameters(0);
        assertEq(configuredTier0.makerFee_DEPRECATED, 4e14, "Deprecated maker fee slot should round-trip");
        assertEq(configuredTier0.makerRebate_DEPRECATED, 5e17, "Deprecated maker rebate slot should round-trip");

        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 100_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 100_000e6);

        int256 buyerBalBefore = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).realBalance;
        int256 sellerBalBefore = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).realBalance;

        executePerpFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            marketId: marketId,
            baseDelta: 1e18,
            price: 3010e18, // Differ from mark price to prove fee exposure uses the mark price.
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        int256 buyerDelta =
            ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).realBalance - buyerBalBefore;
        int256 sellerDelta =
            ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).realBalance - sellerBalBefore;

        // Taker (buyer) pays 4bps of 3000 rUSD/ETH on 1 ETH = 1.2 rUSD debit (6-decimal rUSD).
        assertEq(buyerDelta, -int256(1.2e6), "Taker should pay 4bps fee");
        assertEq(sellerDelta, 0, "Deprecated maker parameters must not affect maker balance");

        // Restore tier 0 so any subsequent tests see defaults.
        vm.prank(sec.multisig);
        IPassivePerpProxyV2(sec.perp).setFeeTierParameters(0, originalTier0);
    }

    /**
     * @notice Assert that the live taker fee cannot exceed 100% of exposure
     */
    function check_TakerFeeParameterUpperBound() internal {
        FeeTierParameters memory originalTier0 = IPassivePerpProxyV2(sec.perp).getFeeTierParameters(0);

        vm.prank(sec.multisig);
        vm.expectRevert(IPassivePerpProxyV2.TakerFeeParameterTooLarge.selector);
        IPassivePerpProxyV2(sec.perp).setFeeTierParameters(
            0, FeeTierParameters({ takerFee: 1e18 + 1, makerFee_DEPRECATED: 4e14, makerRebate_DEPRECATED: 2e14 })
        );

        // Nothing should have changed.
        FeeTierParameters memory after_ = IPassivePerpProxyV2(sec.perp).getFeeTierParameters(0);
        assertEq(after_.takerFee, originalTier0.takerFee, "takerFee unchanged");
        assertEq(after_.makerFee_DEPRECATED, originalTier0.makerFee_DEPRECATED, "maker fee slot unchanged");
        assertEq(after_.makerRebate_DEPRECATED, originalTier0.makerRebate_DEPRECATED, "maker rebate slot unchanged");
    }
}
