import { createServer } from "node:http";
import { routeRequest } from "./router.mjs";

export function createBackendServer() {
  const server = createServer(async (request, response) => {
    try {
      await routeRequest(request, response);
    } catch (error) {
      console.error(error);
      sendJSON(response, error.statusCode ?? 500, {
        error: {
          code: error.code ?? (error.statusCode ? "request_error" : "internal_error"),
          message: error.statusCode ? error.message : "Unexpected server error.",
          retryAfterSeconds: error.retryAfterSeconds
        }
      });
    }
  });

  server.timeout = 0;
  server.keepAliveTimeout = 0;
  return server;
}

export function startBackendServer(options = {}) {
  const port = Number.parseInt(String(options.port ?? process.env.PORT ?? process.env.CAPort ?? "8787"), 10);
  const host = options.host ?? process.env.HOST ?? "0.0.0.0";
  const server = createBackendServer();
  server.listen(port, host, () => {
    if (typeof options.onListening === "function") {
      options.onListening({ host, port, server });
      return;
    }
    console.log(`ViralForge backend listening on http://${host}:${port}`);
  });
  return server;
}

function sendJSON(response, statusCode, body) {
  response.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,DELETE,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type,Authorization,x-user-id"
  });
  response.end(JSON.stringify(body));
}
