# PRO-656 mainnet PerpOB fork evidence

Status: **provisional and incomplete**. This record proves the work that can be
rehearsed at mainnet block `218500000`; it deliberately does not promote
provisional packages, addresses, timestamp policy, dust configuration, or a
pre-RET-21 block into release evidence.

## Acceptance-criteria matrix

The wording and completion boundary below follow the PRO-656 Linear acceptance
criteria, not the earlier 12-test PR smoke scope.

| # | Acceptance criterion | Status | Evidence / gap |
| --- | --- | --- | --- |
| 1 | Mainnet omnibus builds from an immutable release manifest. | **Blocked** | [PR #522](https://github.com/Reya-Labs/reya-deployments/pull/522) builds the isolated [`reya_network_perpob.toml`](../packages/tomls/src/omnibus/reya_network_perpob.toml) overlay with provisional `1.1.2` packages. PRO-958 must supply the immutable, audited release manifest; further audit fixes will produce newer releases. |
| 2 | Generated upgrade/config transaction ordering matches the migration design and is proven on a fork. | **Partial** | The ordered payload below was executed successfully on the fork and its readbacks/tests pass. It omits release-blocked timestamp, terminal-market and dust-production inputs and therefore is not the final payload. |
| 3 | Rendered mainnet ME configuration passes fail-closed schema validation with no unknown/deprecated keys. | **Satisfied** | [reya-chain PR #236](https://github.com/Reya-Labs/reya-chain/pull/236) rejects unknown `MATCHING_ENGINE__*` variables recursively. The rendered [reya-devops PR #1035](https://github.com/Reya-Labs/reya-devops/pull/1035) environment has 24 keys and a zero-key schema difference. |
| 4 | Mainnet ME uses current reactor persistence and no obsolete broadcast configuration. | **Satisfied** | PR #1035 replaces all five `MATCHING_ENGINE__PERSISTENCE__*` keys with `MATCHING_ENGINE__REACTOR_PERSISTENCE__*`; repository-wide search finds no `MATCHING_ENGINE__BROADCAST__ENABLED`. It also replaces `MATCHING_ENGINE__MATCHING_ENGINE__NETWORK` and removes three keys rejected by the current schema. |
| 5 | Mainnet fork checks pass at a recorded recent block and cover the full multi-market shape. | **Partial** | The full retained/replacement `test/reya_network/**/*.sol` suite is the CI boundary, and state checks iterate all 75 markets. Block `218500000` is recorded, but it is not the final post-RET-21 block and the terminal test is honestly skipped. See test output and terminal limitation below. |
| 6 | PRO-637 state-survival requirements are satisfied or incorporated. | **Satisfied provisionally** | [`MigrationState.fork.t.sol`](../packages/tests/test/reya_network/perpob/MigrationState.fork.t.sol) compares pre/post implementations and preserves the live account owner, rUSD balance, raw ETH/BTC position storage, trackers, market identity, funding timestamps and OI; activation/timestamp/OI are checked for all 75 markets. Must be rerun with final packages/block. |
| 7 | No retained check depends on removed PerpOB behavior. | **Satisfied** | [`pro-656-reya-network-fork-test-inventory.md`](./pro-656-reya-network-fork-test-inventory.md) classifies every pre-existing fork-test file as retain/adapt/replace/remove and ties each disposition to PerpOB behavior. The CI runner no longer selects only 12 tests. |
| 8 | Post-upgrade state proves ETH/BTC preservation, all other markets closed, timestamp policy, permissions/config, freshness and dust behavior. | **Partial** | ETH/BTC survival, conditional timestamp behavior, readbacks, permissions, signed fills and real fresh/stale paths are covered. Dust happy/negative/permission paths use an isolated provisional sink/keeper and expose the `1.1.2` price-zero/collar incompatibility. Fifty non-ETH/BTC markets still have OI at this block, so terminal closure is not claimed. |
| 9 | Commands, SHAs/packages, fork block, payload summary and output are attached. | **Satisfied for this provisional rehearsal** | This document records them below. Final release evidence must replace the provisional inputs and rerun the same commands. |
| 10 | PRO-261 gate links are present and the migration has required review. | **Missing** | [PRO-261](https://linear.app/reya-labs/issue/PRO-261) gate/review sign-off has not been supplied. This cannot be inferred from a green local run. |

## Revisions and inputs

| Repository | Revision / PR | Purpose |
| --- | --- | --- |
| `reya-deployments` | PR [#522](https://github.com/Reya-Labs/reya-deployments/pull/522), based on `2c5c5ba73f817cd1267f84a8dc9313b5747f3044` | Fork payload, full-suite runner, fork gates, inventory and this evidence. |
| `reya-chain` | `057bd7517a1c03f1a6d74e3a896dbf33453992cf`, PR [#236](https://github.com/Reya-Labs/reya-chain/pull/236) | Fail-closed ME environment schema and tests. |
| `reya-devops` | `6a29b8c8c69f89a838b5ff24b25f41ed1439e67b`, PR [#1035](https://github.com/Reya-Labs/reya-devops/pull/1035) | Mainnet ME key migration and stale-key removal. |
| `reya-python-sdk` | `f989de09460531ac238b2209aa258e8455763056` (`origin/feat/perpOB`) | Bounded audit only: 610 passed, 18 skipped, 1 warning; no SDK source changes and no further PRO-656 scope. |

- Source fork block: `218500000`
- Post-Cannon block: `218500086`
- Package references: `reya-core:1.1.2@router`,
  `reya-orders-gateway:1.1.2@router`,
  `reya-instrument-passive-perp:1.1.2@router`, and
  `reya-periphery:1.1.2@router`
- Cannon package: `reya-mainnet-perpob-fork:0.1.0@main`
- Cannon dry-run estimate: `123,181,930` gas
- Transaction signer for every invoke: mainnet proxy owner/multisig
  `0x1Fe50318e5E3165742eDC9c4a15d997bDB935Eb9`

## Commands and results

### Deployments and fork suite

```sh
cd packages/tests
REYA_PERPOB_CANNON_PORT=18549 \
REYA_PERPOB_EVIDENCE_DIR=/tmp/pro656-full-evidence-2 \
./scripts/reya-network-perpob.test.sh
```

This runs Cannon over the pinned mainnet state, verifies that upgrade
transactions advanced the block, then runs the complete
`test/reya_network/**/*.sol` tree with `--threads 1`. The separate PerpOB
runner's previous 12-test match boundary is not used.

The distinction is material: the previous [PR CI
run](https://github.com/Reya-Labs/reya-deployments/actions/runs/33177455575/job/98869670021)
reported 114 passes and 165 failures across 279 legacy-mainnet tests, while the
separate 12-test PerpOB smoke command was green. This change makes the
classified PerpOB suite itself the `reya_network:test`/CI boundary.

```text
Ran 24 test suites in 658.70s (658.64s CPU time):
138 tests passed, 0 failed, 1 skipped (139 total tests)
```

The sole skip is
`test_TerminalMarketsAreClosedAtApprovedForkBlock`; it is the explicit
RET-21/PRO-394 gate described below. All other retained, adapted and replacement
tests are green. The evidence directory contains `cannon.log`, `forge-test.log`
and `run.env` for this run.

Additional build check:

```sh
cd packages/tests
yarn build
# success
```

### Matching-engine schema

```sh
cargo fmt --all -- --check
cargo test -p matching-engine-server --test config_test
# 150 passed; 0 failed
cargo clippy -p matching-engine-server --all-targets -- -D warnings
# success
```

The config tests prove that the loader rejects retired persistence, obsolete
broadcast enablement and arbitrary typo keys while accepting current reset
configuration.

### Rendered mainnet environment

```sh
helm template mainnet-matching-engine charts/reya-mono-gke \
  -f charts/reya-mono-gke/values.yaml \
  -f deployments/mainnet-gke/values-mainnet-matching-engine.yaml

rg 'MATCHING_ENGINE__BROADCAST__ENABLED' .
# no matches
```

The rendered workload contains 24 `MATCHING_ENGINE__*` names. Comparing the
sorted names against `config-schema` produced zero unknown keys. Secret-sourced
`MATCHING_ENGINE__MATCHING_ENGINE__SIGNER_PRIVATE_KEY` is included in that
comparison.

## Executed Cannon payload

All mutating steps below executed successfully and were mined between blocks
`218500001` and `218500086`. The proxy `owner()` supplies the sender for every
call. Clone/deploy steps produce new router implementations and do not mutate
existing mainnet account/market storage; the invokes below are the fork-state
mutations.

Cannon executed four top-level clone steps and 26 invoke steps; its log contains
zero skipped steps. The release-blocked operations listed after the table are
absent from the TOML rather than silently skipped by Cannon.

| Order | Target | Function / ordered calldata summary | Dependency | Expected/read-back post-state |
| --- | --- | --- | --- | --- |
| 1 | Core `0xA763B6a5E09378434406C003daE6487FbbDc1a80` | `upgradeTo(CoreRouter 1.1.2)` | Core package clone | Implementation changes; account/collateral/position state survives. |
| 2 | OrdersGateway `0xfc8c96bE87Da63CeCddBf54abFA7B13ee8044739` | `upgradeTo(OrdersGatewayRouter 1.1.2)` | OrdersGateway package clone | Signed/batch fills and dust entry point installed. |
| 3 | PassivePerp `0x27E5cb712334e101B3c232eB0Be198baaa595F5F` | `upgradeTo(PassivePerpRouter 1.1.2)` | PassivePerp package clone | V2 config/readbacks installed; legacy position/market storage survives. |
| 4 | Periphery `0xCd2869d1eb1BC8991Bc55de9E9B779e912faF736` | `upgradeTo(PeripheryRouter 1.1.2)` | Periphery package clone | Current collateral periphery calls remain available. |
| 5 | PassivePerp | Allow owner for `configureFees`; set global config `{coreProxy, exchangeProxy_DEPRECATED, oracleManagerAddress, maxAbsFundingRate=0.1e18, dustAccountId_DEPRECATED=0}`; allow owner for `configureMarket` | PassivePerp upgrade | Exact fields read back; provisional funding cap recorded. |
| 6 | PassivePerp | Set global fee parameters and tiers `0..6,100,101` | PassivePerp upgrade | Taker/maker-compatible fields and global rebates match TOML. |
| 7 | PassivePerp | Allow relays `0x6154...3462`, `0xa91C...09Fd3` for `oraclePushers` and `multicall`; allow ME publisher `0x47b3...2296` for `oraclePublishers` | PassivePerp upgrade | Authorized actors can push; unauthorized actors fail. Addresses are provisional. |
| 8 | PassivePerp | Set four global deniers and `global` allow-all | PassivePerp upgrade | Deniers read back; global execution enabled. |
| 9 | PassivePerp | `setMarketConfiguration(1, ETH config)` and `(2, BTC config)` | `configureMarket` owner permission | Legacy risk/sizing retained; mark freshness `60s`, funding freshness `600s`, mark/fill deviation `5%`, provisional `minFundingInterval=0`; values read back. |

The exact structs, hashes, addresses and dependency edges are source-controlled
in the included TOMLs referenced by
[`reya_network_perpob.toml`](../packages/tomls/src/omnibus/reya_network_perpob.toml).
The Cannon log confirms the resolved calldata, signer, contract address,
transaction hash and gas for every row.

### Deliberately absent/skipped payload steps

| Step | Why it is absent | Final requirement |
| --- | --- | --- |
| Immutable release selection | PRO-958 has not supplied final audited package references. | Replace all provisional `1.1.2` sources and record immutable identifiers. |
| Funding timestamp initializer | Both active market timestamps are already non-zero at this block; policy is blocked by PRO-393. | Generate calls only for zero timestamps; reject replay/non-zero values. The fork test proves both branches synthetically without pretending the provisional payload includes a call. |
| Non-ETH/BTC terminal closure | RET-21/PRO-394 has not produced the final post-close block. | Re-run with `REYA_REQUIRE_TERMINAL_MARKETS=true` and the final block; require inactive and zero OI for IDs 3–75. |
| Production dust sink/keeper configuration | PRO-956/PRO-654 inputs are unresolved. | Configure real sink/keeper and prove price-zero settlement under the final audited package/configuration. |

## Fork gates and observed post-state

- Explicit old-to-new survival: implementation address changes while the live
  account `125718`, its rUSD collateral, raw ETH/BTC position slots, market
  identity, long/short funding/ADL trackers, timestamps and OI remain equal.
- Full shape: activation, funding timestamp and OI comparisons iterate market
  IDs `1..75`, not only ETH/BTC.
- Funding timestamp: existing non-zero timestamps are unchanged and initializer
  calls fail closed; an isolated zero slot initializes to `block.timestamp`
  exactly once and replay fails closed.
- Configuration/permissions: global, ETH/BTC, fees, deniers, owner, pusher and
  publisher values are read back; unauthorized callers are rejected.
- Freshness: real pushed mark/funding values pass while fresh and reject after
  their configured `60s`/`600s` windows.
- Signed execution: ETH, BTC and spot signed fills, batch fills, signature and
  metadata binding, nonce replay, reduce-only, fee and margin paths execute
  through the upgraded OrdersGateway.
- Dust: isolated happy, unset-sink, sink-itself, unauthorized keeper, net-short
  sink and enabled-collar rejection paths run. Package `1.1.2` requires the
  fill-deviation collar to be disabled for the price-zero happy path; this is
  recorded as provisional, not accepted as a production configuration.

## Terminal-market limitation

At post-Cannon block `218500086`, **50** markets in IDs `3..75` retain non-zero
OI. Examples include market 3 (`8571799630673111279469` wei), 11
(`2528250000000000000000`), 22 (`501000000000000000000000`) and 75
(`63600000000000000000`). Therefore this run cannot prove terminal closure and
does not claim it.

[`MarketClose.fork.t.sol`](../packages/tests/test/reya_network/trade/MarketClose.fork.t.sol)
is reusable: its gate skips by default at this known-invalid block and becomes
strict with:

```sh
REYA_PERPOB_FORK_BLOCK=<final-post-RET-21-block> \
REYA_REQUIRE_TERMINAL_MARKETS=true \
./scripts/reya-network-perpob.test.sh
```

In strict mode, every market ID `3..75` must be inactive and have zero OI. A
skip is not a terminal-closure pass.

## External blockers retained by PRO-656

- [PRO-958](https://linear.app/reya-labs/issue/PRO-958): immutable audited
  release/package manifest.
- [PRO-393](https://linear.app/reya-labs/issue/PRO-393): final funding-timestamp
  initialization policy/payload.
- [PRO-956](https://linear.app/reya-labs/issue/PRO-956) and
  [PRO-654](https://linear.app/reya-labs/issue/PRO-654): production dust
  settlement configuration and audited behavior.
- [RET-21](https://linear.app/reya-labs/issue/RET-21) and
  [PRO-394](https://linear.app/reya-labs/issue/PRO-394): terminal markets and the
  final reusable fork block.

None of these criteria is marked complete from a synthetic storage edit,
provisional address, provisional package, disabled collar, or skipped test.
