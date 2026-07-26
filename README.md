# reya-deployments

- variables follow camel case
- invoke commands follow snake case

```
yarn
RPC_KEY=... yarn reya_network:test
RPC_KEY=... yarn reya_cronos:test
```

## Verify an exact Cannon artifact closure

`yarn cannon:artifact-closure:verify` reads an exact root CID from the
Kubo-shaped Reya reader facade, independently recomputes every CID, and
recursively verifies the deployment's `miscUrl` and imported deployment URLs.
The Reya facade contract deliberately returns HTTP 404 for a missing CID;
stock Kubo may return HTTP 500 and is not status-compatible. The verifier does
not upload, publish, resolve a mutable package tag, or stage a Safe transaction.

The JSON result is deliberately marked non-authoritative and incomplete.
Registry-resolution provenance and imported-package metadata CIDs are not
discoverable from deployment imports, so any known metadata CIDs must be
provided explicitly with repeatable `--meta` arguments. These metadata objects
are recorded as caller-provided and unbound; they are not represented as root
links.

Only structurally complete, published Cannon `DeploymentInfo` objects with
`status: complete` are accepted. Partial staging candidates and legacy objects
without status are intentionally outside this verifier's contract.

```sh
yarn cannon:artifact-closure:verify \
  --endpoint https+ipfs://artifacts.example.internal \
  --root QmExactRootCid \
  --meta QmExplicitRootMetadataCid \
  --package-ref reya-omnibus:1.2.3@main \
  --chain-id 1729 \
  --verification-sha 0123456789abcdef0123456789abcdef01234567 \
  --verification-repository Reya-Labs/reya-deployments \
  --artifact-source-sha 89abcdef0123456789abcdef0123456789abcdef \
  --allowed-host artifacts.example.internal \
  --require-reya-endpoint \
  --out artifact-closure-verification.json
```

The verifier never sends credentials to the supplied read endpoint and always
rejects hosted `usecannon.com` endpoints. In strict rehearsal mode, the
endpoint hostname must also exactly match an explicit `--allowed-host`. Local
fixture tests may explicitly opt into an insecure localhost endpoint;
non-local endpoints must use HTTPS.

`yarn cannon:artifact-closure:test` is a fixture-only unit suite; it does not
perform a live endpoint rehearsal. Production verification still requires the
exact root, known metadata CIDs, source identity, expected package/chain, and
approved Reya endpoint hostname. Run
`yarn cannon:artifact-closure:verify --help` for the complete CLI.
