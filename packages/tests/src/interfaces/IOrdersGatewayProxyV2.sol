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
    // Order lifetime. Zero means valid until cancelled. Enforced on-chain at settlement.
    uint256 expiresAfter;
    address signer;
    uint256 nonce;
}

struct ExecuteFillInputV2 {
    OrderDetails accountOrder;
    OrderDetails counterpartyOrder;
    EIP712Signature accountSignature;
    EIP712Signature counterpartySignature;
    SignedMatchingEnginePayload mePayload;
}

interface IOrdersGatewayProxyV2 {
    // ── FillExecutionModule ──────────────────────────────────────────────
    function executeFill(ExecuteFillInputV2 calldata input) external returns (bytes memory outputs);
    function cancelNonce(address signer, uint256 nonce) external;

    // ── BatchExecutionModule ─────────────────────────────────────────────
    function batchExecuteFill(ExecuteFillInputV2[] calldata inputs) external returns (bytes[] memory outputs);

    // ── ConfigurationModule ──────────────────────────────────────────────
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

    // ── Events ───────────────────────────────────────────────────────────
    event ReduceOnlyPermissionUpdated(address indexed owner, address indexed target, bool granted);

    // ── Errors ───────────────────────────────────────────────────────────
    error UnauthorizedForOrderType(uint8 orderType);
    error OrderExpired(uint256 expiresAfter);
    error InvalidTimeInForce(uint8 timeInForce);
    error NonZeroTriggerPriceForLimitOrder(uint256 triggerPrice);
}
