#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PACKAGE_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
REPO_ROOT=$(cd "$PACKAGE_DIR/../.." && pwd)

export CANNON_DIRECTORY="${CANNON_DIRECTORY:-${XDG_CACHE_HOME:-$HOME/.cache}/reya-perpob-cannon}"
export CANNON_REGISTRY_ADDRESS="${CANNON_REGISTRY_ADDRESS:-0x8E5C7EFC9636A6A0408A46BB7F617094B81e5dba}"
export CANNON_REGISTRY_CHAIN_ID="${CANNON_REGISTRY_CHAIN_ID:-10}"
export CANNON_REGISTRY_RPC_URL="${CANNON_REGISTRY_RPC_URL:-https://mainnet.optimism.io}"
export CANNON_IPFS_URL="${CANNON_IPFS_URL:-https+ipfs://repo.usecannon.com}"
export CANNON_IPFS_RETRIES="${CANNON_IPFS_RETRIES:-5}"
export CANNON_IPFS_TIMEOUT="${CANNON_IPFS_TIMEOUT:-300000}"

mkdir -p "$CANNON_DIRECTORY"

exec node "$REPO_ROOT/node_modules/@usecannon/cli/bin/cannon.js" build \
    "$PACKAGE_DIR/src/omnibus/reya_network_perpob.toml" \
    --rpc-url "${REYA_RPC_URL:-https://rpc.reya.network/${RPC_KEY:-}}" \
    --chain-id 1729 \
    --dry-run \
    --impersonate-all \
    --anvil.fork-block-number 218500000
