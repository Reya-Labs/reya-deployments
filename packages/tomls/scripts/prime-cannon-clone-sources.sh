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
# Overridable only so the regression test can substitute a fake cannon that
# needs no network. Nothing in normal use should set it.
CANNON="${CANNON_PRIME_CANNON_BIN:-../../node_modules/@usecannon/cli-devnet/bin/cannon.js}"
# Retry budget for each `cannon fetch`. Overridable so CI can be more patient
# than a local run without editing the script.
FETCH_ATTEMPTS="${CANNON_PRIME_FETCH_ATTEMPTS:-4}"
FETCH_BACKOFF="${CANNON_PRIME_FETCH_BACKOFF:-3}"

# Every `cannon fetch` writes its stdout+stderr here instead of /dev/null.
# Keeping that output is the whole point -- see dump_fetch_failure.
FETCH_LOG="$(mktemp "${TMPDIR:-/tmp}/cannon-prime-fetch.XXXXXX")"
trap 'rm -f "${FETCH_LOG}"' EXIT

# NOT `node -p`. chainId is a NUMBER, and `node -p` renders its result through
# util.inspect, which COLOURS numbers when stdout is a TTY -- so this read
# returns the literal bytes ESC[33m13370ESC[39m rather than 13370. CI runs this
# script through `lerna run` (nx), which allocates a PTY for task output; a
# developer running the script directly gets a pipe and clean digits. That one
# difference is the entire local-passes-CI-fails story:
#
#   * `--chain-id $CHAIN_ID` reaches cannon as a non-numeric string, so
#     Number() gives NaN, cannon falls through to its interactive
#     _promptChainId(), finds no answer on stdin, and EXITS 0 HAVING WRITTEN
#     NOTHING -- which is exactly the "wrote no usable tag" with exit 0 the
#     diagnostics caught;
#   * and $TAG embeds the escape codes too, so the read-back could never match
#     even if the fetch had succeeded.
#
# `node -e` + process.stdout.write bypasses util.inspect entirely and is
# TTY-independent. String-valued reads below are unaffected (node prints
# top-level strings raw, uncoloured), which is why the ref list always parsed
# fine while this one value was quietly poisoned.
CHAIN_ID="$(node -e "process.stdout.write(String(require('./${LOCKFILE}').chainId))")"
CANNON_DIR="${CANNON_DIRECTORY:-$HOME/.local/share/cannon}"
VERIFY_ONLY="${1:-}"

# Fail loudly rather than passing junk to cannon and reading a junk tag path.
# Without this the failure surfaces four layers away as an interactive prompt.
case "${CHAIN_ID}" in
  '' | *[!0-9]*)
    echo "!!! chain id read from ${LOCKFILE} is not numeric:"
    printf '%s\n' "${CHAIN_ID}" | cat -v | sed 's/^/      /'
    echo "!!! something is decorating this value (a TTY-coloured node -p is the"
    echo "!!! usual culprit). Refusing to run: cannon would prompt for a chain id"
    echo "!!! and silently write no tags."
    exit 1
    ;;
esac

# ---------------------------------------------------------------------------
# Failure diagnostics.
#
# The previous version ran the fetch as `>/dev/null 2>&1` and reported only
# "wrote no usable tag". That is the same silent-failure class this whole
# workstream keeps hitting: a retry loop that hides why it is retrying cannot
# be debugged, and it cost two CI runs and a wrong root-cause theory
# ("transient repo.usecannon.com flake") before anyone could see the error.
#
# Everything dumped here answers a question the bare message could not: did
# cannon even start, did it reach the network, does the directory it writes
# into exist, and is the settings.json the CI step claims to write actually
# there.
# ---------------------------------------------------------------------------
dump_fetch_failure() {
  local ref="$1" tag="$2" status="$3"
  echo
  echo "    ---- diagnostics for ${ref} ----"
  echo "    cannon exit code  : ${status}"
  echo "    expected tag file : ${tag}"
  echo "    tag file exists   : $([ -f "${tag}" ] && echo yes || echo no)"
  echo "    CANNON_DIRECTORY  : ${CANNON_DIRECTORY:-<unset; defaulted>}"
  echo "    cannon dir        : ${CANNON_DIR} ($([ -d "${CANNON_DIR}" ] && echo exists || echo MISSING))"
  echo "    tags dir          : $([ -d "${CANNON_DIR}/tags" ] && echo exists || echo MISSING)"
  echo "    settings.json     : $([ -f "${CANNON_DIR}/settings.json" ] && echo exists || echo MISSING)"
  echo "    tags dir contents :"
  ls -la "${CANNON_DIR}/tags" 2>&1 | sed 's/^/      /' | head -40
  echo "    cannon output (stdout+stderr):"
  if [ -s "${FETCH_LOG}" ]; then
    sed 's/^/      /' "${FETCH_LOG}" | tail -40
  else
    echo "      <cannon produced no output at all>"
  fi
  echo "    ---- end diagnostics ----"
  echo
}

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
PRIMED=0
PROCESSED=0
MISSING_MISC=""

# NOTE the `<&3` on the read and the `3< <(...)` on the done: the work list is
# fed on file descriptor 3, NOT stdin.
#
# This is not style. On main the loop read from stdin, and in CI it executed
# exactly ONE iteration -- refs 2..12 were never attempted, in every run on
# every branch. A child process in the loop body inherits the loop's stdin, and
# any child that reads it swallows the rest of the package list, so the next
# `read` sees EOF and the loop ends. The logs show it plainly: the FAILED line
# for ref 1 and the closing summary are 0.37s apart, which is not enough time
# for eleven more fetches.
#
# That truncation was also invisible, because the old summary printed the
# LOCKFILE's ref count rather than the number actually primed -- so a run where
# ref 1 happened to succeed would report "all 12 clone sources primed and
# verified" with 11 unprimed, which is precisely the wrong-addresses-silently
# outcome this script exists to prevent. The PROCESSED counter below closes
# that hole.
while IFS=$'\t' read -r REF DEPLOY_CID MISC_CID <&3; do
  PROCESSED=$((PROCESSED + 1))
  # tags/<name>_<version>_<chainId>-<preset>.txt  (LocalRegistry.getTagReferenceStorage)
  NAME="${REF%%:*}"; REST="${REF#*:}"; VERSION="${REST%%@*}"; PRESET="${REST#*@}"
  TAG="${CANNON_DIR}/tags/${NAME}_${VERSION}_${CHAIN_ID}-${PRESET}.txt"

  # Retry the fetch. repo.usecannon.com does flake, and a flaked prime is worse
  # than a loud failure: the build then runs against an unprimed cache, resolves
  # different artifacts, decides the whole deployment is stale and replays it,
  # so the genesis steps revert (PoolAlreadyTokenized) and the run reads as a
  # config breakage.
  #
  # CORRECTION (this commit): an earlier version of this comment blamed CI run
  # 33027437158 on "one transient miss on reya-core:1.0.0@proxy". That was
  # wrong, and the >/dev/null on the fetch is why nobody could tell. The run
  # did not lose a race -- the loop ran exactly one iteration and the remaining
  # eleven refs were never attempted at all. Do not re-derive a flake theory
  # from "wrote no usable tag" alone; read the captured cannon output below.
  #
  # Verify by reading the tag back rather than trusting the exit code: cannon
  # fetch has been observed to exit 0 while writing nothing.
  if [ "${VERIFY_ONLY}" != "--verify-only" ]; then
    ATTEMPT=1
    while [ "${ATTEMPT}" -le "${FETCH_ATTEMPTS}" ]; do
      # </dev/null belt-and-braces on top of the FD-3 loop above: this child
      # must never be able to touch the work list, whatever cannon does with
      # stdin. Output is captured rather than discarded.
      node "${CANNON}" fetch "ipfs://${DEPLOY_CID}" "${REF}" \
        --chain-id "${CHAIN_ID}" >"${FETCH_LOG}" 2>&1 </dev/null
      FETCH_STATUS=$?

      if [ "$(cat "${TAG}" 2>/dev/null)" = "ipfs://${DEPLOY_CID}" ]; then
        [ "${ATTEMPT}" -gt 1 ] && echo "    (recovered on attempt ${ATTEMPT})  ${REF}"
        break
      fi

      # One line for EVERY failed attempt, not just the last. The question this
      # instrumentation exists to answer is transient-vs-deterministic, and that
      # is only visible by comparing attempts: four identical exit codes half a
      # second apart is a deterministic fault wearing a retry loop's clothes,
      # and a final-attempt-only dump cannot tell you that. The full dump still
      # fires once, after the last attempt, so the cost stays bounded.
      echo "    attempt ${ATTEMPT}/${FETCH_ATTEMPTS} ${REF}: cannon exit ${FETCH_STATUS}, no usable tag"
      LAST_ERR="$(grep -v '^[[:space:]]*$' "${FETCH_LOG}" 2>/dev/null | tail -1)"
      [ -n "${LAST_ERR}" ] && echo "              last output: ${LAST_ERR}"

      if [ "${ATTEMPT}" -lt "${FETCH_ATTEMPTS}" ]; then
        sleep $((ATTEMPT * FETCH_BACKOFF))
      else
        dump_fetch_failure "${REF}" "${TAG}" "${FETCH_STATUS}"
      fi
      ATTEMPT=$((ATTEMPT + 1))
    done
  fi

  ACTUAL="$(cat "${TAG}" 2>/dev/null)"
  if [ "${ACTUAL}" = "ipfs://${DEPLOY_CID}" ]; then
    echo "    ok      ${REF} -> ${DEPLOY_CID}"
    PRIMED=$((PRIMED + 1))
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
  if [ -n "${MISC_CID}" ] && [ -z "${CANNON_PRIME_SKIP_MISC_CHECK:-}" ]; then
    CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 60 </dev/null \
      -X POST "https://repo.usecannon.com/api/v0/cat?arg=${MISC_CID}")"
    if [ "${CODE}" != "200" ]; then
      MISSING_MISC="${MISSING_MISC}      ${REF}  misc=${MISC_CID}  (HTTP ${CODE})"$'\n'
    fi
  fi
done 3< <(node -p "
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

EXPECTED="$(echo "${LOCK_REFS}" | wc -l | tr -d ' ')"

# The loop must have SEEN every pinned ref. Anything less means it terminated
# early, and the refs it never reached are unprimed -- which a per-ref failure
# count cannot detect, because a ref that was never attempted never failed.
#
# Reported BEFORE, and independently of, the per-ref failures. In the CI
# breakage both were true at once -- the loop truncated AND the single ref it
# reached failed -- and exiting on the failure alone is precisely what kept the
# truncation invisible while three people read the log as "one flaky ref".
TRUNCATED=0
if [ "${PROCESSED}" -ne "${EXPECTED}" ]; then
  TRUNCATED=1
  echo
  echo "==> prime loop processed ${PROCESSED} of ${EXPECTED} clone sources"
  echo "!!! the loop terminated early. The refs it never reached are NOT primed,"
  echo "!!! so a build on this cache silently resolves them from the registry and"
  echo "!!! clones them at different addresses. This is a bug in this script, not"
  echo "!!! a bad pin -- check that nothing in the loop body consumes the work list."
fi

if [ "${FAILED}" -ne 0 ]; then
  echo
  echo "==> ${FAILED} of ${PROCESSED} attempted clone source(s) failed to prime"
fi

if [ "${FAILED}" -ne 0 ] || [ "${TRUNCATED}" -ne 0 ]; then
  exit 1
fi

echo "==> all ${PRIMED} of ${EXPECTED} clone sources primed and verified"
