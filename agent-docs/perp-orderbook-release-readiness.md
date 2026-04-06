# Perp Orderbook Release Readiness Plan

## 1. Executive Summary

This document captures the full plan for deploying and stress-testing the perp orderbook (perpOB) release on a new **reya devnet** environment, and the eventual migration path to cronos testnet and mainnet.

The perpOB release fundamentally transitions Reya's perpetual futures system from an **AMM-based model** (depth factors, velocity-based funding, log price multipliers, passive pool counterparty) to a **pure order book model** (oracle-pushed mark prices and funding rates, matching engine fills via EIP-712 signed payloads, dedicated backstop liquidator account).

**Source of truth**: All on-chain changes live on the `feat/perpOB` branch of `reya-network` (54 commits, ~26,000 insertions, ~12,600 deletions across 193 files relative to `main`).

---

## 2. Architecture Changes Summary

### 2.1 What's Being Removed (AMM Model)

| Concept | Description | Affected Code |
|---------|-------------|---------------|
| **Log Price Multiplier** | AMM-computed prices from pool state | `PriceMultiplier.sol` (deleted) |
| **Depth Factor** | Pool-exposure-based slippage curves | `depthFactor` field, `setMarketConfigurationDepth()`, `initialize_depth_factors.toml` |
| **Velocity-Based Funding** | Funding rate = pSlippage * velocityMultiplier, with complex clamping/integration | `velocityMultiplier` field, `QuadraticEquation.sol` (deleted) |
| **Max Exposure** | Pool exposure constraints | `MaxExposure.sol` (deleted), `maxExposureFactor` field |
| **Price Spread** | Bid-ask spread applied to AMM prices | `priceSpread` field, `setMarketConfigurationSpread()`, `set_spread_executors.toml` |
| **MTM Window** | Mark-to-market window for position valuation | `mtmWindow` field, `lastMTM` struct |
| **Cached Pool Node Margin Info** | Pool margin caching layer | `CachedPoolNodeMarginInfo.sol` (deleted), `pool_node_margin_info.toml` |
| **Passive Pool as Perp Counterparty** | Pool account absorbs all perp trades | `passivePoolId`, `poolAccountId` in market data |
| **Old Conditional Order Types** | Stop-loss, take-profit, old market orders | `OrderType` enum entries removed |
| **MatchOrderFees** | Old fee structure with pool rebate | Replaced by `PerpFillFees` |

### 2.2 What's Being Added (Order Book Model)

| Concept | Description | Key Files |
|---------|-------------|-----------|
| **Oracle Push Module** | EIP-712 signed mark price + funding rate pushes | `OraclePushModule.sol`, `OracleValidation.sol`, `OraclePushEIP712Helpers.sol` |
| **Fill-Based Matching** | `executeFill()` via Orders Gateway with matching engine payloads | `PerpFillExecution.sol`, updated `ExecutionModule` |
| **New Order Types** | `LimitOrderPerp`, `ReduceOnlyPerp` | `OrderType` enum in Orders Gateway |
| **PerpFillFees** | Separated maker fee/rebate (mutually exclusive) | `FeeComputation.sol`, `FeeValidation.sol` |
| **Config Validation** | Centralized market config validation with error codes | `ConfigValidation.sol` |
| **Multicall Module** | Batched calls with per-call success tracking | `MulticallModule.sol` |
| **Event Sequencing** | Global + per-market event sequence numbers | `IdStore.sol` |
| **ADL Simplification** | Pure position-based ADL (no exposure model) | `ADL.sol` |
| **Staleness Checks** | `markPriceMaxStaleDuration`, `fundingRateMaxStaleDuration` | Market configuration |
| **Price Deviation Checks** | `markPriceMaxDeviation`, `fillPriceMaxDeviation` | Market configuration |
| **Dedicated Backstop Account** | Replaces passive pool for liquidation absorption | Backstop liquidator account ID |

### 2.3 Key Data Structure Changes

**Market.Data struct** -- new fields:
- `markPrice` (UD60x18), `markPriceTimestamp` (uint256)
- `fundingRate` (SD59x18), `fundingRateTimestamp` (uint256)

**Market.Data struct** -- deprecated fields:
- `lastFundingVelocity`, `logPriceMultiplier`, `lastMTM`
- `passivePoolId`, `poolAccountId`

**MarketConfigurationData** -- new fields:
- `markPriceMaxStaleDuration`, `fundingRateMaxStaleDuration`
- `markPriceMaxDeviation`, `fillPriceMaxDeviation`

**MarketConfigurationData** -- deprecated fields (kept with `_DEPRECATED` suffix):
- `velocityMultiplier_DEPRECATED`, `depthFactor_DEPRECATED`
- `maxPSlippage_DEPRECATED`, `priceSpread_DEPRECATED`
- `volatilityIndexMultiplier_DEPRECATED`, `mtmWindow`

**Fee model**:
- Old: `MatchOrderFees` with `makerPayments[0]` array, pool rebate
- New: `PerpFillFees` with `protocolFeeCredit`, `exchangeFeeCredit`, `referrerFeeCredit`, `takerFeeDebit`, `makerFeeCredit`, `makerFeeDebit` (fee and rebate are mutually exclusive)

**FeeTierParameters**:
- Added `makerRebate` field (mutually exclusive with `makerFee`)

**Counterparty model**:
- Old: `uint128[] counterpartyAccountIds` (array, expected length 1)
- New: `uint128 counterpartyAccountId` (single)

**Event system**:
- `PassivePerpExecutionV2` -> `PassivePerpExecutionV3` with `executionType` enum, order IDs, counterparty exchange ID

**New feature flags**:
- `oraclePushers` -- who can relay oracle data
- `oraclePublishers` -- whose EIP-712 signatures are accepted
- `multicall` -- multicall module access

---

## 3. Devnet Environment Specification

### 3.1 Chain Configuration

| Property | Value |
|----------|-------|
| **Chain** | Reya Cronos testnet (shared) |
| **Chain ID** | 89346162 |
| **RPC** | `https://rpc.reya-cronos.gelato.digital/` |
| **Deployment Strategy** | Fresh proxy deployments, reuse existing Cronos token contracts |

### 3.2 Shared Infrastructure (from Cronos)

The following are **reused from Cronos** (no redeploy):
- Token contracts: USDC, WETH, rUSD proxy
- Oracle adapters proxy (Stork)
- LayerZero endpoint
- Stork verify contract

### 3.3 Fresh Deployments (devnet-specific proxies)

New proxies deployed for:
- CoreProxy
- PassivePerpProxy
- PassivePoolProxy
- OrdersGatewayProxy
- PeripheryProxy
- OracleManagerProxy
- ExchangePassProxy
- RanksProxy
- SBTProxy

### 3.4 Minimal Market Set

| Type | Market | Details |
|------|--------|---------|
| **Perp** | ETH (market ID 1) | LimitOrderPerp + ReduceOnlyPerp via matching engine fills |
| **Spot** | WETH/rUSD (spot market 1) | LimitOrderSpot via matching engine fills |

### 3.5 Minimal Collateral Set

| Collateral | Role |
|------------|------|
| **rUSD** | Primary quote/margin collateral |
| **wETH** | Secondary collateral (enables spot market) |

### 3.6 Key Configuration Parameters

**ETH Perp Market:**
- `riskMatrixIndex`: 0
- `maxOpenBase`: 4950 (same as cronos)
- `oracleNodeId`: ETH/USDC mark oracle node
- `baseSpacing`: 0.001
- `priceSpacing`: 0.001
- `minimumOrderBase`: 0.010
- `dutchConfig.lambda`: 1, `dutchConfig.minBase`: 0
- `slippageParams.phi`: 0, `slippageParams.beta`: 0
- `markPriceMaxStaleDuration`: 3600 (1 hour, configurable)
- `fundingRateMaxStaleDuration`: 3600 (1 hour, configurable)
- `markPriceMaxDeviation`: 0 (disabled initially)
- `fillPriceMaxDeviation`: 0 (disabled initially)
- All `_DEPRECATED` fields: 0

**Collateral Pool:**
- `maxMarkets`: 1
- `maxCollaterals`: 2
- `imMultiplier`: 1.3
- `mmrMultiplier`: 1
- `dutchMultiplier`: 1
- `adlMultiplier`: 0.65
- Risk matrix: 1x1 with `cp1Rusd_market1Eth_riskMatrix00Unscaled = "0.000947"` (25x leverage)
- Dedicated backstop liquidator account (not passive pool)

**Fee Configuration:**
- `takerFeeTier0`: 0.00040
- `makerFeeTier0`: 0.00040 (or set `makerRebate` for maker rebate model)
- `exchangeRebate`: 0.2
- `poolRebate`: removed (perpOB)

**Feature Flags:**
- `oraclePushers`: [oracle pusher address]
- `oraclePublishers`: [oracle publisher address]
- `matching_engine_publisher`: [matching engine address]
- `multicall`: [authorized addresses]

### 3.7 Roles (Simplified)

| Role | Count | Notes |
|------|-------|-------|
| Owner | 1 | Same as Cronos owner |
| Pausers | 1 | Simplified from 4 |
| Liquidators | 1 | Simplified from 10 |
| Matching Engine Publishers | 1 | Same as Cronos |
| Oracle Pushers | 1 | New role for perpOB |
| Oracle Publishers | 1 | New role for perpOB |
| Backstop Liquidator Account | 1 | Dedicated account (replaces passive pool) |
| CO Execution Bots | 0 | Old conditional orders not supported |
| Rebalancers | 0 | No pool rebalancing needed initially |

---

## 4. Fork Check Rework Plan (partially implemented)

### 4.1 Overview

Fork checks are Solidity tests that validate on-chain state against expected behavior. They live in:
- Base contracts: `packages/tests/test/reya_common/` (`.fork.c.sol`)
- Environment runners: `packages/tests/test/reya_{cronos,network,devnet}/` (`.fork.t.sol`)

The perpOB transition affects trade-related fork checks significantly. Collateral, oracle, and pool staking checks are unaffected.

**Approach taken**: New perpOB-specific base contracts created alongside legacy ones (no modifications to legacy files). This ensures the PR is mergeable without breaking cronos/mainnet tests.

### 4.2 Detailed Per-File Analysis

#### DELETE (AMM-only, no perpOB equivalent)

**`PSlippage.fork.c.sol`** (1163 lines)
- **What it tests**: AMM depth factor slippage curves for 60+ markets using `depthFactor`, `setMarketConfigurationDepth()`, and hardcoded `sPrimeLong`/`sPrimeShort` lookup tables
- **Why delete**: The entire AMM pricing model is removed. In perpOB, fill prices come from the matching engine, not from pool-computed slippage. There is no `pSlippage` function, no `depthFactor`, no depth-based price curves.
- **Action**: Do not include in devnet tests. Keep in cronos/network tests until those environments migrate to perpOB.
- **Replacement**: New `PerpFill.fork.c.sol` validates fill price deviation from oracle mark price instead.

#### COMPLETELY REWRITE

**`FundingRate.fork.c.sol`** (56 lines) -> **new `FundingRatePerpOB.fork.c.sol`** ✅ DONE
- **What it tests**: `fundingRate2 - fundingRate1 == pSlippage * velocityMultiplier` over 1 day
- **AMM references**: `getPSlippage(marketId)` (removed), `marketData.velocityMultiplier` (deprecated), velocity-based funding rate delta
- **Why rewrite**: Funding is now push-based. Rate is pushed via EIP-712 signed payload to `OraclePushModule`. Accrual uses simple rectangle model: `delta = rate * price * time * baseMultiplier`.
- **Implemented in `FundingRatePerpOB.fork.c.sol`**:
  - ✅ `check_PushFundingRate(marketId)`: Push a funding rate, verify `getFundingRate()` returns pushed value + timestamp
  - ✅ `check_FundingRateStaleness(marketId)`: Push rate, warp past max stale duration, verify stale state
  - ✅ `check_PushMarkPrice(marketId)`: Push mark price, verify `getMarkPrice()` returns pushed value + timestamp
  - ⬜ `check_FundingAccrual(marketId)`: Push rate, open position, warp time, verify funding PnL (TODO)
  - ⬜ `check_FundingRateBounds(marketId)`: Push rate exceeding `maxAbsFundingRate`, verify revert (TODO)

**`CoOrder.fork.c.sol`** (596 lines) -> **new `PerpFill.fork.c.sol`** ✅ DONE
- **What it tests**: Stop-loss, take-profit, limit, market, reduce-only, full-close orders via Orders Gateway against passive pool
- **AMM references**: Uses `counterpartyAccountIds` array with `passivePoolAccountId` (line 91-92), old order types (0-5), old `execute()` path on Orders Gateway
- **Why rewrite**: SL (type 0) and TP (type 1) are removed. New order types are `LimitOrderPerp` and `ReduceOnlyPerp`. Execution path changes from `execute()` to `executeFill()` with matching engine EIP-712 signatures.
- **Reference implementation**: `Spot.fork.c.sol` already uses the new fill-based pattern (`executeFill()`, `LimitOrderSpotDetails`, `SignedMatchingEnginePayload`) -- use as template.
- **Implemented in `PerpFill.fork.c.sol`**:
  - ✅ `check_PerpExecuteFill(marketId)`: Create buyer + seller accounts, push mark price, construct `LimitOrderPerp` orders, create matching engine payload, call `executeFill()`, verify positions
  - ✅ `check_PerpBatchExecuteFill(marketId)`: Batch fill execution with two fills at different prices
  - ✅ `check_PerpMarkPriceStaleness(marketId)`: Mark price staleness enforcement on fill
  - ⬜ `check_PerpReduceOnlyFill(marketId)`: Reduce-only order enforcement (TODO)
  - ⬜ `check_PerpFillPriceDeviation(marketId)`: Fill price deviation from mark price check (TODO)

**`Order.fork.c.sol`** (335 lines)
- **What it tests**: Match order fees, fee discounts (OG/VLTZ), zero fees, spread configuration, cached pool margin info, gas costs
- **AMM references**:
  - `check_MatchOrder_CachedPoolNodeMarginInfo()` -- `CachedPoolNodeMarginInfo` concept deleted entirely
  - `check_MatchOrder_Spread()` -- uses `setMarketConfigurationSpread()`, `spreadDiscount` -- spread concept removed
  - `check_MatchOrder_Fees()` / `check_MatchOrder_GasCost()` -- use `executeCoreMatchOrder()` with passive pool counterparty
- **Changes needed**:
  - **Delete** `check_MatchOrder_CachedPoolNodeMarginInfo` (concept removed)
  - **Delete** `check_MatchOrder_Spread` (spread removed)
  - **Rewrite** `check_MatchOrder_Fees` to use fill-based execution and verify `PerpFillFees` (taker fee, maker fee/rebate, protocol fee, exchange fee)
  - **Rewrite** `check_MatchOrder_FeeDiscounts` to verify OG/VLTZ discounts still work with new fee model
  - **Rewrite** `check_MatchOrder_GasCost` to measure `executeFill()` gas instead of `executeCoreMatchOrder()`
  - **Add** `check_MatchOrder_MakerRebate` testing the new maker rebate flow (when `makerRebateParameter > 0`)

#### UPDATE -> NEW PERPOB FILES CREATED

**`Liquidation.fork.c.sol`** (199 lines) -> **new `LiquidationPerpOB.fork.c.sol`** ✅ DONE
- **What it tests**: Dutch liquidation (forced close) and backstop liquidation (absorb positions)
- **Implemented in `LiquidationPerpOB.fork.c.sol`** (inherits from PerpFillForkCheck):
  - ✅ `check_DutchLiquidation_PerpOB(marketId)`: Opens leveraged long via fill, drops mark price, executes Dutch liquidation, verifies position transfer
  - ✅ `check_BackstopLiquidation_PerpOB(marketId, backstopAccountId)`: Opens leveraged long, drops price severely, executes backstop to dedicated account (not passive pool)
  - Legacy `LiquidationForkCheck` preserved for cronos/mainnet

**`Leverage.fork.c.sol`** (218 lines) -> **new `LeveragePerpOB.fork.c.sol`** ✅ DONE
- **What it tests**: Leverage limits per market (hardcoded: 25x ETH, 40x BTC, etc.)
- **Implemented in `LeveragePerpOB.fork.c.sol`** (inherits from PerpFillForkCheck):
  - ✅ `check_trade_leverage_perpOB(marketId, expectedLev, markPrice, collateral)`: Opens position via fill, computes leverage = exposure / IMR, asserts match to expected
  - Legacy `LeverageForkCheck` preserved for cronos/mainnet

**`PassivePool.fork.c.sol`** (477 lines) -- ⬜ NOT YET UPDATED
- **What it tests**: Pool health, deposits, withdrawals, tokenized srUSD
- **Changes needed**:
  - Pool no longer trades perps directly -- remove any trade-through-pool test expectations
  - Pool health and deposit/withdraw mechanics likely unchanged
  - Lower priority for devnet (pool is not perp counterparty)

**`Permissions.fork.t.sol`** (39 lines in cronos) -> **new `PermissionsPerpOB.fork.c.sol`** ✅ DONE
- **What it tests**: `configureSpread` (6 addresses) and `configureDepth` (8 addresses) allowlists
- **Implemented in `PermissionsPerpOB.fork.c.sol`**:
  - ✅ `check_OraclePusherPermission(marketId)`: Unauthorized address cannot push oracle data
  - ✅ `check_AuthorizedOraclePusher(marketId)`: Authorized pusher can push mark price, verify storage
  - ✅ `check_MatchingEnginePermission(marketId)`: Unauthorized ME cannot execute fills
  - ✅ `check_RevokeOraclePusher(marketId)`: Grant then revoke oracle pusher, verify rejection
  - Legacy `Permissions.fork.t.sol` preserved for cronos/mainnet

**`WethCollateral.fork.c.sol`** -> **new `WethCollateralPerpOB.fork.c.sol`** ✅ DONE
- **Implemented in `WethCollateralPerpOB.fork.c.sol`** (inherits from PerpFillForkCheck):
  - ✅ `check_WethTradeWithWethCollateral_PerpOB(marketId)`: Deposits wETH, opens short via fill, verifies margin stability across price movements (hedged position)
  - Legacy `WethCollateralForkCheck` preserved for cronos/mainnet

**`BaseReyaForkTest.sol`** (base test infrastructure) -- ✅ KEPT UNCHANGED
- **Decision**: PerpOB helpers live in `PerpFill.fork.c.sol` rather than `BaseReyaForkTest.sol` to avoid `EIP712Signature` import conflicts across interface files. This follows the pattern used by `Spot.fork.c.sol`.
- Existing `executeCoreMatchOrder()`, `getMatchOrderCoreCommand()` preserved for cronos/mainnet backward compat.
- New perpOB helpers: `executePerpFill()`, `pushMarkPrice()`, `pushFundingRate()`, `createLimitOrderPerp()` are in `PerpFillForkCheck` base contract.

**`OracleDataPayloadHashing.sol`** ✅ NEW UTILITY
- EIP-712 digest computation for oracle push payloads, following the `ConditionalOrderHashing`/`FillHashing` pattern.

#### UNCHANGED

| File | Lines | Reason |
|------|-------|--------|
| `Spot.fork.c.sol` | 841 | Already uses fill-based matching -- serves as reference implementation |
| `PoolStake.fork.c.sol` | 54 | Staking/unstaking independent of orderbook |
| `OracleAdapter.fork.c.sol` | 56 | Stork adapter unchanged |
| `General.fork.c.sol` | ~100+ | Configuration validation independent of orderbook |
| `RusdCollateral.fork.c.sol` | | Collateral system independent (reused for devnet) |
| `WethCollateral.fork.c.sol` | | Has AMM trade dependency; new `WethCollateralPerpOB.fork.c.sol` created for devnet |
| `WbtcCollateral.fork.c.sol` | | Collateral system independent |
| `AutoExchange.fork.c.sol` | | Auto-exchange independent |
| `LmTokenCollateral.fork.c.sol` | | LM tokens independent |
| `ReyaBridging.fork.c.sol` | | Bridging independent |
| `ReyaCollateral.fork.c.sol` | | Collateral independent |
| `SreyaCollateral.fork.c.sol` | | Collateral independent |
| `SrusdCollateral.fork.c.sol` | | Collateral independent |
| `UsualCollateral.fork.c.sol` | | Collateral independent |
| `SpotAccount.fork.c.sol` | | Spot accounts independent |

---

## 5. Devnet Omnibus Structure

### 5.1 File: `packages/tomls/src/omnibus/reya_devnet.toml`

Module includes (referencing devnet-specific configs where needed):

```
include = [
    "utils/commons.toml",
    "utils/constants.toml",
    "../token/devnet.toml",
    "../rusd/testnet.toml",
    "../core/devnet.toml",
    "../passive_pool/testnet.toml",
    "../passive_perp/devnet.toml",
    "../periphery/testnet.toml",
    "../oracle_manager/testnet.toml",
    "../exchange_pass_nft/testnet.toml",
    "../ranks/testnet.toml",
    "../collateral_pools/collateral_pool_1/devnet.toml",
    "../orders_gateway/devnet.toml",
    "../oracle_adapters/testnet.toml",
    "../share_token/mainnet.toml",
    "../sbt/testnet.toml",
]
```

### 5.2 Devnet Module Files

| File | Purpose | Pattern |
|------|---------|---------|
| `token/devnet.toml` | Reference existing Cronos USDC + WETH tokens only | Subset of `token/testnet.toml` |
| `core/devnet.toml` | Core with only rusd + weth collateral configs | Subset of `core/mainnet.toml` + deploy_proxy |
| `passive_perp/devnet.toml` | No AMM configs; oracle push setup | Custom (no depth/velocity/logf/spread) |
| `collateral_pools/collateral_pool_1/devnet.toml` | Only market_1eth, 1x1 risk matrix, 2 tokens | Subset of `collateral_pool_1/mainnet.toml` |
| `orders_gateway/devnet.toml` | Fill execution + matching engine publisher | Same as `testnet.toml` |

### 5.3 Passive Perp Devnet Config

`passive_perp/devnet.toml` includes:
```
include = [
    "utils/upgrade_proxy.toml",
    "utils/deploy_proxy.toml",
    "configs/feature_flags.toml",
    "configs/global_config.toml",
    "configs/fees.toml",
]
```

**Excluded** (AMM-specific):
- `configs/set_spread_executors.toml`
- `configs/set_depth_executors.toml`
- `configs/initialize_logf_executors.toml`
- `configs/initialize_depth_factors.toml`
- `configs/initialize_velocity_multipliers.toml`
- `configs/pool_node_margin_info.toml`

**New config sections** (added inline or as separate config files):
- Oracle push feature flags: `oraclePushers`, `oraclePublishers` allowlists
- Multicall feature flag

---

## 6. Interface Updates ✅ DONE

### 6.1 `IPassivePerpProxy.sol` ✅

**New functions added:**
- `pushOracleData(OracleDataPayload calldata payload, EIP712Signature calldata signature)` -- push mark price or funding rate
- `getMarkPrice(uint128 marketId) returns (uint256)` -- get latest pushed mark price
- `getMarkPriceTimestamp(uint128 marketId) returns (uint256)` -- timestamp of last mark price push
- `getFundingRate(uint128 marketId) returns (int256)` -- get latest pushed funding rate
- `getFundingRateTimestamp(uint128 marketId) returns (uint256)` -- timestamp of last funding rate push
- `getMarketConfigurationV2(uint128 marketId) returns (MarketConfigurationDataV2)` -- read full perpOB config

**New structs added:**
- `MarketConfigurationDataV2` -- full perpOB layout with deprecated AMM fields and new orderbook fields (`markPriceMaxStaleDuration`, `fundingRateMaxStaleDuration`, `markPriceMaxDeviation`, `fillPriceMaxDeviation`)
- `PerpFillFees` with: `protocolFeeCredit`, `exchangeFeeCredit`, `makerFeeCredit`, `makerFeeDebit`, `referrerFeeCredit`
- `ExecutionType` enum: `MatchOrder`, `DutchLiquidation`, `RankedLiquidation`, `BackstopLiquidation`, `ADL`
- `OracleDataType` enum: `MarkPrice`, `FundingRate`
- `OracleDataPayload` struct

**New errors added:**
- `StaleMarkPrice`, `StaleFundingRate`, `FillPriceDeviationExceeded`, `MarkPriceDeviationExceeded`

**Backward compat note:** The original `MarketConfigurationData` struct is preserved unchanged for cronos/mainnet ABI compatibility. `MarketConfigurationDataV2` is used by perpOB-specific tests.

### 6.2 `IOrdersGatewayProxy.sol` ✅

**New order types** added to `OrderType` enum:
- `LimitOrderPerp` (index 7)
- `ReduceOnlyPerp` (index 8)

**New struct added:**
- `LimitOrderPerpDetails` with `baseDelta` (SD59x18) and `price` (UD60x18)

**Already present (verified):**
- `executeFill()` and `batchExecuteFill()` -- used by Spot
- `FillDetails`, `SignedMatchingEnginePayload` -- used by Spot

### 6.3 `ICoreProxy.sol`

**Not yet updated** (deferred -- `executeMatchOrder` signature change will break cronos/mainnet tests if done now)

---

## 7. Devnet vs Testnet (Cronos) Delta

| Feature | Testnet (Cronos) | Devnet | Notes |
|---------|-----------------|--------|-------|
| **Perp Markets** | 75 | 1 (ETH) | Add more when needed |
| **Spot Markets** | 3 active (WETH, WBTC, REYA) | 1 (WETH/rUSD) | |
| **Collateral Assets** | 14 | 2 (rUSD, wETH) | |
| **Pricing Model** | AMM (depth factor, pSlippage) | Order book (mark price push, ME fills) | Core difference |
| **Funding Rate** | Velocity-based with clamping | Push-based rectangle model | Core difference |
| **Perp Counterparty** | Passive pool account | Matching engine (buyer <-> seller) | Core difference |
| **Backstop Liquidation** | Passive pool absorbs | Dedicated backstop liquidator account | Core difference |
| **Perp Order Types** | SL, TP, Limit, Market, ReduceOnly, FullClose | LimitOrderPerp, ReduceOnlyPerp | Simplified |
| **Fee Model** | MatchOrderFees with pool rebate | PerpFillFees with maker fee/rebate | Core difference |
| **Oracle Model** | Stork price feeds via oracle manager | Stork feeds + oracle push module for mark/funding | New module |
| **Feature Flags** | configureSpread, configureDepth | oraclePushers, oraclePublishers, multicall | New flags |
| **Exchanges** | 5 (passive pool + 4 fee collectors) | 1 (passive pool, not trading perps) | Simplified |
| **Pausers** | 4 | 1 | Simplified |
| **Liquidators** | 10 + 3 AE | 1 | Simplified |
| **CO Execution Bots** | 7 | 0 | Old COs removed |
| **Rebalancers** | 6 | 0 | Not needed initially |
| **LM Tokens** | rselini, ramber, rhedge | None | Not needed |
| **Staking Tokens** | srusd, sreya | None | Not needed |
| **Bridge Config** | Full multi-chain | None | Not needed initially |
| **Risk Matrix** | 75x75 | 1x1 | Single market |
| **Rotations** | Yes | No | Not needed |
| **Market Vol Configurators** | 20 | 0 | AMM concept removed |
| **MulticallModule** | No | Yes | New in perpOB |
| **Event Sequencing** | No | Yes | New in perpOB |

### Introducing Missing Features

When the devnet proves stable, gradually introduce:
1. Additional perp markets (BTC, SOL, etc.)
2. Additional collateral assets
3. Bridge configuration
4. Multiple liquidators
5. Additional pausers
6. Pool staking features

---

## 8. Migration Roadmap

### Phase 1: Devnet (Current)
**Goal**: Deploy and stress-test perpOB changes in isolation.

1. Create devnet omnibus with minimal market/collateral set
2. Deploy fresh proxies using current cannon packages
3. Build and publish perpOB router packages from `feat/perpOB` branch
4. Upgrade devnet proxies to perpOB routers
5. Configure oracle push infrastructure (pusher, publisher addresses)
6. Configure matching engine publisher
7. Create dedicated backstop liquidator account
8. Run devnet fork checks
9. Stress test: high-volume fills, edge-case liquidations, funding accrual, staleness enforcement

### Phase 2: Cronos Testnet Migration
**Goal**: Migrate existing cronos environment to perpOB model.

1. Publish perpOB router packages as new versions
2. Update cronos omnibus `cannonClonePackages` to reference perpOB routers
3. Handle market data migration:
   - Deprecated fields (`velocityMultiplier`, `depthFactor`, etc.) set to 0
   - New fields (`markPriceMaxStaleDuration`, etc.) configured per market
4. Configure oracle push infrastructure on cronos
5. Migrate from passive pool counterparty to dedicated backstop account
6. Update all 75 market configurations
7. Update fork checks for cronos (same changes as devnet)
8. Run full cronos test suite
9. Deploy upgrade via Cannon

### Phase 3: Mainnet Migration
**Goal**: Production rollout of perpOB model.

1. Audit perpOB contracts (Pashov, Trail of Bits reviews already in progress per `agent-docs/` in reya-network)
2. Update mainnet omnibus with perpOB router packages
3. Staged market migration (start with top markets: ETH, BTC, SOL)
4. Configure mainnet oracle push infrastructure
5. Migrate mainnet backstop from passive pool to dedicated account
6. Update mainnet fork checks
7. Run full mainnet test suite
8. Deploy upgrade with governance approval

---

## 9. Deployment Sequence (Devnet)

### Step 1: Omnibus & Module Files ✅ DONE
1. ✅ Create `agent-docs/perp-orderbook-release-readiness.md` (this file)
2. ✅ Create `token/devnet.toml`
3. ✅ Create `core/devnet.toml`
4. ✅ Create `passive_perp/devnet.toml`
5. ✅ Create `collateral_pools/collateral_pool_1/devnet.toml`
6. ✅ Create `orders_gateway/devnet.toml`
7. ✅ Create `omnibus/reya_devnet.toml`
8. ✅ Update `package.json` files with devnet scripts

### Step 2: Test Infrastructure ✅ DONE
1. ✅ Update `IPassivePerpProxy.sol` with perpOB types (OracleDataPayload, OracleDataType, ExecutionType, PerpFillFees, MarketConfigurationDataV2, pushOracleData, getMarkPrice/getFundingRate)
2. ✅ Update `IOrdersGatewayProxy.sol` with LimitOrderPerp, ReduceOnlyPerp, LimitOrderPerpDetails
3. ✅ Create `OracleDataPayloadHashing.sol` utility
4. ✅ Create `PerpFill.fork.c.sol` -- fill-based perp matching (executePerpFill, pushMarkPrice, pushFundingRate, createLimitOrderPerp helpers)
5. ✅ Create `FundingRatePerpOB.fork.c.sol` -- push-based funding rate tests (kept legacy FundingRate.fork.c.sol for cronos/mainnet)
6. ✅ Create `LiquidationPerpOB.fork.c.sol` -- Dutch + backstop liquidation with fill-based position opening, dedicated backstop account
7. ✅ Create `LeveragePerpOB.fork.c.sol` -- max leverage verification via fill execution
8. ✅ Create `WethCollateralPerpOB.fork.c.sol` -- wETH collateral hedged trading via fills
9. ✅ Create `PermissionsPerpOB.fork.c.sol` -- oracle pusher/ME publisher access control, grant/revoke
10. ✅ Create devnet `ReyaForkTest.sol` with placeholder proxy addresses
11. ✅ Create devnet test runner files:
    - `trade/PerpFill.fork.t.sol` (basic fill, staleness, batch)
    - `trade/FundingRate.fork.t.sol` (push rate, staleness, push mark price)
    - `trade/Spot.fork.t.sol` (reuse existing SpotForkCheck)
    - `trade/Liquidation.fork.t.sol` (Dutch + backstop)
    - `trade/Leverage.fork.t.sol` (ETH with rUSD + wETH collateral)
    - `trade/Permissions.fork.t.sol` (oracle pushers, ME publishers, revocation)
    - `collaterals/RusdCollateral.fork.t.sol` (reuse existing check)
    - `collaterals/WethCollateral.fork.t.sol` (perpOB-adapted)
12. ✅ Full compilation verified (167 files, zero errors)
13. ✅ Backward compatibility verified (existing cronos/mainnet tests unaffected)

### Step 2b: Test Infrastructure TODO
1. ⬜ Add `ReduceOnlyPerp` fork check (open + partial close flow)
2. ⬜ Add ADL fork check (auto-deleveraging execution type)
3. ⬜ Add perpOB fee model fork check (taker fees, maker fee/rebate, protocol/exchange fees)

### Step 3: Build & Deploy (blocked on perpOB package publish)
1. ⬜ Build perpOB router packages from `reya-network` feat/perpOB
2. ⬜ Publish packages to Cannon registry
3. ⬜ Update devnet omnibus with published package versions
4. ⬜ Update devnet `ReyaForkTest.sol` proxy addresses with actual deployed addresses
5. ⬜ Run `cannon build` dry-run (`yarn reya_devnet:simulate`)
6. ⬜ Deploy to Cronos chain

### Step 4: Validate
1. ⬜ Run devnet fork checks (`yarn reya_devnet:test`)
2. ⬜ Execute test trades via matching engine
3. ⬜ Verify oracle push flow end-to-end
4. ⬜ Verify liquidation with backstop account
5. ⬜ Verify funding rate accrual
6. ⬜ Stress test with concurrent fills

---

## 10. Open Questions & Risk Items

1. **Router package versions**: perpOB router packages need to be built and published before devnet omnibus can be fully resolved. Currently using placeholder versions.

2. **MarketDataUpdated event ABI**: The `createMarket` invocation in `market_1eth.toml` includes an inline ABI for the `MarketDataUpdated` event. This ABI references old `Market.Data` fields (`passivePoolId`, `poolAccountId`, `lastFundingVelocity`, `lastMTM`). The ABI must be updated to match the perpOB `Market.Data` struct.

3. **Global configuration**: `passive_perp/configs/global_config.toml` sets `exchangeProxy = PassivePoolProxy.address`. In perpOB, if the passive pool is no longer the perp counterparty, this configuration may need to change or the relationship between exchange proxy and passive pool may need clarification.

4. **Backstop liquidator account creation**: Need to define the process for creating and funding the dedicated backstop liquidator account on devnet.

5. **Fee tier `makerRebate` field**: The current `fees.toml` config sets tier parameters. Need to verify whether `makerRebate` is a new field that needs to be added to the fee configuration toml files.

6. **Spot market + perpOB compatibility**: Spot market already uses fill-based matching on cronos. Need to verify that spot and perp fill execution can coexist on the same Orders Gateway deployment.

7. **Oracle push key management**: Need to define who holds the oracle publisher private key and the oracle pusher address for devnet.

8. **Multicall module gating**: Need to define which addresses should have multicall access on devnet.

9. **maxAbsFundingRate**: Need to define the global max absolute funding rate for devnet ETH market.

10. **Insurance fund**: The `market_1eth.toml` creates an insurance fund account per collateral pool. Need to verify this flow is unchanged in perpOB.
