# ViralForge Backend Deployment

## Runtime

- Node.js 22 or later
- Persistent disk if using SQLite
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
SQLITE_PATH=/data/viralforge.sqlite
AI_PROVIDER_MODE=china_live
QWEN_API_KEY=
SEEDREAM_API_KEY=
ARK_API_KEY=
IAP_VERIFICATION_MODE=app_store_server
APP_STORE_SERVER_ENVIRONMENT=sandbox
APP_STORE_SERVER_ISSUER_ID=
APP_STORE_SERVER_KEY_ID=
APP_STORE_SERVER_BUNDLE_ID=com.phil.viralforge
APP_STORE_SERVER_PRIVATE_KEY_PATH=/run/secrets/AuthKey_XXXXXXXXXX.p8
```

Keep `.env`, `.p8` files, and SQLite data out of source control.

Use `AI_PROVIDER_MODE=china_live` for the first China release. This mode only requires Qwen and Seedream/Ark provider keys. `OPENAI_API_KEY` is only needed when the international release is enabled later with `AI_PROVIDER_MODE=live`.

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

1. Create a Node 22 service or deploy the Docker image.
2. Attach persistent storage and set `SQLITE_PATH` to that mounted disk.
3. Add provider API keys as encrypted environment variables.
4. Add App Store Server API credentials as encrypted environment variables or mounted secret files.
5. Expose the service behind HTTPS.
6. Set App Store Server Notifications V2 in App Store Connect:

```text
https://YOUR_BACKEND_DOMAIN/api/app-store/notifications/v2
```

7. Test Apple notifications from App Store Connect.
8. Update the iOS app backend URL to the public HTTPS backend URL before TestFlight.

## iOS Backend URL

Debug builds default to:

```text
http://localhost:8787
```

Release builds intentionally do not default to localhost. Before TestFlight or App Store submission, set `INFOPLIST_KEY_BACKEND_BASE_URL` for the Release configuration in `project.yml` to the public HTTPS backend URL, regenerate the Xcode project, then rebuild the app.

## Production Notes

SQLite is acceptable for early TestFlight and low-volume MVP usage if the platform provides reliable persistent storage and backups. Before scaling, move quota, projects, subscriptions, and notifications to a managed database.

Use `APP_STORE_SERVER_ENVIRONMENT=sandbox` for TestFlight. Switch to `production` for the production app release after sandbox verification passes.
