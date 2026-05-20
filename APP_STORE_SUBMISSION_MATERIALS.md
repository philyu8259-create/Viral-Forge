# App Store Connect Submission Materials

Prepared for ViralForge `1.1 (10)`.

## App Information

- Bundle ID: `com.phil.viralforge`
- SKU: `viralforge-ios`
- Primary category: Graphics & Design
- Secondary category: Business
- Age rating: 4+
- Copyright: `2026 Phil Yu`
- App Review contact email: `philyu2023@qq.com`
- Support URL: `https://philyu8259-create.github.io/Viral-Forge/zh/support.html`
- Privacy Policy URL: `https://philyu8259-create.github.io/Viral-Forge/zh/privacy.html`

## Simplified Chinese

- Name: `ViralForge 爆款内容助手`
- Subtitle: `种草短视频AI创作工具`
- Promotional Text: `从产品简报到爆款文案、真实 AI 海报和品牌记忆，一套工作流完成种草内容创作。`
- Keywords: `AI文案,海报,内容创作,新媒体,种草,短视频,私域,电商,个人IP,营销`
- Privacy URL: `https://philyu8259-create.github.io/Viral-Forge/zh/privacy.html`
- Support URL: `https://philyu8259-create.github.io/Viral-Forge/zh/support.html`
- Terms URL: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`

## English

- Name: `ViralForge AI Studio`
- Subtitle: `AI posts, posters, planning`
- Promotional Text: `Turn one product brief into social copy, AI poster assets, brand-consistent posts, and reusable creator workflows.`
- Keywords: `AI writer,content,poster,social,short video,creator,marketing,copywriting,brand`
- Privacy URL: `https://philyu8259-create.github.io/Viral-Forge/en/privacy.html`
- Support URL: `https://philyu8259-create.github.io/Viral-Forge/en/support.html`
- Terms URL: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`

## Review Notes

ViralForge is a single-bundle dual-locale iOS app for AI copy and poster creation. No login is required.

Suggested review flow:
1. Open the Create tab.
2. Enter a product or topic brief, for example: `portable blender for office breakfast`.
3. Tap Start Viral Creation to generate copy and poster direction.
4. Open the generated result, copy text, and tap the poster/image action to preview or edit the poster.
5. Open Settings or the Pro tab to view Privacy Policy, Terms of Use, Support, Restore Purchases, and subscription status.

Free users have a limited starter quota and may see Pangle app-open ads, native/feed ads, and rewarded video ads. ViralForge requests App Tracking Transparency permission on first launch for free/non-Pro users before starting the Pangle SDK and before requesting app-open, native/feed, or rewarded ads. To review this, install a fresh build and open the app; the system tracking permission prompt appears from the Create tab before ads are loaded. ViralForge Pro uses Apple StoreKit subscriptions and unlocks premium templates, watermark-free export, unlimited copy generation, AI background generation up to 10/day and 200/month, and a completely ad-free experience.

The Release build uses the public ViralForge backend:
`https://viralfo-backend-ipiunjbsno.cn-hangzhou.fcapp.run`

Support email: `philyu2023@qq.com`

## Subscriptions

### Monthly

- Product ID: `viralforge_pro_monthly`
- Reference Name: `ViralForge Pro Monthly`
- Display Name zh-CN: `ViralForge Pro 月度会员`
- Display Name en-US: `ViralForge Pro Monthly`
- Price: `CNY 39.8/month`
- Description zh-CN: `解锁不限文案、会员模板、完全去广告、无水印导出和 AI 背景 10张/天、200张/月。`
- Description en-US: `Unlock unlimited copy, premium templates, ad-free use, watermark-free exports, and AI backgrounds up to 10/day and 200/month.`

### Yearly

- Product ID: `viralforge_pro_yearly`
- Reference Name: `ViralForge Pro Yearly`
- Display Name zh-CN: `ViralForge Pro 年度会员`
- Display Name en-US: `ViralForge Pro Yearly`
- Price: `CNY 398/year`
- Description zh-CN: `按年解锁不限文案、会员模板、完全去广告、无水印导出和 AI 背景 10张/天、200张/月。`
- Description en-US: `Yearly access to unlimited copy, premium templates, ad-free use, watermark-free exports, and AI backgrounds up to 10/day and 200/month.`

## App Privacy Draft

- Tracking: Yes when Release ads are enabled through Pangle and ATT. Disclose advertising identifiers/device identifiers and ad interaction data used for third-party advertising or attribution.
- Data linked to user:
  - User Content: product briefs, prompts, uploaded product reference images, generated copy, poster drafts, brand profile fields, saved projects.
  - Purchases: StoreKit product ID, subscription state, transaction state needed for entitlement sync.
  - Identifiers: in-app user ID and StoreKit app account token.
  - Usage Data: generation quota, project sync events, and basic app-functionality request metadata.
- Data not linked to user:
  - Operational diagnostics only if backend logs are retained without linking to in-app user ID.
  - Ad SDK diagnostics, ad performance, and SKAdNetwork attribution only if configured by Pangle without linking to the in-app user ID.
- Sensitive Data: No intentional collection.
- Photos/Videos: Used when the user selects a product reference image or saves a generated poster. Disclose selected reference images as collected for app functionality if they are transmitted to the backend or Seedream.
- Pro ad removal: Pro users are completely ad-free; free users may see app-open, native/feed, and rewarded video ads.

## App Store Screenshots

Use localized screenshot sets for both app languages.

### iPad Pro 13-inch

Chinese screenshots with promotional headlines:

1. `artifacts/app_store_previews/ipad13_cn/01_home.png`
2. `artifacts/app_store_previews/ipad13_cn/02_result.png`
3. `artifacts/app_store_previews/ipad13_cn/03_poster.png`
4. `artifacts/app_store_previews/ipad13_cn/04_templates.png`
5. `artifacts/app_store_previews/ipad13_cn/05_brand.png`
6. `artifacts/app_store_previews/ipad13_cn/06_pro.png`

English screenshots with promotional headlines:

1. `artifacts/app_store_previews/ipad13_en/01_home.png`
2. `artifacts/app_store_previews/ipad13_en/02_result.png`
3. `artifacts/app_store_previews/ipad13_en/03_poster.png`
4. `artifacts/app_store_previews/ipad13_en/04_templates.png`
5. `artifacts/app_store_previews/ipad13_en/05_brand.png`
6. `artifacts/app_store_previews/ipad13_en/06_pro.png`

Contact sheets for review:

- `artifacts/app_store_previews/ipad13_cn/_contact_sheet.jpg`
- `artifacts/app_store_previews/ipad13_en/_contact_sheet.jpg`

### iPhone 6.9-inch

Chinese screenshots with promotional headlines:

1. `artifacts/app_store_previews/iphone65_cn/01_home.png`
2. `artifacts/app_store_previews/iphone65_cn/02_result.png`
3. `artifacts/app_store_previews/iphone65_cn/03_poster.png`
4. `artifacts/app_store_previews/iphone65_cn/04_templates.png`
5. `artifacts/app_store_previews/iphone65_cn/05_brand.png`
6. `artifacts/app_store_previews/iphone65_cn/06_pro.png`

English screenshots with promotional headlines:

1. `artifacts/app_store_previews/iphone65_en/01_home.png`
2. `artifacts/app_store_previews/iphone65_en/02_result.png`
3. `artifacts/app_store_previews/iphone65_en/03_poster.png`
4. `artifacts/app_store_previews/iphone65_en/04_templates.png`
5. `artifacts/app_store_previews/iphone65_en/05_brand.png`
6. `artifacts/app_store_previews/iphone65_en/06_pro.png`

Contact sheets for review:

- `artifacts/app_store_previews/iphone65_cn/_contact_sheet.jpg`
- `artifacts/app_store_previews/iphone65_en/_contact_sheet.jpg`

### Seedream Hero Poster Asset

The poster screenshots use a real Seedream-generated commercial product background:

- `artifacts/app_store_seedream/office_smoothie_blender_appstore_hero.png`
