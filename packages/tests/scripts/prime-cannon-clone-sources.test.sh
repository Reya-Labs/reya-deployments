#!/usr/bin/env bash
# Tests for prime-cannon-clone-sources.sh.
#
# One thing is pinned here, because one thing broke: the prime loop must
# attempt EVERY pinned ref, even when the fetch child reads stdin.
#
# The regression: the loop read its work list from stdin, so a child that
# consumed stdin swallowed the remaining refs and the loop ended after one
# iteration. In CI it primed 1 of 12 on every run, on every branch, for days --
# and reported "all 12 clone sources primed and verified" whenever that first
# ref happened to succeed, because the summary printed the lockfile's ref count
# instead of the number actually primed.
#
# Both halves are covered: the loop completes all twelve iterations against a
# stdin-draining fake cannon, and the summary reports real counts.
#
# No network and no real cannon: CANNON_PRIME_CANNON_BIN points at a fake that
# writes the tag files, and CANNON_PRIME_SKIP_MISC_CHECK skips the misc probe.
# Dependency-free and bash-3.2 safe. Run:  ./scripts/prime-cannon-clone-sources.test.sh
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/../../tomls/scripts/prime-cannon-clone-sources.sh"
LOCKFILE="$HERE/../../tomls/src/omnibus/reya_devnet.lock.json"

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); printf '  ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  FAIL %s\n     %s\n' "$1" "$2"; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/prime-test.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

EXPECTED_REFS="$(node -p "Object.keys(require('$LOCKFILE').packages).length")"

# A fake cannon that behaves like the real one in the way that matters here and
# in the way that broke the loop: it DRAINS STDIN. If the loop ever feeds its
# work list on stdin again, this fake eats it and the test fails loudly.
cat > "$WORK/fake-cannon.js" <<'EOF'
const fs = require('fs');
const path = require('path');
// Drain stdin, exactly as the bug required. Shelling out to `cat` rather than
// fs.readFileSync(0): fd 0 is non-blocking here, so readFileSync throws EAGAIN
// and drains nothing, which would make this fake silently stop testing the
// regression. `cat` on an inherited fd blocks and consumes to EOF.
try {
  require('child_process').execSync('cat >/dev/null', { stdio: ['inherit', 'ignore', 'ignore'] });
} catch (e) { /* no stdin to drain */ }
const argv = process.argv.slice(2);
if (argv[0] !== 'fetch') process.exit(64);
const url = argv[1];
const ref = argv[2];
const chainId = argv[argv.indexOf('--chain-id') + 1];
const [name, rest] = ref.split(':');
const [version, preset] = rest.split('@');
const dir = path.join(process.env.CANNON_DIRECTORY, 'tags');
fs.mkdirSync(dir, { recursive: true });
fs.writeFileSync(path.join(dir, `${name}_${version}_${chainId}-${preset}.txt`), url);
EOF

echo "== prime loop =="

OUT="$WORK/run.log"
CANNON_DIRECTORY="$WORK/cannon" \
CANNON_PRIME_CANNON_BIN="$WORK/fake-cannon.js" \
CANNON_PRIME_SKIP_MISC_CHECK=1 \
  bash "$SCRIPT" >"$OUT" 2>&1
STATUS=$?

# (i) every ref attempted -- the actual regression.
GOT_OK="$(grep -c '^    ok      ' "$OUT" | tr -d ' ')"
if [ "$GOT_OK" = "$EXPECTED_REFS" ]; then
  ok "primes all $EXPECTED_REFS refs against a stdin-draining fetch"
else
  bad "primes all $EXPECTED_REFS refs against a stdin-draining fetch" \
      "only $GOT_OK ref(s) reached; the loop terminated early"
fi

# (ii) exit status.
if [ "$STATUS" -eq 0 ]; then
  ok "exits 0 when every ref primes"
else
  bad "exits 0 when every ref primes" "exit $STATUS; output: $(tail -3 "$OUT" | tr '\n' ' ')"
fi

# (iii) the summary must count what was primed, not what was pinned. The old
# summary was a constant and so could not fail; this asserts it is derived.
if grep -q "all ${EXPECTED_REFS} of ${EXPECTED_REFS} clone sources primed" "$OUT"; then
  ok "summary reports primed count, not the lockfile count"
else
  bad "summary reports primed count, not the lockfile count" \
      "got: $(grep '^==>' "$OUT" | tail -1)"
fi

# (iv) the early-exit guard must fire when the loop is truncated. Simulate by
# making the fake cannon exit after the first ref, so later tags never appear.
OUT2="$WORK/run2.log"
cat > "$WORK/fake-cannon-onces.js" <<'EOF'
const fs = require('fs');
const path = require('path');
const marker = path.join(process.env.CANNON_DIRECTORY, '.seen');
if (fs.existsSync(marker)) process.exit(1);
fs.mkdirSync(process.env.CANNON_DIRECTORY, { recursive: true });
fs.writeFileSync(marker, '1');
const argv = process.argv.slice(2);
const ref = argv[2];
const chainId = argv[argv.indexOf('--chain-id') + 1];
const [name, rest] = ref.split(':');
const [version, preset] = rest.split('@');
const dir = path.join(process.env.CANNON_DIRECTORY, 'tags');
fs.mkdirSync(dir, { recursive: true });
fs.writeFileSync(path.join(dir, `${name}_${version}_${chainId}-${preset}.txt`), argv[1]);
EOF

CANNON_DIRECTORY="$WORK/cannon2" \
CANNON_PRIME_CANNON_BIN="$WORK/fake-cannon-onces.js" \
CANNON_PRIME_SKIP_MISC_CHECK=1 \
CANNON_PRIME_FETCH_ATTEMPTS=1 \
  bash "$SCRIPT" >"$OUT2" 2>&1
STATUS2=$?

if [ "$STATUS2" -ne 0 ]; then
  ok "fails loudly when refs do not prime"
else
  bad "fails loudly when refs do not prime" "exited 0"
fi

# (v) the diagnostics must actually surface the fetch's exit code, which is the
# thing >/dev/null was hiding.
if grep -q 'cannon exit ' "$OUT2"; then
  ok "reports the cannon exit code on a failed attempt"
else
  bad "reports the cannon exit code on a failed attempt" "no 'cannon exit' line in output"
fi

if grep -q -- '---- diagnostics for ' "$OUT2"; then
  ok "dumps state after the final failed attempt"
else
  bad "dumps state after the final failed attempt" "no diagnostics block in output"
fi

echo
echo "== $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
