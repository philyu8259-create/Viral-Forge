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
      ? "输入图片只用于识别真实产品本体。保留产品的外形、比例、颜色、材质、透明窗口、可见内部结构和包装细节；不要在产品透明区域里新增液体、水果或装饰内容，除非参考图产品本身已有。忽略并不要复刻输入图里的背景或非产品标记。不要替换成相似产品，不要重新设计产品。围绕该真实产品生成自然商业摄影场景，让光影、透视、接触阴影和环境反射一致。"
      : undefined,
    "这是一张纯商业摄影素材，画面必须像真实相机照片，不是成品海报、平面设计图或社交应用截图。",
    hasProductReference
      ? "不要新增或复制任何可读标记、招牌、印刷物、贴纸或界面元素；只允许保留输入产品本体上物理印刷的可见标识。"
      : "画面里不要出现任何可读标记、招牌、印刷物、贴纸、界面元素、标签面板或虚构品牌标识；商品外观保持无品牌、无标记。",
    "生成完整全画幅高级海报摄影构图。不要大面积空白、纯色大板、模板占位区或为了叠字而牺牲画面的空区域。",
    "画面整体必须丰富但不杂乱：加入商业摄影层次，例如前景虚化、桌面反光、柔和投影、产品周边道具、背景空间纵深、轮廓光、材质纹理、克制的色彩点缀和与品类相关的生活方式元素。必须有 3 到 6 个与品类相关的辅助元素分布在前景、中景和背景，上半画幅也必须至少有两个可识别的场景物件，例如柔焦道具、植物、反光、置物架边缘、光影纹理、光斑或背景物件，不能只是一片抽象虚化。不能只有一个产品配空墙、空窗或空桌面，任何单一低细节墙面、窗面或桌面都不能占据画面主导面积。主商品仍然是视觉中心，后续叠字由 App 渲染完成，图片本身只需要自然的明暗层次和视觉秩序。",
    "如果画面出现纸张、笔记本、书、本子、屏幕、包装、标签、收据、贴纸、菜单或文件，它们必须是空白、背向镜头、被裁切，或虚化到看不清任何字母、数字、符号、界面和手写内容。",
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
