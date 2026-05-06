import TableStore from "tablestore";

const tableName = requiredEnv("TABLESTORE_TABLE_NAME");
const client = new TableStore.Client({
  accessKeyId: process.env.TABLESTORE_ACCESS_KEY_ID ?? process.env.ALIBABA_CLOUD_ACCESS_KEY_ID,
  secretAccessKey: process.env.TABLESTORE_ACCESS_KEY_SECRET ?? process.env.ALIBABA_CLOUD_ACCESS_KEY_SECRET,
  stsToken: process.env.TABLESTORE_SECURITY_TOKEN ?? process.env.ALIBABA_CLOUD_SECURITY_TOKEN,
  endpoint: requiredEnv("TABLESTORE_ENDPOINT"),
  instancename: requiredEnv("TABLESTORE_INSTANCE")
});

export function nowISO() {
  return new Date().toISOString();
}

export function parseJSON(value, fallback = null) {
  try {
    return JSON.parse(value);
  } catch {
    return fallback;
  }
}

export async function getQuotaRecord(userId) {
  const row = await getRecord(userPK(userId), "quota");
  if (!row) return null;
  return {
    remaining_text_generations: Number(row.remainingTextGenerations ?? 0),
    remaining_poster_exports: Number(row.remainingPosterExports ?? 0),
    is_pro: row.isPro ? 1 : 0
  };
}

export async function putQuotaRecord(userId, quota) {
  await putRecord(userPK(userId), "quota", {
    type: "quota",
    remainingTextGenerations: quota.remainingTextGenerations,
    remainingPosterExports: quota.remainingPosterExports,
    isPro: Boolean(quota.isPro),
    updatedAt: nowISO()
  });
}

export async function getBrandRecord(userId) {
  const row = await getRecord(userPK(userId), "brand");
  return row ? { profile_json: row.profileJson } : null;
}

export async function putBrandRecord(userId, profile) {
  await putRecord(userPK(userId), "brand", {
    type: "brand",
    profileJson: JSON.stringify(profile),
    updatedAt: nowISO()
  });
}

export async function saveProjectRecord(userId, project) {
  await putRecord(userPK(userId), `project#${project.projectId}`, {
    type: "project",
    userId,
    projectId: project.projectId,
    createdAt: project.createdAt,
    updatedAt: project.updatedAt,
    payloadJson: JSON.stringify(project)
  });
}

export async function listProjectRecords(userId) {
  const rows = await listRecords(userPK(userId), "project#");
  return rows
    .map((row) => parseJSON(row.payloadJson, {}))
    .sort((a, b) => String(b.createdAt ?? "").localeCompare(String(a.createdAt ?? "")));
}

export async function deleteProjectRecord(userId, projectId) {
  const existing = await getRecord(userPK(userId), `project#${projectId}`);
  if (!existing) return false;
  await deleteRecord(userPK(userId), `project#${projectId}`);
  return true;
}

export async function resetProjectRecords() {
  // Test helper only. Tablestore production data should not be wiped from app code.
}

export async function upsertSubscriptionRecord(subscription) {
  const payload = normalizeSubscription(subscription);
  const userKey = userPK(subscription.userId);
  const subscriptionKey = `subscription#${subscription.originalTransactionId}`;
  await putRecord(userKey, subscriptionKey, payload);
  await putRecord(`subscription_original#${subscription.originalTransactionId}`, userKey, payload);
  if (subscription.appAccountToken) {
    await putRecord(`subscription_token#${subscription.appAccountToken}`, userKey, payload);
  }
}

export async function latestSubscriptionRecord(userId) {
  const rows = await listRecords(userPK(userId), "subscription#");
  const latest = rows.sort((a, b) => String(b.updatedAt ?? "").localeCompare(String(a.updatedAt ?? "")))[0];
  if (!latest) return null;
  return sqliteSubscriptionShape(latest);
}

export async function findSubscriptionRecords({ originalTransactionId, appAccountToken }) {
  const byOriginal = originalTransactionId
    ? await listRecords(`subscription_original#${originalTransactionId}`)
    : [];
  const byToken = appAccountToken
    ? await listRecords(`subscription_token#${appAccountToken}`)
    : [];
  const seen = new Set();
  return [...byOriginal, ...byToken]
    .filter((row) => {
      const key = `${row.userId}:${row.originalTransactionId}`;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    })
    .map((row) => ({
      userId: row.userId,
      productId: row.productId,
      transactionId: row.transactionId,
      originalTransactionId: row.originalTransactionId,
      appAccountToken: row.appAccountToken,
      environment: row.environment,
      purchaseDate: row.purchaseDate,
      expirationDate: row.expirationDate,
      verificationStatus: row.verificationStatus,
      rawPayload: parseJSON(row.rawPayloadJson, {}),
      updatedAt: row.updatedAt
    }));
}

export async function upsertNotificationRecord(notification) {
  await putRecord("notification", notification.notificationUUID, {
    type: "notification",
    notificationUUID: notification.notificationUUID,
    notificationType: notification.notificationType,
    subtype: notification.subtype,
    environment: notification.environment,
    appAccountToken: notification.appAccountToken,
    originalTransactionId: notification.originalTransactionId,
    transactionId: notification.transactionId,
    productId: notification.productId,
    signedPayload: notification.signedPayload,
    decodedPayloadJson: JSON.stringify(notification.decodedPayload),
    receivedAt: notification.receivedAt
  });
}

async function getRecord(pk, sk) {
  const data = await call("getRow", {
    tableName,
    primaryKey: [{ pk }, { sk }],
    maxVersions: 1
  });
  if (!data.row) return null;
  const attributes = data.row.attributes ?? data.row.attributeColumns ?? data.row.attribute_columns ?? [];
  if (attributes.length === 0) return null;
  return rowToObject(data.row);
}

async function putRecord(pk, sk, attributes) {
  await call("putRow", {
    tableName,
    primaryKey: [{ pk }, { sk }],
    attributeColumns: objectToAttributes(attributes),
    condition: new TableStore.Condition(TableStore.RowExistenceExpectation.IGNORE, null)
  });
}

async function deleteRecord(pk, sk) {
  await call("deleteRow", {
    tableName,
    primaryKey: [{ pk }, { sk }],
    condition: new TableStore.Condition(TableStore.RowExistenceExpectation.IGNORE, null)
  });
}

async function listRecords(pk, skPrefix = "") {
  const rows = [];
  let inclusiveStartPrimaryKey = [{ pk }, { sk: skPrefix || TableStore.INF_MIN }];
  const exclusiveEndPrimaryKey = [{ pk }, { sk: TableStore.INF_MAX }];

  while (inclusiveStartPrimaryKey) {
    const data = await call("getRange", {
      tableName,
      direction: TableStore.Direction.FORWARD,
      inclusiveStartPrimaryKey,
      exclusiveEndPrimaryKey,
      maxVersions: 1,
      limit: 100
    });

    for (const row of data.rows ?? []) {
      const parsed = rowToObject(row);
      if (skPrefix && !String(parsed.sk ?? "").startsWith(skPrefix)) {
        continue;
      }
      rows.push(parsed);
    }
    inclusiveStartPrimaryKey = data.nextStartPrimaryKey ?? data.next_start_primary_key ?? null;
  }

  return rows;
}

function rowToObject(row) {
  const result = {};
  for (const primaryKey of row.primaryKey ?? row.primary_key ?? []) {
    mergeColumn(result, primaryKey);
  }
  for (const attribute of row.attributes ?? row.attributeColumns ?? row.attribute_columns ?? []) {
    mergeColumn(result, attribute);
  }
  return result;
}

function mergeColumn(target, column) {
  if (column.columnName !== undefined) {
    target[column.columnName] = normalizeValue(column.columnValue);
    return;
  }

  if (column.name !== undefined) {
    target[column.name] = normalizeValue(column.value);
    return;
  }

  for (const [key, value] of Object.entries(column)) {
    if (key === "timestamp") continue;
    target[key] = normalizeValue(value);
    return;
  }
}

function objectToAttributes(object) {
  return Object.entries(object)
    .filter(([, value]) => value !== undefined)
    .map(([key, value]) => ({ [key]: value === null ? "" : value }));
}

function normalizeValue(value) {
  if (value && typeof value === "object" && typeof value.toNumber === "function") {
    return value.toNumber();
  }
  if (value && typeof value === "object" && typeof value.toString === "function" && value.low !== undefined && value.high !== undefined) {
    return value.toString();
  }
  return value;
}

function call(method, params) {
  return new Promise((resolve, reject) => {
    client[method](params, (error, data) => {
      if (error) {
        reject(error);
        return;
      }
      resolve(data);
    });
  });
}

function normalizeSubscription(subscription) {
  return {
    type: "subscription",
    userId: subscription.userId,
    productId: subscription.productId,
    appAccountToken: subscription.appAccountToken,
    originalTransactionId: subscription.originalTransactionId,
    transactionId: subscription.transactionId,
    environment: subscription.environment,
    purchaseDate: subscription.purchaseDate,
    expirationDate: subscription.expirationDate,
    verificationStatus: subscription.verificationStatus,
    rawPayloadJson: JSON.stringify(subscription.rawPayload),
    updatedAt: subscription.updatedAt
  };
}

function sqliteSubscriptionShape(row) {
  return {
    product_id: row.productId,
    transaction_id: row.transactionId,
    original_transaction_id: row.originalTransactionId,
    app_account_token: row.appAccountToken,
    expiration_date: row.expirationDate,
    verification_status: row.verificationStatus
  };
}

function userPK(userId) {
  return `user#${userId}`;
}

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`${name} is required when DATA_STORE=tablestore.`);
  }
  return value;
}
