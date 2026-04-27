import { spawn } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const port = Number.parseInt(process.env.SMOKE_PORT ?? "8792", 10);
const baseURL = `http://127.0.0.1:${port}`;
const tempDir = mkdtempSync(join(tmpdir(), "viralforge-smoke-"));
const sqlitePath = join(tempDir, "viralforge.sqlite");

const server = spawn(process.execPath, ["src/main.mjs"], {
  cwd: new URL("..", import.meta.url),
  env: {
    ...process.env,
    PORT: String(port),
    SQLITE_PATH: sqlitePath,
    AI_PROVIDER_MODE: "mock",
    IAP_VERIFICATION_MODE: "local_development",
    CONTENT_RATE_MAX: "2",
    CONTENT_RATE_WINDOW_MS: "60000"
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
  await expectJSON("/health", (body) => body.status === "ok");
  await expectJSON("/api/providers/status", (body) => body.mode === "mock");
  await expectJSON("/api/app-store/status", (body) => body.mode === "local_development");
  const templates = await expectJSON("/api/templates", (body) => Array.isArray(body.templates) && body.templates.length > 0);
  assert(templates.templates.some((template) => ["xiaohongshu", "douyin", "wechat"].includes(template.platform)), "templates include China launch platforms");
  assert(templates.templates.some((template) => ["tiktok", "instagram", "youtube_shorts"].includes(template.platform)), "templates include English launch platforms");
  assert(templates.templates.some((template) => template.name.includes("小红书")), "templates include Chinese launch copy");
  assert(templates.templates.some((template) => template.name.includes("TikTok")), "templates include English launch copy");
  await expectJSON("/api/quota", (body) => body.remainingTextGenerations === 3, {
    "x-user-id": "smoke-user"
  });
  const savedBrand = await postJSON("/api/brand", {
    profile: {
      brandName: "轻氧日记",
      industry: "便携健康小家电",
      audience: "25-35岁上班族女性",
      tone: "真实、轻快、有种草感",
      bannedWords: "治疗, 保证瘦",
      defaultPlatform: "xiaohongshu",
      primaryColorName: "Emerald"
    }
  });
  assert(savedBrand.profile?.brandName === "轻氧日记", "brand profile saved");

  const generated = await postJSON("/api/content/generate", {
    language: "zh-Hans",
    platform: "xiaohongshu",
    goal: "sell_product",
    topic: "便携榨汁杯，适合上班族女生",
    audience: "25-35岁上班族女性",
    tone: "真实、轻快、有种草感",
    templateName: "小红书种草封面",
    templatePromptHint: "突出省时、轻便、容易清洗",
    templateStyle: "Clean"
  });
  assert(Array.isArray(generated.titles) && generated.titles.length > 0, "content generation returned titles");
  assert(generated.projectId, "content generation returned projectId");
  const projects = await expectJSON("/api/projects", (body) => Array.isArray(body.projects), {
    "x-user-id": "smoke-user"
  });
  assert(projects.projects[0]?.input?.brandName === "轻氧日记", "generated project includes saved brand memory");
  assert(projects.projects[0]?.input?.bannedWords === "治疗, 保证瘦", "generated project includes banned words");

  const unsafeResult = await postJSONExpectingStatus(
    "/api/content/generate",
    {
      language: "zh-Hans",
      platform: "xiaohongshu",
      goal: "sell_product",
      topic: "宣称可以治疗痘痘并且百分百有效的护肤品",
      audience: "敏感肌用户",
      tone: "强转化"
    },
    422,
    { "x-user-id": "safety-user" }
  );
  assert(unsafeResult.error?.code === "medical_claim", "unsafe medical claim is blocked before generation");
  const safetyQuota = await expectJSON("/api/quota", (body) => body.remainingTextGenerations === 3, {
    "x-user-id": "safety-user"
  });
  assert(safetyQuota.remainingTextGenerations === 3, "blocked content does not consume quota");

  await postJSON(
    "/api/content/generate",
    {
      language: "zh-Hans",
      platform: "xiaohongshu",
      goal: "sell_product",
      topic: "办公室保温杯，适合冬天通勤",
      audience: "通勤白领",
      tone: "真实轻快"
    },
    { "x-user-id": "rate-user" }
  );
  await postJSON(
    "/api/content/generate",
    {
      language: "zh-Hans",
      platform: "xiaohongshu",
      goal: "sell_product",
      topic: "桌面收纳盒，适合租房办公桌",
      audience: "租房青年",
      tone: "实用直接"
    },
    { "x-user-id": "rate-user" }
  );
  const rateLimited = await postJSONExpectingStatus(
    "/api/content/generate",
    {
      language: "zh-Hans",
      platform: "xiaohongshu",
      goal: "sell_product",
      topic: "便携咖啡杯，适合早八通勤",
      audience: "年轻上班族",
      tone: "轻快"
    },
    429,
    { "x-user-id": "rate-user" }
  );
  assert(rateLimited.error?.code === "rate_limited", "rapid content generation is rate limited");

  const deleteResult = await deleteJSON(`/api/projects/${generated.projectId}`);
  assert(deleteResult.deleted === true, "project deletion returned true");
  const projectsAfterDelete = await expectJSON("/api/projects", (body) => Array.isArray(body.projects), {
    "x-user-id": "smoke-user"
  });
  assert(!projectsAfterDelete.projects.some((project) => project.projectId === generated.projectId), "deleted project is removed");

  const background = await postJSON("/api/poster/background", {
    projectId: generated.projectId,
    language: "zh-Hans",
    style: "Clean",
    aspectRatio: "9:16",
    prompt: "小红书商业海报背景，不要文字。"
  });
  assert(background.imageUrl, "poster background returned imageUrl");

  console.log("Smoke test passed.");
} finally {
  server.kill("SIGTERM");
  rmSync(tempDir, { recursive: true, force: true });
}

async function waitForHealth() {
  const deadline = Date.now() + 8000;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(`${baseURL}/health`);
      if (response.ok) {
        return;
      }
    } catch {
      // Server is still starting.
    }
    await delay(200);
  }

  throw new Error(`Backend did not become healthy. Output:\n${serverOutput}`);
}

async function expectJSON(path, predicate, headers = {}) {
  const response = await fetch(`${baseURL}${path}`, { headers });
  const body = await response.json();
  assert(response.ok, `${path} returned HTTP ${response.status}: ${JSON.stringify(body)}`);
  assert(predicate(body), `${path} returned unexpected body: ${JSON.stringify(body)}`);
  return body;
}

async function postJSON(path, body, headers = {}) {
  const response = await fetch(`${baseURL}${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-user-id": "smoke-user",
      ...headers
    },
    body: JSON.stringify(body)
  });
  const responseBody = await response.json();
  assert(response.ok, `${path} returned HTTP ${response.status}: ${JSON.stringify(responseBody)}`);
  return responseBody;
}

async function postJSONExpectingStatus(path, body, expectedStatus, headers = {}) {
  const response = await fetch(`${baseURL}${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-user-id": "smoke-user",
      ...headers
    },
    body: JSON.stringify(body)
  });
  const responseBody = await response.json();
  assert(
    response.status === expectedStatus,
    `${path} expected HTTP ${expectedStatus} but returned HTTP ${response.status}: ${JSON.stringify(responseBody)}`
  );
  return responseBody;
}

async function deleteJSON(path) {
  const response = await fetch(`${baseURL}${path}`, {
    method: "DELETE",
    headers: {
      "x-user-id": "smoke-user"
    }
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
