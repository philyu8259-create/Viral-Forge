import { backend } from "../store/storageBackend.mjs";

const defaultQuota = {
  remainingTextGenerations: 3,
  freeTextDailyKey: "",
  remainingPosterExports: 3,
  isPro: false,
  proPosterDailyUsed: 0,
  proPosterDailyKey: "",
  proPosterMonthlyUsed: 0,
  proPosterMonthlyKey: ""
};

export async function getQuota(userId, options = {}) {
  const store = await backend();
  const row = await store.getQuotaRecord(userId);

  if (!row) {
    const quota = quotaForCurrentWindow({ ...defaultQuota }, options);
    await store.putQuotaRecord(userId, quota);
    return quota;
  }

  return quotaForCurrentWindow({
    remainingTextGenerations: row.remaining_text_generations,
    freeTextDailyKey: row.free_text_daily_key ?? "",
    remainingPosterExports: row.remaining_poster_exports,
    isPro: Boolean(row.is_pro),
    proPosterDailyUsed: Number(row.pro_poster_daily_used ?? 0),
    proPosterDailyKey: row.pro_poster_daily_key ?? "",
    proPosterMonthlyUsed: Number(row.pro_poster_monthly_used ?? 0),
    proPosterMonthlyKey: row.pro_poster_monthly_key ?? ""
  }, options);
}

export async function consumeTextGeneration(userId, options = {}) {
  const quota = await getQuota(userId, options);
  assertTextGenerationAvailable(quota);
  if (quota.isPro) {
    return quota;
  }
  return updateQuota(userId, {
    ...quota,
    remainingTextGenerations: quota.remainingTextGenerations - 1
  });
}

export async function consumePosterExport(userId, options = {}) {
  const quota = await getQuota(userId, options);
  assertPosterExportAvailable(quota);
  if (quota.isPro) {
    return updateQuota(userId, {
      ...quota,
      proPosterDailyUsed: quota.proPosterDailyUsed + 1,
      proPosterMonthlyUsed: quota.proPosterMonthlyUsed + 1
    });
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

export async function ensurePosterExportAvailable(userId, options = {}) {
  const quota = await getQuota(userId, options);
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
    const error = new Error("Daily free text generation quota is exhausted.");
    error.statusCode = 429;
    error.code = "quota_exhausted";
    throw error;
  }
}

function assertPosterExportAvailable(quota) {
  if (quota.isPro) {
    if (quota.proPosterDailyUsed >= proPosterDailyLimit()) {
      const error = new Error("Daily Pro AI background quota is exhausted.");
      error.statusCode = 429;
      error.code = "pro_daily_poster_limit_exhausted";
      throw error;
    }
    if (quota.proPosterMonthlyUsed >= proPosterMonthlyLimit()) {
      const error = new Error("Monthly Pro AI background quota is exhausted.");
      error.statusCode = 429;
      error.code = "pro_monthly_poster_limit_exhausted";
      throw error;
    }
    return;
  }
  if (quota.remainingPosterExports <= 0) {
    const error = new Error("Free AI background quota is exhausted.");
    error.statusCode = 429;
    error.code = "quota_exhausted";
    throw error;
  }
}

function quotaForCurrentWindow(quota, options = {}) {
  const { dailyKey, monthlyKey } = usageWindowKeys(options.now);
  const dailyLimit = proPosterDailyLimit();
  const monthlyLimit = proPosterMonthlyLimit();
  const freeTextDailyLimit = freeTextGenerationDailyLimit();
  const freeTextDailyKey = quota.freeTextDailyKey ?? "";
  const normalizedQuota = {
    ...quota,
    remainingTextGenerations: !quota.isPro && freeTextDailyKey !== dailyKey
      ? freeTextDailyLimit
      : Number(quota.remainingTextGenerations ?? freeTextDailyLimit),
    freeTextDailyKey: dailyKey,
    proPosterDailyUsed: quota.proPosterDailyKey === dailyKey ? Number(quota.proPosterDailyUsed ?? 0) : 0,
    proPosterDailyKey: dailyKey,
    proPosterMonthlyUsed: quota.proPosterMonthlyKey === monthlyKey ? Number(quota.proPosterMonthlyUsed ?? 0) : 0,
    proPosterMonthlyKey: monthlyKey
  };

  return {
    ...normalizedQuota,
    proPosterUsage: {
      dailyUsed: normalizedQuota.proPosterDailyUsed,
      dailyLimit,
      monthlyUsed: normalizedQuota.proPosterMonthlyUsed,
      monthlyLimit,
      dailyKey,
      monthlyKey
    }
  };
}

function usageWindowKeys(now = new Date()) {
  const date = now instanceof Date ? now : new Date(now);
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: process.env.QUOTA_TIME_ZONE || "Asia/Shanghai",
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
  }).formatToParts(date);
  const part = (type) => parts.find((item) => item.type === type)?.value;
  const year = part("year");
  const month = part("month");
  const day = part("day");
  return {
    dailyKey: `${year}-${month}-${day}`,
    monthlyKey: `${year}-${month}`
  };
}

function proPosterDailyLimit() {
  return positiveIntegerFromEnv("PRO_POSTER_DAILY_LIMIT", 10);
}

function proPosterMonthlyLimit() {
  return positiveIntegerFromEnv("PRO_POSTER_MONTHLY_LIMIT", 200);
}

function freeTextGenerationDailyLimit() {
  return positiveIntegerFromEnv("FREE_TEXT_DAILY_LIMIT", 3);
}

function positiveIntegerFromEnv(name, fallback) {
  const value = Number.parseInt(process.env[name] ?? "", 10);
  return Number.isFinite(value) && value > 0 ? value : fallback;
}
