#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PACKAGE_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(cd "$PACKAGE_DIR/../.." && pwd)
TOMLS_DIR="$REPO_ROOT/packages/tomls"
FORK_BLOCK="${REYA_PERPOB_FORK_BLOCK:-218500000}"
CANNON_PORT="${REYA_PERPOB_CANNON_PORT:-18547}"
LOCAL_RPC="http://127.0.0.1:${CANNON_PORT}"
EVIDENCE_DIR="${REYA_PERPOB_EVIDENCE_DIR:-}"
MATCH_PATH="${REYA_PERPOB_MATCH_PATH:-test/reya_network_perpob/**/*.sol}"

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

RUN_DIR=$(mktemp -d "${TMPDIR:-/tmp}/reya-perpob-cannon.XXXXXX")
CANNON_LOG="$RUN_DIR/cannon.log"
CANNON_PID=""
touch "$CANNON_LOG"

cleanup() {
    if [ -n "$CANNON_PID" ] && kill -0 "$CANNON_PID" >/dev/null 2>&1; then
        kill "$CANNON_PID" >/dev/null 2>&1 || true
        wait "$CANNON_PID" >/dev/null 2>&1 || true
    fi
    if [ -n "$EVIDENCE_DIR" ]; then
        mkdir -p "$EVIDENCE_DIR"
        cp "$CANNON_LOG" "$EVIDENCE_DIR/cannon.log"
    fi
    rm -rf "$RUN_DIR"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

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

echo "Running PerpOB fork tests at upgraded block ${LATEST_BLOCK}."
cd "$PACKAGE_DIR"
if [ -n "$EVIDENCE_DIR" ]; then
    mkdir -p "$EVIDENCE_DIR"
    {
        echo "fork_block=${FORK_BLOCK}"
        echo "upgraded_block=${LATEST_BLOCK}"
        echo "terminal_gate=${REYA_REQUIRE_TERMINAL_MARKETS:-false}"
    } > "$EVIDENCE_DIR/run.env"
    REYA_USE_ACTIVE_FORK=true REYA_PERPOB_FORK_BLOCK="$FORK_BLOCK" RPC_KEY="${RPC_KEY:-}" forge test \
        --fork-url "$LOCAL_RPC" \
        --match-path "$MATCH_PATH" \
        --threads 1 \
        "$@" 2>&1 | tee "$EVIDENCE_DIR/forge-test.log"
else
    REYA_USE_ACTIVE_FORK=true REYA_PERPOB_FORK_BLOCK="$FORK_BLOCK" RPC_KEY="${RPC_KEY:-}" forge test \
        --fork-url "$LOCAL_RPC" \
        --match-path "$MATCH_PATH" \
        --threads 1 \
        "$@"
fi
