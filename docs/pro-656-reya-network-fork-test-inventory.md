# PRO-656 `reya_network` fork-test inventory

Classification is against the test tree that existed at PR #522 commit `805b396`.
Every callable test in a row inherits that row's disposition unless a narrower
exception is stated. “Retain” means the behavior is independent of the retired
AMM execution path; “adapt/replace/remove” is tied to the PerpOB runtime model.

| Original fork-test file | Classification | PerpOB reason and resulting coverage |
| --- | --- | --- |
| `accounts/SpotAccount.fork.t.sol` | Adapt | Retain spot-account deposits, withdrawals and collateral limits. Remove the direct legacy perp-trade assertion. The provisional 1.1.2 Core router also lacks the transfer selector, so transfer remains release-blocked rather than being reported green; signed PerpOB fills are covered by `trade/Order` and `collaterals/WethCollateral`. |
| `collaterals/AutoExchange.fork.t.sol` | Remove | All 20 executable tests submit the retired AMM `CommandType.MatchOrder` (command type 3), which the PerpOB Core rejects. Collateral/margin integration is retained through signed rUSD/wETH fills and dust settlement. |
| `collaterals/LmTokenCollateral.fork.t.sol` | Adapt | Retain mint, redemption, caps, views, deposit and withdrawal. Remove direct AMM-trade deposit/withdraw variants; signed-fill collateral integration is covered by the PerpOB leverage and wETH tests. |
| `collaterals/ReyaBridging.fork.t.sol` | Retain | Bridging, staking and withdrawal permissions do not use PassivePerp AMM execution. |
| `collaterals/ReyaCollateral.fork.t.sol` | Retain | REYA collateral and spot-market configuration must survive the upgrade unchanged. |
| `collaterals/RusdCollateral.fork.t.sol` | Remove | The wrapper exposed no executable test; rUSD is exercised by every signed-fill, leverage, liquidation and dust replacement. |
| `collaterals/SreyaCollateral.fork.t.sol` | Retain | sREYA configuration and disabled spot state are unrelated to removed perp execution. |
| `collaterals/SrusdCollateral.fork.t.sol` | Adapt | Retain token, view, deposit, withdrawal and transfer checks; remove the direct AMM-trade variant. |
| `collaterals/UsualCollateral.fork.t.sol` | Adapt | Retain mint/burn, views, caps and deposit/withdraw for all listed collateral. Remove six direct AMM-trade variants. |
| `collaterals/WbtcCollateral.fork.t.sol` | Retain | WBTC collateral and spot configuration readbacks remain valid and do not invoke the retired perp order path. |
| `collaterals/WethCollateral.fork.t.sol` | Replace | Replace pool-counterparty trading with signed OrdersGateway PerpOB fill execution and pushed mark/funding data. |
| `general/General.fork.t.sol` | Adapt | Retain ownership, proxy upgrade protection, Periphery, oracle and collateral-feed survival. Remove the two feed-processing assertions whose health calculation traverses still-open terminal markets; replace legacy all-market AMM price/stale/max-OI and mutable active-list assertions with PerpOB configuration, state-survival and reusable terminal gates. |
| `oracle_manager/OracleAdapter.fork.t.sol` | Retain | Stork adapter fulfilment remains an input dependency for collateral and deviation checks. |
| `permissions/Permissions.fork.t.sol` | Adapt | Retain current pool, Core, account and oracle-adapter permissions. Replace brittle legacy spread/depth/volatility/conditional-order assertions with `configureMarket`, oracle pusher/publisher, matching-engine publisher and closed `settle_dust` gates. |
| `trade/CoOrder.fork.t.sol` | Remove | The legacy conditional-order executor and pool-routed order schema are not part of the unified signed PerpOB fill path. Signature binding, nonce replay and reduce-only behavior move to `trade/Order`. |
| `trade/FundingRate.fork.t.sol` | Replace | Velocity-derived funding is removed. Replacement pushes signed rates and proves readback, push-time staleness, trade-time staleness and accrual on ETH/BTC. |
| `trade/Leverage.fork.t.sol` | Replace | Legacy leverage opened pool-routed positions across markets that must become terminal. Replacement opens signed ETH/BTC fills and covers rUSD and wETH collateral. |
| `trade/Liquidation.fork.t.sol` | Replace | Position setup moves from AMM orders to signed fills; Dutch/backstop happy and negative paths remain required. |
| `trade/MarketClose.fork.t.sol` | Replace | Legacy W1 replay is not the final RET-21 state. Replacement is block-parameterized and skips unless `REYA_REQUIRE_TERMINAL_MARKETS=true`; it then requires every non-ETH/BTC market to be inactive with zero OI. |
| `trade/Order.fork.t.sol` | Replace | Pool match-order fees/spread/gas checks are removed behavior. Replacement covers signed ETH/BTC fills, metadata binding, nonce replay, batches, closes, fees, margin, reduce-only and actual mark staleness. |
| `trade/PSlippage.fork.t.sol` | Remove | The file contained no enabled tests and p-slippage is an AMM concept; PerpOB uses mark/fill deviation collars. |
| `trade/PassivePool.fork.t.sol` | Adapt | Retain the two permission-negative gates. Remove 40 operational pool tests for this block because pool health/share valuation traverses the 50 non-ETH/BTC markets that still have OI and zero current mark timestamps. They become meaningful only after the RET-21 terminal block and are not used as provisional evidence. |
| `trade/PoolStake.fork.t.sol` | Remove | Both stake/unstake tests require pool-health valuation across the same nonterminal legacy markets. Re-run this behavior at the final RET-21 block; it cannot honestly be made green at block `218500000`. |
| `trade/Spot.fork.t.sol` | Replace | Replace the old spot signature schema with unified `OrderDetails` signed fills and batch fills through the upgraded OrdersGateway. |
| `perpob/MigrationState.fork.t.sol` | Adapt | Expand representative storage checks into explicit old-implementation to new-implementation survival, all-market activation/OI/timestamps, conditional timestamp initialization and replay rejection. |
| `perpob/Runtime.fork.t.sol` | Adapt | Expand the initial 12-test smoke into configuration/fee readbacks, permissions, signed fills and freshness behavior; it is no longer the CI match-path boundary. |

New acceptance-only coverage lives in `perpob/DustSettlement.fork.t.sol` and
the reusable terminal gate. The dust suite provisions an isolated test sink and
keeper because the production sink/keeper inputs are externally blocked; it is
not evidence that release configuration exists.

The classified suite result at fork block `218500000` is 138 passed, 0 failed
and 1 explicitly skipped across 24 suites (139 total). The skip is only the
strict terminal-market replacement, which requires the final post-RET-21 block;
it is not counted as closure evidence.
