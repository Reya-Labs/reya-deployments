// SPDX-License-Identifier: UNLICENSED
// perpOB-aligned Orders Gateway interface. Use this for devnet / perpOB environments.
// Pre-orderbook environments (cronos, mainnet) should keep using IOrdersGatewayProxy.sol.
pragma solidity ^0.8.4;

import { EIP712Signature, FillDetails, SignedMatchingEnginePayload } from "./IOrdersGatewayProxy.sol";

enum OrderTypeV2 {
    Limit,
    StopLoss,
    TakeProfit
}

enum MarketTypeV2 {
    Spot,
    Perp
}

// Unified order struct — replaces ConditionalOrderDetails + LimitOrderSpotDetails + LimitOrderPerpDetails + StopLossOrderDetails.
struct OrderDetails {
    uint128 accountId;
    uint128 marketId;
    uint128 exchangeId;
    OrderTypeV2 orderType;
    // Signed maximum executable quantity for the order nonce. Positive = buy/long, negative = sell/short.
    int256 quantity;
    // Worst acceptable execution price (UD60x18).
    uint256 limitPrice;
    // Trigger price for stop-loss / take-profit orders (UD60x18). Must be zero for limit orders.
    uint256 triggerPrice;
    // 0 = GTC, 1 = IOC.
    uint8 timeInForce;
    // Off-chain client-provided order id, signed but unused on-chain.
    uint64 clientOrderId;
    // Signed reduce-only intent.
    bool reduceOnly;
    // Signed post-only (maker-only) intent. Order must rest as a maker; a crossing post-only
    // order is rejected at matching. Valid on GTC/GTT, rejected on IOC and TP/SL.
    bool postOnly;
    // Order lifetime. Zero means valid until cancelled. Enforced on-chain at settlement.
    uint256 expiresAfter;
    address signer;
    uint256 nonce;
}

struct SignedOrderV2 {
    OrderDetails orderDetails;
    EIP712Signature signature;
}

struct ExecuteFillInputV2 {
    SignedOrderV2 accountOrder;
    SignedOrderV2 counterpartyOrder;
    SignedMatchingEnginePayload mePayload;
    bytes metadata;
}

struct OrdersGatewayConfigurationV2 {
    address coreProxy;
    address passivePerpProxy;
    address oracleAdaptersProxy_DEPRECATED;
    uint128 dustAccountId;
}

interface IOrdersGatewayProxyV2 {
    // ── FillExecutionModule ──────────────────────────────────────────────
    function executeFill(ExecuteFillInputV2 calldata input) external;
    function cancelNonce(address signer, uint256 nonce) external;

    // ── BatchExecutionModule ─────────────────────────────────────────────
    function batchExecuteFill(ExecuteFillInputV2[] calldata inputs) external;

    // ── Dust Settlement Module ──────────────────────────────────────────
    function settleDust(uint128 accountId, uint128 marketId) external;

    // ── ConfigurationModule ──────────────────────────────────────────────
    function getConfiguration() external view returns (OrdersGatewayConfigurationV2 memory);
    function setConfiguration(OrdersGatewayConfigurationV2 calldata config) external;
    function managePermissionBySig(
        address owner,
        address target,
        bool permissionState,
        EIP712Signature calldata sig
    )
        external;
    function managePermission(address target, bool permissionState) external;
    function hasPermission(address owner, address target) external view returns (bool);
    function getPermissionedAddresses(address owner) external view returns (address[] memory);
    function getLatestFailedUnifiedFillEventSequenceNumber() external view returns (uint128);
    function getLatestNumericNonceUpdatedSequenceNumber() external view returns (uint128);
    function getLatestGatewayPermissionUpdatedSequenceNumber() external view returns (uint128);

    // ── Feature Flag Module ──────────────────────────────────────────────
    function addToFeatureFlagAllowlist(bytes32 feature, address account) external;
    function removeFromFeatureFlagAllowlist(bytes32 feature, address account) external;
    function getFeatureFlagAllowlist(bytes32 feature) external view returns (address[] memory);
    function getFeatureFlagAllowAll(bytes32 feature) external view returns (bool);
    function isFeatureAllowed(bytes32 feature, address account) external view returns (bool);

    // ── Events ───────────────────────────────────────────────────────────
    event ReduceOnlyPermissionUpdated(address indexed owner, address indexed target, bool granted);

    // ── Errors ───────────────────────────────────────────────────────────
    error UnauthorizedForOrderType(uint8 orderType);
    error OrderExpired(uint256 expiresAfter);
    error InvalidTimeInForce(uint8 timeInForce);
    error NonZeroTriggerPriceForLimitOrder(uint256 triggerPrice);
    error FeatureUnavailable(bytes32 which);
    error DustAccountNotConfigured();
    error CannotSettleDustAccount(uint128 dustAccountId);
    error DustAccountNetShort(uint128 dustAccountId, uint128 marketId);
}
