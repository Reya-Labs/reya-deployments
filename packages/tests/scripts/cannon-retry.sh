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

  # A fetch flake surfaces as a skipped clone step, NOT as a non-zero exit.
  if grep -qE 'Skipping \[clone\.' "$LOG"; then
    echo "==> package fetch flaked (clone step skipped); retrying"
    continue
  fi

  exit "$status"
done

echo "==> cannon still failing after ${ATTEMPTS} attempts"
exit 1
