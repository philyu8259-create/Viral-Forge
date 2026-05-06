import { db, nowISO, parseJSON } from "../db/database.mjs";

export { nowISO, parseJSON };

export async function getQuotaRecord(userId) {
  return db.prepare(`
    SELECT remaining_text_generations, remaining_poster_exports, is_pro
    FROM quota
    WHERE user_id = ?
  `).get(userId);
}

export async function putQuotaRecord(userId, quota) {
  db.prepare(`
    INSERT INTO quota (
      user_id,
      remaining_text_generations,
      remaining_poster_exports,
      is_pro,
      updated_at
    ) VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(user_id) DO UPDATE SET
      remaining_text_generations = excluded.remaining_text_generations,
      remaining_poster_exports = excluded.remaining_poster_exports,
      is_pro = excluded.is_pro,
      updated_at = excluded.updated_at
  `).run(
    userId,
    quota.remainingTextGenerations,
    quota.remainingPosterExports,
    quota.isPro ? 1 : 0,
    nowISO()
  );
}

export async function getBrandRecord(userId) {
  return db.prepare(`
    SELECT profile_json
    FROM brand_profiles
    WHERE user_id = ?
  `).get(userId);
}

export async function putBrandRecord(userId, profile) {
  db.prepare(`
    INSERT INTO brand_profiles (
      user_id,
      profile_json,
      updated_at
    ) VALUES (?, ?, ?)
    ON CONFLICT(user_id) DO UPDATE SET
      profile_json = excluded.profile_json,
      updated_at = excluded.updated_at
  `).run(userId, JSON.stringify(profile), nowISO());
}

export async function saveProjectRecord(userId, project) {
  db.prepare(`
    INSERT INTO projects (
      user_id,
      project_id,
      created_at,
      updated_at,
      input_json,
      result_json,
      payload_json
    ) VALUES (?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(user_id, project_id) DO UPDATE SET
      updated_at = excluded.updated_at,
      input_json = excluded.input_json,
      result_json = excluded.result_json,
      payload_json = excluded.payload_json
  `).run(
    userId,
    project.projectId,
    project.createdAt,
    project.updatedAt,
    JSON.stringify(project.input ?? {}),
    JSON.stringify(project.result ?? {}),
    JSON.stringify(project)
  );
}

export async function listProjectRecords(userId) {
  return db.prepare(`
    SELECT payload_json
    FROM projects
    WHERE user_id = ?
    ORDER BY created_at DESC
  `)
    .all(userId)
    .map((row) => parseJSON(row.payload_json, {}));
}

export async function deleteProjectRecord(userId, projectId) {
  const result = db.prepare(`
    DELETE FROM projects
    WHERE user_id = ? AND project_id = ?
  `).run(userId, projectId);
  return result.changes > 0;
}

export async function resetProjectRecords() {
  db.exec("DELETE FROM projects;");
}

export async function upsertSubscriptionRecord(subscription) {
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
    subscription.userId,
    subscription.productId,
    subscription.appAccountToken,
    subscription.originalTransactionId,
    subscription.transactionId,
    subscription.environment,
    subscription.purchaseDate,
    subscription.expirationDate,
    subscription.verificationStatus,
    JSON.stringify(subscription.rawPayload),
    subscription.updatedAt
  );
}

export async function latestSubscriptionRecord(userId) {
  return db.prepare(`
    SELECT product_id, transaction_id, original_transaction_id, app_account_token, expiration_date, verification_status
    FROM subscriptions
    WHERE user_id = ?
    ORDER BY updated_at DESC
    LIMIT 1
  `).get(userId);
}

export async function findSubscriptionRecords({ originalTransactionId, appAccountToken }) {
  return db.prepare(`
    SELECT user_id, product_id, transaction_id, original_transaction_id, app_account_token, environment, purchase_date, expiration_date, verification_status, raw_payload_json, updated_at
    FROM subscriptions
    WHERE original_transaction_id = ?
       OR (? != '' AND app_account_token = ?)
  `).all(originalTransactionId, appAccountToken, appAccountToken)
    .map((row) => ({
      userId: row.user_id,
      productId: row.product_id,
      transactionId: row.transaction_id,
      originalTransactionId: row.original_transaction_id,
      appAccountToken: row.app_account_token,
      environment: row.environment,
      purchaseDate: row.purchase_date,
      expirationDate: row.expiration_date,
      verificationStatus: row.verification_status,
      rawPayload: parseJSON(row.raw_payload_json, {}),
      updatedAt: row.updated_at
    }));
}

export async function upsertNotificationRecord(notification) {
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
    notification.notificationUUID,
    notification.notificationType,
    notification.subtype,
    notification.environment,
    notification.appAccountToken,
    notification.originalTransactionId,
    notification.transactionId,
    notification.productId,
    notification.signedPayload,
    JSON.stringify(notification.decodedPayload),
    notification.receivedAt
  );
}
