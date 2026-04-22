pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import { ICoreProxy, MarginInfo, RiskMultipliers, CollateralInfo } from "../../../src/interfaces/ICoreProxy.sol";
import {
    IPassivePerpProxy,
    PerpPosition,
    EIP712Signature as PerpEIP712Signature,
    GlobalFeeParameters
} from "../../../src/interfaces/IPassivePerpProxy.sol";
import {
    IPassivePerpProxyV2,
    OracleDataPayload,
    OracleDataType,
    FeeTierParameters
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
    ExecuteFillInputV2
} from "../../../src/interfaces/IOrdersGatewayProxyV2.sol";
import { OrderDetailsHashing } from "../../../src/utils/OrderDetailsHashing.sol";
import { FillHashing } from "../../../src/utils/FillHashing.sol";
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

        // Matching engine payload
        SignedMatchingEnginePayload memory mePayload = createPerpMatchingEnginePayload({
            price: price,
            baseDelta: baseDelta,
            accountOrderId: 1,
            counterpartyOrderId: 2,
            nonce: meNonce
        });

        // Execute fill
        ExecuteFillInputV2 memory fillInput = ExecuteFillInputV2({
            accountOrder: buyerOrder,
            counterpartyOrder: sellerOrder,
            accountSignature: buyerSig,
            counterpartySignature: sellerSig,
            mePayload: mePayload
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
        pushMarkPrice(marketId, 3000e18);

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

            SignedMatchingEnginePayload memory mePayload1 = createPerpMatchingEnginePayload({
                price: 3000e18,
                baseDelta: 0.1e18,
                accountOrderId: 1,
                counterpartyOrderId: 2,
                nonce: 1
            });

            fills[0] = ExecuteFillInputV2({
                accountOrder: buyerOrder1,
                counterpartyOrder: sellerOrder1,
                accountSignature: buyerSig1,
                counterpartySignature: sellerSig1,
                mePayload: mePayload1
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

            SignedMatchingEnginePayload memory mePayload2 = createPerpMatchingEnginePayload({
                price: 3010e18,
                baseDelta: 0.2e18,
                accountOrderId: 3,
                counterpartyOrderId: 4,
                nonce: 2
            });

            fills[1] = ExecuteFillInputV2({
                accountOrder: buyerOrder2,
                counterpartyOrder: sellerOrder2,
                accountSignature: buyerSig2,
                counterpartySignature: sellerSig2,
                mePayload: mePayload2
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
        pushMarkPrice(marketId, 3000e18);
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
        pushMarkPrice(marketId, 3000e18);
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
        pushMarkPrice(marketId, 3000e18);
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

        // Close: buyer sells 0.5 ETH (negative baseDelta), seller buys 0.5 ETH (positive baseDelta)
        // Build orders manually since executePerpFill assumes perpBuyer=long
        {
            // perpBuyer's order: sell 0.5 ETH (negative baseDelta = short/close)
            (OrderDetails memory buyerCloseOrder, EIP712Signature memory buyerCloseSig) =
            createLimitOrderPerp({
                accountId: buyerAccountId,
                marketId: marketId,
                baseDelta: -int256(0.5e18),
                price: 3000e18,
                nonce: 2,
                signer: perpBuyer,
                signerPk: perpBuyerPk
            });

            // perpSeller's order: buy 0.5 ETH (positive baseDelta = long/close short)
            (OrderDetails memory sellerCloseOrder, EIP712Signature memory sellerCloseSig) =
            createLimitOrderPerp({
                accountId: sellerAccountId,
                marketId: marketId,
                baseDelta: int256(0.5e18),
                price: 3000e18,
                nonce: 2,
                signer: perpSeller,
                signerPk: perpSellerPk
            });

            // ME payload: seller (buying) is the "account", buyer (selling) is the "counterparty"
            SignedMatchingEnginePayload memory mePayload = createPerpMatchingEnginePayload({
                price: 3000e18,
                baseDelta: 0.5e18,
                accountOrderId: 3,
                counterpartyOrderId: 4,
                nonce: 2
            });

            ExecuteFillInputV2 memory fillInput = ExecuteFillInputV2({
                accountOrder: sellerCloseOrder,
                counterpartyOrder: buyerCloseOrder,
                accountSignature: sellerCloseSig,
                counterpartySignature: buyerCloseSig,
                mePayload: mePayload
            });

            vm.prank(sec.coExecutionBot);
            IOrdersGatewayProxyV2(sec.ordersGateway).executeFill(fillInput);
        }

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
        pushMarkPrice(marketId, 3000e18);
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
        pushMarkPrice(marketId, 3100e18);
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
        pushMarkPrice(marketId, 2800e18);
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
     * @notice Test that fees are correctly deducted from both buyer and seller on a perp fill
     * @dev Devnet fee config: tier0 taker=0.04%, maker=0.04%, no discounts, no maker rebate.
     *      Fee per side = |baseDelta| * fillPrice * 0.0004.
     *      We verify by checking getCollateralInfo(accountId, rusd).realBalance before/after.
     *      Unrealized PnL only affects marginBalance, not realBalance, so only fees change realBalance.
     */
    function check_PerpFillFees(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPrice(marketId, 3000e18);
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

        int256 buyerBalAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).realBalance;
        int256 sellerBalAfter = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).realBalance;

        int256 buyerPaid = buyerBalBefore - buyerBalAfter;
        int256 sellerPaid = sellerBalBefore - sellerBalAfter;

        // Expected fee per side = 1 ETH * $3000 * 0.0004 = $1.20 = 1.2e6 rUSD
        int256 expectedFee = 1.2e6;

        assertEq(buyerPaid, expectedFee, "Buyer should pay exactly 4bps taker fee");
        assertEq(sellerPaid, expectedFee, "Seller should pay exactly 4bps maker fee");
        assertGt(buyerPaid, 0, "Buyer fee should be positive");
        assertGt(sellerPaid, 0, "Seller fee should be positive");
    }

    /**
     * @notice Test zero fees when market zero-fee flag is enabled
     * @dev Enables the marketZeroFees flag, executes a fill, and verifies no fees are charged.
     */
    function check_PerpFillZeroFees(uint128 marketId, address zeroFeeBot) internal {
        setupPerpTestActors();
        mockFreshPrices();

        // Enable zero fees for this market
        bytes32 flagId = keccak256(abi.encode(keccak256(bytes("marketZeroFees")), marketId));
        vm.prank(zeroFeeBot);
        IPassivePerpProxy(sec.perp).setFeatureFlagAllowAll(flagId, true);

        pushMarkPrice(marketId, 3000e18);
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

        assertEq(buyerPaid, 0, "Buyer should pay zero fees");
        assertEq(sellerPaid, 0, "Seller should pay zero fees");

        // Restore default (fees on)
        vm.prank(zeroFeeBot);
        IPassivePerpProxy(sec.perp).setFeatureFlagAllowAll(flagId, false);
    }

    /**
     * @notice Test that insufficient margin blocks a perp fill
     * @dev Attempts to open a position larger than what the margin can support.
     *      With $10 deposit and 1 ETH at $3000 → ~300x leverage, well beyond the 25x limit.
     *      Verifies that the revert is specifically AccountBelowIM for the buyer's account
     *      (the seller has $100k collateral and should not be the one failing).
     */
    function check_PerpFillInsufficientMargin(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPrice(marketId, 3000e18);
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

            fillInput = ExecuteFillInputV2({
                accountOrder: buyerOrder,
                counterpartyOrder: sellerOrder,
                accountSignature: buyerSig,
                counterpartySignature: sellerSig,
                mePayload: createPerpMatchingEnginePayload({
                    price: 3000e18,
                    baseDelta: 1e18,
                    accountOrderId: 1,
                    counterpartyOrderId: 2,
                    nonce: 1
                })
            });
        }

        // Execute and verify the revert is AccountBelowIM for the buyer's account specifically
        vm.prank(sec.coExecutionBot);
        try IOrdersGatewayProxyV2(sec.ordersGateway).executeFill(fillInput) {
            revert("Expected AccountBelowIM revert for underfunded buyer");
        } catch (bytes memory revertData) {
            assertEq(bytes4(revertData), ICoreProxy.AccountBelowIM.selector, "Should revert with AccountBelowIM");

            // Decode accountId: AccountBelowIM(uint128 accountId, int256 delta)
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
        pushMarkPrice(marketId, 3000e18);
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
                expiresAfter: 0,
                signer: perpBuyer,
                nonce: 2
            });

            uint256 deadline = block.timestamp + 3600;
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(
                perpBuyerPk, OrderDetailsHashing.mockCalculateDigest(reduceOrder, deadline, sec.ordersGateway)
            );
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

            SignedMatchingEnginePayload memory mePayload = createPerpMatchingEnginePayload({
                price: 3000e18,
                baseDelta: 0.5e18,
                accountOrderId: 3,
                counterpartyOrderId: 4,
                nonce: 2
            });

            ExecuteFillInputV2 memory fillInput = ExecuteFillInputV2({
                accountOrder: reduceOrder,
                counterpartyOrder: sellerOrder,
                accountSignature: reduceSig,
                counterpartySignature: sellerSig,
                mePayload: mePayload
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
        pushMarkPrice(marketId, 3000e18);
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
        pushMarkPrice(marketId, 3000e18);
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
                expiresAfter: 0,
                signer: perpBuyer,
                nonce: 2
            });

            uint256 deadline = block.timestamp + 3600;
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(
                perpBuyerPk, OrderDetailsHashing.mockCalculateDigest(reduceOrder, deadline, sec.ordersGateway)
            );
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

            fillInput = ExecuteFillInputV2({
                accountOrder: reduceOrder,
                counterpartyOrder: sellerOrder,
                accountSignature: reduceSig,
                counterpartySignature: sellerSig,
                mePayload: createPerpMatchingEnginePayload({
                    price: 3000e18,
                    baseDelta: 0.5e18,
                    accountOrderId: 3,
                    counterpartyOrderId: 4,
                    nonce: 2
                })
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

    int256 private constant BASIC_TIER_FEE_PERCENTAGE = 0.0004e18;

    /**
     * @notice Test that OG/VLTZ fee discounts apply to perpOB fills
     * @dev Mirrors the AMM-based check_MatchOrder_FeeDiscounts in Order.fork.c.sol.
     *      Applies OG and/or VLTZ discount to the buyer, verifies reduced fee.
     *      Seller has no discounts and should pay the full 4bps fee.
     */
    function check_PerpFillFeeDiscounts(uint128 marketId, bool ogDiscount, bool vltzDiscount) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPrice(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        IPassivePerpProxy perp = IPassivePerpProxy(sec.perp);

        // Set up fee config bot with configureFees permission
        (address feeBot,) = makeAddrAndKey("feeBot");
        vm.prank(sec.multisig);
        perp.addToFeatureFlagAllowlist(keccak256(bytes("configureFees")), feeBot);

        // Configure global discount parameters
        GlobalFeeParameters memory config = perp.getGlobalFeeParameters();
        config.ogDiscount = ogDiscount ? 0.2e18 : 0; // 20% OG discount
        config.vltzDiscount = vltzDiscount ? 0.1e18 : 0; // 10% VLTZ discount
        vm.prank(sec.multisig);
        perp.setGlobalFeeParameters(config);

        // Apply discounts to buyer only — seller gets no discounts
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

        // Compute expected discounted fee for buyer
        // Base fee = 1 ETH * $3000 * 0.0004 = $1.20 = 1.2e6 rUSD
        SD59x18 feeRate = sd(BASIC_TIER_FEE_PERCENTAGE);
        if (ogDiscount) feeRate = feeRate.mul(ONE_sd.sub(sd(0.2e18)));
        if (vltzDiscount) feeRate = feeRate.mul(ONE_sd.sub(sd(0.1e18)));
        int256 expectedBuyerFee = sd(3000e18).mul(sd(1e18)).mul(feeRate).unwrap() / 1e12;

        // Seller pays full fee (no discounts applied)
        int256 expectedSellerFee = sd(3000e18).mul(sd(1e18)).mul(sd(BASIC_TIER_FEE_PERCENTAGE)).unwrap() / 1e12;

        assertEq(buyerPaid, expectedBuyerFee, "Buyer should pay discounted fee");
        assertEq(sellerPaid, expectedSellerFee, "Seller should pay full fee (no discount)");

        // Verify discounts actually reduced the buyer's fee vs the base rate
        if (ogDiscount || vltzDiscount) {
            assertLt(buyerPaid, expectedSellerFee, "Buyer fee should be less than seller fee due to discounts");
        }
    }

    /**
     * @notice Test that exchange-level zero-fee flag disables fees for perpOB fills
     * @dev Similar to check_PerpFillZeroFees (market-level), but uses the exchangeZeroFees flag.
     *      PerpOB fills use exchangeId=1, so we toggle that flag.
     */
    function check_PerpFillExchangeZeroFees(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPrice(marketId, 3000e18);
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

        assertEq(buyerPaid, 0, "Buyer should pay zero fees (exchange zero-fee)");
        assertEq(sellerPaid, 0, "Seller should pay zero fees (exchange zero-fee)");

        // Restore default (fees on)
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).setFeatureFlagAllowAll(flagId, false);
    }

    /**
     * @notice Exercise the maker-rebate fee path (1.0.52 feature).
     * @dev makerRebate is the UD60x18 fraction of REMAINING taker fee (after referrer & exchange
     *      rebates) that is credited back to the maker — not a rate on notional. With a 50%
     *      rebate and the devnet passive-pool exchange rebate of 20%, the math is:
     *        takerFeeDebit    = takerFeeParameter * exposure = 4bps * 3000 rUSD = 1.20 rUSD
     *        exchangeFeeCredit = 20% * 1.20                                    = 0.24 rUSD
     *        remaining        = 1.20 - 0 - 0.24                                = 0.96 rUSD
     *        makerFeeCredit   = 50% * 0.96                                     = 0.48 rUSD
     */
    function check_PerpFillMakerRebate(uint128 marketId) internal {
        setupPerpTestActors();
        mockFreshPrices();
        pushMarkPrice(marketId, 3000e18);
        pushFundingRate(marketId, 0);

        // Configure tier 0: taker 4bps, no maker fee, 50% maker rebate (fraction of remaining).
        FeeTierParameters memory originalTier0 = IPassivePerpProxyV2(sec.perp).getFeeTierParameters(0);
        vm.prank(sec.multisig);
        IPassivePerpProxyV2(sec.perp).setFeeTierParameters(
            0, FeeTierParameters({ takerFee: 4e14, makerFee: 0, makerRebate: 5e17 })
        );

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

        int256 buyerDelta =
            ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).realBalance - buyerBalBefore;
        int256 sellerDelta =
            ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).realBalance - sellerBalBefore;

        // Taker (buyer) pays 4bps of 3000 rUSD/ETH on 1 ETH = 1.2 rUSD debit (6-decimal rUSD).
        assertEq(buyerDelta, -int256(1.2e6), "Taker should pay 4bps fee");
        // Maker (seller) receives 50% of remaining (after 20% exchange rebate) = 0.48 rUSD credit.
        assertEq(sellerDelta, int256(0.48e6), "Maker should receive 50% of remaining as rebate credit");

        // Restore tier 0 so any subsequent tests see defaults.
        vm.prank(sec.multisig);
        IPassivePerpProxyV2(sec.perp).setFeeTierParameters(0, originalTier0);
    }

    /**
     * @notice Assert that setFeeTierParameters rejects both maker fee and rebate being nonzero.
     * @dev Mutual-exclusion invariant introduced with the rebate field in 1.0.52.
     */
    function check_MakerFeeAndRebateMutuallyExclusive() internal {
        FeeTierParameters memory originalTier0 = IPassivePerpProxyV2(sec.perp).getFeeTierParameters(0);

        vm.prank(sec.multisig);
        vm.expectRevert(IPassivePerpProxyV2.MakerFeeAndRebateBothNonZero.selector);
        IPassivePerpProxyV2(sec.perp).setFeeTierParameters(
            0, FeeTierParameters({ takerFee: 4e14, makerFee: 4e14, makerRebate: 2e14 })
        );

        // Nothing should have changed.
        FeeTierParameters memory after_ = IPassivePerpProxyV2(sec.perp).getFeeTierParameters(0);
        assertEq(after_.takerFee, originalTier0.takerFee, "takerFee unchanged");
        assertEq(after_.makerFee, originalTier0.makerFee, "makerFee unchanged");
        assertEq(after_.makerRebate, originalTier0.makerRebate, "makerRebate unchanged");
    }
}
