import assert from "node:assert/strict";
import { createServer } from "node:http";
import { createRequire } from "node:module";
import { once } from "node:events";
import test from "node:test";

import {
  ArtifactVerificationError,
  normalizeArtifactEndpoint,
  parseArguments,
  verifyArtifactClosure,
} from "./cannon-artifact-closure.mjs";

const require = createRequire(import.meta.url);
const { compress, getContentCID } = require("@usecannon/builder");
const IpfsOnlyHash = require("ipfs-only-hash");

async function artifact(value) {
  const raw = Buffer.from(compress(JSON.stringify(value)));
  return { cid: await getContentCID(raw), raw };
}

async function rawArtifact(raw) {
  return { cid: await IpfsOnlyHash.of(raw), raw };
}

function deployment(value) {
  return {
    timestamp: 1_721_234_567_890,
    status: "complete",
    ...value,
    state: Object.fromEntries(
      Object.entries(value.state || {}).map(([name, step]) => [
        name,
        {
          version: 1,
          hash: null,
          ...step,
        },
      ]),
    ),
  };
}

async function fixtureServer(blobs) {
  const server = createServer((request, response) => {
    const url = new URL(request.url, "http://localhost");
    const cid = url.searchParams.get("arg");
    const raw = blobs.get(cid);
    if (request.method !== "POST" || url.pathname !== "/api/v0/cat" || !raw) {
      response.writeHead(404).end();
      return;
    }
    response.writeHead(200, { "content-length": raw.length });
    response.end(raw);
  });

  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  const { port } = server.address();
  return {
    endpoint: `http+ipfs://127.0.0.1:${port}`,
    close: () =>
      new Promise((resolveClose) => {
        server.close(resolveClose);
        server.closeAllConnections();
      }),
  };
}

async function closureFixture() {
  const importedMisc = await artifact({ artifacts: {} });
  const importedDeployment = await artifact(
    deployment({
      generator: "cannon cli 2.23.0",
      def: { name: "dependency", version: "1.0.0", preset: "main" },
      state: {},
      options: {},
      meta: {
        gitUrl: "https://github.com/example/dependency",
        commitHash: "1".repeat(40),
      },
      miscUrl: `ipfs://${importedMisc.cid}`,
      chainId: 1729,
    }),
  );
  const rootMisc = await artifact({ artifacts: {}, root: true });
  const rootDeployment = await artifact(
    deployment({
      generator: "cannon cli 2.23.0",
      def: { name: "reya-omnibus", version: "1.2.3", preset: "main" },
      state: {
        "pull.dependency": {
          artifacts: {
            imports: {
              dependency: { url: `ipfs://${importedDeployment.cid}` },
            },
          },
        },
      },
      options: {},
      meta: {
        gitUrl: "https://github.com/Reya-Labs/reya-deployments",
        commitHash: "2".repeat(40),
      },
      miscUrl: `ipfs://${rootMisc.cid}`,
      chainId: 1729,
    }),
  );
  const rootMeta = await artifact({
    gitUrl: "https://github.com/Reya-Labs/reya-deployments",
  });

  return {
    rootCid: rootDeployment.cid,
    metaCid: rootMeta.cid,
    blobs: new Map(
      [
        importedMisc,
        importedDeployment,
        rootMisc,
        rootDeployment,
        rootMeta,
      ].map(({ cid, raw }) => [cid, raw]),
    ),
  };
}

test("verifies and deterministically inventories a complete Cannon closure", async () => {
  const fixture = await closureFixture();
  const server = await fixtureServer(fixture.blobs);

  try {
    const config = {
      endpoint: server.endpoint,
      rootCid: fixture.rootCid,
      metaCids: [fixture.metaCid],
      verificationSha: "a".repeat(40),
      verificationRepository: "Reya-Labs/reya-deployments",
      expectedArtifactSourceSha: "2".repeat(40),
      expectedPackageRef: "reya-omnibus:1.2.3@main",
      expectedChainId: 1729,
      allowInsecureLocalhost: true,
    };
    const first = await verifyArtifactClosure(config);
    const second = await verifyArtifactClosure(config);

    assert.deepEqual(first, second);
    assert.equal(first.schema, "reya.cannon.artifact-closure-verification/v1");
    assert.equal(first.authoritative, false);
    assert.equal(first.complete, false);
    assert.equal(first.verification.repository, "Reya-Labs/reya-deployments");
    assert.equal(first.package.name, "reya-omnibus");
    assert.equal(first.package.chainId, 1729);
    assert.equal(first.package.source.commit, "2".repeat(40));
    assert.equal(first.closure.length, 5);
    const metadataRecord = first.closure.find(
      ({ cid }) => cid === fixture.metaCid,
    );
    assert.equal(metadataRecord.metadataBinding, "caller-provided-unbound");
    assert.deepEqual(metadataRecord.references, ["providedMeta[0]"]);
    assert.equal(
      first.observed.totalCompressedBytes,
      first.closure.reduce(
        (total, record) => total + record.compressedBytes,
        0,
      ),
    );
    assert.deepEqual(
      first.closure.map(({ cid }) => cid),
      [...first.closure.map(({ cid }) => cid)].sort(),
    );
  } finally {
    await server.close();
  }
});

test("deduplicates repeated imports while retaining every reference", async () => {
  const childMisc = await artifact({ child: true });
  const child = await artifact(
    deployment({
      generator: "cannon cli 2.23.0",
      def: { name: "dependency", version: "1.0.0", preset: "main" },
      state: {},
      options: {},
      meta: {},
      miscUrl: `ipfs://${childMisc.cid}`,
      chainId: 1729,
    }),
  );
  const rootMisc = await artifact({ root: true });
  const root = await artifact(
    deployment({
      generator: "cannon cli 2.23.0",
      def: { name: "reya-omnibus", version: "1.2.3", preset: "main" },
      state: {
        "pull.one": {
          artifacts: { imports: { one: { url: `ipfs://${child.cid}` } } },
        },
        "pull.two": {
          artifacts: { imports: { two: { url: `ipfs://${child.cid}` } } },
        },
      },
      options: {},
      meta: {},
      miscUrl: `ipfs://${rootMisc.cid}`,
      chainId: 1729,
    }),
  );
  const server = await fixtureServer(
    new Map(
      [childMisc, child, rootMisc, root].map(({ cid, raw }) => [cid, raw]),
    ),
  );

  try {
    const manifest = await verifyArtifactClosure({
      endpoint: server.endpoint,
      rootCid: root.cid,
      verificationSha: "d".repeat(40),
      allowInsecureLocalhost: true,
    });
    const childRecord = manifest.closure.find(({ cid }) => cid === child.cid);
    assert.equal(childRecord.references.length, 2);
    assert.equal(manifest.closure.length, 4);

    await assert.rejects(
      verifyArtifactClosure({
        endpoint: server.endpoint,
        rootCid: root.cid,
        verificationSha: "d".repeat(40),
        maxReferences: 3,
        allowInsecureLocalhost: true,
      }),
      (error) =>
        error instanceof ArtifactVerificationError &&
        error.code === "ARTIFACT_REFERENCE_LIMIT",
    );
  } finally {
    await server.close();
  }
});

test("deduplicates a CID shared by deployment and auxiliary references", async () => {
  const childMisc = await artifact({ child: true });
  const child = await artifact(
    deployment({
      generator: "cannon cli 2.23.0",
      def: { name: "dependency", version: "1.0.0", preset: "main" },
      state: {},
      options: {},
      meta: {},
      miscUrl: `ipfs://${childMisc.cid}`,
      chainId: 1729,
    }),
  );
  const root = await artifact(
    deployment({
      generator: "cannon cli 2.23.0",
      def: { name: "reya-omnibus", version: "1.2.3", preset: "main" },
      state: {
        "pull.dependency": {
          artifacts: {
            imports: { dependency: { url: `ipfs://${child.cid}` } },
          },
        },
      },
      options: {},
      meta: {},
      miscUrl: `ipfs://${child.cid}`,
      chainId: 1729,
    }),
  );
  const server = await fixtureServer(
    new Map([childMisc, child, root].map(({ cid, raw }) => [cid, raw])),
  );

  try {
    const manifest = await verifyArtifactClosure({
      endpoint: server.endpoint,
      rootCid: root.cid,
      verificationSha: "8".repeat(40),
      allowInsecureLocalhost: true,
    });
    const childRecord = manifest.closure.find(({ cid }) => cid === child.cid);
    assert.deepEqual(childRecord.kinds, ["deployment", "misc"]);
    assert.equal(childRecord.deployment.packageRef, "dependency:1.0.0@main");
    assert.ok(
      manifest.closure.some(({ cid }) => cid === childMisc.cid),
      "child deployment miscUrl should be traversed",
    );
  } finally {
    await server.close();
  }
});

test("rejects a non-string source commit with the typed source error", async () => {
  const misc = await artifact({ root: true });
  const root = await artifact(
    deployment({
      generator: "cannon cli 2.23.0",
      def: { name: "reya-omnibus", version: "1.2.3", preset: "main" },
      state: {},
      options: {},
      meta: {
        gitUrl: "https://github.com/Reya-Labs/reya-deployments",
        commitHash: ["2".repeat(40)],
      },
      miscUrl: `ipfs://${misc.cid}`,
      chainId: 1729,
    }),
  );
  const server = await fixtureServer(
    new Map([misc, root].map(({ cid, raw }) => [cid, raw])),
  );

  try {
    await assert.rejects(
      verifyArtifactClosure({
        endpoint: server.endpoint,
        rootCid: root.cid,
        verificationSha: "8".repeat(40),
        allowInsecureLocalhost: true,
      }),
      (error) =>
        error instanceof ArtifactVerificationError &&
        error.code === "ARTIFACT_SOURCE_INVALID",
    );
  } finally {
    await server.close();
  }
});

test("honors the Reya reader facade 404 contract for a missing CID", async () => {
  const fixture = await closureFixture();
  fixture.blobs.delete(
    [...fixture.blobs.keys()].find((cid) => cid !== fixture.rootCid),
  );
  const server = await fixtureServer(fixture.blobs);

  try {
    await assert.rejects(
      verifyArtifactClosure({
        endpoint: server.endpoint,
        rootCid: fixture.rootCid,
        verificationSha: "b".repeat(40),
        allowInsecureLocalhost: true,
      }),
      (error) =>
        error instanceof ArtifactVerificationError &&
        error.code === "ARTIFACT_MISSING",
    );
  } finally {
    await server.close();
  }
});

test("rejects bytes that do not match the requested CID", async () => {
  const fixture = await closureFixture();
  const wrong = await artifact({ wrong: true });
  fixture.blobs.set(fixture.rootCid, wrong.raw);
  const server = await fixtureServer(fixture.blobs);

  try {
    await assert.rejects(
      verifyArtifactClosure({
        endpoint: server.endpoint,
        rootCid: fixture.rootCid,
        verificationSha: "c".repeat(40),
        allowInsecureLocalhost: true,
      }),
      (error) =>
        error instanceof ArtifactVerificationError &&
        error.code === "ARTIFACT_CID_MISMATCH",
    );
  } finally {
    await server.close();
  }
});

test("rejects hosted Cannon and enforces the strict Reya endpoint allowlist", () => {
  assert.throws(
    () => normalizeArtifactEndpoint("https+ipfs://repo.usecannon.com"),
    (error) =>
      error instanceof ArtifactVerificationError &&
      error.code === "HOSTED_CANNON_ENDPOINT_FORBIDDEN",
  );

  assert.throws(
    () =>
      normalizeArtifactEndpoint("https+ipfs://repo.usecannon.com.", {
        requireReyaEndpoint: true,
        allowedHosts: ["repo.usecannon.com"],
      }),
    (error) =>
      error instanceof ArtifactVerificationError &&
      error.code === "ARTIFACT_ENDPOINT_INVALID",
  );

  assert.throws(
    () =>
      normalizeArtifactEndpoint("https+ipfs://other.example.internal", {
        requireReyaEndpoint: true,
        allowedHosts: ["artifacts.example.internal"],
      }),
    (error) =>
      error instanceof ArtifactVerificationError &&
      error.code === "ARTIFACT_ENDPOINT_NOT_ALLOWED",
  );

  assert.throws(
    () =>
      normalizeArtifactEndpoint(
        "https+ipfs://artifacts.example.internal:8443",
        {
          requireReyaEndpoint: true,
          allowedHosts: ["artifacts.example.internal"],
        },
      ),
    (error) =>
      error instanceof ArtifactVerificationError &&
      error.code === "ARTIFACT_ENDPOINT_NOT_ALLOWED",
  );

  assert.equal(
    normalizeArtifactEndpoint("https+ipfs://artifacts.example.internal", {
      requireReyaEndpoint: true,
      allowedHosts: ["artifacts.example.internal"],
    }).hostname,
    "artifacts.example.internal",
  );

  assert.throws(
    () => normalizeArtifactEndpoint("http+ipfs://artifacts.example.internal"),
    (error) =>
      error instanceof ArtifactVerificationError &&
      error.code === "ARTIFACT_ENDPOINT_INSECURE",
  );

  assert.throws(
    () =>
      normalizeArtifactEndpoint("https+ipfs://artifacts.example.internal", {
        requireReyaEndpoint: true,
      }),
    (error) =>
      error instanceof ArtifactVerificationError &&
      error.code === "ARTIFACT_ENDPOINT_ALLOWLIST_MISSING",
  );

  assert.throws(
    () =>
      normalizeArtifactEndpoint("https+ipfs://artifacts.example.internal", {
        requireReyaEndpoint: true,
        allowedHosts: ["Artifacts.Example.Internal"],
      }),
    (error) =>
      error instanceof ArtifactVerificationError &&
      error.code === "ARTIFACT_ENDPOINT_ALLOWLIST_INVALID",
  );
});

test("rejects unknown and duplicate CLI flags while accepting repeatable metadata", () => {
  assert.throws(
    () => parseArguments(["--chain-idd", "1729"]),
    (error) =>
      error instanceof ArtifactVerificationError &&
      error.code === "ARGUMENT_INVALID",
  );
  assert.throws(
    () => parseArguments(["--chain-id", "1729", "--chain-id", "1729"]),
    (error) =>
      error instanceof ArtifactVerificationError &&
      error.code === "ARGUMENT_INVALID",
  );
  assert.deepEqual(
    parseArguments(["--meta", "first", "--meta", "second"])["--meta"],
    ["first", "second"],
  );
});

test("strict rehearsal requires the complete expected identity before fetching", async () => {
  await assert.rejects(
    verifyArtifactClosure({
      endpoint: "https+ipfs://artifacts.example.internal",
      allowedHosts: ["artifacts.example.internal"],
      requireReyaEndpoint: true,
      rootCid: "QmYwAPJzv5CZsnAzt8auVZRn5F3t5gY6T1x1E2r7ZJxj2M",
      verificationSha: "9".repeat(40),
    }),
    (error) =>
      error instanceof ArtifactVerificationError &&
      error.code === "ARTIFACT_EXPECTED_IDENTITY_MISSING",
  );
});

test("structurally rejects a malformed 46-character CID before fetching", async () => {
  await assert.rejects(
    verifyArtifactClosure({
      endpoint: "http+ipfs://127.0.0.1:1",
      rootCid: "A".repeat(46),
      verificationSha: "9".repeat(40),
      allowInsecureLocalhost: true,
    }),
    (error) =>
      error instanceof ArtifactVerificationError &&
      error.code === "ARTIFACT_INVALID_REFERENCE",
  );
});

test("rejects a root that is not a Cannon DeploymentInfo", async () => {
  const invalidRoot = await artifact({ not: "deployment info" });
  const server = await fixtureServer(
    new Map([[invalidRoot.cid, invalidRoot.raw]]),
  );

  try {
    await assert.rejects(
      verifyArtifactClosure({
        endpoint: server.endpoint,
        rootCid: invalidRoot.cid,
        verificationSha: "e".repeat(40),
        allowInsecureLocalhost: true,
      }),
      (error) =>
        error instanceof ArtifactVerificationError &&
        error.code === "ARTIFACT_INVALID_DEPLOYMENT",
    );
  } finally {
    await server.close();
  }
});

test("rejects corrupt compressed bytes after independently verifying their CID", async () => {
  const corruptRoot = await rawArtifact(Buffer.from("not zlib"));
  const server = await fixtureServer(
    new Map([[corruptRoot.cid, corruptRoot.raw]]),
  );

  try {
    await assert.rejects(
      verifyArtifactClosure({
        endpoint: server.endpoint,
        rootCid: corruptRoot.cid,
        verificationSha: "f".repeat(40),
        allowInsecureLocalhost: true,
      }),
      (error) =>
        error instanceof ArtifactVerificationError &&
        error.code === "ARTIFACT_DECOMPRESSION_FAILED",
    );
  } finally {
    await server.close();
  }
});

test("rejects trailing bytes that Cannon's decoder would not accept", async () => {
  const misc = await artifact({ root: true });
  const valid = await artifact(
    deployment({
      generator: "cannon cli 2.23.0",
      def: { name: "reya-omnibus", version: "1.0.0", preset: "main" },
      state: {},
      options: {},
      meta: {},
      miscUrl: `ipfs://${misc.cid}`,
      chainId: 1729,
    }),
  );
  const withTrailingBytes = await rawArtifact(
    Buffer.concat([valid.raw, Buffer.from("trailing")]),
  );
  const server = await fixtureServer(
    new Map([
      [withTrailingBytes.cid, withTrailingBytes.raw],
      [misc.cid, misc.raw],
    ]),
  );

  try {
    await assert.rejects(
      verifyArtifactClosure({
        endpoint: server.endpoint,
        rootCid: withTrailingBytes.cid,
        verificationSha: "a".repeat(40),
        allowInsecureLocalhost: true,
      }),
      (error) =>
        error instanceof ArtifactVerificationError &&
        error.code === "ARTIFACT_TRAILING_BYTES",
    );
  } finally {
    await server.close();
  }
});

test("rejects partial or structurally incomplete deployment evidence", async () => {
  const misc = await artifact({ root: true });
  const partial = await artifact(
    deployment({
      generator: "cannon cli 2.23.0",
      def: { name: "reya-omnibus", version: "1.0.0", preset: "main" },
      state: {},
      options: {},
      meta: {},
      miscUrl: `ipfs://${misc.cid}`,
      chainId: 1729,
      status: "partial",
    }),
  );
  const server = await fixtureServer(
    new Map([
      [partial.cid, partial.raw],
      [misc.cid, misc.raw],
    ]),
  );

  try {
    await assert.rejects(
      verifyArtifactClosure({
        endpoint: server.endpoint,
        rootCid: partial.cid,
        verificationSha: "b".repeat(40),
        allowInsecureLocalhost: true,
      }),
      (error) =>
        error instanceof ArtifactVerificationError &&
        error.code === "ARTIFACT_INVALID_DEPLOYMENT",
    );
  } finally {
    await server.close();
  }
});

test("enforces per-artifact compressed and inflated size limits", async () => {
  const fixture = await closureFixture();
  const server = await fixtureServer(fixture.blobs);
  const rootRaw = fixture.blobs.get(fixture.rootCid);

  try {
    await assert.rejects(
      verifyArtifactClosure({
        endpoint: server.endpoint,
        rootCid: fixture.rootCid,
        verificationSha: "1".repeat(40),
        maxCompressedBytes: rootRaw.length - 1,
        allowInsecureLocalhost: true,
      }),
      (error) =>
        error instanceof ArtifactVerificationError &&
        error.code === "ARTIFACT_TOO_LARGE",
    );

    await assert.rejects(
      verifyArtifactClosure({
        endpoint: server.endpoint,
        rootCid: fixture.rootCid,
        verificationSha: "1".repeat(40),
        maxInflatedBytes: 16,
        allowInsecureLocalhost: true,
      }),
      (error) =>
        error instanceof ArtifactVerificationError &&
        error.code === "ARTIFACT_TOO_LARGE",
    );
  } finally {
    await server.close();
  }
});

test("enforces aggregate traversal byte and artifact-count limits", async () => {
  const fixture = await closureFixture();
  const server = await fixtureServer(fixture.blobs);
  const rootRaw = fixture.blobs.get(fixture.rootCid);

  try {
    await assert.rejects(
      verifyArtifactClosure({
        endpoint: server.endpoint,
        rootCid: fixture.rootCid,
        verificationSha: "3".repeat(40),
        maxTotalCompressedBytes: rootRaw.length,
        allowInsecureLocalhost: true,
      }),
      (error) =>
        error instanceof ArtifactVerificationError &&
        error.code === "ARTIFACT_TOTAL_COMPRESSED_BYTES_LIMIT",
    );

    await assert.rejects(
      verifyArtifactClosure({
        endpoint: server.endpoint,
        rootCid: fixture.rootCid,
        verificationSha: "3".repeat(40),
        maxTotalInflatedBytes: 1,
        allowInsecureLocalhost: true,
      }),
      (error) =>
        error instanceof ArtifactVerificationError &&
        error.code === "ARTIFACT_TOTAL_INFLATED_BYTES_LIMIT",
    );

    await assert.rejects(
      verifyArtifactClosure({
        endpoint: server.endpoint,
        rootCid: fixture.rootCid,
        verificationSha: "3".repeat(40),
        maxArtifacts: 1,
        allowInsecureLocalhost: true,
      }),
      (error) =>
        error instanceof ArtifactVerificationError &&
        error.code === "ARTIFACT_NODE_LIMIT",
    );
  } finally {
    await server.close();
  }
});

test("rejects wrong root identity while preserving imported chain context", async () => {
  const fixture = await closureFixture();
  const server = await fixtureServer(fixture.blobs);

  try {
    await assert.rejects(
      verifyArtifactClosure({
        endpoint: server.endpoint,
        rootCid: fixture.rootCid,
        verificationSha: "4".repeat(40),
        expectedPackageRef: "wrong:1.0.0@main",
        allowInsecureLocalhost: true,
      }),
      (error) =>
        error instanceof ArtifactVerificationError &&
        error.code === "ARTIFACT_PACKAGE_MISMATCH",
    );
    await assert.rejects(
      verifyArtifactClosure({
        endpoint: server.endpoint,
        rootCid: fixture.rootCid,
        verificationSha: "4".repeat(40),
        expectedChainId: 1,
        allowInsecureLocalhost: true,
      }),
      (error) =>
        error instanceof ArtifactVerificationError &&
        error.code === "ARTIFACT_CHAIN_MISMATCH",
    );
  } finally {
    await server.close();
  }

  const importedMisc = await artifact({ imported: true });
  const imported = await artifact(
    deployment({
      generator: "cannon cli 2.23.0",
      def: { name: "dependency", version: "1.0.0", preset: "main" },
      state: {},
      options: {},
      meta: {},
      miscUrl: `ipfs://${importedMisc.cid}`,
      chainId: 1,
    }),
  );
  const rootMisc = await artifact({ root: true });
  const root = await artifact(
    deployment({
      generator: "cannon cli 2.23.0",
      def: { name: "reya-omnibus", version: "1.0.0", preset: "main" },
      state: {
        "pull.dependency": {
          artifacts: {
            imports: { dependency: { url: `ipfs://${imported.cid}` } },
          },
        },
      },
      options: {},
      meta: {},
      miscUrl: `ipfs://${rootMisc.cid}`,
      chainId: 1729,
    }),
  );
  const crossChainServer = await fixtureServer(
    new Map([
      [root.cid, root.raw],
      [rootMisc.cid, rootMisc.raw],
      [imported.cid, imported.raw],
      [importedMisc.cid, importedMisc.raw],
    ]),
  );

  try {
    const manifest = await verifyArtifactClosure({
      endpoint: crossChainServer.endpoint,
      rootCid: root.cid,
      verificationSha: "5".repeat(40),
      allowInsecureLocalhost: true,
    });
    const importedRecord = manifest.closure.find(
      ({ cid }) => cid === imported.cid,
    );
    assert.equal(importedRecord.deployment.chainId, 1);
    assert.equal(manifest.package.chainId, 1729);
  } finally {
    await crossChainServer.close();
  }
});

test("keeps verification identity separate from artifact source identity", async () => {
  const fixture = await closureFixture();
  const server = await fixtureServer(fixture.blobs);

  try {
    await assert.rejects(
      verifyArtifactClosure({
        endpoint: server.endpoint,
        rootCid: fixture.rootCid,
        verificationSha: "6".repeat(40),
        expectedArtifactSourceSha: "7".repeat(40),
        allowInsecureLocalhost: true,
      }),
      (error) =>
        error instanceof ArtifactVerificationError &&
        error.code === "ARTIFACT_SOURCE_MISMATCH",
    );
  } finally {
    await server.close();
  }
});
