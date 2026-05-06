import { fetchWithTimeout, timeoutMsFromEnv } from "../fetchWithTimeout.mjs";

export async function seedreamGeneratePosterBackground(request) {
  const apiKey = process.env.SEEDREAM_API_KEY || process.env.ARK_API_KEY;
  if (!apiKey) {
    throw missingKey("SEEDREAM_API_KEY or ARK_API_KEY");
  }

  const usedProductReference = hasReferenceImage(request);
  const response = await fetchWithTimeout(process.env.SEEDREAM_IMAGES_URL ?? "https://ark.cn-beijing.volces.com/api/v3/images/generations", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify(buildSeedreamRequestBody(request))
  }, {
    provider: "seedream",
    timeoutMs: timeoutMsFromEnv(["SEEDREAM_TIMEOUT_MS", "AI_IMAGE_TIMEOUT_MS", "AI_PROVIDER_TIMEOUT_MS"], 120000)
  });

  if (!response.ok) {
    throw upstreamError("seedream", response.status, await response.text(), request);
  }

  const payload = await response.json();
  const imageUrl = extractImageURL(payload);
  if (!imageUrl) {
    throw new Error("Seedream response did not include an image URL.");
  }

  return { imageUrl, usedProductReference };
}

export function buildSeedreamRequestBody(request) {
  const body = {
    model: process.env.SEEDREAM_IMAGE_MODEL || request.modelRoute?.imageModel || "doubao-seedream-4-5-251128",
    prompt: buildImagePrompt(request),
    size: imageSize(request.aspectRatio),
    response_format: "url",
    watermark: false
  };

  const referenceImage = referenceImageInput(request);
  if (referenceImage) {
    body.image = referenceImage;
    body.sequential_image_generation = "disabled";
  }

  return body;
}

export function hasReferenceImage(request) {
  return Boolean(referenceImageInput(request));
}

function referenceImageInput(request) {
  const value = request.productImageDataUrl;
  if (typeof value !== "string") {
    return undefined;
  }
  const trimmed = value.trim();
  if (!trimmed) {
    return undefined;
  }
  return trimmed;
}

function buildImagePrompt(request) {
  const hasProductReference = hasReferenceImage(request);
  return [
    request.prompt || "纯商业商品摄影背景底图",
    hasProductReference
      ? "输入图片只用于识别真实产品本体。保留产品的外形、比例、颜色、材质、透明窗口、可见内部结构和包装细节；不要在产品透明区域里新增液体、水果、道具、标签或装饰内容，除非参考图产品本身已有。忽略并不要复刻输入图里的背景、水印、非产品文字或非产品 logo。不要替换成相似产品，不要重新设计产品。围绕该真实产品生成自然商业摄影场景，让光影、透视、接触阴影和环境反射一致。"
      : undefined,
    "这是一张给 App 叠加文字使用的纯背景摄影素材，不是成品海报设计。",
    "不要生成海报排版，不要生成标题区，不要生成按钮，不要生成平台贴纸或社交媒体界面。",
    hasProductReference
      ? "不要新增或复制任何非产品文字、汉字、英文字母、数字、logo、品牌标识、标签、贴纸、水印、二维码、字幕或 UI 元素；只允许保留输入产品本体上物理印刷的可见标识。"
      : "画面里绝对不要出现任何文字、汉字、英文字母、数字、logo、品牌标识、标签、贴纸、水印、二维码、字幕或 UI 元素。",
    "为 App 后续叠加标题、副标题和按钮保留干净留白，优先在画面上方或中部留白。",
    `视觉风格：${request.style || "Clean"}。`,
    "真实高级商业摄影质感，光线干净，主体清晰，适合电商种草封面。"
  ].filter(Boolean).join(" ");
}

function imageSize(aspectRatio) {
  switch (aspectRatio) {
  case "1:1":
    return process.env.SEEDREAM_SIZE_SQUARE || "2048x2048";
  case "3:4":
    return process.env.SEEDREAM_SIZE_SOCIAL_COVER || "1728x2304";
  case "16:9":
    return process.env.SEEDREAM_SIZE_LANDSCAPE || "2560x1440";
  case "9:16":
  default:
    return process.env.SEEDREAM_SIZE_PORTRAIT || "1440x2560";
  }
}

function extractImageURL(payload) {
  return payload.data?.[0]?.url
    || payload.data?.[0]?.image_url
    || payload.result?.data?.[0]?.url
    || payload.result?.images?.[0]?.url
    || payload.images?.[0]?.url
    || (payload.data?.[0]?.b64_json ? `data:image/png;base64,${payload.data[0].b64_json}` : undefined);
}

function missingKey(name) {
  const error = new Error(`${name} is required for live Seedream generation.`);
  error.statusCode = 500;
  return error;
}

function upstreamError(provider, status, body, request) {
  const upstreamMessage = parseUpstreamMessage(body);
  const model = process.env.SEEDREAM_IMAGE_MODEL || request.modelRoute?.imageModel || "doubao-seedream-4-5-251128";
  const message = upstreamMessage?.code === "ModelNotOpen"
    ? `Seedream model ${model} is not activated in the Volcengine Ark Console. Please enable the model service in Ark Open Management.`
    : `${provider} upstream returned HTTP ${status}: ${body.slice(0, 300)}`;
  const error = new Error(message);
  error.statusCode = 502;
  return error;
}

function parseUpstreamMessage(body) {
  try {
    return JSON.parse(body).error;
  } catch {
    return undefined;
  }
}
