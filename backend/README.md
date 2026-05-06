# ViralForge Backend

Prototype backend for the iOS app. It exposes the API shape the app already expects, while keeping model provider keys off device.

## Run

```sh
cd backend
npm start
```

Default URL:

```text
http://localhost:8787
```

Set this in the iOS project's `BACKEND_BASE_URL` build setting when you want the app to call the backend instead of `MockContentService`.

Deployment notes live in [`DEPLOYMENT.md`](./DEPLOYMENT.md).

## Current Endpoints

```text
GET  /health
GET  /api/quota
GET  /api/projects
GET  /api/templates
GET  /api/providers/status
GET  /api/app-store/status
GET  /api/brand
POST /api/brand
POST /api/subscription/sync
POST /api/app-store/notifications/v2
POST /api/content/generate
POST /api/poster/background
POST /api/project/save
```

## SQLite

Local development uses Node's built-in SQLite module and stores data at:

```text
backend/data/viralforge.sqlite
```

Override with:

```text
SQLITE_PATH=/absolute/path/to/viralforge.sqlite
```

The current SQLite layer persists:

- quota
- projects
- brand profiles
- seeded templates
- subscriptions
- App Store Server Notifications V2 posts

## Provider Strategy

`AI_PROVIDER_MODE=mock` is the default prototype mode.

`AI_PROVIDER_MODE=china_live` is the first-release China mode:

- Chinese content generation to Qwen.
- Chinese poster background generation to Seedream.
- Any accidental English request is still routed to Qwen/Seedream so the China release does not depend on OpenAI.

`AI_PROVIDER_MODE=live` currently keeps the same provider family:

- Chinese content generation to Qwen.
- English content generation to Qwen.
- Chinese poster background generation to Seedream.
- English poster background generation to Seedream.

Use this endpoint to check whether the backend can see the required keys without making a paid model call:

```sh
curl http://localhost:8787/api/providers/status
```

To verify the full paid China provider chain with a temporary SQLite database, run:

```sh
npm run smoke:china-live
```

This starts an isolated local backend, forces `AI_PROVIDER_MODE=china_live`, calls Qwen for Chinese copy, calls Seedream for a poster background, and prints only non-secret status fields.

Suggested live settings:

```text
AI_PROVIDER_MODE=china_live
QWEN_API_KEY=...
SEEDREAM_API_KEY=...
QWEN_TEXT_MODEL=qwen-plus
SEEDREAM_IMAGE_MODEL=doubao-seedream-4-5-251128
```

International settings can be revisited later if the app needs a separate overseas provider stack.

Seedream generation uses the Volcengine Ark image generations endpoint by default:

```text
https://ark.cn-beijing.volces.com/api/v3/images/generations
```

The provider router is currently shaped for the Qwen + Seedream stack:

- Chinese text: Qwen
- Chinese image/poster background: Seedream
- English text: Qwen
- English image/poster background: Seedream

The iOS app sends routing hints, but the backend should make the final provider decision.

## App Store Subscription Verification

Local development defaults to client-verified StoreKit 2 transactions:

```text
IAP_VERIFICATION_MODE=local_development
```

For production, configure App Store Server API credentials and switch verification mode:

```text
IAP_VERIFICATION_MODE=app_store_server
APP_STORE_SERVER_ENVIRONMENT=sandbox
APP_STORE_SERVER_ISSUER_ID=...
APP_STORE_SERVER_KEY_ID=...
APP_STORE_SERVER_BUNDLE_ID=com.phil.viralforge
APP_STORE_SERVER_PRIVATE_KEY_PATH=/secure/path/AuthKey_XXXXXXXXXX.p8
```

You can also provide `APP_STORE_SERVER_PRIVATE_KEY` directly, using `\n` for line breaks. Prefer a private key path in deployed environments.

Use this endpoint to confirm the backend can see the required App Store Server API configuration without printing secret values:

```sh
curl http://localhost:8787/api/app-store/status
```

Set the App Store Server Notifications V2 URL in App Store Connect to:

```text
https://YOUR_BACKEND_DOMAIN/api/app-store/notifications/v2
```

The iOS app sends a stable StoreKit `appAccountToken` generated from the backend `userId` when purchasing. The backend stores this token with the subscription, cross-checks it when present in signed transaction payloads, and uses either `appAccountToken` or `originalTransactionId` to match App Store Server Notifications V2 back to the local user.

The notification handler stores the signed notification payload, decodes nested signed transaction and renewal payloads, and updates matching local subscription rows by `appAccountToken` or `originalTransactionId`.
