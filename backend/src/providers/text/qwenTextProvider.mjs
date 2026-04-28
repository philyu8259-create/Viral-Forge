import { buildContentPrompt, normalizeContentResponse, parseContentJSON } from "../contentSchema.mjs";
import { fetchWithTimeout, timeoutMsFromEnv } from "../fetchWithTimeout.mjs";

const defaultBaseURL = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions";

export async function qwenGenerateContent(request) {
  const apiKey = process.env.QWEN_API_KEY;
  if (!apiKey) {
    throw missingKey("QWEN_API_KEY");
  }

  const response = await fetchWithTimeout(process.env.QWEN_CHAT_COMPLETIONS_URL ?? defaultBaseURL, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model: request.modelRoute?.textModel || process.env.QWEN_TEXT_MODEL || "qwen-plus",
      messages: [
        {
          role: "system",
          content: "You generate structured social content JSON for ViralForge. Return JSON only."
        },
        {
          role: "user",
          content: buildContentPrompt(request)
        }
      ],
      response_format: {
        type: "json_object"
      }
    })
  }, {
    provider: "qwen",
    timeoutMs: timeoutMsFromEnv(["QWEN_TIMEOUT_MS", "AI_TEXT_TIMEOUT_MS", "AI_PROVIDER_TIMEOUT_MS"], 45000)
  });

  if (!response.ok) {
    throw upstreamError("qwen", response.status, await response.text());
  }

  const payload = await response.json();
  const content = payload.choices?.[0]?.message?.content;
  return normalizeContentResponse(parseContentJSON(content), request);
}

function missingKey(name) {
  const error = new Error(`${name} is required for live Qwen generation.`);
  error.statusCode = 500;
  return error;
}

function upstreamError(provider, status, body) {
  const error = new Error(`${provider} upstream returned HTTP ${status}: ${body.slice(0, 300)}`);
  error.statusCode = 502;
  return error;
}
