export async function seedreamGeneratePosterBackground(request) {
  const apiKey = process.env.SEEDREAM_API_KEY || process.env.ARK_API_KEY;
  if (!apiKey) {
    throw missingKey("SEEDREAM_API_KEY or ARK_API_KEY");
  }

  const response = await fetch(process.env.SEEDREAM_IMAGES_URL ?? "https://ark.cn-beijing.volces.com/api/v3/images/generations", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model: process.env.SEEDREAM_IMAGE_MODEL || request.modelRoute?.imageModel || "doubao-seedream-4-5-251128",
      prompt: buildImagePrompt(request),
      size: imageSize(request.aspectRatio),
      response_format: "url",
      watermark: false
    })
  });

  if (!response.ok) {
    throw upstreamError("seedream", response.status, await response.text(), request);
  }

  const payload = await response.json();
  const imageUrl = extractImageURL(payload);
  if (!imageUrl) {
    throw new Error("Seedream response did not include an image URL.");
  }

  return { imageUrl };
}

function buildImagePrompt(request) {
  return [
    request.prompt || "小红书商业海报背景",
    "不要生成文字，不要生成水印。",
    "为 App 后续叠加标题、副标题和按钮保留干净留白。",
    `海报风格：${request.style || "Clean"}。`,
    "商业摄影质感，高级、清晰、适合社交媒体封面。"
  ].join(" ");
}

function imageSize(aspectRatio) {
  switch (aspectRatio) {
  case "1:1":
    return process.env.SEEDREAM_SIZE_SQUARE || "2048x2048";
  case "3:4":
    return process.env.SEEDREAM_SIZE_SOCIAL_COVER || "1440x1920";
  case "16:9":
    return process.env.SEEDREAM_SIZE_LANDSCAPE || "2048x1152";
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
