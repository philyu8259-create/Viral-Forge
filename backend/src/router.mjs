import { randomUUID } from "node:crypto";
import { appStoreServerStatus } from "./appStore/serverAPI.mjs";
import { generateContent, generatePosterBackground, providerStatus } from "./providers/providerRouter.mjs";
import {
  consumePosterExport,
  consumeTextGeneration,
  ensurePosterExportAvailable,
  ensureTextGenerationAvailable,
  getQuota,
  setProStatus
} from "./quota/quotaManager.mjs";
import { assertRateLimit } from "./safety/rateLimiter.mjs";
import { assertSafeContentRequest, assertSafePosterRequest } from "./safety/contentSafety.mjs";
import { processServerNotification } from "./store/appStoreNotificationStore.mjs";
import { getBrandProfile, saveBrandProfile } from "./store/brandStore.mjs";
import { deleteProject, listProjects, saveProject } from "./store/memoryStore.mjs";
import { currentSubscription, syncSubscription } from "./store/subscriptionStore.mjs";
import { listTemplates } from "./store/templateStore.mjs";

export async function routeRequest(request, response) {
  if (request.method === "OPTIONS") {
    return sendJSON(response, 204, {});
  }

  const url = new URL(request.url ?? "/", "http://localhost");

  if (request.method === "GET" && url.pathname === "/health") {
    return sendJSON(response, 200, {
      status: "ok",
      service: "viralforge-backend"
    });
  }

  if (request.method === "GET" && url.pathname === "/api/quota") {
    return sendJSON(response, 200, await getQuota(userIdFrom(request)));
  }

  if (request.method === "POST" && url.pathname === "/api/quota/pro") {
    const userId = userIdFrom(request);
    const body = await readJSON(request);
    return sendJSON(response, 200, await setProStatus(userId, body.isPro === true));
  }

  if (request.method === "GET" && url.pathname === "/api/subscription") {
    return sendJSON(response, 200, await currentSubscription(userIdFrom(request)));
  }

  if (request.method === "POST" && url.pathname === "/api/subscription/sync") {
    const userId = userIdFrom(request);
    const body = await readJSON(request);
    return sendJSON(response, 200, await syncSubscription(userId, body));
  }

  if (request.method === "GET" && url.pathname === "/api/app-store/status") {
    return sendJSON(response, 200, appStoreServerStatus());
  }

  if (request.method === "POST" && url.pathname === "/api/app-store/notifications/v2") {
    const body = await readJSON(request);
    return sendJSON(response, 200, await processServerNotification(body));
  }

  if (request.method === "GET" && url.pathname === "/api/projects") {
    return sendJSON(response, 200, {
      projects: await listProjects(userIdFrom(request))
    });
  }

  if (request.method === "DELETE" && url.pathname.startsWith("/api/projects/")) {
    const projectId = decodeURIComponent(url.pathname.replace("/api/projects/", ""));
    if (!projectId.trim()) {
      return sendJSON(response, 400, {
        error: {
          code: "missing_project_id",
          message: "Missing project id."
        }
      });
    }
    return sendJSON(response, 200, {
      deleted: await deleteProject(userIdFrom(request), projectId)
    });
  }

  if (request.method === "GET" && url.pathname === "/api/templates") {
    return sendJSON(response, 200, {
      templates: await listTemplates()
    });
  }

  if (request.method === "GET" && url.pathname === "/api/providers/status") {
    return sendJSON(response, 200, providerStatus());
  }

  if (request.method === "GET" && url.pathname === "/api/brand") {
    return sendJSON(response, 200, {
      profile: await getBrandProfile(userIdFrom(request))
    });
  }

  if (request.method === "POST" && url.pathname === "/api/brand") {
    const userId = userIdFrom(request);
    const body = await readJSON(request);
    return sendJSON(response, 200, {
      profile: await saveBrandProfile(userId, body.profile ?? body)
    });
  }

  if (request.method === "POST" && url.pathname === "/api/content/generate") {
    const userId = userIdFrom(request);
    const body = await readJSON(request);
    const brandProfile = await getBrandProfile(userId);
    const enrichedBody = applyBrandProfile(body, brandProfile);
    assertSafeContentRequest(enrichedBody);
    await ensureTextGenerationAvailable(userId);
    assertRateLimit(userId, "content");
    const generated = await generateContent(enrichedBody);
    await consumeTextGeneration(userId);
    const result = {
      ...generated,
      projectId: generated.projectId || randomUUID()
    };
    await saveProject(userId, {
      projectId: result.projectId,
      createdAt: new Date().toISOString(),
      input: enrichedBody,
      result
    });
    return sendJSON(response, 200, result);
  }

  if (request.method === "POST" && url.pathname === "/api/poster/background") {
    const userId = userIdFrom(request);
    const body = await readJSON(request);
    assertSafePosterRequest(body);
    await ensurePosterExportAvailable(userId);
    assertRateLimit(userId, "poster");
    const result = await generatePosterBackground(body);
    await consumePosterExport(userId);
    return sendJSON(response, 200, result);
  }

  if (request.method === "POST" && url.pathname === "/api/project/save") {
    const userId = userIdFrom(request);
    const body = await readJSON(request);
    const saved = await saveProject(userId, {
      ...body,
      updatedAt: new Date().toISOString()
    });
    return sendJSON(response, 200, {
      project: saved
    });
  }

  return sendJSON(response, 404, {
    error: {
      code: "not_found",
      message: "Route not found."
    }
  });
}

function userIdFrom(request) {
  return request.headers["x-user-id"] || "demo-user";
}

function applyBrandProfile(body, profile) {
  return {
    ...body,
    brandName: firstNonEmpty(body.brandName, profile.brandName),
    brandIndustry: firstNonEmpty(body.brandIndustry, profile.industry),
    audience: firstNonEmpty(body.audience, profile.audience),
    tone: firstNonEmpty(body.tone, profile.tone),
    bannedWords: firstNonEmpty(body.bannedWords, profile.bannedWords)
  };
}

function firstNonEmpty(primary, fallback) {
  if (typeof primary === "string" && primary.trim()) {
    return primary;
  }
  return typeof fallback === "string" ? fallback : "";
}

async function readJSON(request) {
  const chunks = [];
  for await (const chunk of request) {
    chunks.push(chunk);
  }

  const raw = Buffer.concat(chunks).toString("utf8");
  if (!raw.trim()) {
    return {};
  }

  try {
    return JSON.parse(raw);
  } catch {
    const error = new Error("Invalid JSON body.");
    error.statusCode = 400;
    throw error;
  }
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
