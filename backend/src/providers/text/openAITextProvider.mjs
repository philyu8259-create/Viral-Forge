import { buildContentPrompt, contentResponseSchema, normalizeContentResponse, parseContentJSON } from "../contentSchema.mjs";
import { fetchWithTimeout, timeoutMsFromEnv } from "../fetchWithTimeout.mjs";

const defaultBaseURL = "https://api.openai.com/v1/responses";

export async function openAIGenerateContent(request) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) {
    throw missingKey("OPENAI_API_KEY");
  }

  const response = await fetchWithTimeout(process.env.OPENAI_RESPONSES_URL ?? defaultBaseURL, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      model: request.modelRoute?.textModel || process.env.OPENAI_TEXT_MODEL || "gpt-5.4",
      input: [
        {
          role: "system",
          content: "You generate structured social content JSON for ViralForge."
        },
        {
          role: "user",
          content: buildContentPrompt(request)
        }
      ],
      text: {
        format: {
          type: "json_schema",
          name: "viralforge_content_package",
          schema: contentResponseSchema,
          strict: true
        }
      }
    })
  }, {
    provider: "openai",
    timeoutMs: timeoutMsFromEnv(["OPENAI_TEXT_TIMEOUT_MS", "AI_TEXT_TIMEOUT_MS", "AI_PROVIDER_TIMEOUT_MS"], 45000)
  });

  if (!response.ok) {
    throw upstreamError("openai", response.status, await response.text());
  }

  const payload = await response.json();
  const content = extractOutputText(payload);
  return normalizeContentResponse(parseContentJSON(content), request);
}

function extractOutputText(payload) {
  if (typeof payload.output_text === "string") {
    return payload.output_text;
  }

  const message = payload.output?.find((item) => item.type === "message");
  const textContent = message?.content?.find((item) => item.type === "output_text" || item.type === "text");
  if (typeof textContent?.text === "string") {
    return textContent.text;
  }

  throw new Error("OpenAI response did not include output text.");
}

function missingKey(name) {
  const error = new Error(`${name} is required for live OpenAI generation.`);
  error.statusCode = 500;
  return error;
}

function upstreamError(provider, status, body) {
  const error = new Error(`${provider} upstream returned HTTP ${status}: ${body.slice(0, 300)}`);
  error.statusCode = 502;
  return error;
}
