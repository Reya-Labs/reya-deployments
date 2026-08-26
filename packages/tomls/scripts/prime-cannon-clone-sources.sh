#!/usr/bin/env bash
# Prime the LOCAL cannon registry with the clone-source artifacts devnet was
# actually deployed from (PRO-998).
#
# THE PROBLEM
#
# Cannon resolves a `clone.source` package through the on-chain registry, and
# for 12 of devnet's 17 clone sources the registry now serves DIFFERENT bytes
# than devnet was built from -- the packages were rebuilt on a newer cannon
# toolchain and republished under the same ref. Cannon deploys cloned proxies
# via arachnid CREATE2, so different artifact bytes give different initcode,
# which gives a different proxy address. Concretely, for
# reya-exchange-passive-pool:1.0.0@proxy:
#
#   pinned artifact  (cannon cli 2.23.0) -> PassivePool 0x9fDba948...abA2  (live devnet)
#   registry artifact(cannon cli 2.12.4) -> PassivePool 0xE93414D5...8652  (everyone else)
#
# So devnet reproduces on exactly one machine -- the one whose local cache
# still holds the originals -- and the devnet fork suite cannot pass in CI.
#
# THE FIX
#
# Cannon consults the LOCAL registry before the on-chain ones, so fetching the
# pinned CIDs into the local registry makes every machine resolve the same
# bytes. Run this before ANY devnet build (`reya_devnet:test`,
# `reya_devnet:simulate`); it is idempotent and cheap once cached.
#
# chainId 13370 is deliberate and is NOT the devnet chain id. Cannon resolves
# clone sources at CANNON_CHAIN_ID (the portable variant) regardless of the
# target chain -- @usecannon/builder steps/clone.js, `config.chainId ??
# CANNON_CHAIN_ID`. Priming these under 89346162 (as the omnibus prime step
# correctly does for the omnibus package, which really is an 89346162
# deployment) writes tags that no clone step ever reads, so the build silently
# falls through to the registry and you get the wrong addresses anyway.
#
# Usage: prime-cannon-clone-sources.sh [--verify-only]
set -uo pipefail

cd "$(dirname "$0")/.."

LOCKFILE="src/omnibus/reya_devnet.lock.json"
OMNIBUS="src/omnibus/reya_devnet.toml"
CANNON="../../node_modules/@usecannon/cli-devnet/bin/cannon.js"
CHAIN_ID="$(node -p "require('./${LOCKFILE}').chainId")"
CANNON_DIR="${CANNON_DIRECTORY:-$HOME/.local/share/cannon}"
VERIFY_ONLY="${1:-}"

# `cannon fetch` reads publishIpfsUrl (CANNON_PUBLISH_IPFS_URL) for its download
# loader -- NOT CANNON_IPFS_URL and not CANNON_WRITE_IPFS_URL. Unset, it falls
# back to getCannonRepoRegistryUrl(), the region-derived repo hosts that were
# decommissioned, and dies with an SSL handshake failure (EPROTO). Same trap as
# `cannon publish`. Defaulted here so a developer gets a working `yarn
# reya_devnet:prime` without exporting anything; CI sets them explicitly.
export CANNON_PUBLISH_IPFS_URL="${CANNON_PUBLISH_IPFS_URL:-https+ipfs://repo.usecannon.com}"
export CANNON_IPFS_URL="${CANNON_IPFS_URL:-https+ipfs://repo.usecannon.com}"

echo "==> priming cannon clone sources from ${LOCKFILE}"
echo "    cannon directory : ${CANNON_DIR}"
echo "    ipfs repo        : ${CANNON_PUBLISH_IPFS_URL}"
echo "    chain id         : ${CHAIN_ID}  (cannon portable variant, not the devnet chain)"

# ---------------------------------------------------------------------------
# Drift guard. A pin is worthless if the omnibus has since moved to another
# version of the same package: cannon would resolve the NEW ref from the
# registry and the prime step would silently prime a ref nobody builds.
# ---------------------------------------------------------------------------
TOML_REFS="$(grep -oE '^[a-zA-Z]+Package = "[^"]+"' "${OMNIBUS}" | sed 's/.*= "//; s/"$//' | sort -u)"
LOCK_REFS="$(node -p "Object.keys(require('./${LOCKFILE}').packages).join('\n')" | sort -u)"

STALE="$(comm -23 <(echo "${LOCK_REFS}") <(echo "${TOML_REFS}"))"
if [ -n "${STALE}" ]; then
  echo "!!! lockfile pins refs that ${OMNIBUS} no longer clones:"
  echo "${STALE}" | sed 's/^/      /'
  echo "!!! update ${LOCKFILE} (see CANNON.md, 'Clone-source pinning')"
  exit 1
fi

UNPINNED="$(comm -13 <(echo "${LOCK_REFS}") <(echo "${TOML_REFS}"))"
if [ -n "${UNPINNED}" ]; then
  echo "--> not pinned (registry still serves the deployed artifacts for these):"
  echo "${UNPINNED}" | sed 's/^/      /'
fi

# ---------------------------------------------------------------------------
# Fetch each pinned deployment blob into the local registry, then read the tag
# back. `cannon fetch` exits 0 on some partial failures, so verify rather than
# trust the exit code.
# ---------------------------------------------------------------------------
FAILED=0
MISSING_MISC=""

while IFS=$'\t' read -r REF DEPLOY_CID MISC_CID; do
  # tags/<name>_<version>_<chainId>-<preset>.txt  (LocalRegistry.getTagReferenceStorage)
  NAME="${REF%%:*}"; REST="${REF#*:}"; VERSION="${REST%%@*}"; PRESET="${REST#*@}"
  TAG="${CANNON_DIR}/tags/${NAME}_${VERSION}_${CHAIN_ID}-${PRESET}.txt"

  if [ "${VERIFY_ONLY}" != "--verify-only" ]; then
    node "${CANNON}" fetch "ipfs://${DEPLOY_CID}" "${REF}" --chain-id "${CHAIN_ID}" >/dev/null 2>&1
  fi

  ACTUAL="$(cat "${TAG}" 2>/dev/null)"
  if [ "${ACTUAL}" = "ipfs://${DEPLOY_CID}" ]; then
    echo "    ok      ${REF} -> ${DEPLOY_CID}"
  else
    echo "    FAILED  ${REF}"
    echo "              expected ipfs://${DEPLOY_CID}"
    echo "              got      ${ACTUAL:-<no tag written>}"
    FAILED=$((FAILED + 1))
  fi

  # The clone step reads deployInfo.miscUrl UNCONDITIONALLY for contract
  # bytecode (steps/clone.js: `const upstreamMisc = await
  # runtime.readBlob(deployInfo.miscUrl)`), so a deploy blob whose misc blob is
  # unreachable cannot actually be cloned on a cold machine. `cannon fetch`
  # stores only the deploy tag -- misc is fetched lazily at build time -- so
  # check reachability here rather than discovering it mid-build as a skipped
  # clone step and a cascade of confusing downstream failures.
  if [ -n "${MISC_CID}" ]; then
    CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 60 \
      -X POST "https://repo.usecannon.com/api/v0/cat?arg=${MISC_CID}")"
    if [ "${CODE}" != "200" ]; then
      MISSING_MISC="${MISSING_MISC}      ${REF}  misc=${MISC_CID}  (HTTP ${CODE})"$'\n'
    fi
  fi
done < <(node -p "
  const l = require('./${LOCKFILE}');
  Object.entries(l.packages).map(([r, p]) => [r, p.deploy, p.misc || ''].join('\t')).join('\n')
")

if [ -n "${MISSING_MISC}" ]; then
  echo
  echo "!!! artifact (misc) blobs NOT reachable on repo.usecannon.com:"
  printf '%s' "${MISSING_MISC}"
  echo "!!! the deploy blobs above are pinned correctly, but a machine without"
  echo "!!! these in its local ipfs_cache CANNOT clone these packages -- publish"
  echo "!!! them alongside the deploy blobs (PRO-998 step 1 follow-up)."
fi

if [ "${FAILED}" -ne 0 ]; then
  echo
  echo "==> ${FAILED} clone source(s) failed to prime"
  exit 1
fi

echo "==> all $(echo "${LOCK_REFS}" | wc -l | tr -d ' ') clone sources primed and verified"
