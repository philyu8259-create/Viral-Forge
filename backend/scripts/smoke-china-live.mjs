import { spawn } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const port = Number.parseInt(process.env.SMOKE_PORT ?? "8793", 10);
const baseURL = `http://127.0.0.1:${port}`;
const tempDir = mkdtempSync(join(tmpdir(), "viralforge-china-live-smoke-"));
const sqlitePath = join(tempDir, "viralforge.sqlite");

const server = spawn(process.execPath, ["src/main.mjs"], {
  cwd: new URL("..", import.meta.url),
  env: {
    ...process.env,
    PORT: String(port),
    SQLITE_PATH: sqlitePath,
    AI_PROVIDER_MODE: "china_live",
    CONTENT_RATE_MAX: "10",
    POSTER_RATE_MAX: "10"
  },
  stdio: ["ignore", "pipe", "pipe"]
});

let serverOutput = "";
server.stdout.on("data", (chunk) => {
  serverOutput += chunk.toString();
});
server.stderr.on("data", (chunk) => {
  serverOutput += chunk.toString();
});

try {
  await waitForHealth();

  const status = await getJSON("/api/providers/status");
  assert(status.mode === "china_live", "AI_PROVIDER_MODE should be china_live");
  assert(status.routes?.chineseText?.configured, "QWEN_API_KEY is not configured");
  assert(status.routes?.chineseImage?.configured, "SEEDREAM_API_KEY or ARK_API_KEY is not configured");

  const generated = await postJSON("/api/content/generate", {
    language: "zh-Hans",
    platform: "xiaohongshu",
    goal: "sell_product",
    topic: "便携榨汁杯，适合上班族办公室快速早餐，主打便携、好清洗、低噪音、颜值高。",
    audience: "25-35岁上班族女性",
    tone: "真实、轻快、有种草感",
    templateName: "小红书种草封面",
    templatePromptHint: "突出省时、轻便、容易清洗",
    templateStyle: "Clean",
    modelRoute: {
      textProvider: "qwen",
      textModel: status.routes.chineseText.model,
      imageProvider: "seedream",
      imageModel: status.routes.chineseImage.model
    }
  });

  assert(Array.isArray(generated.titles) && generated.titles.length > 0, "Live content returned no titles");
  assert(Array.isArray(generated.hooks) && generated.hooks.length > 0, "Live content returned no hooks");
  assert(generated.caption, "Live content returned no caption");
  assert(generated.poster?.headline, "Live content returned no poster headline");
  assert(generated.projectId, "Live content returned no projectId");

  const background = await postJSON("/api/poster/background", {
    projectId: generated.projectId,
    language: "zh-Hans",
    style: generated.poster.style || "Clean",
    aspectRatio: "9:16",
    prompt: "小红书商业海报背景，便携榨汁杯，办公室早餐场景，清爽明亮，高级商业摄影质感。不要文字，不要水印。",
    modelRoute: {
      imageProvider: "seedream",
      imageModel: status.routes.chineseImage.model
    }
  });

  assert(background.imageUrl, "Live poster background returned no imageUrl");

  const imageURL = new URL(background.imageUrl);
  console.log("China live smoke passed.");
  console.log(`Provider mode: ${status.mode}`);
  console.log(`Text: qwen / ${status.routes.chineseText.model}`);
  console.log(`Image: seedream / ${status.routes.chineseImage.model}`);
  console.log(`Generated project: ${generated.projectId}`);
  console.log(`Titles: ${generated.titles.length}; hooks: ${generated.hooks.length}`);
  console.log(`Image URL host: ${imageURL.host}`);
} finally {
  server.kill("SIGTERM");
  rmSync(tempDir, { recursive: true, force: true });
}

async function waitForHealth() {
  const deadline = Date.now() + 10000;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(`${baseURL}/health`);
      if (response.ok) {
        return;
      }
    } catch {
      // Server is still starting.
    }
    await delay(250);
  }

  throw new Error(`Backend did not become healthy. Output:\n${serverOutput}`);
}

async function getJSON(path) {
  const response = await fetch(`${baseURL}${path}`, {
    headers: {
      "x-user-id": "china-live-smoke-user"
    }
  });
  const body = await response.json();
  assert(response.ok, `${path} returned HTTP ${response.status}: ${JSON.stringify(body)}`);
  return body;
}

async function postJSON(path, body) {
  const response = await fetch(`${baseURL}${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-user-id": "china-live-smoke-user"
    },
    body: JSON.stringify(body)
  });
  const responseBody = await response.json();
  assert(response.ok, `${path} returned HTTP ${response.status}: ${JSON.stringify(responseBody)}`);
  return responseBody;
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
