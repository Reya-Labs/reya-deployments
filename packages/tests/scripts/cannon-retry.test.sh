#!/usr/bin/env bash
# Tests for cannon-retry.sh.
#
# Two layers:
#   1. classify_log() against recorded cannon output (testdata/*.log), which
#      pins the classification rules.
#   2. the retry loop end-to-end against a fake cannon, which pins the thing
#      that actually costs time: how many attempts each class burns.
#
# Dependency-free and bash-3.2 safe. Run:  ./scripts/cannon-retry.test.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/cannon-retry.sh"
DATA="$HERE/testdata"

# shellcheck source=./cannon-retry.sh
. "$SCRIPT"

PASS=0
FAIL=0

ok()   { PASS=$((PASS + 1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL + 1)); printf '  FAIL %s\n     %s\n' "$1" "$2"; }

# expect_class <fixture> <exit-status> <expected-class>
expect_class() {
  local fixture="$1" status="$2" want="$3" got
  got="$(classify_log "$DATA/$fixture" "$status")"
  if [ "$got" = "$want" ]; then
    ok "$fixture (exit $status) -> $want"
  else
    bad "$fixture (exit $status)" "expected '$want', got '$got'"
  fi
}

echo "== classifier =="

# (i) clean -- cannon exited 0 and skipped nothing.
expect_class clean.log                    0 clean

# (ii) transient -- worth retrying.
expect_class fetch-flake.log              0 transient   # cannon exits 0 despite skips
expect_class rate-limit.log               0 transient   # registry 429 / Too Many Requests
expect_class upload-failure.log           1 transient   # zero skips, dies at artifact upload

# (iii) deterministic -- retrying is pure waste.
expect_class revert.log                   0 deterministic
expect_class revert-account-not-found.log 0 deterministic
expect_class cannonfile-event.log         0 deterministic
expect_class parse-units.log              0 deterministic
expect_class forge-fail.log               1 deterministic
expect_class gateway-misconfig.log        1 deterministic  # "upload to ipfs" but a misconfig
expect_class cascade-only.log             0 deterministic  # cascades alone never retry

# Precedence: a revert wins over incidental network noise in the same log,
# because a retry cannot fix the revert.
expect_class revert-with-network-noise.log 0 deterministic

# (iv) unknown -- retried, but loudly.
expect_class unknown.log                  0 unknown

echo
echo "== cascade suppression =="

# The revert fixture has 1 real failure and 5 cascade lines. The report must
# name the 1 and count the 5, not dump them.
REPORT="$(report_root_cause "$DATA/revert.log")"
if printf '%s' "$REPORT" | grep -q 'cascade skips suppressed: 5'; then
  ok "cascades reported as a count (5)"
else
  bad "cascade count" "not found in report:\n$REPORT"
fi
if [ "$(printf '%s' "$REPORT" | grep -c 'dependency operation not completed')" -eq 0 ]; then
  ok "no cascade lines dumped into the report"
else
  bad "cascade lines leaked" "$REPORT"
fi
if printf '%s' "$REPORT" | grep -q 'invoke.enable_market_eth'; then
  ok "real failing step named in the report"
else
  bad "root cause missing" "$REPORT"
fi

# Regression: the deterministic alternation must be GROUPED before ".*" in
# the signature grep. Ungrouped, an ERE binds ".*" to the last branch only
# and the signature prints as a bare "transaction reverted in contract" with
# the contract and custom error -- the actually useful part -- chopped off.
if printf '%s' "$REPORT" | grep -q 'FeatureUnavailable'; then
  ok "error signature keeps the decoded revert reason"
else
  bad "signature truncated" "$REPORT"
fi

# When a deterministic failure and network noise coexist, the report must say
# so rather than silently hiding that a flake was also seen.
NOISE_REPORT="$(report_root_cause "$DATA/revert-with-network-noise.log")"
if printf '%s' "$NOISE_REPORT" | grep -q 'transient markers were also present'; then
  ok "co-occurring transient markers are disclosed"
else
  bad "transient disclosure missing" "$NOISE_REPORT"
fi

echo
echo "== ansi colour tolerance =="

# cannon colours these lines with chalk (yellowBright). Colour is normally
# off when stdout is not a TTY, but CI runners and FORCE_COLOR can turn it
# back on -- so the patterns must stay unanchored and match a coloured line
# just the same. Build coloured copies and re-classify.
ANSI_TMP="$(mktemp -d)"
colourise() {
  # wrap every non-empty line in yellowBright ... reset
  sed -e 's/^\(.*[^ ].*\)$/\'"$(printf '\033')"'[93m\1'"$(printf '\033')"'[39m/' "$1"
}
for fx in revert.log fetch-flake.log clean.log forge-fail.log; do
  colourise "$DATA/$fx" > "$ANSI_TMP/$fx"
done

plain_class() { classify_log "$DATA/$1" "$2"; }
ansi_class()  { classify_log "$ANSI_TMP/$1" "$2"; }

for pair in "revert.log 0" "fetch-flake.log 0" "clean.log 0" "forge-fail.log 1"; do
  set -- $pair
  want="$(plain_class "$1" "$2")"
  got="$(ansi_class "$1" "$2")"
  if [ "$got" = "$want" ]; then
    ok "ANSI-coloured $1 still classifies as $want"
  else
    bad "ANSI $1" "plain gave '$want', coloured gave '$got'"
  fi
done
rm -rf "$ANSI_TMP"

echo
echo "== retry loop (end to end) =="

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Fake cannon: FAKE_PLAN is a space-separated list of <fixture>:<exit-status>,
# one entry per attempt; the last entry repeats if attempts outrun the plan.
cat > "$TMP/fake-cannon" <<'FAKE'
#!/usr/bin/env bash
n=0
[ -f "$FAKE_COUNT" ] && n="$(cat "$FAKE_COUNT")"
n=$((n + 1))
echo "$n" > "$FAKE_COUNT"
i=0
for entry in $FAKE_PLAN; do
  i=$((i + 1))
  [ "$i" -ge "$n" ] && break
done
cat "$FAKE_DATA/${entry%%:*}"
exit "${entry##*:}"
FAKE
chmod +x "$TMP/fake-cannon"

# run_case <name> <plan> <want-attempts> <want-exit>
run_case() {
  local name="$1" plan="$2" want_attempts="$3" want_exit="$4"
  local out code attempts
  export FAKE_PLAN="$plan"
  export FAKE_DATA="$DATA"
  export FAKE_COUNT="$TMP/count"
  rm -f "$FAKE_COUNT"

  out="$(CANNON_RETRY_ATTEMPTS=3 "$SCRIPT" "$TMP/fake-cannon" 2>&1)"
  code=$?
  attempts="$(printf '%s' "$out" | grep -c 'cannon attempt')"

  if [ "$attempts" = "$want_attempts" ] && [ "$code" = "$want_exit" ]; then
    ok "$name (attempts=$attempts exit=$code)"
  else
    bad "$name" "expected attempts=$want_attempts exit=$want_exit, got attempts=$attempts exit=$code"
  fi
}

# The headline fix: a deterministic failure must cost ONE attempt, not three.
run_case "revert stops after 1 attempt"      "revert.log:0"                      1 1
run_case "forge failure stops after 1"       "forge-fail.log:1"                  1 1
run_case "cascade-only stops after 1"        "cascade-only.log:0"                1 1
# Transient failures still get the full budget, and still fail CI when the
# budget runs out.
run_case "persistent flake exhausts budget"  "fetch-flake.log:0"                 3 1
# ... and a flake that clears is a pass, on the attempt that cleared it.
run_case "flake then clean recovers"         "fetch-flake.log:0 clean.log:0"     2 0
run_case "upload flake then clean recovers"  "upload-failure.log:1 clean.log:0"  2 0
# A clean run must not retry and must exit 0.
run_case "clean run exits immediately"       "clean.log:0"                       1 0
# Unknown is retried, not silently accepted.
run_case "unknown is retried, then fails"    "unknown.log:0"                     3 1

echo
echo "== $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
