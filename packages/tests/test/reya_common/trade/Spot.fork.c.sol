pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";
import { ICoreProxy, CollateralInfo, SpotMarketConfig, SpotMarketData } from "../../../src/interfaces/ICoreProxy.sol";
import {
    IOrdersGatewayProxy,
    ConditionalOrderDetails,
    EIP712Signature,
    ExecuteFillInput,
    SignedMatchingEnginePayload,
    FillDetails,
    LimitOrderSpotDetails,
    OrderType
} from "../../../src/interfaces/IOrdersGatewayProxy.sol";
import { ConditionalOrderHashing } from "../../../src/utils/ConditionalOrderHashing.sol";
import { FillHashing } from "../../../src/utils/FillHashing.sol";

import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

/**
 * @title SpotForkCheck
 * @notice Fork tests for spot execution functionality
 * @dev Tests executeFill and batchExecuteFill via the Orders Gateway.
 *      Only WETH spot market is enabled; other markets should revert with FeatureUnavailable.
 */
contract SpotForkCheck is BaseReyaForkTest {
    // Error selectors for feature detection
    bytes4 internal constant UNKNOWN_SELECTOR_ERROR = bytes4(keccak256("UnknownSelector(bytes4)"));
    // Test actors
    address internal buyer;
    uint256 internal buyerPk;
    address internal seller;
    uint256 internal sellerPk;
    address internal matchingEngine;
    uint256 internal matchingEnginePk;

    // Feature flag constants (must match FeatureFlagSupport._MATCHING_ENGINE_PUBLISHER_FEATURE_FLAG)
    bytes32 internal constant MATCHING_ENGINE_PUBLISHER_FLAG = keccak256(bytes("matching_engine_publisher"));

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
        (buyer, buyerPk) = makeAddrAndKey("spotBuyer");
        (seller, sellerPk) = makeAddrAndKey("spotSeller");
        (matchingEngine, matchingEnginePk) = makeAddrAndKey("matchingEngine");

        // Grant matching engine publisher access on Orders Gateway
        vm.prank(sec.multisig);
        IOrdersGatewayProxy(sec.ordersGateway).addToFeatureFlagAllowlist(MATCHING_ENGINE_PUBLISHER_FLAG, matchingEngine);
    }

    function getSpotMarketEnabledFeatureFlagId(uint128 spotMarketId) internal pure returns (bytes32) {
        return keccak256(abi.encode(keccak256(bytes("spotMarketEnabled")), spotMarketId));
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
        returns (ConditionalOrderDetails memory order, EIP712Signature memory sig)
    {
        uint128[] memory counterpartyAccountIds = new uint128[](0);

        bytes memory inputs = abi.encode(LimitOrderSpotDetails({ baseDelta: baseDelta, price: price }));

        order = ConditionalOrderDetails({
            accountId: accountId,
            marketId: spotMarketId,
            exchangeId: 1,
            counterpartyAccountIds: counterpartyAccountIds,
            orderType: uint8(OrderType.LimitOrderSpot),
            inputs: inputs,
            signer: signer,
            nonce: nonce
        });

        uint256 deadline = block.timestamp + 3600;
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(signerPk, ConditionalOrderHashing.mockCalculateDigest(order, deadline, sec.ordersGateway));

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
            vm.sign(matchingEnginePk, FillHashing.mockCalculateDigest(fillDetails, deadline, sec.ordersGateway));

        EIP712Signature memory sig = EIP712Signature({ v: v, r: r, s: s, deadline: deadline });

        return SignedMatchingEnginePayload({ fillDetails: fillDetails, signature: sig });
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
        // Deposit rUSD directly (not USDC through periphery)
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
        // Buyer order (positive baseDelta = buying base token)
        (ConditionalOrderDetails memory buyerOrder, EIP712Signature memory buyerSig) = createLimitOrderSpot({
            accountId: buyerAccountId,
            spotMarketId: spotMarketId,
            baseDelta: int256(baseDelta),
            price: price,
            nonce: buyerNonce,
            signer: buyer,
            signerPk: buyerPk
        });

        // Seller order (negative baseDelta = selling base token)
        (ConditionalOrderDetails memory sellerOrder, EIP712Signature memory sellerSig) = createLimitOrderSpot({
            accountId: sellerAccountId,
            spotMarketId: spotMarketId,
            baseDelta: -int256(baseDelta),
            price: price,
            nonce: sellerNonce,
            signer: seller,
            signerPk: sellerPk
        });

        // Matching engine payload
        SignedMatchingEnginePayload memory mePayload = createMatchingEnginePayload({
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

        // Execute as the conditional order execution bot (which is on the allowlist)
        vm.prank(sec.coExecutionBot);
        IOrdersGatewayProxy(sec.ordersGateway).executeFill(fillInput);
    }

    /**
     * @notice Test basic spot fill execution for WETH market
     * @dev Verifies that buyer receives WETH and seller receives rUSD
     */
    function check_SpotExecuteFill_WETH(uint128 wethSpotMarketId) internal {
        setupSpotTestActors();
        mockFreshPrices();
        removeOraclePriceDeviationConfig(wethSpotMarketId);

        // Create accounts
        uint128 buyerAccountId = createOrGetSpotAccountWithRusdDeposit(buyer, 10_000e6);
        uint128 sellerAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(seller);
        depositWethToAccount(seller, sellerAccountId, 10e18);

        // Record initial balances
        int256 buyerRusdBefore = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).netDeposits;
        int256 sellerRusdBefore = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).netDeposits;
        int256 sellerWethBefore = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.weth).netDeposits;

        // Execute spot fill: buyer buys 0.1 WETH at $3000
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

        // Verify balances
        int256 buyerRusdAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).netDeposits;
        int256 buyerWethAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.weth).netDeposits;
        int256 sellerRusdAfter = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).netDeposits;
        int256 sellerWethAfter = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.weth).netDeposits;

        // The quote token (rUSD) uses 6 decimals while prices are 18 decimals, so
        // the effective transfer is baseDelta * price / 1e30 (rounded down)
        uint256 expectedRusdDelta = (baseDelta * price) / 1e30;

        assertEq(buyerRusdAfter, buyerRusdBefore - int256(expectedRusdDelta), "Buyer rUSD balance incorrect");
        assertEq(buyerWethAfter, int256(baseDelta), "Buyer WETH balance incorrect");

        assertEq(sellerRusdAfter, sellerRusdBefore + int256(expectedRusdDelta), "Seller rUSD balance incorrect");
        assertEq(sellerWethAfter, sellerWethBefore - int256(baseDelta), "Seller WETH balance incorrect");
    }

    /**
     * @notice Test basic spot fill execution for WETH market
     * @dev Verifies that buyer receives WETH and seller receives rUSD
     */
    function check_SpotExecuteFill_SmallQuantity_And_Price_WETH(uint128 wethSpotMarketId) internal {
        setupSpotTestActors();
        mockFreshPrices();
        removeOraclePriceDeviationConfig(wethSpotMarketId);

        // Create accounts
        uint128 buyerAccountId = createOrGetSpotAccountWithRusdDeposit(buyer, 10_000e6);
        uint128 sellerAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(seller);
        depositWethToAccount(seller, sellerAccountId, 10e18);

        // Record initial balances
        int256 buyerRusdBefore = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).netDeposits;
        int256 sellerWethBefore = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.weth).netDeposits;

        // Using base delta equal to the base spacing to test rounding
        uint256 baseDelta = 0.001e18;
        // Use a price with many significant digits to exercise rounding
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

        // Verify balances
        int256 buyerRusdAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).netDeposits;
        int256 buyerWethAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.weth).netDeposits;
        int256 sellerRusdAfter = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).netDeposits;
        int256 sellerWethAfter = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.weth).netDeposits;

        // Buyer: -3.123830 rUSD (0.001 * 3123.83), +0.001 WETH
        assertEq(buyerRusdAfter, buyerRusdBefore - 3_123_830, "Buyer rUSD balance incorrect");
        assertEq(buyerWethAfter, int256(baseDelta), "Buyer WETH balance incorrect");

        // Seller: +3.123830 rUSD, -0.001 WETH
        assertEq(sellerRusdAfter, 3_123_830, "Seller rUSD balance incorrect");
        assertEq(sellerWethAfter, sellerWethBefore - int256(baseDelta), "Seller WETH balance incorrect");
    }

    /**
     * @notice Test batch spot fill execution for WETH market
     * @dev Verifies that multiple fills can be executed in a single transaction
     */
    function check_SpotBatchExecuteFill_WETH(uint128 wethSpotMarketId) internal {
        setupSpotTestActors();
        mockFreshPrices();
        removeOraclePriceDeviationConfig(wethSpotMarketId);

        // Create accounts
        uint128 buyerAccountId = createOrGetSpotAccountWithRusdDeposit(buyer, 20_000e6);
        uint128 sellerAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(seller);
        depositWethToAccount(seller, sellerAccountId, 10e18);

        // Create two fill inputs
        ExecuteFillInput[] memory fills = new ExecuteFillInput[](2);

        // Fill 1: 0.1 WETH at $3000
        {
            (ConditionalOrderDetails memory buyerOrder1, EIP712Signature memory buyerSig1) = createLimitOrderSpot({
                accountId: buyerAccountId,
                spotMarketId: wethSpotMarketId,
                baseDelta: int256(0.1e18),
                price: 3000e18,
                nonce: 1,
                signer: buyer,
                signerPk: buyerPk
            });

            (ConditionalOrderDetails memory sellerOrder1, EIP712Signature memory sellerSig1) = createLimitOrderSpot({
                accountId: sellerAccountId,
                spotMarketId: wethSpotMarketId,
                baseDelta: -int256(0.1e18),
                price: 3000e18,
                nonce: 1,
                signer: seller,
                signerPk: sellerPk
            });

            SignedMatchingEnginePayload memory mePayload1 = createMatchingEnginePayload({
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

        // Fill 2: 0.2 WETH at $3000
        {
            (ConditionalOrderDetails memory buyerOrder2, EIP712Signature memory buyerSig2) = createLimitOrderSpot({
                accountId: buyerAccountId,
                spotMarketId: wethSpotMarketId,
                baseDelta: int256(0.2e18),
                price: 3000e18,
                nonce: 2,
                signer: buyer,
                signerPk: buyerPk
            });

            (ConditionalOrderDetails memory sellerOrder2, EIP712Signature memory sellerSig2) = createLimitOrderSpot({
                accountId: sellerAccountId,
                spotMarketId: wethSpotMarketId,
                baseDelta: -int256(0.2e18),
                price: 3000e18,
                nonce: 2,
                signer: seller,
                signerPk: sellerPk
            });

            SignedMatchingEnginePayload memory mePayload2 = createMatchingEnginePayload({
                price: 3000e18,
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

        // Record initial balances
        int256 buyerRusdBefore = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).netDeposits;
        int256 sellerWethBefore = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.weth).netDeposits;

        // Execute batch fill as the conditional order execution bot
        vm.prank(sec.coExecutionBot);
        bytes[] memory outputs = IOrdersGatewayProxy(sec.ordersGateway).batchExecuteFill(fills);

        // Verify outputs returned
        assertEq(outputs.length, 2, "Should return 2 outputs");

        // Verify balances
        int256 buyerRusdAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).netDeposits;
        int256 buyerWethAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.weth).netDeposits;
        int256 sellerRusdAfter = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).netDeposits;
        int256 sellerWethAfter = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.weth).netDeposits;

        // Total: 0.3 WETH at $3000 = 900 rUSD
        assertEq(buyerRusdAfter, buyerRusdBefore - 900e6, "Buyer rUSD balance incorrect");
        assertEq(buyerWethAfter, 0.3e18, "Buyer WETH balance incorrect");
        assertEq(sellerRusdAfter, 900e6, "Seller rUSD balance incorrect");
        assertEq(sellerWethAfter, sellerWethBefore - 0.3e18, "Seller WETH balance incorrect");
    }

    // ==================== WBTC Spot Market Checks ====================

    function depositWbtcToAccount(address user, uint128 accountId, uint256 amount) internal {
        deal(sec.wbtc, user, amount);
        vm.startPrank(user);
        ITokenProxy(sec.wbtc).approve(sec.core, amount);
        ICoreProxy(sec.core).deposit(accountId, sec.wbtc, amount);
        vm.stopPrank();
    }

    /**
     * @notice Test basic spot fill execution for WBTC market
     * @dev Verifies that buyer receives WBTC and seller receives rUSD
     *      Note: WBTC token uses 8 decimals, but order baseDelta uses 18 decimals
     */
    function check_SpotExecuteFill_WBTC(uint128 wbtcSpotMarketId) internal {
        setupSpotTestActors();
        mockFreshPrices();
        removeOraclePriceDeviationConfig(wbtcSpotMarketId);

        // Create accounts
        uint128 buyerAccountId = createOrGetSpotAccountWithRusdDeposit(buyer, 100_000e6);
        uint128 sellerAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(seller);
        depositWbtcToAccount(seller, sellerAccountId, 10e8); // 10 WBTC (8 decimals)

        // Record initial balances
        int256 buyerRusdBefore = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).netDeposits;
        int256 sellerRusdBefore = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).netDeposits;
        int256 sellerWbtcBefore = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.wbtc).netDeposits;

        // Execute spot fill: buyer buys 0.001 WBTC at $100,000
        // Order baseDelta uses 18 decimals (minimumOrderBase is 1e14 = 0.0001e18)
        uint256 baseDelta = 0.001e18; // 0.001 WBTC in 18 decimals
        uint256 price = 100_000e18; // $100,000 with 18 decimals

        executeSpotFill({
            buyerAccountId: buyerAccountId,
            sellerAccountId: sellerAccountId,
            spotMarketId: wbtcSpotMarketId,
            baseDelta: baseDelta,
            price: price,
            buyerNonce: 1,
            sellerNonce: 1,
            meNonce: 1
        });

        // Verify balances
        int256 buyerRusdAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).netDeposits;
        int256 buyerWbtcAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.wbtc).netDeposits;
        int256 sellerRusdAfter = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).netDeposits;
        int256 sellerWbtcAfter = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.wbtc).netDeposits;

        // baseDelta is 18 decimals, price is 18 decimals, rUSD is 6 decimals
        // expectedRusdDelta = baseDelta * price / 1e30
        uint256 expectedRusdDelta = (baseDelta * price) / 1e30;
        // WBTC balance delta: convert from 18 decimals to 8 decimals (divide by 1e10)
        uint256 expectedWbtcDelta = baseDelta / 1e10;

        assertEq(buyerRusdAfter, buyerRusdBefore - int256(expectedRusdDelta), "Buyer rUSD balance incorrect");
        assertEq(buyerWbtcAfter, int256(expectedWbtcDelta), "Buyer WBTC balance incorrect");

        assertEq(sellerRusdAfter, sellerRusdBefore + int256(expectedRusdDelta), "Seller rUSD balance incorrect");
        assertEq(sellerWbtcAfter, sellerWbtcBefore - int256(expectedWbtcDelta), "Seller WBTC balance incorrect");
    }

    /**
     * @notice Test batch spot fill execution for WBTC market
     * @dev Verifies that multiple fills can be executed in a single transaction
     *      Note: Order baseDelta uses 18 decimals
     */
    function check_SpotBatchExecuteFill_WBTC(uint128 wbtcSpotMarketId) internal {
        setupSpotTestActors();
        mockFreshPrices();
        removeOraclePriceDeviationConfig(wbtcSpotMarketId);

        // Create accounts
        uint128 buyerAccountId = createOrGetSpotAccountWithRusdDeposit(buyer, 500_000e6);
        uint128 sellerAccountId = ICoreProxy(sec.core).createOrGetSpotAccount(seller);
        depositWbtcToAccount(seller, sellerAccountId, 10e8); // 10 WBTC

        // Create two fill inputs
        ExecuteFillInput[] memory fills = new ExecuteFillInput[](2);

        // Fill 1: 0.001 WBTC at $100,000 (baseDelta in 18 decimals)
        {
            (ConditionalOrderDetails memory buyerOrder1, EIP712Signature memory buyerSig1) = createLimitOrderSpot({
                accountId: buyerAccountId,
                spotMarketId: wbtcSpotMarketId,
                baseDelta: int256(0.001e18),
                price: 100_000e18,
                nonce: 1,
                signer: buyer,
                signerPk: buyerPk
            });

            (ConditionalOrderDetails memory sellerOrder1, EIP712Signature memory sellerSig1) = createLimitOrderSpot({
                accountId: sellerAccountId,
                spotMarketId: wbtcSpotMarketId,
                baseDelta: -int256(0.001e18),
                price: 100_000e18,
                nonce: 1,
                signer: seller,
                signerPk: sellerPk
            });

            SignedMatchingEnginePayload memory mePayload1 = createMatchingEnginePayload({
                price: 100_000e18,
                baseDelta: 0.001e18,
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

        // Fill 2: 0.002 WBTC at $100,000 (baseDelta in 18 decimals)
        {
            (ConditionalOrderDetails memory buyerOrder2, EIP712Signature memory buyerSig2) = createLimitOrderSpot({
                accountId: buyerAccountId,
                spotMarketId: wbtcSpotMarketId,
                baseDelta: int256(0.002e18),
                price: 100_000e18,
                nonce: 2,
                signer: buyer,
                signerPk: buyerPk
            });

            (ConditionalOrderDetails memory sellerOrder2, EIP712Signature memory sellerSig2) = createLimitOrderSpot({
                accountId: sellerAccountId,
                spotMarketId: wbtcSpotMarketId,
                baseDelta: -int256(0.002e18),
                price: 100_000e18,
                nonce: 2,
                signer: seller,
                signerPk: sellerPk
            });

            SignedMatchingEnginePayload memory mePayload2 = createMatchingEnginePayload({
                price: 100_000e18,
                baseDelta: 0.002e18,
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

        // Record initial balances
        int256 buyerRusdBefore = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).netDeposits;
        int256 sellerWbtcBefore = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.wbtc).netDeposits;

        // Execute batch fill as the conditional order execution bot
        vm.prank(sec.coExecutionBot);
        bytes[] memory outputs = IOrdersGatewayProxy(sec.ordersGateway).batchExecuteFill(fills);

        // Verify outputs returned
        assertEq(outputs.length, 2, "Should return 2 outputs");

        // Verify balances
        int256 buyerRusdAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).netDeposits;
        int256 buyerWbtcAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.wbtc).netDeposits;
        int256 sellerRusdAfter = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.rusd).netDeposits;
        int256 sellerWbtcAfter = ICoreProxy(sec.core).getCollateralInfo(sellerAccountId, sec.wbtc).netDeposits;

        // Total: 0.003 WBTC (18 decimals) at $100,000 = 300 rUSD
        // WBTC balance in 8 decimals: 0.003e18 / 1e10 = 0.003e8 = 300000
        assertEq(buyerRusdAfter, buyerRusdBefore - 300e6, "Buyer rUSD balance incorrect");
        assertEq(buyerWbtcAfter, 0.003e8, "Buyer WBTC balance incorrect");
        assertEq(sellerRusdAfter, 300e6, "Seller rUSD balance incorrect");
        assertEq(sellerWbtcAfter, sellerWbtcBefore - 0.003e8, "Seller WBTC balance incorrect");
    }
}
