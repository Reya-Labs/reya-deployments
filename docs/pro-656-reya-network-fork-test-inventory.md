# PRO-656 `reya_network` fork-test inventory

Scope: every active `test*` function under
`test/reya_network/**/*.fork.t.sol` at the PR #522 foundation (354 tests in 24
files). A row classifies every active test in that source file; `PSlippage`
contains only commented-out functions and therefore contributes zero active
tests. The production-neutral `test/reya_network` tree remains unchanged; these
dispositions apply only to the isolated `test/reya_network_perpob` suite.

- **Retain**: behavior and entry point are unchanged by PerpOB.
- **Adapt**: behavior remains required, but setup/assertions use the PerpOB
  router, signed fills, or pinned migration state.
- **Replace**: legacy AMM behavior no longer exists; the named PerpOB family
  covers the corresponding risk through the new execution model.
- **Remove**: no live test exists or the asserted behavior was deliberately
  retired, with no equivalent PerpOB product behavior.

| Legacy source | Tests | Class | PerpOB disposition and reason |
| --- | ---: | --- | --- |
| `accounts/SpotAccount.fork.t.sol` | 3 | Adapt | `reya_network_perpob/accounts/SpotAccount` retains deposits/withdrawals and real collateral-limit assertions. Legacy perp trading is replaced by signed fills; margin-account transfer is exercised through `execute` using two same-owner accounts because the provisional router omits the legacy owner-main-account lookup. |
| `collaterals/AutoExchange.fork.t.sol` | 20 | Remove | Every test submits retired AMM `CommandType.MatchOrder` (type 3). PerpOB has no equivalent pool-counterparty entry point; collateral/margin integration is retained through signed rUSD/wETH fills, liquidation and dust settlement. |
| `collaterals/LmTokenCollateral.fork.t.sol` | 18 | Adapt | Retain mint/redemption/config/cap/deposit/withdrawal behavior and fail if unauthorized feature flags become open. Direct AMM-trade variants are replaced by signed-fill collateral integration. |
| `collaterals/ReyaBridging.fork.t.sol` | 16 | Retain | Bridging, staking and withdrawal permissions do not use PassivePerp AMM execution. |
| `collaterals/ReyaCollateral.fork.t.sol` | 3 | Adapt | Retain collateral and spot configuration with exact global-configuration values rather than non-zero checks. |
| `collaterals/RusdCollateral.fork.t.sol` | 2 | Retain | rUSD/USDC mint-burn authorization is Core collateral behavior independent of the matching model and is now directly wired. |
| `collaterals/SreyaCollateral.fork.t.sol` | 3 | Adapt | Retain sREYA configuration and disabled spot state with exact global-configuration values. |
| `collaterals/SrusdCollateral.fork.t.sol` | 5 | Adapt | Retain token/view/deposit/withdraw/transfer checks; exercise the configured cap through a signed PerpOB fill rather than a retired AMM order. |
| `collaterals/UsualCollateral.fork.t.sol` | 31 | Adapt | Retain configured mint/burn/view/cap/deposit/withdraw behavior. Remove empty deUSD/sdeUSD cap bodies rather than counting no-op passes; those assets are absent from the provisional package. |
| `collaterals/WbtcCollateral.fork.t.sol` | 5 | Retain | WBTC collateral and spot configuration do not invoke retired perp execution. |
| `collaterals/WethCollateral.fork.t.sol` | 1 | Replace | Replace pool-counterparty trading with signed OrdersGateway fills and pushed mark/funding data. |
| `general/General.fork.t.sol` | 11 | Adapt | Retain ownership, proxy, Periphery, oracle and collateral-feed survival; pin cross-chain price comparison at the same fork block with symmetric tolerance. Legacy all-market AMM health assertions become explicit state-survival and reusable terminal-market gates. |
| `oracle_manager/OracleAdapter.fork.t.sol` | 1 | Retain | Stork adapter fulfilment remains an input dependency for collateral and deviation checks. |
| `permissions/Permissions.fork.t.sol` | 23 | Replace | Replace AMM/periphery/conditional-order permissions with PerpOB matching-engine publisher, oracle publisher/pusher, owner, denial and revocation paths. |
| `trade/CoOrder.fork.t.sol` | 23 | Replace | Conditional-order/pool routing is retired. Signed OrdersGateway authentication, metadata binding, nonce replay and reduce-only behavior replace it in `trade/Order`. |
| `trade/FundingRate.fork.t.sol` | 54 | Replace | Velocity-derived AMM funding is retired. Signed push/readback, freshness/staleness, accrual and conditional initialization/replay/fail-closed behavior replace it for ETH and BTC. |
| `trade/Leverage.fork.t.sol` | 65 | Replace | Replace the 75-market pool match matrix with signed ETH/BTC fills covering margin impact, insufficient margin, reduce-only, withdrawal with a position and tighter leverage assertions. |
| `trade/Liquidation.fork.t.sol` | 2 | Adapt | Position setup uses signed fills; Dutch/backstop happy and negative paths run for ETH and BTC with proportional ADL/OI assertions. Exact long-side and non-zero backstop-LP cases are tracked by PRO-1053/PRO-1054. |
| `trade/MarketClose.fork.t.sol` | 7 | Adapt | The replacement is block-parameterized. It fails closed under `REYA_REQUIRE_TERMINAL_MARKETS=true` unless every non-ETH/BTC market is inactive with zero OI; RET-21/PRO-394 owns the final block. |
| `trade/Order.fork.t.sol` | 9 | Replace | Replace pool spreads/gas/fee flags with signed fills, fee bounds/rebates, deprecated-field inertness, batch/close, replay, metadata, margin and actual mark-staleness gates. |
| `trade/PSlippage.fork.t.sol` | 0 | Remove | No active tests exist and AMM p-slippage is retired; PerpOB mark/fill deviation is covered by Runtime/Order. |
| `trade/PassivePool.fork.t.sol` | 42 | Adapt | Retain permission negatives and immediate pre/post share-supply and share-price continuity. Deposit/withdraw/rebalance economics remain terminal-block-gated because retired markets still carry OI and stale marks at block 218,500,000. |
| `trade/PoolStake.fork.t.sol` | 2 | Adapt | The entry points are independent of matching, but they require passive-pool valuation. At the pinned pre-RET-21 block they assert fail-closed stale retired-market marks; under the terminal-block flag they execute the original stake/unstake and move-liquidity happy paths. |
| `trade/Spot.fork.t.sol` | 8 | Replace | Replace the legacy spot signature schema with unified `OrderDetails` signed WETH/WBTC/REYA fills, batches and precision paths. |

New acceptance-only coverage lives in `perpob/MigrationState.fork.t.sol`,
`perpob/Runtime.fork.t.sol`, and `perpob/DustSettlement.fork.t.sol`. It covers
wider account/storage/permission and economic-view survival, configuration,
signed fills, funding initialization, freshness, dust happy/negative/permission
paths, and the reusable terminal gate. The isolated dust sink and keeper prove
runtime mechanics only; PRO-956/654 still own release configuration.

## Accounting and gate status

- Accounted for: **354/354 active legacy tests**.
- No active legacy test is silently dropped.
- The lane must execute its complete discovered PerpOB suite; a focused
  `--match-test` run is diagnostic only.
- Terminal-market closure, terminal-block passive-pool economics, and final
  release inputs remain external gates. The scheduled/blocking flips are
  tracked by PRO-1052.
- The latest complete-suite result is recorded in
  `docs/pro-656-mainnet-fork-evidence.md`; this inventory does not convert an
  external or provisional result into release closure.
