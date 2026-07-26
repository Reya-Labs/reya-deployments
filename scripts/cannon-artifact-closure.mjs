import { createRequire } from "node:module";
import { mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { inflateSync } from "node:zlib";
import { pathToFileURL } from "node:url";
import { CID } from "multiformats/cid";

const require = createRequire(import.meta.url);
const IpfsOnlyHash = require("ipfs-only-hash");

const DEFAULT_MAX_COMPRESSED_BYTES = 32 * 1024 * 1024;
const DEFAULT_MAX_INFLATED_BYTES = 128 * 1024 * 1024;
const DEFAULT_MAX_ARTIFACTS = 2_048;
const DEFAULT_MAX_REFERENCES = 32_768;
const DEFAULT_MAX_TOTAL_COMPRESSED_BYTES = 256 * 1024 * 1024;
const DEFAULT_MAX_TOTAL_INFLATED_BYTES = 512 * 1024 * 1024;
const DEFAULT_TIMEOUT_MS = 30_000;

function compareStrings(left, right) {
  return left < right ? -1 : left > right ? 1 : 0;
}

export class ArtifactVerificationError extends Error {
  constructor(code, message, cause) {
    super(message, { cause });
    this.name = "ArtifactVerificationError";
    this.code = code;
  }
}

function requireCid(value, context) {
  if (typeof value !== "string") {
    throw new ArtifactVerificationError(
      "ARTIFACT_INVALID_REFERENCE",
      `${context} must be an exact Cannon CID or ipfs://CID`,
    );
  }

  const trimmed = value.trim();
  const cid = trimmed.startsWith("ipfs://") ? trimmed.slice(7) : trimmed;
  try {
    const parsed = CID.parse(cid);
    if (
      parsed.version !== 0 ||
      parsed.toString() !== cid ||
      (trimmed !== cid && trimmed !== `ipfs://${cid}`)
    ) {
      throw new Error("CID is not a canonical Cannon CIDv0 reference");
    }
    return cid;
  } catch (error) {
    throw new ArtifactVerificationError(
      "ARTIFACT_INVALID_REFERENCE",
      `${context} must be an exact canonical Cannon CIDv0 or ipfs://CIDv0`,
      error,
    );
  }
}

function isLocalhost(hostname) {
  return (
    hostname === "localhost" || hostname === "127.0.0.1" || hostname === "[::1]"
  );
}

function normalizeAllowedHost(value) {
  if (
    typeof value !== "string" ||
    !value ||
    value !== value.toLowerCase() ||
    value.endsWith(".") ||
    !/^[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?$/.test(value)
  ) {
    throw new ArtifactVerificationError(
      "ARTIFACT_ENDPOINT_ALLOWLIST_INVALID",
      `Invalid canonical artifact endpoint hostname ${JSON.stringify(value)}`,
    );
  }
  return value;
}

export function normalizeArtifactEndpoint(value, options = {}) {
  if (!value) {
    throw new ArtifactVerificationError(
      "ARTIFACT_ENDPOINT_MISSING",
      "Cannon artifact endpoint is required",
    );
  }

  let endpoint;
  try {
    endpoint = new URL(
      value.replace(/^https\+ipfs:/, "https:").replace(/^http\+ipfs:/, "http:"),
    );
  } catch (error) {
    throw new ArtifactVerificationError(
      "ARTIFACT_ENDPOINT_INVALID",
      "Cannon artifact endpoint is not a valid URL",
      error,
    );
  }

  if (
    endpoint.username ||
    endpoint.password ||
    endpoint.search ||
    endpoint.hash
  ) {
    throw new ArtifactVerificationError(
      "ARTIFACT_ENDPOINT_INVALID",
      "Cannon artifact endpoint must not contain credentials, query parameters, or a fragment",
    );
  }

  if (endpoint.protocol !== "https:" && endpoint.protocol !== "http:") {
    throw new ArtifactVerificationError(
      "ARTIFACT_ENDPOINT_INVALID",
      "Cannon artifact endpoint must use https+ipfs or https",
    );
  }

  const hostname = endpoint.hostname.toLowerCase();
  if (hostname.endsWith(".")) {
    throw new ArtifactVerificationError(
      "ARTIFACT_ENDPOINT_INVALID",
      "Cannon artifact endpoint hostname must not use a trailing-dot alias",
    );
  }

  const hostedCannon =
    hostname === "usecannon.com" || hostname.endsWith(".usecannon.com");
  if (hostedCannon) {
    throw new ArtifactVerificationError(
      "HOSTED_CANNON_ENDPOINT_FORBIDDEN",
      "Hosted Cannon endpoints are forbidden by the Reya artifact verifier",
    );
  }

  const allowedHostValues = options.allowedHosts || [];
  if (!Array.isArray(allowedHostValues)) {
    throw new ArtifactVerificationError(
      "ARTIFACT_ENDPOINT_ALLOWLIST_INVALID",
      "Artifact endpoint host allowlist must be an array",
    );
  }
  const allowedHosts = new Set(allowedHostValues.map(normalizeAllowedHost));
  if (options.requireReyaEndpoint && allowedHosts.size === 0) {
    throw new ArtifactVerificationError(
      "ARTIFACT_ENDPOINT_ALLOWLIST_MISSING",
      "Strict Reya artifact rehearsal requires an explicit endpoint hostname allowlist",
    );
  }
  if (allowedHosts.size > 0) {
    if (!allowedHosts.has(hostname)) {
      throw new ArtifactVerificationError(
        "ARTIFACT_ENDPOINT_NOT_ALLOWED",
        `Artifact endpoint hostname ${hostname} is not in the strict Reya allowlist`,
      );
    }
    if (endpoint.port) {
      throw new ArtifactVerificationError(
        "ARTIFACT_ENDPOINT_NOT_ALLOWED",
        "Reya artifact endpoint allowlists do not allow a non-default HTTPS port",
      );
    }
  }

  if (
    endpoint.protocol !== "https:" &&
    !(options.allowInsecureLocalhost && isLocalhost(hostname))
  ) {
    throw new ArtifactVerificationError(
      "ARTIFACT_ENDPOINT_INSECURE",
      "Cannon artifact endpoint must use HTTPS outside an explicitly allowed localhost test",
    );
  }

  endpoint.pathname = "/";
  return endpoint;
}

async function fetchArtifact(cid, endpoint, options) {
  const url = new URL("/api/v0/cat", endpoint);
  url.searchParams.set("arg", cid);

  let response;
  try {
    response = await options.fetchImpl(url, {
      method: "POST",
      redirect: "error",
      signal: AbortSignal.timeout(options.timeoutMs),
    });
  } catch (error) {
    throw new ArtifactVerificationError(
      "ARTIFACT_ENDPOINT_UNREACHABLE",
      `Artifact endpoint could not serve CID ${cid}`,
      error,
    );
  }

  if (response.status === 404) {
    throw new ArtifactVerificationError(
      "ARTIFACT_MISSING",
      `Artifact endpoint is missing CID ${cid}`,
    );
  }
  if (response.status === 401 || response.status === 403) {
    throw new ArtifactVerificationError(
      "ARTIFACT_UNAUTHORIZED",
      `Artifact endpoint denied CID ${cid}`,
    );
  }
  if (response.status !== 200) {
    throw new ArtifactVerificationError(
      "ARTIFACT_HTTP_ERROR",
      `Artifact endpoint returned HTTP ${response.status} for CID ${cid}`,
    );
  }

  const contentLength = response.headers.get("content-length");
  const declaredLength =
    contentLength === null ? undefined : Number(contentLength);
  if (
    Number.isFinite(declaredLength) &&
    declaredLength > options.maxCompressedBytes
  ) {
    throw new ArtifactVerificationError(
      "ARTIFACT_TOO_LARGE",
      `CID ${cid} exceeds the compressed size limit`,
    );
  }

  if (
    Number.isFinite(declaredLength) &&
    declaredLength > options.remainingTotalCompressedBytes
  ) {
    throw new ArtifactVerificationError(
      "ARTIFACT_TOTAL_COMPRESSED_BYTES_LIMIT",
      `CID ${cid} exceeds the remaining aggregate compressed-byte limit`,
    );
  }

  if (!response.body) {
    throw new ArtifactVerificationError(
      "ARTIFACT_RESPONSE_EMPTY",
      `Artifact endpoint returned no body for CID ${cid}`,
    );
  }

  const chunks = [];
  let byteLength = 0;
  try {
    for await (const chunk of response.body) {
      const buffer = Buffer.from(chunk);
      byteLength += buffer.length;
      if (byteLength > options.maxCompressedBytes) {
        throw new ArtifactVerificationError(
          "ARTIFACT_TOO_LARGE",
          `CID ${cid} exceeds the compressed size limit`,
        );
      }
      if (byteLength > options.remainingTotalCompressedBytes) {
        throw new ArtifactVerificationError(
          "ARTIFACT_TOTAL_COMPRESSED_BYTES_LIMIT",
          `CID ${cid} exceeds the remaining aggregate compressed-byte limit`,
        );
      }
      chunks.push(buffer);
    }
  } catch (error) {
    if (error instanceof ArtifactVerificationError) {
      throw error;
    }
    throw new ArtifactVerificationError(
      "ARTIFACT_ENDPOINT_UNREACHABLE",
      `Artifact endpoint interrupted CID ${cid}`,
      error,
    );
  }

  const raw = Buffer.concat(chunks, byteLength);
  if (raw.length === 0) {
    throw new ArtifactVerificationError(
      "ARTIFACT_RESPONSE_EMPTY",
      `Artifact endpoint returned an empty body for CID ${cid}`,
    );
  }

  const observedCid = await IpfsOnlyHash.of(raw);
  if (observedCid !== cid) {
    throw new ArtifactVerificationError(
      "ARTIFACT_CID_MISMATCH",
      `Artifact endpoint returned content ${observedCid} for requested CID ${cid}`,
    );
  }

  return raw;
}

function decodeArtifact(raw, cid, maxInflatedBytes) {
  let result;
  try {
    result = inflateSync(raw, {
      info: true,
      maxOutputLength: maxInflatedBytes,
    });
  } catch (error) {
    const code =
      error?.code === "ERR_BUFFER_TOO_LARGE"
        ? "ARTIFACT_TOO_LARGE"
        : "ARTIFACT_DECOMPRESSION_FAILED";
    throw new ArtifactVerificationError(
      code,
      `CID ${cid} is not a bounded Cannon artifact`,
      error,
    );
  }

  if (result.engine.bytesWritten !== raw.length) {
    throw new ArtifactVerificationError(
      "ARTIFACT_TRAILING_BYTES",
      `CID ${cid} contains bytes after the Cannon zlib stream`,
    );
  }

  const inflated = result.buffer;
  try {
    return {
      byteLength: inflated.length,
      value: JSON.parse(inflated.toString("utf8")),
    };
  } catch (error) {
    throw new ArtifactVerificationError(
      "ARTIFACT_INVALID_JSON",
      `CID ${cid} is not valid Cannon JSON`,
      error,
    );
  }
}

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function deploymentReferences(deployment, reference, maxReferences) {
  const chainId = Number(deployment?.chainId);
  if (
    !isRecord(deployment) ||
    !/^cannon\s+\S/.test(deployment.generator || "") ||
    !Number.isSafeInteger(deployment.timestamp) ||
    deployment.timestamp < 0 ||
    !deployment.def?.name ||
    typeof deployment.def.name !== "string" ||
    !deployment.def?.version ||
    typeof deployment.def.version !== "string" ||
    !deployment.def?.preset ||
    typeof deployment.def.preset !== "string" ||
    !isRecord(deployment.options) ||
    !isRecord(deployment.meta) ||
    !isRecord(deployment.state) ||
    deployment.status !== "complete" ||
    typeof deployment.miscUrl !== "string" ||
    !deployment.miscUrl ||
    typeof deployment.chainId !== "number" ||
    !Number.isSafeInteger(chainId) ||
    chainId <= 0
  ) {
    throw new ArtifactVerificationError(
      "ARTIFACT_INVALID_DEPLOYMENT",
      `${reference} does not contain a Cannon DeploymentInfo`,
    );
  }

  const references = [];
  const addReference = (value) => {
    if (references.length >= maxReferences) {
      throw new ArtifactVerificationError(
        "ARTIFACT_REFERENCE_LIMIT",
        "Artifact closure exceeds the configured reference-edge limit",
      );
    }
    references.push(value);
  };

  addReference({
    cid: requireCid(deployment.miscUrl, `${reference}.miscUrl`),
    kind: "misc",
    reference: `${reference}.miscUrl`,
  });

  for (const [stepName, step] of Object.entries(deployment.state)) {
    if (
      !isRecord(step) ||
      (step.version !== undefined &&
        (!Number.isSafeInteger(step.version) || step.version < 0)) ||
      (step.hash !== undefined &&
        !(step.hash === null || typeof step.hash === "string")) ||
      !isRecord(step.artifacts)
    ) {
      throw new ArtifactVerificationError(
        "ARTIFACT_INVALID_DEPLOYMENT",
        `${reference}.state.${stepName} is not a Cannon step record`,
      );
    }
    const imports = step.artifacts.imports ?? {};
    if (!isRecord(imports)) {
      throw new ArtifactVerificationError(
        "ARTIFACT_INVALID_DEPLOYMENT",
        `${reference}.state.${stepName}.artifacts.imports is not an object`,
      );
    }
    for (const [importName, imported] of Object.entries(imports)) {
      addReference({
        cid: requireCid(
          imported?.url,
          `${reference}.state.${stepName}.imports.${importName}.url`,
        ),
        kind: "deployment",
        reference: `${reference}.state.${stepName}.imports.${importName}`,
      });
    }
  }

  return references;
}

function deploymentIdentity(deployment) {
  const preset = deployment.def.preset;
  const packageRef = `${deployment.def.name}:${deployment.def.version}@${preset}`;
  const commit = deployment.meta?.commitHash;
  const gitUrl = deployment.meta?.gitUrl;

  if (
    commit !== undefined &&
    (typeof commit !== "string" || !/^[0-9a-f]{40}$/i.test(commit))
  ) {
    throw new ArtifactVerificationError(
      "ARTIFACT_SOURCE_INVALID",
      `Artifact ${packageRef} contains an invalid source commit`,
    );
  }
  if (gitUrl !== undefined && typeof gitUrl !== "string") {
    throw new ArtifactVerificationError(
      "ARTIFACT_SOURCE_INVALID",
      `Artifact ${packageRef} contains an invalid source repository`,
    );
  }

  return {
    name: deployment.def.name,
    version: deployment.def.version,
    preset,
    packageRef,
    chainId: Number(deployment.chainId),
    generator: deployment.generator,
    timestamp: deployment.timestamp,
    status: deployment.status,
    source: {
      repository: gitUrl || null,
      commit: commit?.toLowerCase() || null,
    },
  };
}

function validateRootIdentity(identity, config) {
  const { packageRef } = identity;

  if (config.expectedPackageRef && config.expectedPackageRef !== packageRef) {
    throw new ArtifactVerificationError(
      "ARTIFACT_PACKAGE_MISMATCH",
      `Root artifact contains ${packageRef}, expected ${config.expectedPackageRef}`,
    );
  }

  if (
    config.expectedChainId !== undefined &&
    Number(config.expectedChainId) !== identity.chainId
  ) {
    throw new ArtifactVerificationError(
      "ARTIFACT_CHAIN_MISMATCH",
      `Root artifact contains chain ${identity.chainId}, expected ${config.expectedChainId}`,
    );
  }

  if (
    config.expectedArtifactSourceSha &&
    config.expectedArtifactSourceSha.toLowerCase() !== identity.source.commit
  ) {
    throw new ArtifactVerificationError(
      "ARTIFACT_SOURCE_MISMATCH",
      `Root artifact source commit does not match ${config.expectedArtifactSourceSha}`,
    );
  }
}

function validateGitSha(value, context) {
  if (!/^[0-9a-f]{40}$/i.test(value || "")) {
    throw new ArtifactVerificationError(
      "GIT_SHA_INVALID",
      `${context} must be an exact 40-character Git commit SHA`,
    );
  }
  return value.toLowerCase();
}

function positiveInteger(value, fallback, context) {
  const number = value === undefined ? fallback : Number(value);
  if (!Number.isSafeInteger(number) || number <= 0) {
    throw new ArtifactVerificationError(
      "LIMIT_INVALID",
      `${context} must be a positive safe integer`,
    );
  }
  return number;
}

function booleanEnvironmentValue(value, context) {
  if (value === undefined || value === "") {
    return false;
  }
  if (value === "true") {
    return true;
  }
  if (value === "false") {
    return false;
  }
  throw new ArtifactVerificationError(
    "ENVIRONMENT_INVALID",
    `${context} must be exactly true or false`,
  );
}

function optionalPositiveDecimal(value, context) {
  if (value === undefined || value === null || value === "") {
    return undefined;
  }
  const stringValue = String(value);
  if (!/^[1-9][0-9]*$/.test(stringValue)) {
    throw new ArtifactVerificationError(
      "PROVENANCE_VALUE_INVALID",
      `${context} must be a positive decimal integer`,
    );
  }
  return stringValue;
}

export async function verifyArtifactClosure(config) {
  const endpoint = normalizeArtifactEndpoint(config.endpoint, {
    requireReyaEndpoint: config.requireReyaEndpoint,
    allowInsecureLocalhost: config.allowInsecureLocalhost,
    allowedHosts: config.allowedHosts,
  });
  const rootCid = requireCid(config.rootCid, "Root artifact");
  const verificationSha = validateGitSha(
    config.verificationSha,
    "Verification checkout SHA",
  );
  const expectedArtifactSourceSha = config.expectedArtifactSourceSha
    ? validateGitSha(
        config.expectedArtifactSourceSha,
        "Expected artifact source SHA",
      )
    : undefined;
  const workflowRunId = optionalPositiveDecimal(
    config.workflowRunId,
    "Workflow run ID",
  );
  const workflowRunAttempt = optionalPositiveDecimal(
    config.workflowRunAttempt,
    "Workflow run attempt",
  );
  const verificationRepository = config.verificationRepository || null;
  if (
    verificationRepository !== null &&
    !/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(verificationRepository)
  ) {
    throw new ArtifactVerificationError(
      "GIT_REPOSITORY_INVALID",
      "Verification repository must use the owner/repository form",
    );
  }
  const expectedChainId =
    config.expectedChainId === undefined
      ? undefined
      : positiveInteger(
          config.expectedChainId,
          undefined,
          "Expected root chain ID",
        );
  if (
    config.requireReyaEndpoint &&
    (!config.expectedPackageRef ||
      expectedChainId === undefined ||
      !expectedArtifactSourceSha ||
      !verificationRepository)
  ) {
    throw new ArtifactVerificationError(
      "ARTIFACT_EXPECTED_IDENTITY_MISSING",
      "Strict Reya rehearsal requires expected package, chain, artifact source SHA, and verification repository",
    );
  }
  const fetchImpl = config.fetchImpl || globalThis.fetch;
  if (typeof fetchImpl !== "function") {
    throw new ArtifactVerificationError(
      "ARTIFACT_FETCH_INVALID",
      "Artifact fetch implementation must be a function",
    );
  }
  const options = {
    fetchImpl,
    maxArtifacts: positiveInteger(
      config.maxArtifacts,
      DEFAULT_MAX_ARTIFACTS,
      "Maximum artifact count",
    ),
    maxReferences: positiveInteger(
      config.maxReferences,
      DEFAULT_MAX_REFERENCES,
      "Maximum reference count",
    ),
    maxCompressedBytes: positiveInteger(
      config.maxCompressedBytes,
      DEFAULT_MAX_COMPRESSED_BYTES,
      "Maximum compressed bytes per artifact",
    ),
    maxInflatedBytes: positiveInteger(
      config.maxInflatedBytes,
      DEFAULT_MAX_INFLATED_BYTES,
      "Maximum inflated bytes per artifact",
    ),
    maxTotalCompressedBytes: positiveInteger(
      config.maxTotalCompressedBytes,
      DEFAULT_MAX_TOTAL_COMPRESSED_BYTES,
      "Maximum aggregate compressed bytes",
    ),
    maxTotalInflatedBytes: positiveInteger(
      config.maxTotalInflatedBytes,
      DEFAULT_MAX_TOTAL_INFLATED_BYTES,
      "Maximum aggregate inflated bytes",
    ),
    timeoutMs: positiveInteger(
      config.timeoutMs,
      DEFAULT_TIMEOUT_MS,
      "Artifact request timeout",
    ),
  };

  const records = new Map();
  const metaCidValues = config.metaCids || [];
  if (!Array.isArray(metaCidValues)) {
    throw new ArtifactVerificationError(
      "ARTIFACT_METADATA_INVALID",
      "Caller-provided metadata CIDs must be an array",
    );
  }
  const providedMetaCids = metaCidValues
    .map((metaCid, index) => requireCid(metaCid, `Meta artifact ${index}`))
    .sort(compareStrings);
  if (providedMetaCids.length + 1 > options.maxReferences) {
    throw new ArtifactVerificationError(
      "ARTIFACT_REFERENCE_LIMIT",
      `Initial root and metadata references exceed the ${options.maxReferences}-reference limit`,
    );
  }
  const deploymentQueue = [{ cid: rootCid, kind: "root", reference: "root" }];
  const auxiliaryQueue = providedMetaCids.map((metaCid, index) => ({
    cid: metaCid,
    kind: "meta",
    reference: `providedMeta[${index}]`,
  }));
  let deploymentQueueIndex = 0;
  let auxiliaryQueueIndex = 0;
  let referenceCount = deploymentQueue.length + auxiliaryQueue.length;
  let rootDeployment;
  let rootIdentity;
  let totalCompressedBytes = 0;
  let totalInflatedBytes = 0;

  const inspectDeployment = (record, current, value) => {
    const references = deploymentReferences(
      value,
      current.reference,
      options.maxReferences - referenceCount,
    );
    const identity = deploymentIdentity(value);
    record.deployment = identity;
    if (current.kind === "root") {
      rootDeployment = value;
      rootIdentity = identity;
      validateRootIdentity(identity, {
        ...config,
        expectedChainId,
        expectedArtifactSourceSha,
      });
    }
    for (const reference of references) {
      if (reference.kind === "deployment") {
        deploymentQueue.push(reference);
      } else {
        auxiliaryQueue.push(reference);
      }
    }
    referenceCount += references.length;
  };

  while (
    deploymentQueueIndex < deploymentQueue.length ||
    auxiliaryQueueIndex < auxiliaryQueue.length
  ) {
    const current =
      deploymentQueueIndex < deploymentQueue.length
        ? deploymentQueue[deploymentQueueIndex++]
        : auxiliaryQueue[auxiliaryQueueIndex++];
    const existing = records.get(current.cid);
    if (existing) {
      existing.kinds.add(current.kind);
      existing.references.add(current.reference);
      if (
        (current.kind === "root" || current.kind === "deployment") &&
        !existing.deployment
      ) {
        throw new ArtifactVerificationError(
          "ARTIFACT_TRAVERSAL_INVALID",
          `Deployment reference ${current.reference} was processed after auxiliary artifact ${current.cid}`,
        );
      }
      continue;
    }

    if (records.size >= options.maxArtifacts) {
      throw new ArtifactVerificationError(
        "ARTIFACT_NODE_LIMIT",
        `Artifact closure exceeds the ${options.maxArtifacts}-node limit`,
      );
    }

    const record = {
      cid: current.cid,
      kinds: new Set([current.kind]),
      references: new Set([current.reference]),
    };
    records.set(current.cid, record);

    const raw = await fetchArtifact(current.cid, endpoint, {
      ...options,
      remainingTotalCompressedBytes:
        options.maxTotalCompressedBytes - totalCompressedBytes,
    });
    totalCompressedBytes += raw.length;
    const decoded = decodeArtifact(raw, current.cid, options.maxInflatedBytes);
    totalInflatedBytes += decoded.byteLength;
    if (totalInflatedBytes > options.maxTotalInflatedBytes) {
      throw new ArtifactVerificationError(
        "ARTIFACT_TOTAL_INFLATED_BYTES_LIMIT",
        `Artifact closure exceeds the ${options.maxTotalInflatedBytes}-byte aggregate inflated limit`,
      );
    }
    record.compressedBytes = raw.length;
    record.inflatedBytes = decoded.byteLength;

    if (current.kind === "root" || current.kind === "deployment") {
      inspectDeployment(record, current, decoded.value);
    } else if (current.kind === "meta") {
      if (!isRecord(decoded.value)) {
        throw new ArtifactVerificationError(
          "ARTIFACT_INVALID_METADATA",
          `${current.reference} is not a Cannon metadata object`,
        );
      }
      record.metadataBinding = "caller-provided-unbound";
    }
  }

  const manifest = {
    schema: "reya.cannon.artifact-closure-verification/v1",
    authoritative: false,
    complete: false,
    limitations: [
      "Only complete deployment miscUrl/import URLs and caller-provided, unbound metadata CIDs are traversed.",
      "Registry resolution provenance and imported-package metadata CIDs are not discovered.",
      "This unsigned evidence does not authorize artifact publishing or Safe transaction staging.",
    ],
    verification: {
      repository: verificationRepository,
      commit: verificationSha,
      ...(workflowRunId ? { workflowRunId } : {}),
      ...(workflowRunAttempt ? { workflowRunAttempt } : {}),
    },
    package: {
      name: rootDeployment.def.name,
      version: rootDeployment.def.version,
      preset: rootDeployment.def.preset,
      chainId: Number(rootDeployment.chainId),
      generator: rootDeployment.generator,
      timestamp: rootDeployment.timestamp,
      status: rootDeployment.status,
      rootCid,
      source: rootIdentity.source,
    },
    providedMetaCids,
    limits: {
      maxArtifacts: options.maxArtifacts,
      maxReferences: options.maxReferences,
      maxCompressedBytesPerArtifact: options.maxCompressedBytes,
      maxInflatedBytesPerArtifact: options.maxInflatedBytes,
      maxTotalCompressedBytes: options.maxTotalCompressedBytes,
      maxTotalInflatedBytes: options.maxTotalInflatedBytes,
    },
    observed: {
      artifacts: records.size,
      references: referenceCount,
      totalCompressedBytes,
      totalInflatedBytes,
    },
    closure: [...records.values()]
      .map((record) => ({
        cid: record.cid,
        kinds: [...record.kinds].sort(compareStrings),
        references: [...record.references].sort(compareStrings),
        compressedBytes: record.compressedBytes,
        inflatedBytes: record.inflatedBytes,
        ...(record.metadataBinding
          ? { metadataBinding: record.metadataBinding }
          : {}),
        ...(record.deployment
          ? {
              deployment: {
                packageRef: record.deployment.packageRef,
                chainId: record.deployment.chainId,
                timestamp: record.deployment.timestamp,
                status: record.deployment.status,
                source: record.deployment.source,
              },
            }
          : {}),
      }))
      .sort((left, right) => compareStrings(left.cid, right.cid)),
  };

  return manifest;
}

const USAGE = `Usage:
  yarn cannon:artifact-closure:verify \\
    --endpoint https+ipfs://HOST \\
    --root CID \\
    --verification-sha GIT_SHA \\
    [--verification-repository OWNER/REPOSITORY] \\
    [--meta CID]... \\
    [--package-ref NAME:VERSION@PRESET] \\
    [--chain-id CHAIN_ID] \\
    [--artifact-source-sha GIT_SHA] \\
    [--allowed-host HOST]... \\
    [--require-reya-endpoint] \\
    [--max-artifacts N] [--max-references N] \\
    [--max-compressed-bytes N] [--max-inflated-bytes N] \\
    [--max-total-compressed-bytes N] \\
    [--max-total-inflated-bytes N] \\
    [--allow-insecure-localhost] \\
    [--out FILE]

This verifies complete, published Cannon DeploymentInfo artifacts only. It does
not resolve mutable tags, publish artifacts, or produce a canonical manifest.
`;

export function parseArguments(argv) {
  const values = {};
  const booleans = new Set([
    "--require-reya-endpoint",
    "--allow-insecure-localhost",
    "--help",
  ]);
  const repeatable = new Set(["--meta", "--allowed-host"]);
  const singletonValues = new Set([
    "--endpoint",
    "--root",
    "--package-ref",
    "--chain-id",
    "--artifact-source-sha",
    "--verification-sha",
    "--verification-repository",
    "--max-artifacts",
    "--max-references",
    "--max-compressed-bytes",
    "--max-inflated-bytes",
    "--max-total-compressed-bytes",
    "--max-total-inflated-bytes",
    "--out",
  ]);

  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (booleans.has(argument)) {
      if (values[argument]) {
        throw new ArtifactVerificationError(
          "ARGUMENT_INVALID",
          `Duplicate argument ${argument}`,
        );
      }
      values[argument] = true;
      continue;
    }
    if (
      (!singletonValues.has(argument) && !repeatable.has(argument)) ||
      !argv[index + 1] ||
      argv[index + 1].startsWith("--")
    ) {
      throw new ArtifactVerificationError(
        "ARGUMENT_INVALID",
        `Invalid argument ${argument}`,
      );
    }
    if (repeatable.has(argument)) {
      values[argument] ||= [];
      values[argument].push(argv[index + 1]);
    } else {
      if (values[argument] !== undefined) {
        throw new ArtifactVerificationError(
          "ARGUMENT_INVALID",
          `Duplicate argument ${argument}`,
        );
      }
      values[argument] = argv[index + 1];
    }
    index += 1;
  }

  return values;
}

async function main() {
  const args = parseArguments(process.argv.slice(2));
  if (args["--help"]) {
    process.stdout.write(USAGE);
    return;
  }

  const metaArguments = [
    ...(args["--meta"] || []),
    process.env.CANNON_REYA_NETWORK_META_CIDS || "",
  ];
  const allowedHosts = [
    ...(args["--allowed-host"] || []),
    process.env.CANNON_ALLOWED_ARTIFACT_HOSTS || "",
  ];
  const manifest = await verifyArtifactClosure({
    endpoint: args["--endpoint"] || process.env.CANNON_IPFS_URL,
    rootCid: args["--root"] || process.env.CANNON_REYA_NETWORK_BASE_CID,
    metaCids: metaArguments
      .flatMap((value) => value.split(","))
      .map((value) => value.trim())
      .filter(Boolean),
    expectedPackageRef:
      args["--package-ref"] || process.env.CANNON_REYA_NETWORK_PACKAGE_REF,
    expectedChainId:
      args["--chain-id"] || process.env.CANNON_REYA_NETWORK_CHAIN_ID,
    expectedArtifactSourceSha:
      args["--artifact-source-sha"] ||
      process.env.CANNON_REYA_NETWORK_SOURCE_SHA,
    verificationSha: args["--verification-sha"] || process.env.GITHUB_SHA,
    verificationRepository:
      args["--verification-repository"] || process.env.GITHUB_REPOSITORY,
    workflowRunId: process.env.GITHUB_RUN_ID,
    workflowRunAttempt: process.env.GITHUB_RUN_ATTEMPT,
    maxArtifacts: args["--max-artifacts"],
    maxReferences: args["--max-references"],
    maxCompressedBytes: args["--max-compressed-bytes"],
    maxInflatedBytes: args["--max-inflated-bytes"],
    maxTotalCompressedBytes: args["--max-total-compressed-bytes"],
    maxTotalInflatedBytes: args["--max-total-inflated-bytes"],
    allowedHosts: allowedHosts
      .flatMap((value) => value.split(","))
      .map((value) => value.trim())
      .filter(Boolean),
    requireReyaEndpoint:
      args["--require-reya-endpoint"] ||
      booleanEnvironmentValue(
        process.env.CANNON_REQUIRE_REYA_ENDPOINT,
        "CANNON_REQUIRE_REYA_ENDPOINT",
      ),
    allowInsecureLocalhost: args["--allow-insecure-localhost"],
  });

  const serialized = `${JSON.stringify(manifest, null, 2)}\n`;
  const outputPath = args["--out"];
  if (outputPath) {
    const absolutePath = resolve(outputPath);
    await mkdir(dirname(absolutePath), { recursive: true });
    await writeFile(absolutePath, serialized, {
      encoding: "utf8",
      mode: 0o600,
    });
  } else {
    process.stdout.write(serialized);
  }
}

const isMain =
  process.argv[1] &&
  import.meta.url === pathToFileURL(resolve(process.argv[1])).href;
if (isMain) {
  main().catch((error) => {
    const code =
      error instanceof ArtifactVerificationError
        ? error.code
        : "ARTIFACT_VERIFICATION_FAILED";
    process.stderr.write(`${code}: ${error.message}\n`);
    process.exitCode = 1;
  });
}
