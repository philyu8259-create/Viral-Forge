import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const tempDir = mkdtempSync(join(tmpdir(), "viralforge-free-quota-"));
process.env.SQLITE_PATH = join(tempDir, "viralforge.sqlite");
process.env.STORAGE_BACKEND = "sqlite";
process.env.FREE_TEXT_DAILY_LIMIT = "3";

try {
  const {
    consumePosterExport,
    consumeTextGeneration,
    getQuota
  } = await import("../src/quota/quotaManager.mjs");

  const userId = "free-quota-policy-user";
  const firstDay = { now: new Date("2026-05-18T10:00:00+08:00") };
  await consumeTextGeneration(userId, firstDay);
  await consumeTextGeneration(userId, firstDay);
  let quota = await consumeTextGeneration(userId, firstDay);
  assert.equal(quota.remainingTextGenerations, 0, "free copy quota reaches 0 after three text generations");
  await assert.rejects(
    () => consumeTextGeneration(userId, firstDay),
    (error) => error.code === "quota_exhausted"
  );

  quota = await getQuota(userId, { now: new Date("2026-05-19T02:00:00+08:00") });
  assert.equal(quota.remainingTextGenerations, 3, "free copy quota resets to 3 on the next day");

  await consumePosterExport(userId, { now: new Date("2026-05-18T10:00:00+08:00") });
  await consumePosterExport(userId, { now: new Date("2026-05-18T10:05:00+08:00") });
  quota = await consumePosterExport(userId, { now: new Date("2026-05-18T10:10:00+08:00") });
  assert.equal(quota.remainingPosterExports, 0, "free AI background quota reaches 0 after three total uses");
  quota = await getQuota(userId, { now: new Date("2026-05-19T10:00:00+08:00") });
  assert.equal(quota.remainingPosterExports, 0, "free AI background quota does not reset the next day");
  await assert.rejects(
    () => consumePosterExport(userId, { now: new Date("2026-05-19T10:05:00+08:00") }),
    (error) => error.code === "quota_exhausted"
  );

  console.log("Free quota policy check passed.");
} finally {
  rmSync(tempDir, { recursive: true, force: true });
}
