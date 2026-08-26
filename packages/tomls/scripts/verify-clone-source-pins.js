#!/usr/bin/env node
/**
 * Prove that the pins in src/omnibus/reya_devnet.lock.json are the artifacts
 * devnet was actually deployed from (PRO-998).
 *
 * This does NOT need a chain, an RPC key, or a cannon build. Cannon deploys a
 * cloned proxy with arachnid CREATE2, and a CREATE2 address is a pure function
 * of (deployer, salt, initcode) -- so the pinned artifact bytes fully determine
 * the address. We recompute the devnet PassivePool proxy address straight from
 * the pinned bytes and compare it against the address the devnet fork suite
 * asserts (packages/tests/test/reya_devnet/ReyaForkTest.sol).
 *
 * Replicates @usecannon/builder:
 *   - steps/clone.js  `getArtifact: (n) => upstreamMisc.artifacts[n]`
 *   - steps/deploy.js `makeArachnidCreate2Txn(config.salt, txn.data, ...)`
 *   - create2.js      keccak256(toBytes(salt)); arachnid deployer
 *
 * Usage: node scripts/verify-clone-source-pins.js
 *
 * NOTE: `viem` is used transitively via @usecannon/builder rather than being a
 * direct devDependency -- this is a developer verification tool, not part of
 * the build.
 */
const fs = require('fs');
const os = require('os');
const path = require('path');
const zlib = require('zlib');
const viem = require('viem');

const ROOT = path.join(__dirname, '..');
const LOCK = require(path.join(ROOT, 'src/omnibus/reya_devnet.lock.json'));
// Same endpoint cannon itself reads from; `+ipfs` is a cannon-ism axios does not
// understand (see @usecannon/builder ipfs.js readRawIpfs).
const REPO =
  (process.env.CANNON_IPFS_URL || process.env.CANNON_PUBLISH_IPFS_URL || LOCK.ipfsRepo).replace(
    '+ipfs',
    ''
  ) + '/api/v0/cat?arg=';

// Arachnid deterministic deployment proxy. @usecannon/builder's
// ARACHNID_DEFAULT_DEPLOY_ADDR (0x3fab...) is the address it *deploys the
// factory from*; the factory that actually performs the CREATE2 -- and the
// `from` in the address derivation -- is the canonical one below.
const ARACHNID = '0x4e59b44847b379578588920cA78FbF26c0B4956C';

// The single case with a known-good on-chain answer to check against.
const CASE = {
  ref: 'reya-exchange-passive-pool:1.0.0@proxy',
  // reya_devnet.toml [var.initial_proxy_vars].passivePoolSalt
  salt: 'passive-pool-devnet3',
  // reya_devnet.toml [var.wallet_addresses].owner
  owner: '0xaE173a960084903b1d278Ff9E3A81DeD82275556',
  // ReyaForkTest.sol: sec.pool, "devnet's own (CREATE2, passive-pool-devnet3)"
  expected: '0x9fDba948aC22448C310B15C04D9A3DCB4bA8abA2',
};

function fromLocalCache(cid) {
  const dir = path.join(
    process.env.CANNON_DIRECTORY || path.join(os.homedir(), '.local/share/cannon'),
    'ipfs_cache'
  );
  if (!fs.existsSync(dir)) return null;
  const f = fs.readdirSync(dir).find((x) => x.endsWith(`-${cid.toLowerCase()}.json`));
  return f ? JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')) : null;
}

async function fromRepo(cid) {
  const res = await fetch(REPO + cid, { method: 'POST' });
  if (!res.ok) return null;
  const buf = Buffer.from(await res.arrayBuffer());
  // cannon stores blobs zlib-deflated
  return JSON.parse(zlib.inflateSync(buf).toString('utf8'));
}

async function loadBlob(cid) {
  const remote = await fromRepo(cid);
  if (remote) return { blob: remote, via: REPO.replace('/api/v0/cat?arg=', '') };
  const local = fromLocalCache(cid);
  if (local) return { blob: local, via: 'local ipfs_cache' };
  return { blob: null, via: 'UNAVAILABLE' };
}

const create2 = (salt, initcode) =>
  viem.getCreate2Address({
    bytecode: initcode,
    salt: viem.keccak256(viem.toBytes(salt)),
    from: ARACHNID,
  });

async function main() {
  const pin = LOCK.packages[CASE.ref];
  if (!pin) throw new Error(`${CASE.ref} is not pinned in the lockfile`);

  const deploy = await loadBlob(pin.deploy);
  if (!deploy.blob) throw new Error(`deployment blob ${pin.deploy} unavailable`);
  const misc = await loadBlob(pin.misc);
  if (!misc.blob) {
    console.error(`artifact blob ${pin.misc} is unavailable from repo.usecannon.com and is not`);
    console.error('in the local ipfs_cache, so the pin cannot be verified (or cloned) here.');
    process.exit(2);
  }

  console.log(`ref              : ${CASE.ref}`);
  console.log(`deploy blob      : ${pin.deploy}  (via ${deploy.via})`);
  console.log(`artifact blob    : ${pin.misc}  (via ${misc.via})`);
  console.log(`built by         : ${deploy.blob.generator}`);
  console.log(`salt / owner     : ${CASE.salt} / ${CASE.owner}`);

  // Artifact keys come from the package's own definition, exactly as clone.js
  // resolves them -- they differ between cannon toolchain versions.
  const oumKey = deploy.blob.def.deploy.OwnerUpgradeModule.artifact;
  const proxyKey = deploy.blob.def.deploy.InitialProxy.artifact;

  const oum = create2(CASE.salt, misc.blob.artifacts[oumKey].bytecode);
  const args = viem.encodeAbiParameters(
    [{ type: 'address' }, { type: 'address' }],
    [oum, viem.getAddress(CASE.owner)]
  );
  const proxy = create2(CASE.salt, viem.concatHex([misc.blob.artifacts[proxyKey].bytecode, args]));

  console.log(`OwnerUpgradeModule: ${oum}`);
  console.log(`PassivePoolProxy  : ${proxy}`);
  console.log(`expected          : ${CASE.expected}`);

  if (proxy.toLowerCase() !== CASE.expected.toLowerCase()) {
    console.error(
      '\nMISMATCH: the pinned artifact does not reproduce the deployed devnet address.'
    );
    process.exit(1);
  }
  console.log('\nOK: the pinned artifact reproduces the deployed devnet PassivePool address.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
