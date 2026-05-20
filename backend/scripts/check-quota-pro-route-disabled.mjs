import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const port = Number.parseInt(process.env.PRO_ROUTE_CHECK_PORT ?? "8796", 10);
const baseURL = `http://127.0.0.1:${port}`;
const tempDir = mkdtempSync(join(tmpdir(), "viralforge-pro-route-"));
const sqlitePath = join(tempDir, "viralforge.sqlite");

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

  const response = await fetch(`${baseURL}/api/quota/pro`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-user-id": "public-pro-toggle-user"
    },
    body: JSON.stringify({ isPro: true })
  });
  assert.equal(response.status, 404, "public Pro quota toggle route should not exist");

  const quotaResponse = await fetch(`${baseURL}/api/quota`, {
    headers: {
      "x-user-id": "public-pro-toggle-user"
    }
  });
  const quota = await quotaResponse.json();
  assert.equal(quota.isPro, false, "public Pro quota toggle must not activate Pro");

  console.log("Pro quota toggle route disabled check passed.");
} finally {
  server.kill("SIGTERM");
  rmSync(tempDir, { recursive: true, force: true });
}

async function waitForHealth() {
  const startedAt = Date.now();
  while (Date.now() - startedAt < 6000) {
    try {
      const response = await fetch(`${baseURL}/health`);
      if (response.ok) {
        return;
      }
    } catch {}
    await new Promise((resolve) => setTimeout(resolve, 120));
  }
  throw new Error(`Server did not become healthy. Output:\n${serverOutput}`);
}
