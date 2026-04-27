import { db, nowISO } from "../db/database.mjs";

const defaultQuota = {
  remainingTextGenerations: 3,
  remainingPosterExports: 1,
  isPro: false
};

export function getQuota(userId) {
  const row = db.prepare(`
    SELECT remaining_text_generations, remaining_poster_exports, is_pro
    FROM quota
    WHERE user_id = ?
  `).get(userId);

  if (!row) {
    const quota = { ...defaultQuota };
    db.prepare(`
      INSERT INTO quota (
        user_id,
        remaining_text_generations,
        remaining_poster_exports,
        is_pro,
        updated_at
      ) VALUES (?, ?, ?, ?, ?)
    `).run(
      userId,
      quota.remainingTextGenerations,
      quota.remainingPosterExports,
      quota.isPro ? 1 : 0,
      nowISO()
    );
    return quota;
  }

  return {
    remainingTextGenerations: row.remaining_text_generations,
    remainingPosterExports: row.remaining_poster_exports,
    isPro: Boolean(row.is_pro)
  };
}

export function consumeTextGeneration(userId) {
  const quota = getQuota(userId);
  assertTextGenerationAvailable(quota);
  if (quota.isPro) {
    return quota;
  }
  return updateQuota(userId, {
    ...quota,
    remainingTextGenerations: quota.remainingTextGenerations - 1
  });
}

export function consumePosterExport(userId) {
  const quota = getQuota(userId);
  assertPosterExportAvailable(quota);
  if (quota.isPro) {
    return quota;
  }
  return updateQuota(userId, {
    ...quota,
    remainingPosterExports: quota.remainingPosterExports - 1
  });
}

export function ensureTextGenerationAvailable(userId) {
  const quota = getQuota(userId);
  assertTextGenerationAvailable(quota);
  return quota;
}

export function ensurePosterExportAvailable(userId) {
  const quota = getQuota(userId);
  assertPosterExportAvailable(quota);
  return quota;
}

export function setProStatus(userId, isPro) {
  const quota = getQuota(userId);
  return updateQuota(userId, {
    ...quota,
    isPro: Boolean(isPro)
  });
}

export function updateQuota(userId, quota) {
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
  return quota;
}

function assertTextGenerationAvailable(quota) {
  if (quota.isPro) {
    return;
  }
  if (quota.remainingTextGenerations <= 0) {
    const error = new Error("Daily text generation quota is exhausted.");
    error.statusCode = 429;
    error.code = "quota_exhausted";
    throw error;
  }
}

function assertPosterExportAvailable(quota) {
  if (quota.isPro) {
    return;
  }
  if (quota.remainingPosterExports <= 0) {
    const error = new Error("Daily poster export quota is exhausted.");
    error.statusCode = 429;
    error.code = "quota_exhausted";
    throw error;
  }
}
