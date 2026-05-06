import { mockGenerateContent, mockGeneratePosterBackground } from "./mockProvider.mjs";
import { qwenGenerateContent } from "./text/qwenTextProvider.mjs";
import { seedreamGeneratePosterBackground } from "./image/seedreamImageProvider.mjs";

export async function generateContent(request) {
  const mode = process.env.AI_PROVIDER_MODE ?? "mock";

  if (mode === "mock") {
    return mockGenerateContent(request);
  }

  if (mode === "china_live") {
    return qwenGenerateContent(request);
  }

  if (mode === "live") {
    return qwenGenerateContent(request);
  }

  throw providerNotConfigured(mode);
}

export async function generatePosterBackground(request) {
  const mode = process.env.AI_PROVIDER_MODE ?? "mock";

  if (mode === "mock") {
    return mockGeneratePosterBackground(request);
  }

  if (mode === "china_live") {
    return seedreamGeneratePosterBackground(request);
  }

  if (mode === "live") {
    return seedreamGeneratePosterBackground(request);
  }

  throw providerNotConfigured(mode);
}

export function providerStatus() {
  const mode = process.env.AI_PROVIDER_MODE ?? "mock";
  return {
    mode,
    market: mode === "china_live" ? "china" : "global",
    routes: {
      chineseText: {
        provider: "qwen",
        model: process.env.QWEN_TEXT_MODEL || "qwen-plus",
        configured: Boolean(process.env.QWEN_API_KEY)
      },
      englishText: {
        provider: "qwen",
        model: process.env.QWEN_TEXT_MODEL || "qwen-plus",
        configured: Boolean(process.env.QWEN_API_KEY)
      },
      chineseImage: {
        provider: "seedream",
        model: process.env.SEEDREAM_IMAGE_MODEL || "doubao-seedream-4-5-251128",
        configured: Boolean(process.env.SEEDREAM_API_KEY || process.env.ARK_API_KEY)
      },
      englishImage: {
        provider: "seedream",
        model: process.env.SEEDREAM_IMAGE_MODEL || "doubao-seedream-4-5-251128",
        configured: Boolean(process.env.SEEDREAM_API_KEY || process.env.ARK_API_KEY)
      }
    }
  };
}

function providerNotConfigured(mode) {
  const error = new Error(`AI provider mode '${mode}' is not implemented yet.`);
  error.statusCode = 501;
  return error;
}
