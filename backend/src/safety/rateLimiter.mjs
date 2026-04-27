const buckets = new Map();

const defaultLimits = {
  content: {
    windowMs: Number.parseInt(process.env.CONTENT_RATE_WINDOW_MS ?? "60000", 10),
    max: Number.parseInt(process.env.CONTENT_RATE_MAX ?? "8", 10)
  },
  poster: {
    windowMs: Number.parseInt(process.env.POSTER_RATE_WINDOW_MS ?? "60000", 10),
    max: Number.parseInt(process.env.POSTER_RATE_MAX ?? "6", 10)
  }
};

export function assertRateLimit(userId, action) {
  const limit = defaultLimits[action] ?? defaultLimits.content;
  const now = Date.now();
  const key = `${action}:${userId}`;
  const bucket = buckets.get(key) ?? [];
  const recent = bucket.filter((timestamp) => now - timestamp < limit.windowMs);

  if (recent.length >= limit.max) {
    const retryAfterMs = Math.max(1000, limit.windowMs - (now - recent[0]));
    const error = new Error("Too many requests. Please wait a moment and try again.");
    error.statusCode = 429;
    error.code = "rate_limited";
    error.retryAfterSeconds = Math.ceil(retryAfterMs / 1000);
    throw error;
  }

  recent.push(now);
  buckets.set(key, recent);
}

export function resetRateLimitsForTesting() {
  buckets.clear();
}
