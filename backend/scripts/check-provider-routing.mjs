import assert from "node:assert/strict";
import { providerStatus } from "../src/providers/providerRouter.mjs";

const previousMode = process.env.AI_PROVIDER_MODE;
const previousSeedreamKey = process.env.SEEDREAM_API_KEY;
const previousQwenKey = process.env.QWEN_API_KEY;

process.env.AI_PROVIDER_MODE = "live";
process.env.SEEDREAM_API_KEY = process.env.SEEDREAM_API_KEY || "test-seedream-key";
process.env.QWEN_API_KEY = process.env.QWEN_API_KEY || "test-qwen-key";

try {
  const liveStatus = providerStatus();

  assert.equal(liveStatus.routes.chineseText.provider, "qwen");
  assert.equal(liveStatus.routes.englishText.provider, "qwen");
  assert.equal(liveStatus.routes.chineseImage.provider, "seedream");
  assert.equal(liveStatus.routes.englishImage.provider, "seedream");
  assert.equal(liveStatus.routes.englishImage.model, process.env.SEEDREAM_IMAGE_MODEL || "doubao-seedream-4-5-251128");
  assert.equal(liveStatus.routes.englishImage.configured, true);

  process.env.AI_PROVIDER_MODE = "china_live";
  const chinaStatus = providerStatus();

  assert.equal(chinaStatus.routes.chineseText.provider, "qwen");
  assert.equal(chinaStatus.routes.englishText.provider, "qwen");
  assert.equal(chinaStatus.routes.chineseImage.provider, "seedream");
  assert.equal(chinaStatus.routes.englishImage.provider, "seedream");

  console.log("Provider routing check passed.");
} finally {
  restoreEnv("AI_PROVIDER_MODE", previousMode);
  restoreEnv("SEEDREAM_API_KEY", previousSeedreamKey);
  restoreEnv("QWEN_API_KEY", previousQwenKey);
}

function restoreEnv(name, value) {
  if (value === undefined) {
    delete process.env[name];
    return;
  }
  process.env[name] = value;
}
