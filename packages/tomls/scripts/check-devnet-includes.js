#!/usr/bin/env node
/**
 * Guards the devnet OracleAdapters include set against silent drift.
 *
 * devnet cannot simply include `oracle_adapters/mainnet.toml`: it needs its own
 * proxy (a devnet CREATE2 salt, so it does not collide with Cronos) and its own
 * executor allowlist (the shared ones carry Cronos wallets, and devnet's
 * `subSecondExecutors` gate has no allow-all to fall back on). Everything else
 * is meant to stay identical.
 *
 * That hand-maintained divergence is the hazard: add a config to
 * oracle_adapters/mainnet.toml and devnet silently misses it, with no build
 * failure — the deployment just quietly lacks whatever the new file configured.
 * So the divergence is declared below and anything else is an error.
 */
const fs = require('fs');
const path = require('path');

const SRC = path.resolve(__dirname, '..', 'src');
const MAINNET = 'oracle_adapters/mainnet.toml';
const DEVNET = 'devnet/oracle_adapters/oracle_adapters.toml';

/** mainnet include -> what devnet uses instead (null = intentionally dropped). */
const SUBSTITUTIONS = {
  'oracle_adapters/utils/deploy_proxy.toml': 'devnet/oracle_adapters/deploy_proxy.toml',
  'oracle_adapters/configs/set_executors.toml': 'devnet/oracle_adapters/set_executors.toml',
  'oracle_adapters/configs/set_standalone_executors.toml': 'devnet/oracle_adapters/set_executors.toml',
  'oracle_adapters/configs/set_sub_second_executors.toml': 'devnet/oracle_adapters/set_executors.toml',
};

function includesOf(relPath) {
  const abs = path.join(SRC, relPath);
  const text = fs.readFileSync(abs, 'utf8');
  const block = text.match(/^\s*include\s*=\s*\[([\s\S]*?)^\s*\]/m);
  if (!block) throw new Error(`no include array found in ${relPath}`);
  const dir = path.dirname(abs);
  return new Set(
    [...block[1].matchAll(/"([^"]+)"/g)].map((m) =>
      path.relative(SRC, path.resolve(dir, m[1])),
    ),
  );
}

const mainnet = includesOf(MAINNET);
const devnet = includesOf(DEVNET);

const expected = new Set();
for (const inc of mainnet) {
  if (inc in SUBSTITUTIONS) {
    if (SUBSTITUTIONS[inc]) expected.add(SUBSTITUTIONS[inc]);
  } else {
    expected.add(inc);
  }
}

const missing = [...expected].filter((i) => !devnet.has(i)).sort();
const unexpected = [...devnet].filter((i) => !expected.has(i)).sort();
const staleSubs = Object.keys(SUBSTITUTIONS).filter((i) => !mainnet.has(i)).sort();

const problems = [];
if (missing.length) {
  problems.push(
    `Present in ${MAINNET} but missing from ${DEVNET}:\n` +
      missing.map((i) => `    - ${i}`).join('\n') +
      `\n  Add it to the devnet include list, or — if devnet deliberately\n` +
      `  replaces or omits it — declare that in SUBSTITUTIONS in this script.`,
  );
}
if (unexpected.length) {
  problems.push(
    `In ${DEVNET} but not accounted for:\n` +
      unexpected.map((i) => `    - ${i}`).join('\n') +
      `\n  If this is a deliberate devnet replacement, map the mainnet include\n` +
      `  it stands in for via SUBSTITUTIONS in this script.`,
  );
}
if (staleSubs.length) {
  problems.push(
    `SUBSTITUTIONS references includes that no longer exist in ${MAINNET}:\n` +
      staleSubs.map((i) => `    - ${i}`).join('\n') +
      `\n  Drop the stale entries so the guard keeps meaning what it says.`,
  );
}

if (problems.length) {
  console.error('devnet OracleAdapters include set has drifted from mainnet:\n');
  problems.forEach((p) => console.error(`  ${p}\n`));
  process.exit(1);
}

console.log(
  `devnet OracleAdapters include set matches ${MAINNET} ` +
    `(${expected.size} includes, ${Object.keys(SUBSTITUTIONS).length} declared substitutions).`,
);
