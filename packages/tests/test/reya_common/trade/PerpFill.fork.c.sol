pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import { ICoreProxy, MarginInfo } from "../../../src/interfaces/ICoreProxy.sol";
import {
    IPassivePerpProxy,
    OracleDataPayload,
    OracleDataType,
    PerpPosition,
    EIP712Signature as PerpEIP712Signature
} from "../../../src/interfaces/IPassivePerpProxy.sol";
import {
    IOrdersGatewayProxy,
    ConditionalOrderDetails,
    EIP712Signature,
    ExecuteFillInput,
    SignedMatchingEnginePayload,
    FillDetails,
    LimitOrderPerpDetails,
    OrderType
} from "../../../src/interfaces/IOrdersGatewayProxy.sol";
import { ConditionalOrderHashing } from "../../../src/utils/ConditionalOrderHashing.sol";
import { FillHashing } from "../../../src/utils/FillHashing.sol";
import { OracleDataPayloadHashing } from "../../../src/utils/OracleDataPayloadHashing.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
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

        // Grant oracle pusher access on PassivePerp
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).addToFeatureFlagAllowlist(ORACLE_PUSHERS_FLAG, oraclePublisher);
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
        returns (ConditionalOrderDetails memory order, EIP712Signature memory sig)
    {
        uint128[] memory counterpartyAccountIds = new uint128[](0);

        bytes memory inputs = abi.encode(LimitOrderPerpDetails({ baseDelta: baseDelta, price: price }));

        order = ConditionalOrderDetails({
            accountId: accountId,
            marketId: marketId,
            exchangeId: 1,
            counterpartyAccountIds: counterpartyAccountIds,
            orderType: uint8(OrderType.LimitOrderPerp),
            inputs: inputs,
            signer: signer,
            nonce: nonce
        });

        uint256 deadline = block.timestamp + 3600;
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(signerPk, ConditionalOrderHashing.mockCalculateDigest(order, deadline, sec.ordersGateway));

        sig = EIP712Signature({ v: v, r: r, s: s, deadline: deadline });
    }

    function createPerpMatchingEnginePayload(
        uint256 price,
        uint256 baseDelta,
        uint64 accountOrderId,
        uint64 counterpartyOrderId,
        uint256 nonce
    )
        internal
        view
        returns (SignedMatchingEnginePayload memory)
    {
        FillDetails memory fillDetails = FillDetails({
            accountOrderId: accountOrderId,
            counterpartyOrderId: counterpartyOrderId,
            baseDelta: baseDelta,
            price: price,
            nonce: nonce
        });

        uint256 deadline = block.timestamp + 3600;
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(perpMatchingEnginePk, FillHashing.mockCalculateDigest(fillDetails, deadline, sec.ordersGateway));

        EIP712Signature memory sig = EIP712Signature({ v: v, r: r, s: s, deadline: deadline });

        return SignedMatchingEnginePayload({ fillDetails: fillDetails, signature: sig });
    }

    function pushMarkPrice(uint128 marketId, uint256 price) internal {
        OracleDataPayload memory payload = OracleDataPayload({
            marketId: marketId,
            timestamp: block.timestamp,
            dataType: OracleDataType.MarkPrice,
            data: abi.encode(price),
            publisher: oraclePublisher
        });

        uint256 deadline = block.timestamp + 3600;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            oraclePublisherPk,
            OracleDataPayloadHashing.mockCalculateDigest(payload, deadline, sec.perp)
        );

        PerpEIP712Signature memory sig = PerpEIP712Signature({ v: v, r: r, s: s, deadline: deadline });

        vm.prank(oraclePublisher);
        IPassivePerpProxy(sec.perp).pushOracleData(payload, sig);
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
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            oraclePublisherPk,
            OracleDataPayloadHashing.mockCalculateDigest(payload, deadline, sec.perp)
        );

        PerpEIP712Signature memory sig = PerpEIP712Signature({ v: v, r: r, s: s, deadline: deadline });

        vm.prank(oraclePublisher);
        IPassivePerpProxy(sec.perp).pushOracleData(payload, sig);
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
        (ConditionalOrderDetails memory buyerOrder, EIP712Signature memory buyerSig) = createLimitOrderPerp({
            accountId: buyerAccountId,
            marketId: marketId,
            baseDelta: int256(baseDelta),
            price: price,
            nonce: buyerNonce,
            signer: perpBuyer,
            signerPk: perpBuyerPk
        });

        // Seller order (negative baseDelta = short)
        (ConditionalOrderDetails memory sellerOrder, EIP712Signature memory sellerSig) = createLimitOrderPerp({
            accountId: sellerAccountId,
            marketId: marketId,
            baseDelta: -int256(baseDelta),
            price: price,
            nonce: sellerNonce,
            signer: perpSeller,
            signerPk: perpSellerPk
        });

        // Matching engine payload
        SignedMatchingEnginePayload memory mePayload = createPerpMatchingEnginePayload({
            price: price,
            baseDelta: baseDelta,
            accountOrderId: 1,
            counterpartyOrderId: 2,
            nonce: meNonce
        });

        // Execute fill
        ExecuteFillInput memory fillInput = ExecuteFillInput({
            accountOrder: buyerOrder,
            counterpartyOrder: sellerOrder,
            accountSignature: buyerSig,
            counterpartySignature: sellerSig,
            mePayload: mePayload
        });

        vm.prank(sec.coExecutionBot);
        IOrdersGatewayProxy(sec.ordersGateway).executeFill(fillInput);
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
        pushMarkPrice(marketId, markPrice);

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
     * @notice Test that mark price staleness is enforced
     * @dev Pushes a mark price, warps forward past max stale duration, verifies fill reverts
     */
    function check_PerpMarkPriceStaleness(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();

        // Push mark price
        pushMarkPrice(marketId, 3000e18);

        // Create accounts
        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 10_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 10_000e6);

        // Warp forward past max stale duration (e.g., 1 hour + 1 second)
        vm.warp(block.timestamp + 3601);
        mockFreshPrices();

        // Attempt fill should revert due to stale mark price
        vm.expectRevert();
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
    }

    /**
     * @notice Test batch perp fill execution
     * @dev Executes multiple fills in a single transaction
     */
    function check_PerpBatchExecuteFill(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPrice(marketId, 3000e18);

        // Create accounts with sufficient collateral
        uint128 buyerAccountId = depositNewMA(perpBuyer, sec.rusd, 50_000e6);
        uint128 sellerAccountId = depositNewMA(perpSeller, sec.rusd, 50_000e6);

        // Create two fill inputs
        ExecuteFillInput[] memory fills = new ExecuteFillInput[](2);

        // Fill 1: 0.1 ETH at $3000
        {
            (ConditionalOrderDetails memory buyerOrder1, EIP712Signature memory buyerSig1) = createLimitOrderPerp({
                accountId: buyerAccountId,
                marketId: marketId,
                baseDelta: int256(0.1e18),
                price: 3000e18,
                nonce: 1,
                signer: perpBuyer,
                signerPk: perpBuyerPk
            });

            (ConditionalOrderDetails memory sellerOrder1, EIP712Signature memory sellerSig1) = createLimitOrderPerp({
                accountId: sellerAccountId,
                marketId: marketId,
                baseDelta: -int256(0.1e18),
                price: 3000e18,
                nonce: 1,
                signer: perpSeller,
                signerPk: perpSellerPk
            });

            SignedMatchingEnginePayload memory mePayload1 = createPerpMatchingEnginePayload({
                price: 3000e18,
                baseDelta: 0.1e18,
                accountOrderId: 1,
                counterpartyOrderId: 2,
                nonce: 1
            });

            fills[0] = ExecuteFillInput({
                accountOrder: buyerOrder1,
                counterpartyOrder: sellerOrder1,
                accountSignature: buyerSig1,
                counterpartySignature: sellerSig1,
                mePayload: mePayload1
            });
        }

        // Fill 2: 0.2 ETH at $3010
        {
            (ConditionalOrderDetails memory buyerOrder2, EIP712Signature memory buyerSig2) = createLimitOrderPerp({
                accountId: buyerAccountId,
                marketId: marketId,
                baseDelta: int256(0.2e18),
                price: 3010e18,
                nonce: 2,
                signer: perpBuyer,
                signerPk: perpBuyerPk
            });

            (ConditionalOrderDetails memory sellerOrder2, EIP712Signature memory sellerSig2) = createLimitOrderPerp({
                accountId: sellerAccountId,
                marketId: marketId,
                baseDelta: -int256(0.2e18),
                price: 3010e18,
                nonce: 2,
                signer: perpSeller,
                signerPk: perpSellerPk
            });

            SignedMatchingEnginePayload memory mePayload2 = createPerpMatchingEnginePayload({
                price: 3010e18,
                baseDelta: 0.2e18,
                accountOrderId: 3,
                counterpartyOrderId: 4,
                nonce: 2
            });

            fills[1] = ExecuteFillInput({
                accountOrder: buyerOrder2,
                counterpartyOrder: sellerOrder2,
                accountSignature: buyerSig2,
                counterpartySignature: sellerSig2,
                mePayload: mePayload2
            });
        }

        vm.prank(sec.coExecutionBot);
        IOrdersGatewayProxy(sec.ordersGateway).batchExecuteFill(fills);

        // Verify combined position
        PerpPosition memory buyerPosition = IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, buyerAccountId);
        assertEq(buyerPosition.base, int256(0.3e18), "Buyer should have 0.3 ETH long");

        PerpPosition memory sellerPosition =
            IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(marketId, sellerAccountId);
        assertEq(sellerPosition.base, -int256(0.3e18), "Seller should have 0.3 ETH short");
    }
}
