# Viral Forge Project Context

## Current Direction

Viral Forge is a China-first iOS app for generating viral content packages and AI poster backgrounds. The first release focuses on Chinese users and domestic model providers. International/OpenAI support remains deferred.

## Product Scope

- Default language: Simplified Chinese, following the phone system language.
- Primary platforms: Xiaohongshu, Douyin, WeChat.
- First useful outputs: copy package, poster copy, AI poster background, rendered poster export, saved project history.
- The app should not feel like a generic chatbot; it should package workflows and templates around content creation.
- UI/UX expert design is planned later. Current work should continue functional MVP scaffolding and tell the user when it is ready for design handoff.

## AI Provider Decisions

- China-first backend mode: `AI_PROVIDER_MODE=china_live`.
- Text generation: Qwen.
- Image generation: Volcengine Ark / Seedream.
- English/OpenAI support is intentionally postponed.
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
- Live China provider test passed locally: Qwen generated a Chinese content package, and Seedream returned a poster background image URL.
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
- iOS Debug build passed on iPhone 17 simulator.
- iOS Release simulator build passed before the folder rename.
- After renaming the folder to `Viral Forge`, backend check and iOS Debug build passed again.
- Latest validation after local persistence, China-first cleanup, delete flow, poster resize, and StoreKit China-price alignment: iOS Debug build passed on iPhone 17 simulator; `ViralForge.storekit` JSON parses successfully; backend `npm run check` and `npm run smoke:local` passed. Smoke now verifies China-first templates and project deletion.

## Next Work

1. Continue local MVP development before public deployment.
2. Use `npm run smoke:local` after backend changes to verify health, provider status, quota, content generation, and poster background routes without consuming live model credits.
3. The functional MVP is close to UI/UX handoff: a designer can now redesign the visible screens around real workflows instead of placeholders.
4. Later, choose deployment architecture. Alibaba Cloud FC + Tablestore is viable but requires replacing SQLite persistence and adapting the HTTP server to a serverless handler.
5. Before TestFlight, deploy a public HTTPS backend, update Release `BACKEND_BASE_URL`, and configure App Store Server Notifications V2.
6. Prepare privacy policy, terms, and subscription screenshots after UI design.
