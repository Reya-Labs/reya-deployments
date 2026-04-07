pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import {
    IPassivePerpProxy,
    OracleDataPayload,
    OracleDataType,
    MarketDataResponse,
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
import { OracleDataPayloadHashing } from "../../../src/utils/OracleDataPayloadHashing.sol";
import { ConditionalOrderHashing } from "../../../src/utils/ConditionalOrderHashing.sol";
import { FillHashing } from "../../../src/utils/FillHashing.sol";

/**
 * @title PermissionsPerpOBForkCheck
 * @notice Fork tests for perpOB-specific access control
 * @dev Verifies that:
 *      - Only allowlisted oracle pushers can push mark prices and funding rates
 *      - Only allowlisted matching engine publishers can execute fills
 *      - Orders Gateway permission management works correctly
 */
contract PermissionsPerpOBForkCheck is BaseReyaForkTest {
    bytes32 internal constant ORACLE_PUSHERS_FLAG = keccak256(bytes("oraclePushers"));
    bytes32 internal constant ORACLE_PUBLISHERS_FLAG = keccak256(bytes("oraclePublishers"));
    bytes32 internal constant MATCHING_ENGINE_PUBLISHER_FLAG = keccak256(bytes("matching_engine_publisher"));

    /**
     * @notice Test that unauthorized address cannot push oracle data
     */
    function check_OraclePusherPermission(uint128 marketId) internal {
        (address unauthorized, uint256 unauthorizedPk) = makeAddrAndKey("unauthorized");

        OracleDataPayload memory payload = OracleDataPayload({
            marketId: marketId,
            timestamp: block.timestamp,
            dataType: OracleDataType.MarkPrice,
            data: abi.encode(uint256(3000e18)),
            publisher: unauthorized
        });

        uint256 deadline = block.timestamp + 3600;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            unauthorizedPk,
            OracleDataPayloadHashing.mockCalculateDigest(payload, deadline, sec.perp)
        );

        PerpEIP712Signature memory sig = PerpEIP712Signature({ v: v, r: r, s: s, deadline: deadline });

        vm.prank(unauthorized);
        vm.expectRevert();
        IPassivePerpProxy(sec.perp).pushOracleData(payload, sig);
    }

    /**
     * @notice Test that authorized oracle pusher can push data
     */
    function check_AuthorizedOraclePusher(uint128 marketId) internal {
        (address publisher, uint256 publisherPk) = makeAddrAndKey("authorizedPublisher");

        // Grant pusher access (checks msg.sender)
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).addToFeatureFlagAllowlist(ORACLE_PUSHERS_FLAG, publisher);

        // Grant publisher access (checks payload.publisher signature)
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).addToFeatureFlagAllowlist(ORACLE_PUBLISHERS_FLAG, publisher);

        OracleDataPayload memory payload = OracleDataPayload({
            marketId: marketId,
            timestamp: block.timestamp,
            dataType: OracleDataType.MarkPrice,
            data: abi.encode(uint256(3000e18)),
            publisher: publisher
        });

        uint256 deadline = block.timestamp + 3600;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            publisherPk,
            OracleDataPayloadHashing.mockCalculateDigest(payload, deadline, sec.perp)
        );

        PerpEIP712Signature memory sig = PerpEIP712Signature({ v: v, r: r, s: s, deadline: deadline });

        vm.prank(publisher);
        IPassivePerpProxy(sec.perp).pushOracleData(payload, sig);

        // Verify it was stored via getMarketData
        MarketDataResponse memory mdr = IPassivePerpProxy(sec.perp).getMarketData(marketId);
        assertEq(mdr.marketData.markPrice, 3000e18, "Mark price should be stored");
    }

    /**
     * @notice Test that unauthorized matching engine cannot execute fills
     */
    function check_MatchingEnginePermission(uint128 marketId) internal {
        (address buyer, uint256 buyerPk) = makeAddrAndKey("permBuyer");
        (address seller, uint256 sellerPk) = makeAddrAndKey("permSeller");
        (, uint256 unauthorizedMEPk) = makeAddrAndKey("unauthorizedME");

        uint128 buyerAccountId = depositNewMA(buyer, sec.rusd, 10_000e6);
        uint128 sellerAccountId = depositNewMA(seller, sec.rusd, 10_000e6);

        uint128[] memory emptyIds = new uint128[](0);
        uint256 deadline = block.timestamp + 3600;

        ExecuteFillInput memory fillInput;

        // Build buyer order + signature in scoped block
        {
            ConditionalOrderDetails memory buyerOrder = ConditionalOrderDetails({
                accountId: buyerAccountId,
                marketId: marketId,
                exchangeId: 1,
                counterpartyAccountIds: emptyIds,
                orderType: uint8(OrderType.LimitOrderPerp),
                inputs: abi.encode(LimitOrderPerpDetails({ baseDelta: int256(0.1e18), price: 3000e18 })),
                signer: buyer,
                nonce: 1
            });

            (uint8 v, bytes32 r, bytes32 s) =
                vm.sign(buyerPk, ConditionalOrderHashing.mockCalculateDigest(buyerOrder, deadline, sec.ordersGateway));

            fillInput.accountOrder = buyerOrder;
            fillInput.accountSignature = EIP712Signature({ v: v, r: r, s: s, deadline: deadline });
        }

        // Build seller order + signature in scoped block
        {
            ConditionalOrderDetails memory sellerOrder = ConditionalOrderDetails({
                accountId: sellerAccountId,
                marketId: marketId,
                exchangeId: 1,
                counterpartyAccountIds: emptyIds,
                orderType: uint8(OrderType.LimitOrderPerp),
                inputs: abi.encode(LimitOrderPerpDetails({ baseDelta: -int256(0.1e18), price: 3000e18 })),
                signer: seller,
                nonce: 1
            });

            (uint8 v, bytes32 r, bytes32 s) =
                vm.sign(sellerPk, ConditionalOrderHashing.mockCalculateDigest(sellerOrder, deadline, sec.ordersGateway));

            fillInput.counterpartyOrder = sellerOrder;
            fillInput.counterpartySignature = EIP712Signature({ v: v, r: r, s: s, deadline: deadline });
        }

        // Build ME payload signed by unauthorized key in scoped block
        {
            FillDetails memory fillDetails = FillDetails({
                accountOrderId: 1,
                counterpartyOrderId: 2,
                baseDelta: 0.1e18,
                price: 3000e18,
                nonce: 1
            });

            (uint8 v, bytes32 r, bytes32 s) = vm.sign(
                unauthorizedMEPk,
                FillHashing.mockCalculateDigest(fillDetails, deadline, sec.ordersGateway)
            );

            fillInput.mePayload = SignedMatchingEnginePayload({
                fillDetails: fillDetails,
                signature: EIP712Signature({ v: v, r: r, s: s, deadline: deadline })
            });
        }

        // Should revert because ME is not on allowlist
        vm.prank(sec.coExecutionBot);
        vm.expectRevert();
        IOrdersGatewayProxy(sec.ordersGateway).executeFill(fillInput);
    }

    /**
     * @notice Test oracle pusher can be revoked
     */
    function check_RevokeOraclePusher(uint128 marketId) internal {
        (address publisher, uint256 publisherPk) = makeAddrAndKey("revokablePublisher");

        // Grant both flags, then revoke the pusher flag
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).addToFeatureFlagAllowlist(ORACLE_PUSHERS_FLAG, publisher);
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).addToFeatureFlagAllowlist(ORACLE_PUBLISHERS_FLAG, publisher);
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).removeFromFeatureFlagAllowlist(ORACLE_PUSHERS_FLAG, publisher);

        // Attempt push should fail
        OracleDataPayload memory payload = OracleDataPayload({
            marketId: marketId,
            timestamp: block.timestamp,
            dataType: OracleDataType.MarkPrice,
            data: abi.encode(uint256(3000e18)),
            publisher: publisher
        });

        uint256 deadline = block.timestamp + 3600;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            publisherPk,
            OracleDataPayloadHashing.mockCalculateDigest(payload, deadline, sec.perp)
        );

        PerpEIP712Signature memory sig = PerpEIP712Signature({ v: v, r: r, s: s, deadline: deadline });

        vm.prank(publisher);
        vm.expectRevert();
        IPassivePerpProxy(sec.perp).pushOracleData(payload, sig);
    }
}
