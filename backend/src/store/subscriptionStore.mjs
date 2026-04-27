import { db, nowISO } from "../db/database.mjs";
import { decodeCompactJWS, isActiveTransactionPayload, transactionDatesFromPayload, validateTransactionPayload } from "../appStore/jws.mjs";
import { verifyTransactionWithAppStore } from "../appStore/serverAPI.mjs";
import { getQuota, setProStatus } from "../quota/quotaManager.mjs";

const allowedProductIds = new Set([
  "viralforge_pro_monthly",
  "viralforge_pro_yearly"
]);

export async function syncSubscription(userId, payload) {
  const productId = stringValue(payload.productId ?? payload.productID);
  const transactionId = stringValue(payload.transactionId ?? payload.transactionID);
  const originalTransactionId = stringValue(payload.originalTransactionId ?? payload.originalTransactionID ?? transactionId);
  const appAccountToken = nullableString(payload.appAccountToken);
  const signedTransactionInfo = stringValue(payload.signedTransactionInfo);

  if (!allowedProductIds.has(productId)) {
    throwRequestError("Unsupported subscription product.");
  }

  if (!transactionId || !originalTransactionId) {
    throwRequestError("Missing StoreKit transaction identifiers.");
  }

  let signedTransactionPayload = null;
  let appStoreServerSignedTransactionInfo = "";

  if (signedTransactionInfo) {
    signedTransactionPayload = decodeCompactJWS(signedTransactionInfo).payload;
    validateTransactionPayload({
      payload: signedTransactionPayload,
      productId,
      transactionId,
      originalTransactionId,
      appAccountToken
    });
  }

  let payloadDates = signedTransactionPayload
    ? transactionDatesFromPayload(signedTransactionPayload)
    : {};
  let purchaseDate = payloadDates.purchaseDate ?? optionalDateString(payload.purchaseDate);
  let expirationDate = payloadDates.expirationDate ?? optionalDateString(payload.expirationDate);
  let isActive = signedTransactionPayload
    ? isActiveTransactionPayload(signedTransactionPayload, expirationDate)
    : (!expirationDate || new Date(expirationDate).getTime() > Date.now());
  let verificationStatus = verificationStatusForCurrentMode(Boolean(signedTransactionInfo));

  if (currentVerificationMode() === "app_store_server") {
    const verified = await verifyTransactionWithAppStore({
      transactionId,
      productId,
      originalTransactionId,
      appAccountToken
    });
    signedTransactionPayload = verified.payload;
    appStoreServerSignedTransactionInfo = verified.signedTransactionInfo;
    payloadDates = transactionDatesFromPayload(signedTransactionPayload, {
      purchaseDate,
      expirationDate
    });
    purchaseDate = payloadDates.purchaseDate;
    expirationDate = payloadDates.expirationDate;
    isActive = isActiveTransactionPayload(signedTransactionPayload, expirationDate);
    verificationStatus = "app_store_server_verified";
  }

  const updatedAt = nowISO();
  const rawPayload = {
    ...payload,
    appStoreServerSignedTransactionInfo: appStoreServerSignedTransactionInfo || undefined
  };

  db.prepare(`
    INSERT INTO subscriptions (
      user_id,
      product_id,
      app_account_token,
      original_transaction_id,
      transaction_id,
      environment,
      purchase_date,
      expiration_date,
      verification_status,
      raw_payload_json,
      updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(user_id, original_transaction_id) DO UPDATE SET
      product_id = excluded.product_id,
      app_account_token = COALESCE(excluded.app_account_token, subscriptions.app_account_token),
      transaction_id = excluded.transaction_id,
      environment = excluded.environment,
      purchase_date = excluded.purchase_date,
      expiration_date = excluded.expiration_date,
      verification_status = excluded.verification_status,
      raw_payload_json = excluded.raw_payload_json,
      updated_at = excluded.updated_at
  `).run(
    userId,
    productId,
    appAccountToken,
    originalTransactionId,
    transactionId,
    stringValue(payload.environment),
    purchaseDate,
    expirationDate,
    verificationStatus,
    JSON.stringify(rawPayload),
    updatedAt
  );

  const quota = setProStatus(userId, isActive);
  return {
    ...quota,
    subscription: {
      productId,
      transactionId,
      originalTransactionId,
      isActive,
      verificationStatus,
      expiresAt: expirationDate
    }
  };
}

export function currentSubscription(userId) {
  const row = db.prepare(`
    SELECT product_id, transaction_id, original_transaction_id, app_account_token, expiration_date, verification_status
    FROM subscriptions
    WHERE user_id = ?
    ORDER BY updated_at DESC
    LIMIT 1
  `).get(userId);

  const quota = getQuota(userId);
  if (!row) {
    return {
      ...quota,
      subscription: null
    };
  }

  return {
    ...quota,
    subscription: {
      productId: row.product_id,
      transactionId: row.transaction_id,
      originalTransactionId: row.original_transaction_id,
      appAccountToken: row.app_account_token,
      isActive: quota.isPro,
      verificationStatus: row.verification_status,
      expiresAt: row.expiration_date
    }
  };
}

function verificationStatusForCurrentMode(hasSignedTransactionInfo) {
  if (hasSignedTransactionInfo) {
    return "client_verified_signed_payload_checked";
  }
  return "client_verified_local";
}

function currentVerificationMode() {
  return process.env.IAP_VERIFICATION_MODE ?? "local_development";
}

function stringValue(value) {
  return value == null ? "" : String(value);
}

function nullableString(value) {
  const string = stringValue(value);
  return string || null;
}

function optionalDateString(value) {
  if (!value) {
    return null;
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throwRequestError("Invalid subscription date.");
  }
  return date.toISOString();
}

function throwRequestError(message) {
  const error = new Error(message);
  error.statusCode = 400;
  throw error;
}
