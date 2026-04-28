import assert from "node:assert/strict";
import http from "node:http";

import { fetchWithTimeout, timeoutMsFromEnv } from "../src/providers/fetchWithTimeout.mjs";

const server = http.createServer(() => {
  // Intentionally leave the request open so AbortController is the only exit.
});

await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));

try {
  const { port } = server.address();
  const originalTimeout = process.env.AI_PROVIDER_TIMEOUT_MS;
  process.env.AI_PROVIDER_TIMEOUT_MS = "25";

  assert.equal(timeoutMsFromEnv(["AI_PROVIDER_TIMEOUT_MS"], 45000), 25);

  await assert.rejects(
    fetchWithTimeout(`http://127.0.0.1:${port}/slow`, {}, { provider: "test-provider" }),
    (error) => {
      assert.equal(error.code, "upstream_timeout");
      assert.equal(error.statusCode, 504);
      assert.match(error.message, /test-provider upstream timed out/);
      return true;
    }
  );

  if (originalTimeout === undefined) {
    delete process.env.AI_PROVIDER_TIMEOUT_MS;
  } else {
    process.env.AI_PROVIDER_TIMEOUT_MS = originalTimeout;
  }
} finally {
  await new Promise((resolve) => server.close(resolve));
}
