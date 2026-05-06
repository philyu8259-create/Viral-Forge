import { spawn } from "node:child_process";
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { extname, join, resolve } from "node:path";
import { tmpdir } from "node:os";
import assert from "node:assert/strict";
import { fileURLToPath } from "node:url";

const port = Number.parseInt(process.env.SMOKE_PORT ?? "8794", 10);
const baseURL = `http://127.0.0.1:${port}`;
const repoRoot = resolve(fileURLToPath(new URL("../..", import.meta.url)));
const referencePath = resolve(process.env.PRODUCT_REFERENCE_PATH ?? join(repoRoot, "Screenshots/manual-poster-validation/product-reference-cup.jpg"));
const outputPath = resolve(process.env.OUTPUT_IMAGE_PATH ?? join(repoRoot, "Screenshots/manual-poster-validation/seedream-reference-integrated-live.png"));
const integrationMode = process.env.PRODUCT_INTEGRATION_MODE === "natural" ? "natural" : "preserve";
const tempDir = mkdtempSync(join(tmpdir(), "viralforge-seedream-reference-smoke-"));
const sqlitePath = join(tempDir, "viralforge.sqlite");

assert(existsSync(referencePath), `Product reference image does not exist: ${referencePath}`);

const server = spawn(process.execPath, ["src/main.mjs"], {
  cwd: new URL("..", import.meta.url),
  env: {
    ...process.env,
    PORT: String(port),
    SQLITE_PATH: sqlitePath,
    AI_PROVIDER_MODE: "china_live",
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
  assert.equal(status.mode, "china_live");
  assert(status.routes?.chineseImage?.configured, "SEEDREAM_API_KEY or ARK_API_KEY is not configured");

  const background = await postJSON("/api/poster/background", {
    projectId: "seedream-reference-live-smoke",
    language: "zh-Hans",
    style: "Clean",
    aspectRatio: "9:16",
    prompt: [
      "生成一张办公室早餐场景的商业摄影海报背景。",
      "使用参考图里的白色便携榨汁杯作为唯一主商品，保留杯身比例、白色杯盖、透明窗口、可见内部刀片结构和整体外观。",
      "不要在透明窗口内加入水果、液体、饮料或其他内容；透明窗口内应保持参考图中的金属刀片结构。",
      "参考图只用于识别产品本体，忽略并不要复刻参考图里的背景、水印、非产品文字或非产品 logo。",
      productIntegrationInstruction(integrationMode),
      "让产品自然摆放在干净办公桌或窗边台面上，有真实接触阴影和自然光。",
      "画面中上部保留大量干净留白，方便 App 后续叠加文字。",
      "不要新增或复制任何文字、logo、标签、水印、二维码或 UI；只允许保留产品本体上物理印刷的细小标识。"
    ].join(" "),
    modelRoute: {
      imageProvider: "seedream",
      imageModel: status.routes.chineseImage.model
    },
    productImageDataUrl: dataURLFor(referencePath)
  });

  assert(background.imageUrl, "Live poster background returned no imageUrl");
  assert.equal(background.usedProductReference, true);

  await saveImage(background.imageUrl, outputPath);

  console.log("Seedream reference image live smoke passed.");
  console.log(`Image: seedream / ${status.routes.chineseImage.model}`);
  console.log(`Product integration mode: ${integrationMode}`);
  console.log(`Used product reference: ${background.usedProductReference}`);
  console.log(`Saved image: ${outputPath}`);
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
      "x-user-id": "seedream-reference-live-smoke-user"
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
      "x-user-id": "seedream-reference-live-smoke-user"
    },
    body: JSON.stringify(body)
  });
  const responseBody = await response.json();
  assert(response.ok, `${path} returned HTTP ${response.status}: ${JSON.stringify(responseBody)}`);
  return responseBody;
}

function dataURLFor(path) {
  const mimeType = mimeTypeFor(path);
  return `data:${mimeType};base64,${readFileSync(path).toString("base64")}`;
}

function productIntegrationInstruction(mode) {
  if (mode === "natural") {
    return "产品参考图融合模式：优先让真实产品自然融入商业摄影场景，同时保留产品身份。自然融入也不能改变产品身份、轮廓、比例、关键材质、透明窗口和可识别细节。让产品与新场景的透视、接触阴影、反光、轮廓光和桌面关系一致，不能像简单贴图。";
  }

  return "产品参考图融合模式：优先严格保留真实产品外观，高于场景风格。尽量不改变产品轮廓、比例、颜色、材质、透明结构、接缝、按钮、刀头/窗口细节和产品本体上的物理印刷标识。";
}

function mimeTypeFor(path) {
  switch (extname(path).toLowerCase()) {
  case ".jpg":
  case ".jpeg":
    return "image/jpeg";
  case ".webp":
    return "image/webp";
  case ".png":
  default:
    return "image/png";
  }
}

async function saveImage(imageUrl, path) {
  if (imageUrl.startsWith("data:")) {
    const base64 = imageUrl.slice(imageUrl.indexOf(",") + 1);
    writeFileSync(path, Buffer.from(base64, "base64"));
    return;
  }

  const response = await fetch(imageUrl);
  assert(response.ok, `Generated image download returned HTTP ${response.status}`);
  writeFileSync(path, Buffer.from(await response.arrayBuffer()));
}

function delay(ms) {
  return new Promise((resolveDelay) => setTimeout(resolveDelay, ms));
}
