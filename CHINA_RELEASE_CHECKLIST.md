# China Release Checklist

This checklist tracks the first ViralForge release path. The app is now a single bundle with locale-driven Chinese and English modes; backend deployment can still prioritize China hosting first.

## Product Scope

- Default generation language follows the phone system language.
- Chinese mode platforms: Xiaohongshu, Douyin, WeChat.
- English mode platforms: TikTok, Instagram, YouTube Shorts.
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

This is the source of truth for the first TestFlight build. Keep the first deployment simple, but preserve the single-bundle dual-locale behavior.

### Verified Local Baseline

- [x] Core creation flow works in Chinese mock mode: Home -> Result.
- [x] English locale works in mock mode: Home shows TikTok/Instagram/YouTube Shorts and generates an English Result.
- [x] Poster flow works in UI smoke tests: Result -> Poster Editor -> rendered PNG -> Assets > Posters.
- [x] Backend local checks pass with mock/local providers: `npm run check` and `npm run smoke:local`.
- [x] Backend subscription smoke covers local sync, invalid product rejection, App Store notification expiration, and renewal: `npm run smoke:subscriptions`.
- [x] Local StoreKit configuration uses the China-first subscription products and prices.
- [x] Release build keeps `BACKEND_BASE_URL` empty until a real public HTTPS backend is chosen.
- [x] Photo-library permission copy is localized through `InfoPlist.strings`.

### P0 Before First TestFlight Upload

- [ ] Deploy a public HTTPS backend for the beta build.
- [ ] Decide production provider mode for English live generation:
  - `china_live`: Qwen/Seedream handle both Chinese and English prompts.
  - `live`: English routes require OpenAI text/image keys.
- [ ] Configure backend production/sandbox environment variables without committing secrets:
  - `AI_PROVIDER_MODE=china_live`
  - `QWEN_API_KEY`
  - `SEEDREAM_API_KEY` or `ARK_API_KEY`
  - App Store Server API issuer/key/bundle/subscription configuration
  - Persistent SQLite database path and backup plan
- [ ] Update the iOS Release `BACKEND_BASE_URL` in `project.yml`, regenerate the Xcode project, and rebuild.
- [ ] Validate the iOS app against the deployed backend, including quota, generation, poster background, project sync, and deletion.
- [x] Add in-app Settings entry for privacy policy, terms, support, restore purchases, data deletion, version, and user ID.
- [x] Draft public bilingual Privacy Policy, Terms, and Support pages under `docs/`.
- [ ] Deploy public Simplified Chinese and English Privacy Policy and Terms URLs, then verify they open outside GitHub file view.
- [ ] Finish App Store Connect agreements, tax, and banking so subscriptions can be tested and sold.
- [ ] Add Simplified Chinese and English App Store metadata, app screenshots, and subscription review screenshots.
- [ ] Archive and upload a TestFlight build from the final Release configuration.

### P1 Before Wider External Beta

- [ ] Test sandbox purchase, restore, renewal, cancellation, and expired subscription states.
- [ ] Configure and verify App Store Server Notifications V2 against the deployed backend.
- [ ] Complete the manual steps in `SUBSCRIPTION_SANDBOX_TEST_PLAN.md` with a real TestFlight sandbox account.
- [x] Add basic server-side quota/rate-limit protection for provider cost control.
- [x] Harden content safety for illegal, medical, financial, exaggerated, and platform-risky claims.
- [x] Polish backend-down, provider-error, empty-state, and no-quota user-facing messages.
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
