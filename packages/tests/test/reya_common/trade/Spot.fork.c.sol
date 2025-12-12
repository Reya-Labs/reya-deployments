pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";
import { ITokenProxy } from "../../../src/interfaces/ITokenProxy.sol";
import { ICoreProxy, CollateralInfo } from "../../../src/interfaces/ICoreProxy.sol";
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

    // Feature flag constants
    bytes32 internal constant MATCHING_ENGINE_PUBLISHER_FLAG = keccak256(bytes("matchingEnginePublisher"));

    function setupSpotTestActors() internal {
        (buyer, buyerPk) = makeAddrAndKey("spotBuyer");
        (seller, sellerPk) = makeAddrAndKey("spotSeller");
        (matchingEngine, matchingEnginePk) = makeAddrAndKey("matchingEngine");

        // Grant matching engine publisher access
        vm.prank(sec.multisig);
        IOrdersGatewayProxy(sec.ordersGateway).addToFeatureFlagAllowlist(MATCHING_ENGINE_PUBLISHER_FLAG, matchingEngine);
    }

    function getSpotMarketEnabledFeatureFlagId(uint128 spotMarketId) internal pure returns (bytes32) {
        return keccak256(abi.encode(keccak256(bytes("spotMarketEnabled")), spotMarketId));
    }

    function mockCalculateDigest(bytes32 hashedMessage, address verifyingContract) internal pure returns (bytes32) {
        bytes32 EIP712_REVISION_HASH = keccak256("1");
        bytes32 EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,address verifyingContract)");

        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    keccak256(
                        abi.encode(
                            EIP712_DOMAIN_TYPEHASH, keccak256(bytes("Reya")), EIP712_REVISION_HASH, verifyingContract
                        )
                    ),
                    hashedMessage
                )
            );
        }
        return digest;
    }

    function hashConditionalOrder(
        ConditionalOrderDetails memory order,
        uint256 deadline
    )
        internal
        pure
        returns (bytes32)
    {
        bytes32 CONDITIONAL_ORDER_TYPEHASH = keccak256(
            // solhint-disable-next-line max-line-length
            "ConditionalOrderDetails(uint128 accountId,uint128 marketId,uint128 exchangeId,uint128[] counterpartyAccountIds,uint8 orderType,bytes inputs,address signer,uint256 nonce,uint256 deadline)"
        );

        return keccak256(
            abi.encode(
                CONDITIONAL_ORDER_TYPEHASH,
                order.accountId,
                order.marketId,
                order.exchangeId,
                keccak256(abi.encodePacked(order.counterpartyAccountIds)),
                order.orderType,
                keccak256(order.inputs),
                order.signer,
                order.nonce,
                deadline
            )
        );
    }

    function hashFill(FillDetails memory fillDetails, uint256 deadline) internal pure returns (bytes32) {
        bytes32 FILL_DETAILS_TYPEHASH = keccak256(
            // solhint-disable-next-line max-line-length
            "FillDetails(uint64 accountOrderId,uint64 counterpartyOrderId,uint256 baseDelta,uint256 price,uint256 nonce,uint256 deadline)"
        );

        return keccak256(
            abi.encode(
                FILL_DETAILS_TYPEHASH,
                fillDetails.accountOrderId,
                fillDetails.counterpartyOrderId,
                fillDetails.baseDelta,
                fillDetails.price,
                fillDetails.nonce,
                deadline
            )
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
            vm.sign(signerPk, mockCalculateDigest(hashConditionalOrder(order, deadline), sec.ordersGateway));

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
            vm.sign(matchingEnginePk, mockCalculateDigest(hashFill(fillDetails, deadline), sec.ordersGateway));

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

    function createAccountWithRusdDeposit(address user, uint256 amount) internal returns (uint128 accountId) {
        return depositNewMA(user, sec.usdc, amount);
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

        IOrdersGatewayProxy(sec.ordersGateway).executeFill(fillInput);
    }

    /**
     * @notice Test basic spot fill execution for WETH market
     * @dev Verifies that buyer receives WETH and seller receives rUSD
     */
    function check_SpotExecuteFill_WETH(uint128 wethSpotMarketId) internal {
        setupSpotTestActors();
        mockFreshPrices();

        // Create accounts
        uint128 buyerAccountId = createAccountWithRusdDeposit(buyer, 10_000e6);
        uint128 sellerAccountId = ICoreProxy(sec.core).createAccount(seller);
        depositWethToAccount(seller, sellerAccountId, 10e18);

        // Record initial balances
        int256 buyerRusdBefore = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).netDeposits;
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

        // Buyer: -300 rUSD (0.1 * 3000), +0.1 WETH
        assertEq(buyerRusdAfter, buyerRusdBefore - 300e6, "Buyer rUSD balance incorrect");
        assertEq(buyerWethAfter, int256(baseDelta), "Buyer WETH balance incorrect");

        // Seller: +300 rUSD, -0.1 WETH
        assertEq(sellerRusdAfter, 300e6, "Seller rUSD balance incorrect");
        assertEq(sellerWethAfter, sellerWethBefore - int256(baseDelta), "Seller WETH balance incorrect");
    }

    /**
     * @notice Test batch spot fill execution for WETH market
     * @dev Verifies that multiple fills can be executed in a single transaction
     */
    function check_SpotBatchExecuteFill_WETH(uint128 wethSpotMarketId) internal {
        setupSpotTestActors();
        mockFreshPrices();

        // Create accounts
        uint128 buyerAccountId = createAccountWithRusdDeposit(buyer, 20_000e6);
        uint128 sellerAccountId = ICoreProxy(sec.core).createAccount(seller);
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

        // Execute batch fill
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

    /**
     * @notice Test that spot execution reverts for disabled spot markets
     * @dev Uses a non-existent/disabled spot market ID to verify FeatureUnavailable error
     */
    function check_SpotExecuteFill_RevertsWhenMarketDisabled(uint128 disabledSpotMarketId) internal {
        setupSpotTestActors();
        mockFreshPrices();

        // Create accounts
        uint128 buyerAccountId = createAccountWithRusdDeposit(buyer, 10_000e6);
        uint128 sellerAccountId = ICoreProxy(sec.core).createAccount(seller);
        depositWethToAccount(seller, sellerAccountId, 10e18);

        // Create fill input for disabled market
        (ConditionalOrderDetails memory buyerOrder, EIP712Signature memory buyerSig) = createLimitOrderSpot({
            accountId: buyerAccountId,
            spotMarketId: disabledSpotMarketId,
            baseDelta: int256(0.1e18),
            price: 3000e18,
            nonce: 1,
            signer: buyer,
            signerPk: buyerPk
        });

        (ConditionalOrderDetails memory sellerOrder, EIP712Signature memory sellerSig) = createLimitOrderSpot({
            accountId: sellerAccountId,
            spotMarketId: disabledSpotMarketId,
            baseDelta: -int256(0.1e18),
            price: 3000e18,
            nonce: 1,
            signer: seller,
            signerPk: sellerPk
        });

        SignedMatchingEnginePayload memory mePayload = createMatchingEnginePayload({
            price: 3000e18,
            baseDelta: 0.1e18,
            accountOrderId: 1,
            counterpartyOrderId: 2,
            nonce: 1
        });

        ExecuteFillInput memory fillInput = ExecuteFillInput({
            accountOrder: buyerOrder,
            counterpartyOrder: sellerOrder,
            accountSignature: buyerSig,
            counterpartySignature: sellerSig,
            mePayload: mePayload
        });

        // Expect revert with FeatureUnavailable for spot market
        bytes32 flagId = getSpotMarketEnabledFeatureFlagId(disabledSpotMarketId);
        vm.expectRevert(abi.encodeWithSelector(ICoreProxy.FeatureUnavailable.selector, flagId));
        IOrdersGatewayProxy(sec.ordersGateway).executeFill(fillInput);
    }

    /**
     * @notice Test batch execution where one fill fails but others succeed
     * @dev Batch execution should not revert entirely if one fill fails
     */
    function check_SpotBatchExecuteFill_PartialSuccess(
        uint128 wethSpotMarketId,
        uint128 disabledSpotMarketId
    )
        internal
    {
        setupSpotTestActors();
        mockFreshPrices();

        // Create accounts
        uint128 buyerAccountId = createAccountWithRusdDeposit(buyer, 20_000e6);
        uint128 sellerAccountId = ICoreProxy(sec.core).createAccount(seller);
        depositWethToAccount(seller, sellerAccountId, 10e18);

        // Create two fills: one valid (WETH), one invalid (disabled market)
        ExecuteFillInput[] memory fills = new ExecuteFillInput[](2);

        // Fill 1: Valid WETH fill
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

        // Fill 2: Invalid fill (disabled market)
        {
            (ConditionalOrderDetails memory buyerOrder2, EIP712Signature memory buyerSig2) = createLimitOrderSpot({
                accountId: buyerAccountId,
                spotMarketId: disabledSpotMarketId,
                baseDelta: int256(0.1e18),
                price: 3000e18,
                nonce: 2,
                signer: buyer,
                signerPk: buyerPk
            });

            (ConditionalOrderDetails memory sellerOrder2, EIP712Signature memory sellerSig2) = createLimitOrderSpot({
                accountId: sellerAccountId,
                spotMarketId: disabledSpotMarketId,
                baseDelta: -int256(0.1e18),
                price: 3000e18,
                nonce: 2,
                signer: seller,
                signerPk: sellerPk
            });

            SignedMatchingEnginePayload memory mePayload2 = createMatchingEnginePayload({
                price: 3000e18,
                baseDelta: 0.1e18,
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

        // Execute batch fill - should succeed (not revert) even with one failed fill
        bytes[] memory outputs = IOrdersGatewayProxy(sec.ordersGateway).batchExecuteFill(fills);

        // Verify outputs
        assertEq(outputs.length, 2, "Should return 2 outputs");
        assertTrue(outputs[0].length > 0, "First fill should succeed");
        assertEq(outputs[1].length, 0, "Second fill should fail (empty output)");

        // Verify only the first fill succeeded
        int256 buyerRusdAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.rusd).netDeposits;
        int256 buyerWethAfter = ICoreProxy(sec.core).getCollateralInfo(buyerAccountId, sec.weth).netDeposits;

        // Only first fill: 0.1 WETH at $3000 = 300 rUSD
        assertEq(buyerRusdAfter, buyerRusdBefore - 300e6, "Buyer rUSD balance incorrect");
        assertEq(buyerWethAfter, 0.1e18, "Buyer WETH balance incorrect");
    }
}
