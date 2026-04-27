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

## TestFlight Readiness Gap List

This is the source of truth for the first China TestFlight build. Keep the first beta China-only; do not add international/OpenAI scope to clear these items.

### Verified Local Baseline

- [x] Core creation flow works in Chinese mock mode: Home -> Result.
- [x] Poster flow works in UI smoke tests: Result -> Poster Editor -> rendered PNG -> Assets > Posters.
- [x] Backend local checks pass with mock/local providers: `npm run check` and `npm run smoke:local`.
- [x] Local StoreKit configuration uses the China-first subscription products and prices.
- [x] Release build keeps `BACKEND_BASE_URL` empty until a real public HTTPS backend is chosen.

### P0 Before First TestFlight Upload

- [ ] Deploy a public HTTPS backend for the beta build.
- [ ] Configure backend production/sandbox environment variables without committing secrets:
  - `AI_PROVIDER_MODE=china_live`
  - `QWEN_API_KEY`
  - `SEEDREAM_API_KEY` or `ARK_API_KEY`
  - App Store Server API issuer/key/bundle/subscription configuration
  - Persistent SQLite database path and backup plan
- [ ] Update the iOS Release `BACKEND_BASE_URL` in `project.yml`, regenerate the Xcode project, and rebuild.
- [ ] Validate the iOS app against the deployed backend, including quota, generation, poster background, project sync, and deletion.
- [ ] Create public Simplified Chinese Privacy Policy and Terms URLs.
- [ ] Localize the photo-library save permission copy. Current `NSPhotoLibraryAddUsageDescription` is English-only.
- [ ] Finish App Store Connect agreements, tax, and banking so subscriptions can be tested and sold.
- [ ] Add Simplified Chinese App Store metadata, app screenshots, and subscription review screenshots.
- [ ] Archive and upload a TestFlight build from the final Release configuration.

### P1 Before Wider External Beta

- [ ] Test sandbox purchase, restore, renewal, cancellation, and expired subscription states.
- [ ] Configure and verify App Store Server Notifications V2 against the deployed backend.
- [ ] Add basic server-side quota/rate-limit protection for provider cost control.
- [ ] Harden content safety for illegal, medical, financial, exaggerated, and platform-risky claims.
- [ ] Polish backend-down, provider-error, empty-state, and no-quota user-facing messages.
- [ ] Add minimal crash/error monitoring or an operational log review routine for beta support.

### P2 Before App Review

- [ ] Complete UI/UX expert pass and final screenshot set after the visible design stabilizes.
- [ ] Verify layout on target iPhone sizes and any required iPad presentation paths.
- [ ] Confirm ICP/domain requirements based on the final China hosting and domain plan.
- [ ] Add final support/contact flow and account/data deletion instructions.

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
