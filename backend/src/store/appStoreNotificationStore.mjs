import { decodeCompactJWS, isActiveTransactionPayload, transactionDatesFromPayload } from "../appStore/jws.mjs";
import { backend } from "./storageBackend.mjs";
import { setProStatus } from "../quota/quotaManager.mjs";

export async function processServerNotification(body) {
  const store = await backend();
  const signedPayload = stringValue(body.signedPayload);
  const notification = decodeCompactJWS(signedPayload).payload;
  const transactionPayload = decodeNestedJWS(notification.data?.signedTransactionInfo);
  const renewalPayload = decodeNestedJWS(notification.data?.signedRenewalInfo);
  const notificationUUID = stringValue(notification.notificationUUID);

  if (!notificationUUID) {
    throwRequestError("Missing App Store notification UUID.");
  }

  await store.upsertNotificationRecord({
    notificationUUID,
    notificationType: stringValue(notification.notificationType),
    subtype: nullableString(notification.subtype),
    environment: nullableString(notification.data?.environment),
    appAccountToken: nullableString(transactionPayload?.appAccountToken),
    originalTransactionId: nullableString(transactionPayload?.originalTransactionId),
    transactionId: nullableString(transactionPayload?.transactionId),
    productId: nullableString(transactionPayload?.productId),
    signedPayload,
    decodedPayload: {
      notification,
      transaction: transactionPayload,
      renewal: renewalPayload
    },
    receivedAt: store.nowISO()
  });

  const updatedSubscriptions = transactionPayload
    ? await applyTransactionNotification(store, notification, transactionPayload, body)
    : 0;

  return {
    status: "ok",
    notificationType: notification.notificationType,
    updatedSubscriptions
  };
}

async function applyTransactionNotification(store, notification, transactionPayload, rawBody) {
  const originalTransactionId = stringValue(transactionPayload.originalTransactionId);
  const appAccountToken = stringValue(transactionPayload.appAccountToken);
  if (!originalTransactionId && !appAccountToken) {
    return 0;
  }

  const matchingRows = await store.findSubscriptionRecords({ originalTransactionId, appAccountToken });

  if (matchingRows.length === 0) {
    return 0;
  }

  const dates = transactionDatesFromPayload(transactionPayload);
  const isActive = isActiveTransactionPayload(transactionPayload, dates.expirationDate);
  const updatedAt = store.nowISO();

  for (const row of matchingRows) {
    await store.upsertSubscriptionRecord({
      ...row,
      productId: stringValue(transactionPayload.productId),
      appAccountToken: nullableString(appAccountToken) ?? row.appAccountToken,
      transactionId: stringValue(transactionPayload.transactionId),
      environment: nullableString(notification.data?.environment),
      purchaseDate: dates.purchaseDate ?? row.purchaseDate,
      expirationDate: dates.expirationDate,
      verificationStatus: "app_store_server_notification",
      rawPayload: rawBody,
      updatedAt
    });
    await setProStatus(row.userId, isActive);
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
