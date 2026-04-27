import { mockGenerateContent, mockGeneratePosterBackground } from "./mockProvider.mjs";
import { qwenGenerateContent } from "./text/qwenTextProvider.mjs";
import { openAIGenerateContent } from "./text/openAITextProvider.mjs";
import { seedreamGeneratePosterBackground } from "./image/seedreamImageProvider.mjs";
import { openAIGeneratePosterBackground } from "./image/openAIImageProvider.mjs";

export async function generateContent(request) {
  const mode = process.env.AI_PROVIDER_MODE ?? "mock";

  if (mode === "mock") {
    return mockGenerateContent(request);
  }

  if (mode === "china_live") {
    return qwenGenerateContent(request);
  }

  if (mode === "live") {
    if (request.language === "en") {
      return openAIGenerateContent(request);
    }
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
    if (request.language === "en") {
      return openAIGeneratePosterBackground(request);
    }
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
        provider: mode === "china_live" ? "qwen" : "openai",
        model: mode === "china_live" ? (process.env.QWEN_TEXT_MODEL || "qwen-plus") : (process.env.OPENAI_TEXT_MODEL || "gpt-5.4"),
        configured: mode === "china_live" ? Boolean(process.env.QWEN_API_KEY) : Boolean(process.env.OPENAI_API_KEY)
      },
      chineseImage: {
        provider: "seedream",
        model: process.env.SEEDREAM_IMAGE_MODEL || "doubao-seedream-4-5-251128",
        configured: Boolean(process.env.SEEDREAM_API_KEY || process.env.ARK_API_KEY)
      },
      englishImage: {
        provider: mode === "china_live" ? "seedream" : "openai",
        model: mode === "china_live" ? (process.env.SEEDREAM_IMAGE_MODEL || "doubao-seedream-4-5-251128") : (process.env.OPENAI_IMAGE_MODEL || "gpt-image-1.5"),
        configured: mode === "china_live" ? Boolean(process.env.SEEDREAM_API_KEY || process.env.ARK_API_KEY) : Boolean(process.env.OPENAI_API_KEY)
      }
    }
  };
}

function providerNotConfigured(mode) {
  const error = new Error(`AI provider mode '${mode}' is not implemented yet.`);
  error.statusCode = 501;
  return error;
}
