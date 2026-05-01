pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";
import { ICoreProxy, CollateralInfo, SpotMarketConfig, SpotMarketData } from "../../../src/interfaces/ICoreProxy.sol";
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

/**
 * @title SpotPerpOBForkCheck
 * @notice perpOB fork tests for spot fill execution
 * @dev Mirrors the devnet-exercised subset of SpotForkCheck but constructs orders using the
 *      unified OrderDetails schema introduced in orders-gateway 1.0.22. Legacy SpotForkCheck
 *      is kept for cronos/mainnet routes that still run the pre-orderbook signature schema.
 */
contract SpotPerpOBForkCheck is BaseReyaForkTest {
    address internal spotBuyer;
    uint256 internal spotBuyerPk;
    address internal spotSeller;
    uint256 internal spotSellerPk;
    address internal spotMatchingEngine;
    uint256 internal spotMatchingEnginePk;

    bytes32 internal constant MATCHING_ENGINE_PUBLISHER_FLAG = keccak256(bytes("matching_engine_publisher"));

    // Orders gateway encodes spot markets in the signed OrderDetails.marketId using a namespace offset.
    // See orders-gateway/src/libraries/MarketIdCodec.sol :: SPOT_MARKET_ID_OFFSET.
    uint128 internal constant SPOT_MARKET_ID_OFFSET = 1e10;

    function toSignedSpotMarketId(uint128 coreSpotMarketId) internal pure returns (uint128) {
        return coreSpotMarketId + SPOT_MARKET_ID_OFFSET;
    }

    function removeOraclePriceDeviationConfig(uint128 spotMarketId) internal {
        SpotMarketData memory marketData = ICoreProxy(sec.core).getSpotMarketData(spotMarketId);
        SpotMarketConfig memory newConfig = SpotMarketConfig({
            oracleDeviation: 0,
            minimumOrderBase: marketData.config.minimumOrderBase,
            baseSpacing: marketData.config.baseSpacing,
            priceSpacing: marketData.config.priceSpacing,
            oracleNodeId: bytes32(0)
        });
        vm.prank(sec.multisig);
        ICoreProxy(sec.core).setSpotMarketConfiguration(spotMarketId, newConfig);
    }

    function setupSpotTestActors() internal {
        (spotBuyer, spotBuyerPk) = makeAddrAndKey("spotBuyer");
        (spotSeller, spotSellerPk) = makeAddrAndKey("spotSeller");
        (spotMatchingEngine, spotMatchingEnginePk) = makeAddrAndKey("spotMatchingEngine");

        vm.prank(sec.multisig);
        IOrdersGatewayProxy(sec.ordersGateway).addToFeatureFlagAllowlist(
            MATCHING_ENGINE_PUBLISHER_FLAG, spotMatchingEngine
        );
    }

    function createLimitOrderSpot(
        uint128 accountId,
        uint128 spotMarketId,
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
            marketId: toSignedSpotMarketId(spotMarketId),
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

    function createMatchingEnginePayload(
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
            vm.sign(spotMatchingEnginePk, FillHashing.mockCalculateDigest(fillDetails, deadline, sec.ordersGateway));

        return SignedMatchingEnginePayload({
            fillDetails: fillDetails,
            signature: EIP712Signature({ v: v, r: r, s: s, deadline: deadline })
        });
    }

    function depositWethToAccount(address user, uint128 accountId, uint256 amount) internal {
        deal(sec.weth, user, amount);
        vm.startPrank(user);
        ITokenProxy(sec.weth).approve(sec.core, amount);
        ICoreProxy(sec.core).deposit(accountId, sec.weth, amount);
        vm.stopPrank();
    }

    function createOrGetSpotAccountWithRusdDeposit(address user, uint256 amount) internal returns (uint128 accountId) {
        vm.prank(user);
        accountId = ICoreProxy(sec.core).createOrGetSpotAccount(user);
        deal(sec.rusd, user, amount);
        vm.startPrank(user);
        ITokenProxy(sec.rusd).approve(sec.core, amount);
        ICoreProxy(sec.core).deposit(accountId, sec.rusd, amount);
        vm.stopPrank();
    }

    function executeSpotFill(
        uint128 buyerAccountId,
        uint128 sellerAccountId,
        uint128 spotMarketId,
        uint256 baseDelta,
        uint256 price,
        uint256 buyerNonce,
        uint256 sellerNonce,
        uint256 meNonce
    )
        internal
    {
        (OrderDetails memory buyerOrder, EIP712Signature memory buyerSig) = createLimitOrderSpot({
            accountId: buyerAccountId,
            spotMarketId: spotMarketId,
            baseDelta: int256(baseDelta),
            price: price,
            nonce: buyerNonce,
            signer: spotBuyer,
            signerPk: spotBuyerPk
        });

        (OrderDetails memory sellerOrder, EIP712Signature memory sellerSig) = createLimitOrderSpot({
            accountId: sellerAccountId,
            spotMarketId: spotMarketId,
            baseDelta: -int256(baseDelta),
            price: price,
            nonce: sellerNonce,
            signer: spotSeller,
            signerPk: spotSellerPk
        });

        SignedMatchingEnginePayload memory mePayload = createMatchingEnginePayload({
            price: price,
            baseDelta: baseDelta,
            accountOrderId: 1,
            counterpartyOrderId: 2,
            nonce: meNonce
        });

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

    function check_SpotExecuteFill_WETH(uint128 wethSpotMarketId) internal {
        setupSpotTestActors();
        mockFreshPrices();
        removeOraclePriceDeviationConfig(wethSpotMarketId);

        uint128 buyerAccountId = createOrGetSpotAccountWithRusdDeposit(spotBuyer, 10_000e6);
        uint128 sellerAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(spotSeller);
        depositWethToAccount(spotSeller, sellerAccountId, 10e18);

        int256 buyerRusdBefore = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).netDeposits;
        int256 sellerRusdBefore = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).netDeposits;
        int256 sellerWethBefore = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.weth).netDeposits;

        uint256 baseDelta = 0.1e18;
        uint256 price = 3000e18;

        executeSpotFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            spotMarketId: wethSpotMarketId,
            baseDelta: baseDelta,
            price: price,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        int256 buyerRusdAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).netDeposits;
        int256 buyerWethAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.weth).netDeposits;
        int256 sellerRusdAfter = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).netDeposits;
        int256 sellerWethAfter = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.weth).netDeposits;

        // rUSD has 6 decimals, price has 18 decimals, base has 18 decimals → divide by 1e30
        uint256 expectedRusdDelta = (baseDelta * price) / 1e30;

        assertEq(buyerRusdAfter, buyerRusdBefore - int256(expectedRusdDelta), "Buyer rUSD balance incorrect");
        assertEq(buyerWethAfter, int256(baseDelta), "Buyer WETH balance incorrect");
        assertEq(sellerRusdAfter, sellerRusdBefore + int256(expectedRusdDelta), "Seller rUSD balance incorrect");
        assertEq(sellerWethAfter, sellerWethBefore - int256(baseDelta), "Seller WETH balance incorrect");
    }

    function check_SpotExecuteFill_SmallQuantity_And_Price_WETH(uint128 wethSpotMarketId) internal {
        setupSpotTestActors();
        mockFreshPrices();
        removeOraclePriceDeviationConfig(wethSpotMarketId);

        uint128 buyerAccountId = createOrGetSpotAccountWithRusdDeposit(spotBuyer, 10_000e6);
        uint128 sellerAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(spotSeller);
        depositWethToAccount(spotSeller, sellerAccountId, 10e18);

        int256 buyerRusdBefore = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).netDeposits;
        int256 sellerWethBefore = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.weth).netDeposits;

        uint256 baseDelta = 0.001e18;
        uint256 price = 312_383e16; // 3123.83 with 18 decimals

        executeSpotFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            spotMarketId: wethSpotMarketId,
            baseDelta: baseDelta,
            price: price,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        int256 buyerRusdAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).netDeposits;
        int256 buyerWethAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.weth).netDeposits;
        int256 sellerRusdAfter = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).netDeposits;
        int256 sellerWethAfter = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.weth).netDeposits;

        assertEq(buyerRusdAfter, buyerRusdBefore - 3_123_830, "Buyer rUSD balance incorrect");
        assertEq(buyerWethAfter, int256(baseDelta), "Buyer WETH balance incorrect");
        assertEq(sellerRusdAfter, 3_123_830, "Seller rUSD balance incorrect");
        assertEq(sellerWethAfter, sellerWethBefore - int256(baseDelta), "Seller WETH balance incorrect");
    }

    function check_SpotBatchExecuteFill_WETH(uint128 wethSpotMarketId) internal {
        setupSpotTestActors();
        mockFreshPrices();
        removeOraclePriceDeviationConfig(wethSpotMarketId);

        uint128 buyerAccountId = createOrGetSpotAccountWithRusdDeposit(spotBuyer, 20_000e6);
        uint128 sellerAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(spotSeller);
        depositWethToAccount(spotSeller, sellerAccountId, 10e18);

        ExecuteFillInputV2[] memory fills = new ExecuteFillInputV2[](2);

        {
            (OrderDetails memory buyerOrder1, EIP712Signature memory buyerSig1) = createLimitOrderSpot({
                accountId: buyerAccountId,
                spotMarketId: wethSpotMarketId,
                baseDelta: int256(0.1e18),
                price: 3000e18,
                nonce: 1,
                signer: spotBuyer,
                signerPk: spotBuyerPk
            });

            (OrderDetails memory sellerOrder1, EIP712Signature memory sellerSig1) = createLimitOrderSpot({
                accountId: sellerAccountId,
                spotMarketId: wethSpotMarketId,
                baseDelta: -int256(0.1e18),
                price: 3000e18,
                nonce: 1,
                signer: spotSeller,
                signerPk: spotSellerPk
            });

            SignedMatchingEnginePayload memory mePayload1 = createMatchingEnginePayload({
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

        {
            (OrderDetails memory buyerOrder2, EIP712Signature memory buyerSig2) = createLimitOrderSpot({
                accountId: buyerAccountId,
                spotMarketId: wethSpotMarketId,
                baseDelta: int256(0.2e18),
                price: 3000e18,
                nonce: 2,
                signer: spotBuyer,
                signerPk: spotBuyerPk
            });

            (OrderDetails memory sellerOrder2, EIP712Signature memory sellerSig2) = createLimitOrderSpot({
                accountId: sellerAccountId,
                spotMarketId: wethSpotMarketId,
                baseDelta: -int256(0.2e18),
                price: 3000e18,
                nonce: 2,
                signer: spotSeller,
                signerPk: spotSellerPk
            });

            SignedMatchingEnginePayload memory mePayload2 = createMatchingEnginePayload({
                price: 3000e18,
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

        int256 buyerRusdBefore = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).netDeposits;
        int256 sellerWethBefore = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.weth).netDeposits;

        vm.prank(sec.coExecutionBot);
        IOrdersGatewayProxyV2(sec.ordersGateway).batchExecuteFill(fills);

        int256 buyerRusdAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).netDeposits;
        int256 buyerWethAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.weth).netDeposits;
        int256 sellerRusdAfter = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).netDeposits;
        int256 sellerWethAfter = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.weth).netDeposits;

        assertEq(buyerRusdAfter, buyerRusdBefore - 900e6, "Buyer rUSD balance incorrect");
        assertEq(buyerWethAfter, 0.3e18, "Buyer WETH balance incorrect");
        assertEq(sellerRusdAfter, 900e6, "Seller rUSD balance incorrect");
        assertEq(sellerWethAfter, sellerWethBefore - 0.3e18, "Seller WETH balance incorrect");
    }
}
