import { createServer } from "node:http";
import { routeRequest } from "./router.mjs";

const port = Number.parseInt(process.env.PORT ?? "8787", 10);

const server = createServer(async (request, response) => {
  try {
    await routeRequest(request, response);
  } catch (error) {
    console.error(error);
    sendJSON(response, error.statusCode ?? 500, {
      error: {
        code: error.statusCode ? "request_error" : "internal_error",
        message: error.statusCode ? error.message : "Unexpected server error."
      }
    });
  }
});

server.listen(port, () => {
  console.log(`ViralForge backend listening on http://localhost:${port}`);
});

function sendJSON(response, statusCode, body) {
  response.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type,Authorization"
  });
  response.end(JSON.stringify(body));
}
