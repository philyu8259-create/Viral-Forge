import { createSign } from "node:crypto";
import { existsSync, readFileSync } from "node:fs";
import { base64URLEncode, decodeCompactJWS, validateTransactionPayload } from "./jws.mjs";

const productionBaseURL = "https://api.storekit.itunes.apple.com";
const sandboxBaseURL = "https://api.storekit-sandbox.itunes.apple.com";

export async function verifyTransactionWithAppStore({ transactionId, productId, originalTransactionId, appAccountToken }) {
  const response = await fetchAppStoreServerAPI(`/inApps/v1/transactions/${encodeURIComponent(transactionId)}`);
  const signedTransactionInfo = response.signedTransactionInfo;
  const decoded = decodeCompactJWS(signedTransactionInfo);

  validateTransactionPayload({
    payload: decoded.payload,
    productId,
    transactionId,
    originalTransactionId,
    appAccountToken
  });

  return {
    signedTransactionInfo,
    payload: decoded.payload
  };
}

export function appStoreServerStatus() {
  const config = appStoreServerConfig();
  return {
    mode: process.env.IAP_VERIFICATION_MODE ?? "local_development",
    environment: config.environment,
    configured: Boolean(config.issuerId && config.keyId && config.bundleId && config.privateKey),
    hasIssuerId: Boolean(config.issuerId),
    hasKeyId: Boolean(config.keyId),
    hasBundleId: Boolean(config.bundleId),
    hasPrivateKey: Boolean(config.privateKey)
  };
}

async function fetchAppStoreServerAPI(path) {
  const config = appStoreServerConfig();
  assertConfigured(config);

  const response = await fetch(`${baseURLForEnvironment(config.environment)}${path}`, {
    headers: {
      Authorization: `Bearer ${signAppStoreServerJWT(config)}`,
      Accept: "application/json"
    }
  });

  if (!response.ok) {
    const body = await safeReadBody(response);
    const error = new Error(`App Store Server API request failed with ${response.status}. ${body}`.trim());
    error.statusCode = response.status === 401 ? 502 : 400;
    throw error;
  }

  return response.json();
}

function signAppStoreServerJWT(config) {
  const now = Math.floor(Date.now() / 1000);
  const header = {
    alg: "ES256",
    kid: config.keyId,
    typ: "JWT"
  };
  const payload = {
    iss: config.issuerId,
    iat: now,
    exp: now + 300,
    aud: "appstoreconnect-v1",
    bid: config.bundleId
  };
  const signingInput = `${base64URLEncode(JSON.stringify(header))}.${base64URLEncode(JSON.stringify(payload))}`;
  const signature = createSign("SHA256")
    .update(signingInput)
    .end()
    .sign({ key: config.privateKey, dsaEncoding: "ieee-p1363" });

  return `${signingInput}.${base64URLEncode(signature)}`;
}

function appStoreServerConfig() {
  return {
    environment: process.env.APP_STORE_SERVER_ENVIRONMENT === "production" ? "production" : "sandbox",
    issuerId: process.env.APP_STORE_SERVER_ISSUER_ID ?? "",
    keyId: process.env.APP_STORE_SERVER_KEY_ID ?? "",
    bundleId: process.env.APP_STORE_SERVER_BUNDLE_ID ?? "com.phil.viralforge",
    privateKey: privateKeyFromEnv()
  };
}

function privateKeyFromEnv() {
  if (process.env.APP_STORE_SERVER_PRIVATE_KEY) {
    return process.env.APP_STORE_SERVER_PRIVATE_KEY.replaceAll("\\n", "\n");
  }

  const path = process.env.APP_STORE_SERVER_PRIVATE_KEY_PATH;
  if (path && existsSync(path)) {
    return readFileSync(path, "utf8");
  }

  return "";
}

function assertConfigured(config) {
  const missing = [];
  if (!config.issuerId) missing.push("APP_STORE_SERVER_ISSUER_ID");
  if (!config.keyId) missing.push("APP_STORE_SERVER_KEY_ID");
  if (!config.bundleId) missing.push("APP_STORE_SERVER_BUNDLE_ID");
  if (!config.privateKey) missing.push("APP_STORE_SERVER_PRIVATE_KEY or APP_STORE_SERVER_PRIVATE_KEY_PATH");

  if (missing.length > 0) {
    const error = new Error(`App Store Server API is not configured. Missing: ${missing.join(", ")}.`);
    error.statusCode = 500;
    throw error;
  }
}

function baseURLForEnvironment(environment) {
  return environment === "production" ? productionBaseURL : sandboxBaseURL;
}

async function safeReadBody(response) {
  try {
    return await response.text();
  } catch {
    return "";
  }
}
