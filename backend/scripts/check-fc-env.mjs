const env = process.env;
const missing = [];
const warnings = [];

requireEquals("AI_PROVIDER_MODE", "china_live");
requireEquals("DATA_STORE", "tablestore");
requireValue("QWEN_API_KEY");

if (!hasValue("SEEDREAM_API_KEY") && !hasValue("ARK_API_KEY")) {
  missing.push("SEEDREAM_API_KEY or ARK_API_KEY");
}

requireValue("TABLESTORE_ENDPOINT");
requireValue("TABLESTORE_INSTANCE");
requireValue("TABLESTORE_TABLE_NAME");

const usesContextCredentials = env.USE_CONTEXT_CREDENTIALS === "1";

if (!usesContextCredentials && !hasValue("TABLESTORE_ACCESS_KEY_ID") && !hasValue("ALIBABA_CLOUD_ACCESS_KEY_ID")) {
  missing.push("TABLESTORE_ACCESS_KEY_ID or ALIBABA_CLOUD_ACCESS_KEY_ID");
}

if (!usesContextCredentials && !hasValue("TABLESTORE_ACCESS_KEY_SECRET") && !hasValue("ALIBABA_CLOUD_ACCESS_KEY_SECRET")) {
  missing.push("TABLESTORE_ACCESS_KEY_SECRET or ALIBABA_CLOUD_ACCESS_KEY_SECRET");
}

if (env.IAP_VERIFICATION_MODE === "app_store_server") {
  requireValue("APP_STORE_SERVER_ENVIRONMENT");
  requireValue("APP_STORE_SERVER_ISSUER_ID");
  requireValue("APP_STORE_SERVER_KEY_ID");
  requireValue("APP_STORE_SERVER_BUNDLE_ID");
  if (!hasValue("APP_STORE_SERVER_PRIVATE_KEY_PATH") && !hasValue("APP_STORE_SERVER_PRIVATE_KEY")) {
    missing.push("APP_STORE_SERVER_PRIVATE_KEY_PATH or APP_STORE_SERVER_PRIVATE_KEY");
  }
} else {
  warnings.push("IAP_VERIFICATION_MODE is not app_store_server.");
}

if (missing.length > 0) {
  console.error("FC deployment env check failed:");
  for (const key of missing) {
    console.error(`- Missing or invalid: ${key}`);
  }
  process.exit(1);
}

console.log("FC deployment env check passed.");
for (const warning of warnings) {
  console.warn(`Warning: ${warning}`);
}

function hasValue(key) {
  return Boolean(env[key] && env[key].trim());
}

function requireValue(key) {
  if (!hasValue(key)) {
    missing.push(key);
  }
}

function requireEquals(key, expected) {
  if (env[key] !== expected) {
    missing.push(`${key}=${expected}`);
  }
}
