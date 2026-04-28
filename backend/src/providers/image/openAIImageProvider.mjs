import { fetchWithTimeout, timeoutMsFromEnv } from "../fetchWithTimeout.mjs";

const defaultBaseURL = "https://api.openai.com/v1/images";

export async function openAIGeneratePosterBackground(request) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw missingKey("OPENAI_API_KEY");
  }

  const response = await fetchWithTimeout(process.env.OPENAI_IMAGES_URL ?? defaultBaseURL, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model: request.modelRoute?.imageModel || process.env.OPENAI_IMAGE_MODEL || "gpt-image-1.5",
      prompt: buildImagePrompt(request),
      size: imageSize(request.aspectRatio),
      response_format: "url"
    })
  }, {
    provider: "openai-image",
    timeoutMs: timeoutMsFromEnv(["OPENAI_IMAGE_TIMEOUT_MS", "AI_IMAGE_TIMEOUT_MS", "AI_PROVIDER_TIMEOUT_MS"], 120000)
  });

  if (!response.ok) {
    throw upstreamError("openai-image", response.status, await response.text());
  }

  const payload = await response.json();
  const imageUrl = payload.data?.[0]?.url || (payload.data?.[0]?.b64_json ? `data:image/png;base64,${payload.data[0].b64_json}` : undefined);
  if (!imageUrl) {
    throw new Error("OpenAI image response did not include a URL.");
  }

  return { imageUrl };
}

function buildImagePrompt(request) {
  return [
    request.prompt || "social media poster background",
    "No embedded text.",
    "Leave clean negative space for app-rendered headline and subtitle.",
    `Style: ${request.style || "Clean"}.`
  ].join(" ");
}

function imageSize(aspectRatio) {
  switch (aspectRatio) {
  case "9:16":
    return "1024x1536";
  case "3:4":
    return "1024x1536";
  case "1:1":
    return "1024x1024";
  default:
    return "1024x1536";
  }
}

function missingKey(name) {
  const error = new Error(`${name} is required for live OpenAI image generation.`);
  error.statusCode = 500;
  return error;
}

function upstreamError(provider, status, body) {
  const error = new Error(`${provider} upstream returned HTTP ${status}: ${body.slice(0, 300)}`);
  error.statusCode = 502;
  return error;
}
