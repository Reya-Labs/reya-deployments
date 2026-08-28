// SPDX-License-Identifier: UNLICENSED
// perpOB-specific extensions to IPassivePerpProxy.
// Use this interface for devnet / perpOB environments.
// AMM environments (cronos, mainnet) should use IPassivePerpProxy.sol.
pragma solidity ^0.8.4;

import {
    DutchConfiguration,
    SlippageParams,
    EIP712Signature,
    FundingAndADLTrackers,
    PriceData
} from "./IPassivePerpProxy.sol";

/**
 * @title IPassivePerpProxyV2
 * @notice perpOB interface additions: oracle push, V2 market data, V2 config.
 * @dev Cast the same contract address to this interface when you need perpOB
 *      functions.  Shared functions (feature flags, ownership, position info,
 *      match orders, etc.) stay on IPassivePerpProxy.
 */
interface IPassivePerpProxyV2 {
    // ─── Oracle Push Module ──────────────────────────────────────────────

    function pushOracleData(
        OracleDataPayload calldata payload,
        EIP712Signature calldata signature
    ) external;

    function getMarkPrice(uint128 marketId)
        external
        view
        returns (
            /* UD60x18 */
            uint256
        );

    function getMarkPriceTimestamp(uint128 marketId)
        external
        view
        returns (uint256);

    function getFundingRate(uint128 marketId)
        external
        view
        returns (
            /* SD59x18 */
            int256
        );

    function getFundingRateTimestamp(uint128 marketId)
        external
        view
        returns (uint256);

    // ─── V2 Configuration ────────────────────────────────────────────────

    function getMarketConfiguration(uint128 marketId)
        external
        view
        returns (MarketConfigurationDataV2 memory config);

    function setMarketConfiguration(uint128 marketId, MarketConfigurationDataV2 memory config) external;

    // ─── Fee Configuration (perpOB) ─────────────────────────────────────

    function setFeeTierParameters(uint256 tierId, FeeTierParameters memory params) external;

    function getFeeTierParameters(uint256 tierId) external view returns (FeeTierParameters memory);

    function setGlobalFeeParameters(GlobalFeeParametersV2 memory params) external;

    function getGlobalFeeParameters() external view returns (GlobalFeeParametersV2 memory);

    function getAccountOwnerFeeParameters(address accountOwner)
        external
        view
        returns (
            /* UD60x18 */ uint256 takerFeeParameter,
            /* UD60x18 */ uint256 takerRebateParameter
        );

    // ─── V2 Market Data (20-field struct) ────────────────────────────────

    function getMarketData(uint128 marketId)
        external
        view
        returns (MarketDataResponseV2 memory);

    // ─── Errors ──────────────────────────────────────────────────────────

    error MarkPriceStale(uint128 marketId, uint256 priceTimestamp, uint256 blockTimestamp, uint256 maxStaleDuration);
    error FundingRateStale(uint128 marketId, uint256 fundingRateTimestamp, uint256 blockTimestamp, uint256 maxStaleDuration);
    error UnauthorizedOraclePusher(address pusher);
    error PriceDeviationTooLarge(uint128 marketId, uint256 price, uint256 referencePrice, uint256 maxDeviation);
    error TakerFeeParameterTooLarge();
}

// ─── Fee Structs (perpOB) ────────────────────────────────────────────────

// Fee model V3 charges only the taker. The former maker fields remain in storage for compatibility.
struct FeeTierParameters {
    /* UD60x18 */ uint256 takerFee;
    /* UD60x18 */ uint256 makerFee_DEPRECATED;
    /* UD60x18 */ uint256 makerRebate_DEPRECATED;
}

struct GlobalFeeParametersV2 {
    /* UD60x18 */ uint256 ogRebateRate;
    /* UD60x18 */ uint256 refereeRebateRate;
    /* UD60x18 */ uint256 referrerRebate;
    /* UD60x18 */ uint256 affiliateReferrerRebate_DEPRECATED;
    /* UD60x18 */ uint256 vltzRebateRate;
    /* UD60x18 */ uint256 spreadDiscount_DEPRECATED;
    /* UD60x18 */ uint256 poolRebate;
    uint128 poolAccountId;
}

// ─── perpOB Enums ────────────────────────────────────────────────────────

enum OracleDataType {
    MarkPrice,
    FundingRate
}

enum ExecutionType {
    MatchOrder,
    DutchLiquidation,
    RankedLiquidation,
    BackstopLiquidation,
    ADL,
    MarketClose
}

// ─── perpOB Structs ──────────────────────────────────────────────────────

struct OracleDataPayload {
    uint128 marketId;
    uint256 timestamp;
    OracleDataType dataType;
    bytes data;
    address publisher;
}

struct PerpFillFees {
    uint256 protocolFeeCredit;
    uint256 referrerFeeCredit;
    uint256 takerRebateCredit;
    uint256 poolFeeCredit;
}

// perpOB MarketConfigurationData with deprecated AMM fields and new orderbook fields
struct MarketConfigurationDataV2 {
    uint256 riskMatrixIndex;
    /* UD60x18 */ uint256 maxOpenBase;
    /* UD60x18 */ uint256 velocityMultiplier_DEPRECATED;
    bytes32 oracleNodeId;
    uint256 mtmWindow_DEPRECATED;
    DutchConfiguration dutchConfig;
    SlippageParams slippageParams;
    /* UD60x18 */ uint256 minimumOrderBase;
    /* UD60x18 */ uint256 baseSpacing;
    /* UD60x18 */ uint256 priceSpacing;
    /* UD60x18 */ uint256 depthFactor_DEPRECATED;
    /* UD60x18 */ uint256 maxExposureFactor_DEPRECATED;
    /* UD60x18 */ uint256 maxPSlippage_DEPRECATED;
    uint256 markPriceMaxStaleDuration;
    /* UD60x18 */ uint256 priceSpread_DEPRECATED;
    /* UD60x18 */ uint256 volatilityIndexMultiplier_DEPRECATED;
    uint256 fundingRateMaxStaleDuration;
    /* UD60x18 */ uint256 markPriceMaxDeviation;
    /* UD60x18 */ uint256 fillPriceMaxDeviation;
    uint256 minFundingInterval;
}

/// @dev 21-field struct matching the perpOB on-chain MarketData.
///      The first 16 positional fields match the AMM MarketRuntimeData;
///      5 new fields are appended for pushed oracle data and close state.
struct MarketRuntimeDataV2 {
    uint128 id;
    uint128 passivePoolId_DEPRECATED;
    uint128 poolAccountId_DEPRECATED;
    address quoteToken;
    uint8 quoteTokenDecimals;
    /* SD59x18 */ int256 lastFundingVelocity_DEPRECATED;
    /* SD59x18 */ int256 lastFundingRate_DEPRECATED;
    uint256 lastFundingTimestamp;
    PriceData lastMTM_DEPRECATED;
    FundingAndADLTrackers longTrackers;
    FundingAndADLTrackers shortTrackers;
    /* UD60x18 */ uint256 openInterest;
    /* SD59x18 */ int256 logPriceMultiplier_DEPRECATED;
    /* UD60x18 */ uint256 depthFactor_DEPRECATED;
    /* UD60x18 */ uint256 priceSpread_DEPRECATED;
    /* UD60x18 */ uint256 velocityMultiplier_DEPRECATED;
    // ── new perpOB fields ──
    /* UD60x18 */ uint256 markPrice;
    uint256 markPriceTimestamp;
    /* SD59x18 */ int256 fundingRate;
    uint256 fundingRateTimestamp;
    /* UD60x18 */ uint256 lockedClosePrice;
}

struct MarketDataResponseV2 {
    MarketRuntimeDataV2 marketData;
    uint256 blockTimestamp;
    uint256 blockNumber;
}
