#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# This lane deliberately mutates an impersonated-governance disposable fork. Its output is rehearsal evidence only;
# it must never be merged into the pinned-block PRO-656 acceptance evidence or substituted for RET-21/PRO-958 inputs.
export REYA_SYNTHETIC_TERMINAL_REHEARSAL=true
export REYA_REQUIRE_TERMINAL_MARKETS=true

exec "$SCRIPT_DIR/reya-network-perpob.test.sh" "$@"
