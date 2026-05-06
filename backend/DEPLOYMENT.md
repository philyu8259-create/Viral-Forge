# ViralForge Backend Deployment

## Runtime

- Alibaba Cloud Function Compute custom container
- Node.js 22 container runtime from `backend/Dockerfile`
- Tablestore for persistent data
- Public HTTPS URL for App Store Server Notifications V2

The server listens on `PORT` and exposes:

```text
GET /health
```

Use `/health` as the platform health check.

## Required Environment

Start with these values:

```env
PORT=8787
AI_PROVIDER_MODE=china_live
QWEN_API_KEY=
SEEDREAM_API_KEY=
ARK_API_KEY=
DATA_STORE=tablestore
TABLESTORE_ENDPOINT=https://YOUR_INSTANCE.cn-hangzhou.ots.aliyuncs.com
TABLESTORE_INSTANCE=YOUR_INSTANCE
TABLESTORE_TABLE_NAME=viralforge_records
IAP_VERIFICATION_MODE=app_store_server
APP_STORE_SERVER_ENVIRONMENT=sandbox
APP_STORE_SERVER_ISSUER_ID=
APP_STORE_SERVER_KEY_ID=
APP_STORE_SERVER_BUNDLE_ID=com.phil.viralforge
APP_STORE_SERVER_PRIVATE_KEY=
```

Keep `.env`, private keys, and provider credentials out of source control.

Use `AI_PROVIDER_MODE=china_live` for the first China release. Current live routing only requires Qwen and Seedream/Ark provider keys; OpenAI credentials are not required.

## Docker

Build:

```sh
docker build -t viralforge-backend ./backend
```

Run locally with a persistent data directory:

```sh
docker run --rm \
  -p 8787:8787 \
  --env-file backend/.env \
  -v "$PWD/backend/data:/data" \
  viralforge-backend
```

Check:

```sh
curl http://localhost:8787/health
curl http://localhost:8787/api/providers/status
curl http://localhost:8787/api/app-store/status
```

## Platform Checklist

1. Create an Alibaba Cloud Container Registry repository.
2. Build and push the backend Docker image from `backend/Dockerfile`.
3. Create an Alibaba Cloud Function Compute custom-container function.
4. Set the custom-container listening port to `8787`.
5. Create the Tablestore table from `backend/deploy/fc/README.md`.
6. Add provider, Tablestore, and App Store Server API credentials as FC environment variables.
7. Expose the function through an HTTP trigger or custom HTTPS domain.
6. Set App Store Server Notifications V2 in App Store Connect:

```text
https://YOUR_BACKEND_DOMAIN/api/app-store/notifications/v2
```

8. Test Apple notifications from App Store Connect.
9. Update the iOS app backend URL to the public HTTPS backend URL before TestFlight.

Follow `backend/deploy/fc/README.md` for the FC + Tablestore runbook.

## iOS Backend URL

Debug builds default to:

```text
http://localhost:8787
```

Release builds intentionally do not default to localhost. Before TestFlight or App Store submission, set `INFOPLIST_KEY_BACKEND_BASE_URL` for the Release configuration in `project.yml` to the public HTTPS backend URL, regenerate the Xcode project, then rebuild the app.

## Production Notes

SQLite remains local-development only. TestFlight and production should use `DATA_STORE=tablestore` on FC.

Use `APP_STORE_SERVER_ENVIRONMENT=sandbox` for TestFlight. Switch to `production` for the production app release after sandbox verification passes.
