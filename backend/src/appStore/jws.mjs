export function decodeCompactJWS(jws) {
  if (!jws || typeof jws !== "string") {
    throwRequestError("Missing signed payload.");
  }

  const parts = jws.split(".");
  if (parts.length !== 3) {
    throwRequestError("Invalid signed payload.");
  }

  return {
    header: decodeBase64URLJSON(parts[0]),
    payload: decodeBase64URLJSON(parts[1]),
    signature: parts[2],
    compact: jws
  };
}

export function validateTransactionPayload({ payload, productId, transactionId, originalTransactionId, appAccountToken }) {
  if (!payload || typeof payload !== "object") {
    throwRequestError("Invalid signed transaction payload.");
  }

  assertMatchingValue(payload.productId, productId, "productId");
  assertMatchingValue(payload.transactionId, transactionId, "transactionId");
  assertMatchingValue(payload.originalTransactionId, originalTransactionId, "originalTransactionId");
  assertMatchingValue(payload.appAccountToken, appAccountToken, "appAccountToken");

  if (payload.expiresDate && Number(payload.expiresDate) <= Date.now()) {
    throwRequestError("StoreKit transaction is expired.");
  }
}

export function transactionDatesFromPayload(payload, fallback = {}) {
  return {
    purchaseDate: millisToISO(payload?.purchaseDate) ?? fallback.purchaseDate ?? null,
    expirationDate: millisToISO(payload?.expiresDate) ?? fallback.expirationDate ?? null,
    revocationDate: millisToISO(payload?.revocationDate) ?? null
  };
}

export function isActiveTransactionPayload(payload, fallbackExpirationDate = null) {
  if (payload?.revocationDate) {
    return false;
  }

  const expirationDate = millisToISO(payload?.expiresDate) ?? fallbackExpirationDate;
  return !expirationDate || new Date(expirationDate).getTime() > Date.now();
}

export function base64URLToBuffer(value) {
  return Buffer.from(base64URLToBase64(value), "base64");
}

export function base64URLEncode(value) {
  return Buffer.from(value).toString("base64url");
}

function decodeBase64URLJSON(value) {
  try {
    return JSON.parse(base64URLToBuffer(value).toString("utf8"));
  } catch {
    throwRequestError("Invalid signed payload encoding.");
  }
}

function base64URLToBase64(value) {
  const padded = value.padEnd(value.length + ((4 - (value.length % 4)) % 4), "=");
  return padded.replaceAll("-", "+").replaceAll("_", "/");
}

function millisToISO(value) {
  if (value == null || value === "") {
    return null;
  }

  const millis = Number(value);
  if (!Number.isFinite(millis)) {
    return null;
  }

  return new Date(millis).toISOString();
}

function assertMatchingValue(actual, expected, fieldName) {
  if (actual == null) {
    return;
  }

  if (String(actual) !== String(expected)) {
    throwRequestError(`StoreKit signed transaction ${fieldName} mismatch.`);
  }
}

function throwRequestError(message) {
  const error = new Error(message);
  error.statusCode = 400;
  throw error;
}
