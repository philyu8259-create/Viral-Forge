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
    "The image must look like a clean camera photo, not a finished poster, graphic design, or social app screen.",
    "Create a full-frame premium poster-photography composition. Do not leave a large blank block, flat color panel, template placeholder, signage, printed matter, stickers, label panels, invented brand marks, or interface elements.",
    "Make the whole image visually rich but not cluttered with tasteful commercial-photography layers: foreground blur, reflections, soft shadows, props, background depth, material texture, subtle color accents, and relevant lifestyle cues. Use three to six category-relevant supporting elements across foreground, midground, and background. The upper half must also contain at least two recognizable scene objects such as softly focused props, plants, reflections, shelf edges, light texture, bokeh, or background objects; do not turn it into abstract blur. Do not leave the product alone against a bare wall, blank window area, or large empty tabletop. No single low-detail wall, window, or tabletop surface should dominate the image. The app will render copy later; the image should provide natural tonal hierarchy, not empty space.",
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
