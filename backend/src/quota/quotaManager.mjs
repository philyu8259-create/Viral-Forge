import { backend } from "../store/storageBackend.mjs";

const defaultQuota = {
  remainingTextGenerations: 3,
  remainingPosterExports: 3,
  isPro: false
};

export async function getQuota(userId) {
  const store = await backend();
  const row = await store.getQuotaRecord(userId);

  if (!row) {
    const quota = { ...defaultQuota };
    await store.putQuotaRecord(userId, quota);
    return quota;
  }

  return {
    remainingTextGenerations: row.remaining_text_generations,
    remainingPosterExports: row.remaining_poster_exports,
    isPro: Boolean(row.is_pro)
  };
}

export async function consumeTextGeneration(userId) {
  const quota = await getQuota(userId);
  assertTextGenerationAvailable(quota);
  if (quota.isPro) {
    return quota;
  }
  return updateQuota(userId, {
    ...quota,
    remainingTextGenerations: quota.remainingTextGenerations - 1
  });
}

export async function consumePosterExport(userId) {
  const quota = await getQuota(userId);
  assertPosterExportAvailable(quota);
  if (quota.isPro) {
    return quota;
  }
  return updateQuota(userId, {
    ...quota,
    remainingPosterExports: quota.remainingPosterExports - 1
  });
}

export async function ensureTextGenerationAvailable(userId) {
  const quota = await getQuota(userId);
  assertTextGenerationAvailable(quota);
  return quota;
}

export async function ensurePosterExportAvailable(userId) {
  const quota = await getQuota(userId);
  assertPosterExportAvailable(quota);
  return quota;
}

export async function setProStatus(userId, isPro) {
  const quota = await getQuota(userId);
  return updateQuota(userId, {
    ...quota,
    isPro: Boolean(isPro)
  });
}

export async function updateQuota(userId, quota) {
  const store = await backend();
  await store.putQuotaRecord(userId, quota);
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
