#!/usr/bin/env bash
# Bounded retry around a cannon invocation.
#
# repo.usecannon.com package fetches flake often enough to matter: a failed
# `clone.*` step cascades into dozens of skipped steps, and cannon reports
# SUCCESS anyway — so the run silently deploys less than it should and the
# fork tests fail downstream with confusing errors. Retrying the whole
# invocation is the safe granularity: cannon resumes from cached state, so a
# retry is cheap when most steps already succeeded.
#
# Usage: cannon-retry.sh <command...>
set -uo pipefail

ATTEMPTS="${CANNON_RETRY_ATTEMPTS:-3}"
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

for attempt in $(seq 1 "$ATTEMPTS"); do
  echo "==> cannon attempt ${attempt}/${ATTEMPTS}"
  "$@" 2>&1 | tee "$LOG"
  status="${PIPESTATUS[0]}"

  # Retry on ANY skipped step, not just `clone.*`. A healthy devnet build
  # has zero skips, and cannon RESUMES from cached state: on a retry after a
  # flaked fetch it often re-reports only the downstream
  # `Skipping [invoke.*]` cascade without re-attempting the clone, so a
  # clone-only trigger silently accepts a broken build. (Learned the hard
  # way — this wrapper exited "successfully" on a 29-skip run.)
  if grep -q 'Skipping \[' "$LOG"; then
    echo "==> build skipped steps (likely a flaked package fetch); retrying"
    continue
  fi

  exit "$status"
done

echo "==> cannon still failing after ${ATTEMPTS} attempts"
exit 1
