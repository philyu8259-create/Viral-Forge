import "./env/loadEnv.mjs";
import { startBackendServer } from "./server.mjs";

const localPort = Number.parseInt(process.env.FC_LOCAL_PORT ?? process.env.PORT ?? process.env.CAPort ?? "8787", 10);
const localHost = "127.0.0.1";
let serverPromise = null;

export async function handler(event, context) {
  applyFcCredentials(context);
  await ensureLocalServer();

  const request = parseFcEvent(event);
  const targetURL = new URL(request.path, `http://${localHost}:${localPort}`);
  for (const [key, value] of Object.entries(request.queryParameters)) {
    if (value !== undefined && value !== null) {
      targetURL.searchParams.set(key, String(value));
    }
  }

  const headers = new Headers(request.headers);
  headers.delete("host");
  headers.delete("content-length");
  if (context?.requestId) {
    headers.set("x-fc-request-id", context.requestId);
  }

  const response = await fetch(targetURL, {
    method: request.method,
    headers,
    body: request.body,
    signal: AbortSignal.timeout(Number.parseInt(process.env.FC_HANDLER_TIMEOUT_MS ?? "115000", 10))
  });

  const responseBuffer = Buffer.from(await response.arrayBuffer());
  return {
    statusCode: response.status,
    headers: responseHeaders(response.headers),
    isBase64Encoded: false,
    body: responseBuffer.toString("utf8")
  };
}

function ensureLocalServer() {
  if (!serverPromise) {
    serverPromise = new Promise((resolve, reject) => {
      const server = startBackendServer({
        host: localHost,
        port: localPort,
        onListening: () => resolve(server)
      });
      server.once("error", reject);
    });
  }
  return serverPromise;
}

function parseFcEvent(event) {
  const eventObject = typeof event === "string" || Buffer.isBuffer(event)
    ? JSON.parse(event.toString())
    : event ?? {};
  const method = eventObject.requestContext?.http?.method ?? "GET";
  const path = eventObject.requestContext?.http?.path ?? eventObject.rawPath ?? "/";
  const body = requestBody(eventObject, method);
  return {
    method,
    path,
    body,
    headers: eventObject.headers ?? {},
    queryParameters: eventObject.queryParameters ?? {}
  };
}

function requestBody(eventObject, method) {
  if (method === "GET" || method === "HEAD") {
    return undefined;
  }
  if (!eventObject.body) {
    return "";
  }
  return eventObject.isBase64Encoded
    ? Buffer.from(eventObject.body, "base64")
    : eventObject.body;
}

function responseHeaders(headers) {
  const result = {};
  for (const [key, value] of headers.entries()) {
    if (!["connection", "content-length", "date", "keep-alive", "server", "content-disposition"].includes(key.toLowerCase())) {
      result[key] = value;
    }
  }
  return result;
}

function applyFcCredentials(context) {
  const credentials = context?.credentials;
  if (!credentials) return;

  process.env.ALIBABA_CLOUD_ACCESS_KEY_ID ||= credentials.accessKeyId;
  process.env.ALIBABA_CLOUD_ACCESS_KEY_SECRET ||= credentials.accessKeySecret;
  process.env.ALIBABA_CLOUD_SECURITY_TOKEN ||= credentials.securityToken;
}
