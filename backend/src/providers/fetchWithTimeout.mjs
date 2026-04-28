export async function fetchWithTimeout(url, options = {}, config = {}) {
  const timeoutMs = config.timeoutMs ?? timeoutMsFromEnv(["AI_PROVIDER_TIMEOUT_MS"], 45000);
  const provider = config.provider ?? "provider";
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  try {
    return await fetch(url, {
      ...options,
      signal: controller.signal
    });
  } catch (error) {
    if (error?.name === "AbortError") {
      throw timeoutError(provider, timeoutMs);
    }
    throw error;
  } finally {
    clearTimeout(timer);
  }
}

export function timeoutMsFromEnv(names, fallbackMs) {
  for (const name of names) {
    const raw = process.env[name];
    if (!raw) {
      continue;
    }

    const value = Number.parseInt(raw, 10);
    if (Number.isFinite(value) && value > 0) {
      return value;
    }
  }

  return fallbackMs;
}

function timeoutError(provider, timeoutMs) {
  const error = new Error(`${provider} upstream timed out after ${timeoutMs}ms.`);
  error.statusCode = 504;
  error.code = "upstream_timeout";
  return error;
}
