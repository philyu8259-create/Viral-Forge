# Viral Forge Project Context

## Current Direction

Viral Forge is a single-bundle dual-locale iOS app for generating viral content packages and AI poster backgrounds. The app follows the user's phone language: Simplified Chinese mode focuses on Chinese social platforms, while English mode focuses on global short-form platforms.

## Product Scope

- Default language follows the phone system language.
- Chinese mode platforms: Xiaohongshu, Douyin, WeChat.
- English mode platforms: TikTok, Instagram, YouTube Shorts.
- First useful outputs: copy package, poster copy, AI poster background, rendered poster export, saved project history.
- The app should not feel like a generic chatbot; it should package workflows and templates around content creation.
- UI/UX expert design is planned later. Current work should continue functional MVP scaffolding and tell the user when it is ready for design handoff.

## AI Provider Decisions

- China backend mode: `AI_PROVIDER_MODE=china_live`.
- Text generation: Qwen.
- Image generation: Volcengine Ark / Seedream.
- English UI/mock generation is now part of the MVP.
- Production English live generation can either use `china_live` with Qwen/Seedream English prompts, or `AI_PROVIDER_MODE=live` with OpenAI keys for English text/image routes.
- Volcengine TOS object storage is optional and should not be deployed for MVP unless explicitly requested later.

## Monetization

- Monthly subscription:
  - Name: ViralForge Pro Monthly
  - Product ID: `viralforge_pro_monthly`
  - Target price: USD 5.99/month or China CNY 39.8/month
- Yearly subscription:
  - Name: ViralForge Pro Yearly
  - Product ID: `viralforge_pro_yearly`
  - Target price: USD 59.99/year or China CNY 398/year

## App Store Connect State

- App ID: `6763895926`
- Subscription group: `ViralForge Pro`
- Subscription group ID: `22053732`
- Monthly Apple ID: `6763896490`
- Yearly Apple ID: `6763896846`
- Subscription review screenshots are still needed after UI/UX design is final.
- App Store Server Notifications V2 should be configured after a public HTTPS backend URL exists.

## Backend State

- Backend is Node.js 22 with SQLite.
- Local provider keys are configured outside source control; never print or commit real secrets.
- `.env` and SQLite data are excluded from source control.
- App Store Server API skeleton exists, with local development verification and notification routes.
- Docker is not currently available locally, so local Docker image builds have not been verified.
- TOS storage should remain skipped for now.

## iOS Configuration

- Project path: `/Users/phil/Desktop/Codex Project/Viral Forge`
- Debug builds default to `http://localhost:8787`.
- Release builds intentionally have empty `BACKEND_BASE_URL` until a public HTTPS backend URL is chosen.
- Before TestFlight/App Store, set Release `BACKEND_BASE_URL` in `project.yml`, regenerate the Xcode project, and rebuild.

## Recent Verification

- Backend `npm run check` passed.
- Backend `npm run smoke:local` passed with a temporary SQLite database and mock providers.
- Live China provider test is now reproducible as `npm run smoke:china-live`; it starts an isolated temporary SQLite backend, verifies `china_live`, calls Qwen for Chinese copy, and calls Seedream for a poster background image URL.
- Content topic-guard was added after a live simulator run drifted from "便携榨汁杯" to another product. `npm run check` now includes `scripts/check-content-guard.mjs`, and a live Qwen text-only request confirmed the result included "便携榨汁杯".
- iOS generation input validation was added for empty, punctuation-only, and too-short topics. Home and template generation now disable invalid submissions, show inline guidance only after invalid input, clear stale generation errors while editing, and expose retry buttons on generation failure.
- Brand memory is now functional: brand profile saves locally, syncs to backend when available, appears on Home/Templates, and generation requests carry brand name, industry, audience, tone, and banned words. Backend `/api/content/generate` also enriches requests from saved brand profiles.
- Asset library was upgraded from placeholders: projects now open full content results, poster assets still open the poster editor, favorites are filterable, reusable title/hook/caption/hashtag snippets can be copied, and ResultView supports editing the poster or regenerating from the same brief.
- Batch creation is functional for the China-first MVP: users can enter a product brief, choose 7 or 14 days, select Xiaohongshu/Douyin/WeChat, reuse saved brand memory, generate a content calendar, and turn each day into a full content pack/poster draft. The batch page now auto-scrolls to the generated calendar and keeps enough bottom spacing above the tab bar.
- Simulator screenshot: `/Users/phil/Desktop/Codex Project/Viral Forge/Screenshots/viralforge-batch-calendar.png`
- Poster export/share flow is functional: PosterEditor renders a real PNG file, exposes ShareLink for the PNG, offers Save to Photos, shows export status and preview, marks the project as exported, and makes the poster appear in the Assets > Posters tab.
- Simulator screenshot: `/Users/phil/Desktop/Codex Project/Viral Forge/Screenshots/viralforge-poster-export-asset.png`
- Full local backend flow passed on iPhone 17 with backend at `http://localhost:8787`: backend health/quota/templates/provider status were reachable, Qwen generated Chinese copy for "便携榨汁杯", Seedream returned a poster background URL, the app synced persisted backend projects, generated an AI background inside PosterEditor, exported the PNG, and showed the new poster in Assets > Posters.
- Demo user was temporarily set to Pro locally via `/api/quota/pro` for validation because the free quota was already 0/0.
- Simulator screenshot: `/Users/phil/Desktop/Codex Project/Viral Forge/Screenshots/viralforge-full-local-backend-flow.png`
- Home screen now includes bottom spacer so the final generate button is not trapped behind the tab bar on simulator-sized screens.
- Lightweight local project persistence is now functional for mock/offline mode. Generated projects, poster edits, exports, and favorite changes are saved to device `UserDefaults` and restored on launch.
- China-first launch scope is now enforced in the main app entry points: Home, Brand Kit, Batch Campaign, and default templates expose Xiaohongshu, Douyin, and WeChat instead of international platforms. Default template names and hints were rewritten in Chinese.
- Asset/history cleanup is implemented: projects can be deleted locally from Assets or History, and backend mode also deletes the matching SQLite project row through `DELETE /api/projects/:id`.
- Poster editor now supports one-click canvas targets: Xiaohongshu 3:4, Douyin 9:16, and WeChat 1:1. PNG export uses the selected target dimensions, and AI background generation receives the matching aspect ratio.
- Home/template generation now opens the content result page first, with poster editing available from the result page, so users see the copy package before refining visual assets.
- Local StoreKit testing is aligned with the China-first price plan: `ViralForge.storekit` uses `zh_CN` / `CHN`, monthly `39.8`, yearly `398`.
- Simulator screenshot after China-first cleanup: `/Users/phil/Desktop/Codex Project/Viral Forge/Screenshots/viralforge-china-first-home.png`
- UI/UX direction has started landing in code: Home is now a vibrant ecommerce Studio dashboard with warm red/orange/purple/cyan ambience, colorful platform pills, glassy icon backlights, a recessed brief editor, Magic Paste, topic-triggered strategy expansion, haptic interaction feedback, live/recent pipeline cards, hot template previews, workflow shortcuts, and a shimmer-style generation CTA. This is connected to the existing `AppModel` generation flow rather than a standalone sample view.
- Simulator screenshot for the Vibrant Studio home: `/Users/phil/Desktop/Codex Project/Viral Forge/Screenshots/viralforge-vibrant-studio-home.png`
- Global UI/UX styling has been applied beyond Home: shared `VFStyle` / `VFPage` / glass card components now drive Templates, Brand Kit, Assets, Paywall, Batch Campaign, History, Backend Settings, Result, and quota cards with the same vibrant ecommerce Studio language.
- Simulator screenshot after global styling: `/Users/phil/Desktop/Codex Project/Viral Forge/Screenshots/viralforge-global-style-home.png`
- Follow-up UI/UX audit passed iOS Debug build and reinstalled on iPhone 17 simulator. Poster Editor controls/export actions were also brought into the global vibrant Studio language after the audit found it was still using system bordered buttons.
- Simulator screenshot after UI audit: `/Users/phil/Desktop/Codex Project/Viral Forge/Screenshots/viralforge-ui-audit-create.png`
- Core creation flow now has automated UI smoke tests. `ViralForgeUITests/CreationFlowUITests.swift` launches in Chinese mock mode, enters a product brief, taps the Home generation CTA, verifies the Result page and the `标题` section, then covers Result -> Poster Editor -> render PNG -> Assets -> Posters.
- Dual-locale shell is implemented: Chinese locale uses Xiaohongshu/Douyin/WeChat, English locale uses TikTok/Instagram/YouTube Shorts, default generation language follows `Locale.preferredLanguages`, local sample templates/projects switch by locale, backend templates now include both Chinese and English launch platforms, and photo-library permission copy is localized through `InfoPlist.strings`.
- UI smoke tests now include an English `en_US` launch that verifies global platform pills and generates an English mock content pack to the `Titles` result section.
- Result pages now include a one-tap full publish package export. `ContentProject.formattedPublishPackage` formats platform, topic, best title, hook, caption, selling points, hashtags, and poster copy in Chinese or English, and ResultView exposes Copy Pack plus Share Text actions with visible copy feedback.
- Result copy editing is now functional. ResultView opens an edit sheet for titles, hooks, caption, selling points, and hashtags; saving updates local project state and syncs the edited content result to the backend when backend mode is enabled.
- Template library has been upgraded into a workflow asset system: six monetization-focused categories now cover Product Seeding, Store Traffic, Personal Brand, Live Launch, Seasonal Promo, and New Launch. Each template carries default goal, audience, tone, content structure, sample outcome, output badges, and a direct Use Template generation path. The in-app positioning is now `Viral Template Studio` / `爆款模板工作台` instead of a Canva-branded comparison, and the bilingual local/backend template seeds include visual templates for covers, posters, promo images, key visuals, and live deal graphics.
- Template-to-create workflow is now connected: Template Detail can apply a template preset back to the Create tab, the app root supports programmatic tab switching, Home consumes the applied workflow, shows an applied-template card, preloads platform/goal/audience/tone/poster style, and lets the user only fill the product brief before generating.
- Backend beta protection now includes pre-provider content safety checks for illegal/dangerous, medical, financial, and absolute advertising claims; in-memory per-user rate limiting for content/poster requests; and quota checks that only consume quota after a successful provider response. Backend smoke covers unsafe input blocking, blocked requests not consuming quota, and rapid-request rate limiting.
- App-facing generation errors now map backend quota, rate-limit, content-policy, and provider failures to clearer localized user messages. UI tests include a no-quota Home error-card scenario.
- User-facing edge states are now more product-ready: Assets and History empty states explain the next step and route to Create/Templates, Backend Settings explains unreachable servers and Mock fallback, Brand Kit highlights first setup fields, Paywall can retry StoreKit product loading, Poster Editor preserves manual export after AI background failure, and copy feedback stays visible longer.
- Subscription readiness now has a repeatable local backend smoke: `npm run smoke:subscriptions` verifies local Pro sync, unsupported product rejection, signed transaction field checks, and App Store Server Notification V2 expiration/renewal updates. `SUBSCRIPTION_SANDBOX_TEST_PLAN.md` documents the local StoreKit and TestFlight sandbox pass.
- App icon is now deployed through `ViralForge/Assets.xcassets/AppIcon.appiconset` and wired via `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`. The icon is generated as a full-bleed 1024px opaque master from the provided artwork, with the bottom-right generated-image mark removed by cropping it out instead of leaving a repair artifact.
- Settings/App Store shell is now in place: `SettingsView` exposes privacy policy, terms, support, email support, data deletion request, restore purchases, version, backend mode, and user ID. Bilingual public pages live under `docs/`, GitHub Pages is enabled from `main /docs`, and the public URLs have been verified.
- Legal/support pages are split by locale for the single-bundle dual-mode app: Simplified Chinese pages live under `docs/zh/`, English pages live under `docs/en/`, and Settings opens the matching URL based on the phone locale.
- App Store Connect copy draft now lives in `APP_STORE_METADATA.md`, covering Chinese and English app metadata, subscription metadata, privacy-answer guidance, review notes, and screenshot planning.
- Settings now includes a local data deletion control that clears on-device projects, poster assets, snippets, and brand memory without affecting subscriptions; backend/account deletion remains an email support flow.
- Assets now behaves more like a real library: project cards expose open/copy/favorite/delete actions with confirmation, poster assets expose edit/copy/remove actions, snippets remain reusable, and poster removal preserves the underlying project copy.
- Latest end-to-end checks passed: `xcodebuild ... test` on iPhone 17 simulator for asset project/snippet sections, empty assets next-action routing, English locale generation, Chinese mock generation, no-quota error UI, Paywall China subscription plan display, result copy-pack export, result edit/save, poster export/assets flows, template library/detail workflow, and template apply-to-studio flow; backend `npm run check`, `npm run smoke:local`, and `npm run smoke:subscriptions` also passed.
- Core creation flow screenshots: `/Users/phil/Desktop/Codex Project/Viral Forge/Screenshots/e2e-01-fresh-home.png`, `/Users/phil/Desktop/Codex Project/Viral Forge/Screenshots/e2e-02-topic-entered.png`, `/Users/phil/Desktop/Codex Project/Viral Forge/Screenshots/e2e-03-result.png`
- Previous Elite Studio home screenshot: `/Users/phil/Desktop/Codex Project/Viral Forge/Screenshots/viralforge-elite-studio-home.png`
- Previous Studio home screenshot: `/Users/phil/Desktop/Codex Project/Viral Forge/Screenshots/viralforge-studio-home.png`
- Previous bright dashboard reference screenshot: `/Users/phil/Desktop/Codex Project/Viral Forge/Screenshots/viralforge-bright-glass-home.png`
- Older dark dashboard reference screenshot: `/Users/phil/Desktop/Codex Project/Viral Forge/Screenshots/viralforge-glass-dashboard-tabbar.png`
- iOS Debug build passed on iPhone 17 simulator.
- iOS Release simulator build passed before the folder rename.
- After renaming the folder to `Viral Forge`, backend check and iOS Debug build passed again.
- Latest validation after local persistence, China-first cleanup, delete flow, poster resize, and StoreKit China-price alignment: iOS Debug build passed on iPhone 17 simulator; `ViralForge.storekit` JSON parses successfully; backend `npm run check` and `npm run smoke:local` passed. Smoke now verifies China-first templates and project deletion.

## Next Work

1. Use `CHINA_RELEASE_CHECKLIST.md` as the TestFlight readiness source of truth, with the added dual-locale requirements.
2. Continue local MVP development only where it clears the checklist or removes launch risk.
3. Use `npm run smoke:local` after backend changes to verify health, provider status, quota, content generation, and poster background routes without consuming live model credits. Use `npm run smoke:china-live` only when intentionally validating paid Qwen/Seedream integration.
4. The functional MVP is close to UI/UX handoff: a designer can now redesign the visible screens around real workflows instead of placeholders.
5. Before TestFlight, deploy a public HTTPS backend, update Release `BACKEND_BASE_URL`, regenerate the Xcode project, and validate the app against that backend.
6. Prepare public Simplified Chinese and English privacy policy/terms, App Store metadata, and subscription screenshots.
7. Later, Alibaba Cloud FC + Tablestore remains viable but requires replacing SQLite persistence and adapting the HTTP server to a serverless handler.
