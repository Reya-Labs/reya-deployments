# Working with Cannon

Field notes for this repo. Every entry below cost real debugging time at least
once — most of them present as something other than what they are.

## The one thing to internalise

**Cannon SKIPS a failing step and still exits 0.** One failed step cascades
into every step that `depends` on it, and the build reports success. So:

- A green build is not evidence of a complete deployment. Grep the log for
  `Skipping [` — a healthy build has **zero**.
- Fork tests are the real gate. They read live chain state, so a silently
  skipped config step shows up as a failed assertion rather than as nothing.
- `packages/tests/scripts/cannon-retry.sh` wraps the devnet suite and retries
  on any skip. It is deliberately **not** applied to the mainnet/cronos
  suites — see "Partial builds are normal on mainnet/cronos" below.

## Package resolution

### Registry packages live on TWO chains

Cannon reads package hashes from an on-chain registry deployed at the same
address on both Ethereum and Optimism. Reya's packages are **split across
both**: older proxies resolved from Ethereum, newer routers and the omnibus
baselines from Optimism. Any build needs **both** reachable.

Consequence: pinning a single registry via `CANNON_REGISTRY_*` env vars
**breaks resolution** for whatever lives on the other chain. Those env vars
configure exactly one registry. Use a settings file instead (below).

### Registry lookups get rate-limited

Cannon's default registry config uses globally-shared Infura/Alchemy keys.
On shared IPs (CI runners especially, sometimes home connections) they return
429s, which surface as:

```
Error: deployment not found: <pkg>:<ver>@<preset>. please make sure it exists
       for preset <preset> and network 13370
```

That message reads like "the package was never published". Usually it means
"the registry lookup was throttled". Verify with a direct read before
concluding a package is missing:

```bash
cast call 0x8E5C7EFC9636A6A0408A46BB7F617094B81e5dba \
  "getPackageUrl(bytes32,bytes32,bytes32)(string)" \
  $(cast --format-bytes32-string "reya-core") \
  $(cast --format-bytes32-string "1.1.2") \
  $(cast --format-bytes32-string "13370-router") \
  --rpc-url <an-ethereum-rpc>
```

Empty string = genuinely unpublished **on that chain**. Check the other one
before declaring it missing.

### Fix: a settings file with both registries

`~/.local/share/cannon/settings.json` (CI writes the same file):

```json
{
  "ipfsUrl": "https+ipfs://repo.usecannon.com",
  "registries": [
    {
      "name": "OP Mainnet",
      "chainId": 10,
      "rpcUrl": ["<your-optimism-endpoint>", "https://optimism-rpc.publicnode.com"],
      "address": "0x8E5C7EFC9636A6A0408A46BB7F617094B81e5dba"
    },
    {
      "name": "Ethereum Mainnet",
      "chainId": 1,
      "rpcUrl": ["<your-ethereum-endpoint>", "https://ethereum-rpc.publicnode.com"],
      "address": "0x8E5C7EFC9636A6A0408A46BB7F617094B81e5dba"
    }
  ]
}
```

Public endpoints alone are **not** enough on CI runners — they rate-limit
shared egress IPs too. CI uses a keyed endpoint first, public as fallback.

### The local cache hides all of this

`~/.local/share/cannon` answers lookups that would otherwise fail. A build
that works on a machine which previously built the packages can fail
everywhere else. When a build works only for you, suspect the cache: test
with a throwaway `CANNON_DIRECTORY` holding just the settings file.

## IPFS

### Read URL

Cannon's default read endpoint is chosen by **timezone** and resolves to
regional subdomains (`https+ipfs://<region>.repo.usecannon.com`) which have
been decommissioned (NXDOMAIN). Always set:

```
CANNON_IPFS_URL=https+ipfs://repo.usecannon.com
```

Without it, `--upgrade-from` cannot download the baseline and every step
fails at "Checking for existing package".

### Write URL is a *separate* setting

`publish` uploads through `CANNON_PUBLISH_IPFS_URL`, which falls back to the
same dead regional hosts. Symptom is an SSL handshake failure, not a 404:

```
Error: Failed to upload to IPFS. ... ssl3_read_bytes:ssl/tls alert handshake failure
```

Set **both** when publishing:

```
CANNON_IPFS_URL=https+ipfs://repo.usecannon.com
CANNON_PUBLISH_IPFS_URL=https+ipfs://repo.usecannon.com
```

Fetch flakes are common enough to matter (`Skipping [clone.*]`). Raise
`CANNON_IPFS_RETRIES` / `CANNON_IPFS_TIMEOUT`, and note that on retry cannon
resumes from cached state — it often re-reports only the downstream
`Skipping [invoke.*]` cascade without re-attempting the clone, so a retry
predicate matching only `clone.` will happily accept a broken build.

## Publishing

```bash
CANNON_IPFS_URL=https+ipfs://repo.usecannon.com \
CANNON_PUBLISH_IPFS_URL=https+ipfs://repo.usecannon.com \
cannon publish <pkg>:<ver>@<preset> --chain-id <id> --skip-confirm \
  --exclude-cloned --private-key <key>
```

- **`--exclude-cloned` is usually required.** By default publish also pushes
  cloned sub-packages; if any of those is already registered by another
  owner, the whole registry transaction reverts.
- **`--registry-*` flags crash `publish`** (`Cannot read properties of
  undefined (reading 'chainId')`) — it hard-requires the default two-registry
  shape. Configure registries in the settings file instead.
- Without `--skip-confirm` it prompts interactively for the registry, which
  hangs any non-interactive run.
- Registry `publishFee`/`registerFee` are currently zero; cost is chain gas.
- Publishing a package for one `chain-id` variant does **not** publish the
  others. `1.1.2@router` on chain 89346162 and the same package for chain
  13370 are separate registry entries — and `clone` steps in the tomls
  reference the **13370** (portable) variant.

## CREATE2 collisions between sibling clones

Several cloned packages contain an identical `deploy.OwnerUpgradeModule`
sub-step, which resolves to the same CREATE2 address for all of them.
Whichever clone runs first deploys it; the others fail with:

```
The contract at the create2 destination 0x... is already deployed, but the
Cannon state does not recognize that this contract has already been deployed.
```

This is **scheduling-dependent** — dry runs and real runs can pick different
winners, so a clean dry run does not guarantee a clean deployment.

The sanctioned fix is `ifExists = "continue"` on the deploy step, which we
cannot add from here because the step lives inside published source packages.
It is safe to treat as `continue`: a CREATE2 address is a function of the
initcode hash, so code already at the destination is bit-identical to what
the step would deploy. Until the upstream packages carry `ifExists`, recovery
is: patch the guard locally in `@usecannon/builder/dist/src/steps/deploy.js`
(**both** the top-level copy and the one nested under `@usecannon/cli-devnet`),
then resume.

## Resuming a partial deployment

When a build ends "not fully completed", cannon stores a partial package and
prints its IPFS hash. To continue:

```bash
# NOTE: no --upgrade-from — that restarts from the published baseline
cannon build <omnibus.toml> --rpc-url <rpc> --private-key <key>
```

Executed steps are not re-run; only skipped ones are attempted. Use `--wipe`
only when you intend to redo everything.

## Dependency inference

Cannon computes step dependencies from template access. When it cannot
evaluate a template (advanced expressions) **and** the step declares
`depends`, it silently falls back to the explicit list. A wrong or
incomplete `depends` then produces a step that runs too early and fails on
missing state — visible only as a skip. Prefer keeping template expressions
simple enough to be inferable.

## Partial builds are normal on mainnet/cronos

Local dry runs of `reya_network.toml` / `reya_cronos.toml` end partial by
design: some source packages have never been published (their pins are gone),
so ~24 root failures cascade into ~1800 skips. This is identical on `main`
and on any branch, so a **differential** is still meaningful — compare the
executed-step sets between branches rather than expecting zero skips.

## Verifying a deployment changes nothing elsewhere

To prove a change cannot affect mainnet/cronos, dry-run **both** environments
from **both** `main` and the branch, and diff the step sets:

```bash
cannon build ../tomls/src/omnibus/reya_network.toml --dry-run --impersonate-all \
  --upgrade-from reya-omnibus:latest@main --rpc-url <rpc>
```

Identical executed-step sets is a much stronger claim than "the files look
unrelated". Run the four builds **sequentially** — parallel builds rate-limit
the registry.

## Environment variables, collected

| Variable | Why |
|---|---|
| `CANNON_IPFS_URL` | read endpoint; default regional hosts are dead |
| `CANNON_PUBLISH_IPFS_URL` | **separate** write endpoint for `publish` |
| `CANNON_IPFS_RETRIES`, `CANNON_IPFS_TIMEOUT` | fetch flakes on slow networks |
| `CANNON_DIRECTORY` | point at a throwaway dir to test cold-cache resolution |
| `RPC_KEY` | chain RPC key; one key works for both branded endpoints |

Registry endpoints belong in the settings file, not env vars — the env vars
can only express one registry.
