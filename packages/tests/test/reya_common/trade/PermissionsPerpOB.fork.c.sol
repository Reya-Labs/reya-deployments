pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import {
    IPassivePerpProxy, EIP712Signature as PerpEIP712Signature
} from "../../../src/interfaces/IPassivePerpProxy.sol";
import {
    IPassivePerpProxyV2,
    OracleDataPayload,
    OracleDataType,
    MarketDataResponseV2
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
import { OracleDataPayloadHashing } from "../../../src/utils/OracleDataPayloadHashing.sol";
import { OrderDetailsHashing } from "../../../src/utils/OrderDetailsHashing.sol";
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
    bytes32 internal constant MULTICALL_FLAG = keccak256(bytes("multicall"));
    bytes32 internal constant CONDITIONAL_ORDERS_FLAG = keccak256(bytes("conditional_orders"));

    /**
     * @notice Push a mark price via an authorized oracle publisher
     * @dev Creates a temporary publisher, grants access, pushes price, then used
     *      to seed oracle state before permission tests so they don't revert on stale prices.
     */
    function seedMarkPrice(uint128 marketId, uint256 price) internal {
        (address publisher, uint256 publisherPk) = makeAddrAndKey("seedPublisher");

        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).addToFeatureFlagAllowlist(ORACLE_PUSHERS_FLAG, publisher);
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).addToFeatureFlagAllowlist(ORACLE_PUBLISHERS_FLAG, publisher);

        OracleDataPayload memory payload = OracleDataPayload({
            marketId: marketId,
            timestamp: block.timestamp,
            dataType: OracleDataType.MarkPrice,
            data: abi.encode(price),
            publisher: publisher
        });

        uint256 deadline = block.timestamp + 3600;
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(publisherPk, OracleDataPayloadHashing.mockCalculateDigest(payload, deadline, sec.perp));

        PerpEIP712Signature memory sig = PerpEIP712Signature({ v: v, r: r, s: s, deadline: deadline });

        vm.prank(publisher);
        IPassivePerpProxyV2(sec.perp).pushOracleData(payload, sig);
    }

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
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(unauthorizedPk, OracleDataPayloadHashing.mockCalculateDigest(payload, deadline, sec.perp));

        PerpEIP712Signature memory sig = PerpEIP712Signature({ v: v, r: r, s: s, deadline: deadline });

        vm.prank(unauthorized);
        vm.expectRevert(abi.encodeWithSelector(IPassivePerpProxyV2.UnauthorizedOraclePusher.selector, unauthorized));
        IPassivePerpProxyV2(sec.perp).pushOracleData(payload, sig);
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
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(publisherPk, OracleDataPayloadHashing.mockCalculateDigest(payload, deadline, sec.perp));

        PerpEIP712Signature memory sig = PerpEIP712Signature({ v: v, r: r, s: s, deadline: deadline });

        vm.prank(publisher);
        IPassivePerpProxyV2(sec.perp).pushOracleData(payload, sig);

        // Verify it was stored via getMarketData
        MarketDataResponseV2 memory mdr = IPassivePerpProxyV2(sec.perp).getMarketData(marketId);
        assertEq(mdr.marketData.markPrice, 3000e18, "Mark price should be stored");
    }

    /**
     * @notice Test that unauthorized matching engine cannot execute fills
     */
    function check_MatchingEnginePermission(uint128 marketId) internal {
        (address buyer, uint256 buyerPk) = makeAddrAndKey("permBuyer");
        (address seller, uint256 sellerPk) = makeAddrAndKey("permSeller");
        (address unauthorizedME, uint256 unauthorizedMEPk) = makeAddrAndKey("unauthorizedME");

        // Seed fresh oracle/price state so we reach the permission check
        // rather than reverting early on stale prices
        mockFreshPrices();
        seedMarkPrice(marketId, 3000e18);

        uint128 buyerAccountId = depositNewMA(buyer, sec.rusd, 10_000e6);
        uint128 sellerAccountId = depositNewMA(seller, sec.rusd, 10_000e6);

        uint256 deadline = block.timestamp + 3600;

        ExecuteFillInputV2 memory fillInput;

        // Build buyer order + signature in scoped block
        {
            OrderDetails memory buyerOrder = OrderDetails({
                accountId: buyerAccountId,
                marketId: marketId,
                exchangeId: 1,
                orderType: OrderTypeV2.Limit,
                quantity: int256(0.1e18),
                limitPrice: 3000e18,
                triggerPrice: 0,
                timeInForce: 0,
                clientOrderId: 0,
                reduceOnly: false,
                postOnly: false,
                expiresAfter: 0,
                signer: buyer,
                nonce: 1
            });

            (uint8 v, bytes32 r, bytes32 s) =
                vm.sign(buyerPk, OrderDetailsHashing.mockCalculateDigest(buyerOrder, deadline, sec.ordersGateway));

            fillInput.accountOrder = buyerOrder;
            fillInput.accountSignature = EIP712Signature({ v: v, r: r, s: s, deadline: deadline });
        }

        // Build seller order + signature in scoped block
        {
            OrderDetails memory sellerOrder = OrderDetails({
                accountId: sellerAccountId,
                marketId: marketId,
                exchangeId: 1,
                orderType: OrderTypeV2.Limit,
                quantity: -int256(0.1e18),
                limitPrice: 3000e18,
                triggerPrice: 0,
                timeInForce: 0,
                clientOrderId: 0,
                reduceOnly: false,
                postOnly: false,
                expiresAfter: 0,
                signer: seller,
                nonce: 1
            });

            (uint8 v, bytes32 r, bytes32 s) =
                vm.sign(sellerPk, OrderDetailsHashing.mockCalculateDigest(sellerOrder, deadline, sec.ordersGateway));

            fillInput.counterpartyOrder = sellerOrder;
            fillInput.counterpartySignature = EIP712Signature({ v: v, r: r, s: s, deadline: deadline });
        }

        // Build ME payload signed by unauthorized key in scoped block
        {
            FillDetails memory fillDetails =
                FillDetails({ accountOrderId: 1, counterpartyOrderId: 2, baseDelta: 0.1e18, price: 3000e18, nonce: 1 });

            (uint8 v, bytes32 r, bytes32 s) =
                vm.sign(unauthorizedMEPk, FillHashing.mockCalculateDigest(fillDetails, deadline, sec.ordersGateway));

            fillInput.mePayload = SignedMatchingEnginePayload({
                fillDetails: fillDetails,
                signature: EIP712Signature({ v: v, r: r, s: s, deadline: deadline })
            });
        }

        // Should revert because ME is not on allowlist
        vm.prank(sec.coExecutionBot);
        vm.expectRevert(
            abi.encodeWithSelector(IOrdersGatewayProxy.UnauthorizedMatchingEnginePublisher.selector, unauthorizedME)
        );
        IOrdersGatewayProxyV2(sec.ordersGateway).executeFill(fillInput);
    }

    /**
     * @notice Verify both oracle pushers are in the PassivePerp "oraclePushers" allowlist.
     * @dev ensureOraclePusherAccess checks this flag against msg.sender inside pushOracleData.
     */
    function check_OraclePushersFeatureFlagState() internal view {
        address[] memory allowlist = IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(ORACLE_PUSHERS_FLAG);

        bool pusher1Found = false;
        bool pusher2Found = false;
        for (uint256 i = 0; i < allowlist.length; i++) {
            if (allowlist[i] == sec.oraclePusher1) pusher1Found = true;
            if (allowlist[i] == sec.oraclePusher2) pusher2Found = true;
        }

        assertTrue(pusher1Found, "oraclePusher1 missing from PassivePerp oraclePushers allowlist");
        assertTrue(pusher2Found, "oraclePusher2 missing from PassivePerp oraclePushers allowlist");
    }

    /**
     * @notice Verify both oracle pushers are in the PassivePerp "multicall" allowlist.
     * @dev tryAggregate checks this flag against msg.sender before delegatecalling into
     *      pushOracleData — without it every gas estimation and live submission reverts
     *      with FeatureUnavailable, even though oraclePushers access is correctly granted.
     */
    function check_MulticallFeatureFlagState() internal view {
        address[] memory allowlist = IPassivePerpProxy(sec.perp).getFeatureFlagAllowlist(MULTICALL_FLAG);

        bool pusher1Found = false;
        bool pusher2Found = false;
        for (uint256 i = 0; i < allowlist.length; i++) {
            if (allowlist[i] == sec.oraclePusher1) pusher1Found = true;
            if (allowlist[i] == sec.oraclePusher2) pusher2Found = true;
        }

        assertTrue(pusher1Found, "oraclePusher1 missing from PassivePerp multicall allowlist");
        assertTrue(pusher2Found, "oraclePusher2 missing from PassivePerp multicall allowlist");
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
        (uint8 v, bytes32 r, bytes32 s) =
            vm.sign(publisherPk, OracleDataPayloadHashing.mockCalculateDigest(payload, deadline, sec.perp));

        PerpEIP712Signature memory sig = PerpEIP712Signature({ v: v, r: r, s: s, deadline: deadline });

        vm.prank(publisher);
        vm.expectRevert(abi.encodeWithSelector(IPassivePerpProxyV2.UnauthorizedOraclePusher.selector, publisher));
        IPassivePerpProxyV2(sec.perp).pushOracleData(payload, sig);
    }

    /**
     * @notice The OrdersGateway execution gate for batchExecuteFill (perp fill
     * settlement) is the `conditional_orders` feature flag
     * (FeatureFlagSupport.ensureOrdersGatewayExecutionAccess). The configured
     * executor must be on its allowlist, else perp IOC reverts FeatureUnavailable
     * (the drift behind PRO-152).
     */
    function check_ConditionalOrdersExecutionAllowlist(address executor) internal view {
        assertTrue(
            IOrdersGatewayProxy(sec.ordersGateway).isFeatureAllowed(CONDITIONAL_ORDERS_FLAG, executor),
            "executor must be on the conditional_orders allowlist (batchExecuteFill gate)"
        );
    }
}
