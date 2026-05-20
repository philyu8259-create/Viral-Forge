import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const tempDir = mkdtempSync(join(tmpdir(), "viralforge-pro-quota-"));
process.env.DATA_STORE = "sqlite";
process.env.SQLITE_PATH = join(tempDir, "viralforge.sqlite");

try {
  const {
    consumePosterExport,
    getQuota,
    setProStatus
  } = await import("../src/quota/quotaManager.mjs");

  await setProStatus("pro-daily-limit-user", true);
  for (let index = 0; index < 10; index += 1) {
    await consumePosterExport("pro-daily-limit-user");
  }
  await assert.rejects(
    () => consumePosterExport("pro-daily-limit-user"),
    (error) => error.code === "pro_daily_poster_limit_exhausted"
  );

  await setProStatus("pro-monthly-limit-user", true);
  for (let index = 0; index < 200; index += 1) {
    await consumePosterExport("pro-monthly-limit-user", {
      now: new Date(Date.UTC(2026, 0, 1 + Math.floor(index / 10), 6, 0, 0))
    });
  }
  await assert.rejects(
    () => consumePosterExport("pro-monthly-limit-user", {
      now: new Date(Date.UTC(2026, 0, 25, 6, 0, 0))
    }),
    (error) => error.code === "pro_monthly_poster_limit_exhausted"
  );

  const quota = await getQuota("pro-monthly-limit-user", {
    now: new Date(Date.UTC(2026, 0, 25, 6, 0, 0))
  });
  assert.equal(quota.isPro, true);
  assert.equal(quota.proPosterUsage?.monthlyUsed, 200);
  assert.equal(quota.proPosterUsage?.monthlyLimit, 200);

  console.log("Pro poster quota limits check passed.");
} finally {
  rmSync(tempDir, { recursive: true, force: true });
}
