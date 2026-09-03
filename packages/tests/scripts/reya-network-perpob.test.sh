#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PACKAGE_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(cd "$PACKAGE_DIR/../.." && pwd)
TOMLS_DIR="$REPO_ROOT/packages/tomls"
FORK_BLOCK="${REYA_PERPOB_FORK_BLOCK:-218500000}"
CANNON_PORT="${REYA_PERPOB_CANNON_PORT:-18547}"
VALIDATION_PORT="${REYA_PERPOB_CANNON_VALIDATION_PORT:-$((CANNON_PORT + 1))}"
LOCAL_RPC="http://127.0.0.1:${CANNON_PORT}"
EVIDENCE_DIR="${REYA_PERPOB_EVIDENCE_DIR:-}"
MATCH_PATH="${REYA_PERPOB_MATCH_PATH:-test/reya_network_perpob/**/*.sol}"
MIGRATION_STATE_TEST="$PACKAGE_DIR/test/reya_network_perpob/perpob/MigrationState.fork.t.sol"
FORGE_LINKING_ARGS=()

# Foundry 1.8 enables dynamic test linking by default, which can run only the
# source-affected subset even though `--list` reports the whole match path. CI
# currently pins 1.2.3, where the flag does not exist and all tests run by
# default, so feature-detect it rather than breaking the older toolchain.
if forge test --help | grep -q -- "--no-dynamic-test-linking"; then
    FORGE_LINKING_ARGS+=(--no-dynamic-test-linking)
fi

export CANNON_DIRECTORY="${CANNON_DIRECTORY:-${XDG_CACHE_HOME:-$HOME/.cache}/reya-perpob-cannon}"
export CANNON_REGISTRY_ADDRESS="${CANNON_REGISTRY_ADDRESS:-0x8E5C7EFC9636A6A0408A46BB7F617094B81e5dba}"
export CANNON_REGISTRY_CHAIN_ID="${CANNON_REGISTRY_CHAIN_ID:-10}"
export CANNON_REGISTRY_RPC_URL="${CANNON_REGISTRY_RPC_URL:-https://mainnet.optimism.io}"
export CANNON_IPFS_URL="${CANNON_IPFS_URL:-https+ipfs://repo.usecannon.com}"
export CANNON_IPFS_RETRIES="${CANNON_IPFS_RETRIES:-5}"
export CANNON_IPFS_TIMEOUT="${CANNON_IPFS_TIMEOUT:-300000}"

mkdir -p "$CANNON_DIRECTORY"

if cast chain-id --rpc-url "$LOCAL_RPC" >/dev/null 2>&1; then
    echo "Port ${CANNON_PORT} is already serving an RPC node; set REYA_PERPOB_CANNON_PORT to another port." >&2
    exit 1
fi

VALIDATION_RPC="http://127.0.0.1:${VALIDATION_PORT}"
if cast chain-id --rpc-url "$VALIDATION_RPC" >/dev/null 2>&1; then
    echo "Port ${VALIDATION_PORT} is already serving an RPC node; set REYA_PERPOB_CANNON_VALIDATION_PORT to another port." >&2
    exit 1
fi

RUN_DIR=$(mktemp -d "${TMPDIR:-/tmp}/reya-perpob-cannon.XXXXXX")
CANNON_LOG="$RUN_DIR/cannon.log"
CANNON_VALIDATION_LOG="$RUN_DIR/cannon-validation.log"
FORGE_LOG="$RUN_DIR/forge-test.log"
SYNTHETIC_TERMINAL_LOG="$RUN_DIR/synthetic-terminal.log"
SYNTHETIC_READINESS_TSV="$RUN_DIR/synthetic-terminal-readiness.tsv"
SAFE_PAYLOAD_JSON="$RUN_DIR/provisional-safe-payload.json"
SAFE_REHEARSAL_JSON="$RUN_DIR/provisional-safe-halt-resume.json"
SAFE_REHEARSAL_LOG="$RUN_DIR/provisional-safe-halt-resume.log"
DISCOVERY_JSON="$RUN_DIR/forge-test-list.json"
CANNON_PID=""
touch "$CANNON_LOG"

cleanup() {
    if [ -n "$CANNON_PID" ] && kill -0 "$CANNON_PID" >/dev/null 2>&1; then
        kill "$CANNON_PID" >/dev/null 2>&1 || true
        wait "$CANNON_PID" >/dev/null 2>&1 || true
    fi
    if [ -n "$EVIDENCE_DIR" ]; then
        mkdir -p "$EVIDENCE_DIR"
        [ ! -f "$CANNON_LOG" ] || cp "$CANNON_LOG" "$EVIDENCE_DIR/cannon.log"
        [ ! -f "$CANNON_VALIDATION_LOG" ] || cp "$CANNON_VALIDATION_LOG" "$EVIDENCE_DIR/cannon-validation.log"
        [ ! -f "$FORGE_LOG" ] || cp "$FORGE_LOG" "$EVIDENCE_DIR/forge-test.log"
        [ ! -f "$SYNTHETIC_TERMINAL_LOG" ] || cp "$SYNTHETIC_TERMINAL_LOG" "$EVIDENCE_DIR/synthetic-terminal.log"
        [ ! -f "$SYNTHETIC_READINESS_TSV" ] || cp "$SYNTHETIC_READINESS_TSV" "$EVIDENCE_DIR/synthetic-terminal-readiness.tsv"
        [ ! -f "$SAFE_PAYLOAD_JSON" ] || cp "$SAFE_PAYLOAD_JSON" "$EVIDENCE_DIR/provisional-safe-payload.json"
        [ ! -f "$SAFE_REHEARSAL_JSON" ] || cp "$SAFE_REHEARSAL_JSON" "$EVIDENCE_DIR/provisional-safe-halt-resume.json"
        [ ! -f "$SAFE_REHEARSAL_LOG" ] || cp "$SAFE_REHEARSAL_LOG" "$EVIDENCE_DIR/provisional-safe-halt-resume.log"
        [ ! -f "$DISCOVERY_JSON" ] || cp "$DISCOVERY_JSON" "$EVIDENCE_DIR/forge-test-list.json"
    fi
    rm -rf "$RUN_DIR"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

if [ "$VALIDATION_PORT" = "$CANNON_PORT" ]; then
    echo "Cannon validation and retained-node ports must differ." >&2
    exit 1
fi

SOLIDITY_FORK_BLOCK=$(sed -nE \
    's/^[[:space:]]*uint256 internal constant MAINNET_FORK_BLOCK = ([0-9_]+);/\1/p' \
    "$MIGRATION_STATE_TEST" | tr -d '_')
if [ -z "$SOLIDITY_FORK_BLOCK" ] || ! [[ "$SOLIDITY_FORK_BLOCK" =~ ^[0-9]+$ ]]; then
    echo "Could not read one MAINNET_FORK_BLOCK constant from ${MIGRATION_STATE_TEST}." >&2
    exit 1
fi
if [ "$FORK_BLOCK" != "$SOLIDITY_FORK_BLOCK" ]; then
    echo "REYA_PERPOB_FORK_BLOCK=${FORK_BLOCK} disagrees with Solidity MAINNET_FORK_BLOCK=${SOLIDITY_FORK_BLOCK}." >&2
    exit 1
fi

# Cannon sets process.exitCode=90/91 for partial/failed builds before entering
# keep-alive, so the retained process cannot expose that status until it is
# stopped. Execute the identical build once without keep-alive and capture the
# CLI's real status before allowing tests to use a second retained node.
set +e
(
    cd "$TOMLS_DIR"
    node "$REPO_ROOT/node_modules/@usecannon/cli/bin/cannon.js" build \
        src/omnibus/reya_network_perpob.toml \
        --rpc-url "${REYA_RPC_URL:-https://rpc.reya.network/${RPC_KEY:-}}" \
        --chain-id 1729 \
        --dry-run \
        --impersonate-all \
        --anvil.fork-block-number "$FORK_BLOCK" \
        --port "$VALIDATION_PORT"
) 2>&1 | tee "$CANNON_VALIDATION_LOG"
CANNON_VALIDATION_STATUS=${PIPESTATUS[0]}
set -e
if [ "$CANNON_VALIDATION_STATUS" -ne 0 ]; then
    echo "Cannon validation build failed with exit ${CANNON_VALIDATION_STATUS}." >&2
    exit "$CANNON_VALIDATION_STATUS"
fi

(
    cd "$TOMLS_DIR"
    exec node "$REPO_ROOT/node_modules/@usecannon/cli/bin/cannon.js" build \
        src/omnibus/reya_network_perpob.toml \
        --rpc-url "${REYA_RPC_URL:-https://rpc.reya.network/${RPC_KEY:-}}" \
        --chain-id 1729 \
        --dry-run \
        --impersonate-all \
        --anvil.fork-block-number "$FORK_BLOCK" \
        --keep-alive \
        --port "$CANNON_PORT"
) > >(tee "$CANNON_LOG") 2>&1 &
CANNON_PID=$!

READY=false
for _ in $(seq 1 900); do
    if grep -Eq "deployment was not fully completed|partial deployment" "$CANNON_LOG"; then
        echo "Cannon retained-node build reported a partial deployment." >&2
        exit 90
    fi
    if grep -q "The local node will continue running" "$CANNON_LOG"; then
        READY=true
        break
    fi
    if ! kill -0 "$CANNON_PID" >/dev/null 2>&1; then
        wait "$CANNON_PID" || true
        echo "Cannon exited before the PerpOB fork was ready." >&2
        exit 1
    fi
    sleep 1
done

if [ "$READY" != true ]; then
    echo "Timed out waiting for the PerpOB Cannon fork." >&2
    exit 1
fi

LATEST_BLOCK=$(cast block-number --rpc-url "$LOCAL_RPC")
if [ "$LATEST_BLOCK" -le "$FORK_BLOCK" ]; then
    echo "Cannon fork did not retain its upgrade transactions (latest block: ${LATEST_BLOCK})." >&2
    exit 1
fi
PRISTINE_UPGRADED_BLOCK=$LATEST_BLOCK

if [ "${REYA_SYNTHETIC_TERMINAL_REHEARSAL:-false}" = true ]; then
    if [ "${REYA_REQUIRE_TERMINAL_MARKETS:-false}" != true ]; then
        echo "Synthetic terminal rehearsal requires REYA_REQUIRE_TERMINAL_MARKETS=true." >&2
        exit 1
    fi
    echo "SYNTHETIC REHEARSAL — NOT PRO-656 ACCEPTANCE EVIDENCE"
    "$SCRIPT_DIR/pro656-safe-payload.sh" "$CANNON_LOG" "$LOCAL_RPC" "$SAFE_PAYLOAD_JSON"
    "$SCRIPT_DIR/pro656-safe-halt-resume.sh" \
        "$LOCAL_RPC" \
        "${REYA_RPC_URL:-https://rpc.reya.network/${RPC_KEY:-}}" \
        "$SAFE_PAYLOAD_JSON" \
        "$SAFE_REHEARSAL_JSON" \
        "${REYA_PERPOB_SAFE_REPLAY_PORT:-$((VALIDATION_PORT + 1))}" 2>&1 | tee "$SAFE_REHEARSAL_LOG"
    echo "Terminalizing the disposable fork with impersonated governance."
    cast rpc --rpc-url "$LOCAL_RPC" anvil_impersonateAccount 0x1Fe50318e5E3165742eDC9c4a15d997bDB935Eb9 >/dev/null
    cd "$PACKAGE_DIR"
    set +e
    forge script script/SyntheticTerminalState.s.sol:SyntheticTerminalState \
        --rpc-url "$LOCAL_RPC" \
        --broadcast \
        --unlocked \
        --sender 0x1Fe50318e5E3165742eDC9c4a15d997bDB935Eb9 \
        -vvv 2>&1 | tee "$SYNTHETIC_TERMINAL_LOG"
    SYNTHETIC_TERMINAL_STATUS=${PIPESTATUS[0]}
    set -e
    if [ "$SYNTHETIC_TERMINAL_STATUS" -ne 0 ]; then
        echo "Synthetic terminalization failed with exit ${SYNTHETIC_TERMINAL_STATUS}." >&2
        exit "$SYNTHETIC_TERMINAL_STATUS"
    fi
    if ! grep -q "SYNTHETIC_REHEARSAL_CLOSED_MARKETS 50" "$SYNTHETIC_TERMINAL_LOG"; then
        echo "Synthetic terminalization did not prove all 50 target markets closed." >&2
        exit 1
    fi
    if ! grep -q "SYNTHETIC_REHEARSAL_FAILED_MARKETS 0" "$SYNTHETIC_TERMINAL_LOG"; then
        echo "Synthetic terminalization reported at least one readiness, closure, or readback failure." >&2
        exit 1
    fi
    awk '
        BEGIN {
            OFS="\t"
            print "market_id", "accounts", "open_interest", "exact_max_residual", "base_spacing", "below_lmr", "below_imr_diagnostic", "zero_base_fixture_rows"
        }
        /SYNTHETIC_REHEARSAL_READINESS_MARKET/ { market=$NF }
        /^  accounts / { accounts=$NF }
        /^  openInterest / { oi=$NF }
        /^  exactMaxResidual / { residual=$NF }
        /^  baseSpacing / { spacing=$NF }
        /^  belowLmrCount / { lmr=$NF }
        /^  belowImrCountDiagnosticOnly / { imr=$NF }
        /^  zeroBaseFixtureCount / {
            print market, accounts, oi, residual, spacing, lmr, imr, $NF
        }
    ' "$SYNTHETIC_TERMINAL_LOG" > "$SYNTHETIC_READINESS_TSV"
    if [ "$(($(wc -l < "$SYNTHETIC_READINESS_TSV") - 1))" -ne 50 ]; then
        echo "Synthetic readiness artifact does not contain exactly 50 market rows." >&2
        exit 1
    fi
    LATEST_BLOCK=$(cast block-number --rpc-url "$LOCAL_RPC")
fi

echo "Running PerpOB fork tests at upgraded block ${LATEST_BLOCK}."
cd "$PACKAGE_DIR"
REYA_USE_ACTIVE_FORK=true REYA_PERPOB_FORK_BLOCK="$FORK_BLOCK" REYA_PERPOB_LOCAL_RPC="$LOCAL_RPC" REYA_PERPOB_PRISTINE_UPGRADED_BLOCK="$PRISTINE_UPGRADED_BLOCK" RPC_KEY="${RPC_KEY:-}" forge test \
    --fork-url "$LOCAL_RPC" \
    --match-path "$MATCH_PATH" \
    "${FORGE_LINKING_ARGS[@]}" \
    --threads 1 \
    --list \
    --json \
    "$@" > "$DISCOVERY_JSON"
DISCOVERED_TEST_COUNT=$(jq -er '[.[][][]] | length' "$DISCOVERY_JSON")
if [ "$DISCOVERED_TEST_COUNT" -le 0 ]; then
    echo "Forge discovered zero tests for --match-path ${MATCH_PATH}." >&2
    exit 1
fi

set +e
REYA_USE_ACTIVE_FORK=true REYA_PERPOB_FORK_BLOCK="$FORK_BLOCK" REYA_PERPOB_LOCAL_RPC="$LOCAL_RPC" REYA_PERPOB_PRISTINE_UPGRADED_BLOCK="$PRISTINE_UPGRADED_BLOCK" RPC_KEY="${RPC_KEY:-}" forge test \
    --fork-url "$LOCAL_RPC" \
    --match-path "$MATCH_PATH" \
    "${FORGE_LINKING_ARGS[@]}" \
    --threads 1 \
    "$@" 2>&1 | tee "$FORGE_LOG"
FORGE_STATUS=${PIPESTATUS[0]}
set -e
if [ "$FORGE_STATUS" -ne 0 ]; then
    exit "$FORGE_STATUS"
fi

EXECUTED_TEST_COUNT=$(sed -nE 's/.*\(([0-9]+) total tests\).*/\1/p' "$FORGE_LOG" | tail -n 1)
if [ -z "$EXECUTED_TEST_COUNT" ] || [ "$EXECUTED_TEST_COUNT" -ne "$DISCOVERED_TEST_COUNT" ]; then
    echo "Forge executed-test count ${EXECUTED_TEST_COUNT:-missing} does not match discovered count ${DISCOVERED_TEST_COUNT}." >&2
    exit 1
fi

if [ -n "$EVIDENCE_DIR" ]; then
    mkdir -p "$EVIDENCE_DIR"
    {
        echo "fork_block=${FORK_BLOCK}"
        echo "solidity_fork_block=${SOLIDITY_FORK_BLOCK}"
        echo "upgraded_block=${PRISTINE_UPGRADED_BLOCK}"
        echo "test_state_block=${LATEST_BLOCK}"
        echo "cannon_validation_exit=${CANNON_VALIDATION_STATUS}"
        echo "discovered_test_count=${DISCOVERED_TEST_COUNT}"
        echo "executed_test_count=${EXECUTED_TEST_COUNT}"
        echo "terminal_gate=${REYA_REQUIRE_TERMINAL_MARKETS:-false}"
        echo "synthetic_rehearsal=${REYA_SYNTHETIC_TERMINAL_REHEARSAL:-false}"
        if [ "${REYA_SYNTHETIC_TERMINAL_REHEARSAL:-false}" = true ]; then
            echo "evidence_class=SYNTHETIC REHEARSAL - NOT PRO-656 ACCEPTANCE EVIDENCE"
        fi
    } > "$EVIDENCE_DIR/run.env"
fi
