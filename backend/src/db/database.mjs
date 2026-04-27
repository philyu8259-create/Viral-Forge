import { mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { DatabaseSync } from "node:sqlite";

const databasePath = resolve(process.env.SQLITE_PATH ?? "./data/viralforge.sqlite");
mkdirSync(dirname(databasePath), { recursive: true });

export const db = new DatabaseSync(databasePath);

db.exec("PRAGMA journal_mode = WAL;");
db.exec("PRAGMA foreign_keys = ON;");

db.exec(`
  CREATE TABLE IF NOT EXISTS quota (
    user_id TEXT PRIMARY KEY,
    remaining_text_generations INTEGER NOT NULL,
    remaining_poster_exports INTEGER NOT NULL,
    is_pro INTEGER NOT NULL DEFAULT 0,
    updated_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS projects (
    user_id TEXT NOT NULL,
    project_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    input_json TEXT NOT NULL,
    result_json TEXT NOT NULL,
    payload_json TEXT NOT NULL,
    PRIMARY KEY (user_id, project_id)
  );

  CREATE TABLE IF NOT EXISTS brand_profiles (
    user_id TEXT PRIMARY KEY,
    profile_json TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS templates (
    template_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    platform TEXT NOT NULL,
    style TEXT NOT NULL,
    prompt_hint TEXT NOT NULL,
    locked_to_pro INTEGER NOT NULL DEFAULT 0,
    updated_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS subscriptions (
    user_id TEXT NOT NULL,
    product_id TEXT NOT NULL,
    app_account_token TEXT,
    original_transaction_id TEXT NOT NULL,
    transaction_id TEXT NOT NULL,
    environment TEXT,
    purchase_date TEXT,
    expiration_date TEXT,
    verification_status TEXT NOT NULL,
    raw_payload_json TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    PRIMARY KEY (user_id, original_transaction_id)
  );

  CREATE TABLE IF NOT EXISTS app_store_notifications (
    notification_uuid TEXT PRIMARY KEY,
    notification_type TEXT NOT NULL,
    subtype TEXT,
    environment TEXT,
    app_account_token TEXT,
    original_transaction_id TEXT,
    transaction_id TEXT,
    product_id TEXT,
    signed_payload TEXT NOT NULL,
    decoded_payload_json TEXT NOT NULL,
    received_at TEXT NOT NULL
  );
`);

ensureColumn("subscriptions", "app_account_token", "TEXT");
ensureColumn("app_store_notifications", "app_account_token", "TEXT");

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

function ensureColumn(tableName, columnName, columnDefinition) {
  const columns = db.prepare(`PRAGMA table_info(${tableName})`).all();
  if (columns.some((column) => column.name === columnName)) {
    return;
  }

  db.exec(`ALTER TABLE ${tableName} ADD COLUMN ${columnName} ${columnDefinition}`);
}
