#!/usr/bin/env bash
# Bounded, *classified* retry around a cannon invocation.
#
# Why a wrapper at all: cannon EXITS 0 even when steps failed. It logs
#   ⚠️  Skipping [<step>] (Error: ...)
# and carries on, so exit status alone is not a success signal -- a run can
# silently deploy less than it should and only blow up later in the fork
# tests with confusing errors.
#
# Why *classified*: not every skip is worth retrying, and the difference is
# expensive.
#
#   * A flaked package fetch (repo.usecannon.com IPFS read) is genuine flake.
#     Cannon resumes from cached state, so a retry is cheap and usually works.
#   * A step that reverted on-chain, or a cannonfile that is simply wrong,
#     fails identically every time. Retrying it burns the whole attempt
#     budget on the same error and buries the real cause under the hundreds
#     of "dependency operation not completed" cascade lines it produced.
#
# So: classify the run, retry only what is actually transient, and abort
# immediately with a root-cause summary on anything deterministic.
#
# Scoped to the DEVNET test script only: a healthy devnet build has zero
# skips. The cronos/mainnet builds currently have ~24 persistent root
# failures (source packages whose IPFS pins are missing from
# repo.usecannon.com, e.g. reya-core:1.0.34@router) that cascade into ~1800
# dependency skips on EVERY branch -- wrapping those scripts would turn a
# pre-existing condition into a hard red. Wrap them once the pins are
# restored.
#
# Portability: POSIX-ish bash, no external dependencies beyond grep/sort/cut.
# Must run on macOS bash 3.2 (no associative arrays, no mapfile, no ${x,,})
# and with BSD grep (POSIX flags only -- no -P, no \b in patterns). Patterns
# are deliberately unanchored so they still match when chalk emits ANSI
# colour codes around the line.
#
# Usage:  cannon-retry.sh <command...>
# Env:    CANNON_RETRY_ATTEMPTS       (default 3)
#         CANNON_RETRY_REPORT_LINES   (default 20)
#
# Exit status: 0 only on a clean run. Non-zero on a deterministic failure and
# on exhausted retries.

set -uo pipefail

ATTEMPTS="${CANNON_RETRY_ATTEMPTS:-3}"
REPORT_LINES="${CANNON_RETRY_REPORT_LINES:-20}"

# The literal cannon emits for every failed step (builder logs it via
# console.log, so it lands on stdout).
SKIP_MARKER='Skipping ['

# Cascade noise: emitted once per step that was skipped only because
# something it depends on was skipped. One real failure produces dozens or
# hundreds of these. They are never a root cause and never a retry trigger.
CASCADE_RE='dependency operation not completed'

# Deterministic: identical on every attempt. Retrying is pure waste.
DETERMINISTIC_RE='transaction reverted in contract'
DETERMINISTIC_RE="$DETERMINISTIC_RE"'|Event specified in cannonfile'
DETERMINISTIC_RE="$DETERMINISTIC_RE"'|(parseUnits|formatUnits): unknown ethereum unit name'
DETERMINISTIC_RE="$DETERMINISTIC_RE"'|Invalid CID generated locally'
DETERMINISTIC_RE="$DETERMINISTIC_RE"'|could not decode cannon package data'
# Read-only/gateway IPFS URL is a *misconfiguration*, not a network blip --
# note it deliberately does NOT overlap the retryable "Failed to upload to
# IPFS" string below.
DETERMINISTIC_RE="$DETERMINISTIC_RE"'|unable to upload to ipfs: the IPFS url you have configured'
# forge assertion failures. Without these a test failure that happened to
# coincide with any network noise in the log would be retried, which is both
# wasteful and a regression against the previous behaviour.
DETERMINISTIC_RE="$DETERMINISTIC_RE"'|\[FAIL'
DETERMINISTIC_RE="$DETERMINISTIC_RE"'|Failing tests:'
DETERMINISTIC_RE="$DETERMINISTIC_RE"'|Encountered a total of [0-9]+ failing test'

# Transient: worth retrying.
TRANSIENT_RE='could not download cannon package data from'
# Artifact upload at the very end of a successful build. This aborts before
# forge tests run, with zero skips, so nothing above catches it.
TRANSIENT_RE="$TRANSIENT_RE"'|Failed to upload to IPFS'
TRANSIENT_RE="$TRANSIENT_RE"'|socket hang up|Client network socket disconnected'
TRANSIENT_RE="$TRANSIENT_RE"'|ECONNRESET|ECONNREFUSED|ETIMEDOUT|EAI_AGAIN|ENOTFOUND|EPROTO|EPIPE'
TRANSIENT_RE="$TRANSIENT_RE"'|getaddrinfo|timeout of [0-9]+ms exceeded'
# Registry / gateway throttling. Matched via axios' exact wording rather than
# a bare "429" so a gas figure or an address can never trip it.
TRANSIENT_RE="$TRANSIENT_RE"'|Too Many Requests|Request failed with status code (429|50[0-9])'
TRANSIENT_RE="$TRANSIENT_RE"'|Bad Gateway|Service Unavailable|Gateway Time-?out'

# count_matching <grep-mode> <pattern> <file>
# Echoes a bare integer. grep -c is used rather than wc -l because BSD wc
# pads its output with leading spaces.
count_matching() {
  local mode="$1" pat="$2" file="$3" n
  n=$(grep -c "$mode" -- "$pat" "$file" 2>/dev/null)
  [ -n "$n" ] || n=0
  echo "$n"
}

# root_skips <file> -- the skip lines that are NOT cascade noise.
root_skips() {
  grep -F -- "$SKIP_MARKER" "$1" 2>/dev/null | grep -v -E -- "$CASCADE_RE" 2>/dev/null
}

# classify_log <file> <exit-status>
# Echoes exactly one of: clean | transient | deterministic | unknown
#
# Rule order is load-bearing:
#   1. exited 0 with zero skips              -> clean (short-circuit, so a
#      genuinely green run can never be failed by a stray pattern match)
#   2. any deterministic marker              -> deterministic. Beats transient
#      on purpose: a retry cannot fix a revert, so if both are present the
#      useful answer is the revert.
#   3. any transient marker                  -> transient
#   4. skips present, all of them cascades   -> deterministic. A cascade
#      proves a root failure happened; if no transient marker explains it,
#      retrying is the exact waste this wrapper exists to stop.
#   5. anything else                         -> unknown
classify_log() {
  local file="$1" status="$2" skips roots

  skips=$(count_matching -F "$SKIP_MARKER" "$file")

  if [ "$status" -eq 0 ] && [ "$skips" -eq 0 ]; then
    echo clean
    return 0
  fi

  if grep -E -q -- "$DETERMINISTIC_RE" "$file" 2>/dev/null; then
    echo deterministic
    return 0
  fi

  if grep -E -q -- "$TRANSIENT_RE" "$file" 2>/dev/null; then
    echo transient
    return 0
  fi

  if [ "$skips" -gt 0 ]; then
    roots=$(root_skips "$file" | grep -c '' 2>/dev/null)
    [ -n "$roots" ] || roots=0
    if [ "$roots" -eq 0 ]; then
      echo deterministic
      return 0
    fi
  fi

  echo unknown
}

# report_root_cause <file>
# Prints the non-cascade skips de-duplicated, the cascade count as a single
# number, and any error signatures matched anywhere in the log (which is how
# multi-line errors and top-level throws still get surfaced).
report_root_cause() {
  local file="$1" cascades roots shown

  cascades=$(grep -F -- "$SKIP_MARKER" "$file" 2>/dev/null | grep -c -E -- "$CASCADE_RE" 2>/dev/null)
  [ -n "$cascades" ] || cascades=0
  roots=$(root_skips "$file" | sort -u)

  if [ -n "$roots" ]; then
    shown=$(printf '%s\n' "$roots" | grep -c '')
    echo "==> root-cause steps (${shown} distinct, cascade skips suppressed: ${cascades}):"
    printf '%s\n' "$roots" | cut -c1-240 | head -n "$REPORT_LINES" | sed 's/^/      /'
    if [ "$shown" -gt "$REPORT_LINES" ]; then
      echo "      ... and $((shown - REPORT_LINES)) more distinct failing step(s)"
    fi
  else
    echo "==> no non-cascade skips found (cascade skips: ${cascades})"
  fi

  local sigs
  # NB the alternation must be grouped before ".*" -- in an ERE, "a|b.*"
  # binds the ".*" to the last branch only, which truncates the signature.
  sigs=$(grep -E -o -- "($DETERMINISTIC_RE).*" "$file" 2>/dev/null | cut -c1-240 | sort -u)
  if [ -n "$sigs" ]; then
    echo "==> error signatures:"
    printf '%s\n' "$sigs" | head -n "$REPORT_LINES" | sed 's/^/      /'
  fi

  local flakes
  flakes=$(grep -E -o -- "($TRANSIENT_RE).*" "$file" 2>/dev/null | cut -c1-240 | sort -u)
  if [ -n "$flakes" ]; then
    echo "==> NOTE: transient markers were also present; the deterministic"
    echo "    failure above is reported because a retry cannot fix it:"
    printf '%s\n' "$flakes" | head -n 5 | sed 's/^/      /'
  fi
}

main() {
  if [ "$#" -eq 0 ]; then
    echo "usage: cannon-retry.sh <command...>" >&2
    exit 2
  fi

  local log status class attempt
  log="$(mktemp)"
  trap 'rm -f "$log"' EXIT

  attempt=1
  while [ "$attempt" -le "$ATTEMPTS" ]; do
    echo "==> cannon attempt ${attempt}/${ATTEMPTS}"

    "$@" 2>&1 | tee "$log"
    status="${PIPESTATUS[0]}"

    class="$(classify_log "$log" "$status")"

    case "$class" in
      clean)
        exit "$status"
        ;;
      deterministic)
        echo "==> cannon FAILED deterministically (exit ${status}) -- NOT retrying."
        echo "==> a retry would reproduce this identically; fix the cause below."
        report_root_cause "$log"
        exit 1
        ;;
      transient)
        echo "==> transient failure (network/registry flake) -- retrying."
        ;;
      unknown)
        echo "==> WARNING: could not classify this run (exit ${status})."
        echo "==> treating it as retryable, but this was NOT a clean build --"
        echo "==> if it recurs, add its signature to cannon-retry.sh."
        report_root_cause "$log"
        ;;
    esac

    attempt=$((attempt + 1))
  done

  echo "==> cannon still failing after ${ATTEMPTS} attempts (last class: ${class}, exit ${status})"
  report_root_cause "$log"
  exit 1
}

# Only run when executed, so the test suite can source this file and drive
# classify_log directly.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "$@"
fi
