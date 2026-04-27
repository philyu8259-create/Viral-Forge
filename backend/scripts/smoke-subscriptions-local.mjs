import { spawn } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const port = Number.parseInt(process.env.SUBSCRIPTION_SMOKE_PORT ?? "8793", 10);
const baseURL = `http://127.0.0.1:${port}`;
const tempDir = mkdtempSync(join(tmpdir(), "viralforge-subscription-smoke-"));
const sqlitePath = join(tempDir, "viralforge.sqlite");
const userId = "subscription-user";
const appAccountToken = "11111111-1111-4111-8111-111111111111";
const now = Date.now();
const oneDay = 24 * 60 * 60 * 1000;

const server = spawn(process.execPath, ["src/main.mjs"], {
  cwd: new URL("..", import.meta.url),
  env: {
    ...process.env,
    PORT: String(port),
    SQLITE_PATH: sqlitePath,
    AI_PROVIDER_MODE: "mock",
    IAP_VERIFICATION_MODE: "local_development"
  },
  stdio: ["ignore", "pipe", "pipe"]
});

let serverOutput = "";
server.stdout.on("data", (chunk) => {
  serverOutput += chunk.toString();
});
server.stderr.on("data", (chunk) => {
  serverOutput += chunk.toString();
});

try {
  await waitForHealth();
  await expectJSON("/health", (body) => body.status === "ok");
  await expectJSON("/api/app-store/status", (body) => body.mode === "local_development");

  const initialSubscription = await expectJSON(
    "/api/subscription",
    (body) => body.subscription === null && body.isPro === false,
    { "x-user-id": userId }
  );
  assert(initialSubscription.remainingTextGenerations === 3, "new subscription user starts with free quota");

  const monthlySync = await postJSON("/api/subscription/sync", {
    productId: "viralforge_pro_monthly",
    transactionId: "tx-monthly-active",
    originalTransactionId: "orig-monthly",
    environment: "Sandbox",
    purchaseDate: new Date(now - oneDay).toISOString(),
    expirationDate: new Date(now + 30 * oneDay).toISOString()
  });
  assert(monthlySync.isPro === true, "monthly local sync activates Pro");
  assert(monthlySync.subscription?.productId === "viralforge_pro_monthly", "monthly product ID is preserved");
  assert(monthlySync.subscription?.verificationStatus === "client_verified_local", "unsigned local sync status is recorded");

  const activeSubscription = await expectJSON(
    "/api/subscription",
    (body) => body.isPro === true && body.subscription?.isActive === true,
    { "x-user-id": userId }
  );
  assert(activeSubscription.subscription?.originalTransactionId === "orig-monthly", "active subscription can be read back");

  const unsupportedProduct = await postJSONExpectingStatus(
    "/api/subscription/sync",
    {
      productId: "viralforge_wrong_product",
      transactionId: "tx-wrong-product",
      originalTransactionId: "orig-wrong-product",
      expirationDate: new Date(now + oneDay).toISOString()
    },
    400
  );
  assert(unsupportedProduct.error?.message === "Unsupported subscription product.", "unsupported product is rejected");

  const yearlyTransaction = {
    productId: "viralforge_pro_yearly",
    transactionId: "tx-yearly-active",
    originalTransactionId: "orig-yearly",
    appAccountToken,
    purchaseDate: now - oneDay,
    expiresDate: now + 365 * oneDay
  };
  const yearlySync = await postJSON("/api/subscription/sync", {
    productId: yearlyTransaction.productId,
    transactionId: yearlyTransaction.transactionId,
    originalTransactionId: yearlyTransaction.originalTransactionId,
    appAccountToken,
    environment: "Sandbox",
    signedTransactionInfo: unsignedJWS(yearlyTransaction)
  });
  assert(yearlySync.isPro === true, "signed yearly sync activates Pro");
  assert(yearlySync.subscription?.productId === "viralforge_pro_yearly", "yearly product ID is preserved");
  assert(
    yearlySync.subscription?.verificationStatus === "client_verified_signed_payload_checked",
    "signed local sync validates transaction fields"
  );

  const expiredNotification = await postJSON("/api/app-store/notifications/v2", {
    signedPayload: unsignedJWS({
      notificationUUID: "sub-smoke-expired-1",
      notificationType: "EXPIRED",
      subtype: "VOLUNTARY",
      data: {
        environment: "Sandbox",
        signedTransactionInfo: unsignedJWS({
          ...yearlyTransaction,
          transactionId: "tx-yearly-expired",
          purchaseDate: now - 40 * oneDay,
          expiresDate: now - oneDay
        })
      }
    })
  });
  assert(expiredNotification.updatedSubscriptions === 1, "expired notification updates existing subscription");
  await expectJSON(
    "/api/subscription",
    (body) => body.isPro === false && body.subscription?.isActive === false,
    { "x-user-id": userId }
  );

  const renewalNotification = await postJSON("/api/app-store/notifications/v2", {
    signedPayload: unsignedJWS({
      notificationUUID: "sub-smoke-renewed-1",
      notificationType: "DID_RENEW",
      data: {
        environment: "Sandbox",
        signedTransactionInfo: unsignedJWS({
          ...yearlyTransaction,
          transactionId: "tx-yearly-renewed",
          purchaseDate: now,
          expiresDate: now + 365 * oneDay
        })
      }
    })
  });
  assert(renewalNotification.updatedSubscriptions === 1, "renewal notification updates existing subscription");
  await expectJSON(
    "/api/subscription",
    (body) => body.isPro === true && body.subscription?.transactionId === "tx-yearly-renewed",
    { "x-user-id": userId }
  );

  console.log("Subscription smoke test passed.");
} finally {
  server.kill("SIGTERM");
  rmSync(tempDir, { recursive: true, force: true });
}

async function waitForHealth() {
  const deadline = Date.now() + 8000;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(`${baseURL}/health`);
      if (response.ok) {
        return;
      }
    } catch {
      // Server is still starting.
    }
    await delay(200);
  }

  throw new Error(`Backend did not become healthy. Output:\n${serverOutput}`);
}

async function expectJSON(path, predicate, headers = {}) {
  const response = await fetch(`${baseURL}${path}`, { headers });
  const body = await response.json();
  assert(response.ok, `${path} returned HTTP ${response.status}: ${JSON.stringify(body)}`);
  assert(predicate(body), `${path} returned unexpected body: ${JSON.stringify(body)}`);
  return body;
}

async function postJSON(path, body, headers = {}) {
  const response = await fetch(`${baseURL}${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-user-id": userId,
      ...headers
    },
    body: JSON.stringify(body)
  });
  const responseBody = await response.json();
  assert(response.ok, `${path} returned HTTP ${response.status}: ${JSON.stringify(responseBody)}`);
  return responseBody;
}

async function postJSONExpectingStatus(path, body, expectedStatus, headers = {}) {
  const response = await fetch(`${baseURL}${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-user-id": userId,
      ...headers
    },
    body: JSON.stringify(body)
  });
  const responseBody = await response.json();
  assert(
    response.status === expectedStatus,
    `${path} expected HTTP ${expectedStatus} but returned HTTP ${response.status}: ${JSON.stringify(responseBody)}`
  );
  return responseBody;
}

function unsignedJWS(payload) {
  return [
    base64URLJSON({ alg: "none" }),
    base64URLJSON(payload),
    "signature"
  ].join(".");
}

function base64URLJSON(value) {
  return Buffer.from(JSON.stringify(value)).toString("base64url");
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
