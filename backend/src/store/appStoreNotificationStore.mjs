import { decodeCompactJWS, isActiveTransactionPayload, transactionDatesFromPayload } from "../appStore/jws.mjs";
import { db, nowISO } from "../db/database.mjs";
import { setProStatus } from "../quota/quotaManager.mjs";

export function processServerNotification(body) {
  const signedPayload = stringValue(body.signedPayload);
  const notification = decodeCompactJWS(signedPayload).payload;
  const transactionPayload = decodeNestedJWS(notification.data?.signedTransactionInfo);
  const renewalPayload = decodeNestedJWS(notification.data?.signedRenewalInfo);
  const notificationUUID = stringValue(notification.notificationUUID);

  if (!notificationUUID) {
    throwRequestError("Missing App Store notification UUID.");
  }

  db.prepare(`
    INSERT INTO app_store_notifications (
      notification_uuid,
      notification_type,
      subtype,
      environment,
      app_account_token,
      original_transaction_id,
      transaction_id,
      product_id,
      signed_payload,
      decoded_payload_json,
      received_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(notification_uuid) DO UPDATE SET
      notification_type = excluded.notification_type,
      subtype = excluded.subtype,
      environment = excluded.environment,
      app_account_token = excluded.app_account_token,
      original_transaction_id = excluded.original_transaction_id,
      transaction_id = excluded.transaction_id,
      product_id = excluded.product_id,
      signed_payload = excluded.signed_payload,
      decoded_payload_json = excluded.decoded_payload_json,
      received_at = excluded.received_at
  `).run(
    notificationUUID,
    stringValue(notification.notificationType),
    nullableString(notification.subtype),
    nullableString(notification.data?.environment),
    nullableString(transactionPayload?.appAccountToken),
    nullableString(transactionPayload?.originalTransactionId),
    nullableString(transactionPayload?.transactionId),
    nullableString(transactionPayload?.productId),
    signedPayload,
    JSON.stringify({
      notification,
      transaction: transactionPayload,
      renewal: renewalPayload
    }),
    nowISO()
  );

  const updatedSubscriptions = transactionPayload
    ? applyTransactionNotification(notification, transactionPayload, body)
    : 0;

  return {
    status: "ok",
    notificationType: notification.notificationType,
    updatedSubscriptions
  };
}

function applyTransactionNotification(notification, transactionPayload, rawBody) {
  const originalTransactionId = stringValue(transactionPayload.originalTransactionId);
  const appAccountToken = stringValue(transactionPayload.appAccountToken);
  if (!originalTransactionId && !appAccountToken) {
    return 0;
  }

  const matchingRows = db.prepare(`
    SELECT user_id
    FROM subscriptions
    WHERE original_transaction_id = ?
       OR (? != '' AND app_account_token = ?)
  `).all(originalTransactionId, appAccountToken, appAccountToken);

  if (matchingRows.length === 0) {
    return 0;
  }

  const dates = transactionDatesFromPayload(transactionPayload);
  const isActive = isActiveTransactionPayload(transactionPayload, dates.expirationDate);
  const updatedAt = nowISO();

  db.prepare(`
    UPDATE subscriptions
    SET product_id = ?,
        app_account_token = COALESCE(?, app_account_token),
        transaction_id = ?,
        environment = ?,
        purchase_date = COALESCE(?, purchase_date),
        expiration_date = ?,
        verification_status = ?,
        raw_payload_json = ?,
        updated_at = ?
    WHERE original_transaction_id = ?
       OR (? != '' AND app_account_token = ?)
  `).run(
    stringValue(transactionPayload.productId),
    nullableString(appAccountToken),
    stringValue(transactionPayload.transactionId),
    nullableString(notification.data?.environment),
    dates.purchaseDate,
    dates.expirationDate,
    "app_store_server_notification",
    JSON.stringify(rawBody),
    updatedAt,
    originalTransactionId,
    appAccountToken,
    appAccountToken
  );

  for (const row of matchingRows) {
    setProStatus(row.user_id, isActive);
  }

  return matchingRows.length;
}

function decodeNestedJWS(jws) {
  if (!jws) {
    return null;
  }

  return decodeCompactJWS(jws).payload;
}

function stringValue(value) {
  return value == null ? "" : String(value);
}

function nullableString(value) {
  const string = stringValue(value);
  return string || null;
}

function throwRequestError(message) {
  const error = new Error(message);
  error.statusCode = 400;
  throw error;
}
