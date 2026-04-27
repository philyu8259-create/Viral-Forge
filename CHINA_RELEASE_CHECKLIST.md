# China Release Checklist

This checklist tracks the first ViralForge release for Chinese users. International/OpenAI support remains in the codebase but is not required for this phase.

## Product Scope

- Default generation language: Chinese.
- Primary platforms: Xiaohongshu, Douyin, WeChat.
- First output types: copy package, poster copy, AI poster background, rendered poster export.
- First paid plan: ViralForge Pro monthly/yearly.

## AI Providers

Use backend-only provider keys:

```env
AI_PROVIDER_MODE=china_live
QWEN_API_KEY=
QWEN_TEXT_MODEL=qwen-plus
SEEDREAM_API_KEY=
ARK_API_KEY=
SEEDREAM_IMAGE_MODEL=doubao-seedream-4-5-251128
SEEDREAM_IMAGES_URL=https://ark.cn-beijing.volces.com/api/v3/images/generations
```

`china_live` routes all current generation calls to Qwen and Seedream/Ark, even if an English language value is accidentally sent.

## App Store China Setup

- Monthly product ID: `viralforge_pro_monthly`
- Yearly product ID: `viralforge_pro_yearly`
- China target monthly price: `CNY 39.8/month`
- China target yearly price: `CNY 398/year`
- Confirm China storefront price manually in App Store Connect.
- Add Simplified Chinese subscription screenshots after UI/UX design is final.
- Attach the first subscription to the app version before submitting to App Review.

## Backend Deployment

- Deploy backend behind public HTTPS.
- Use `AI_PROVIDER_MODE=china_live`.
- Store provider keys and App Store Server API keys as encrypted environment variables or secret files.
- Use persistent storage for SQLite during TestFlight/MVP.
- Set the iOS Release `INFOPLIST_KEY_BACKEND_BASE_URL` to the public HTTPS backend URL before TestFlight.
- Configure App Store Server Notifications V2:

```text
https://YOUR_BACKEND_DOMAIN/api/app-store/notifications/v2
```

## Compliance And Operations

- Prepare Simplified Chinese privacy policy and terms.
- Confirm photo library usage copy is localized.
- Add content safety rules before broad launch:
  - Block illegal, medical, financial, and exaggerated claims.
  - Add banned-word handling from Brand Kit.
  - Log provider errors without storing provider API keys.
- Decide whether the public backend domain requires ICP filing based on the final hosting location and domain usage.

## Later International Phase

- Enable `AI_PROVIDER_MODE=live`.
- Configure `OPENAI_API_KEY`.
- Revisit English App Store metadata, screenshots, pricing, and support copy.
