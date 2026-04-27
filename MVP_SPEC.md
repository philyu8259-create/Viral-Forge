# AI Content Viral Assistant MVP Spec

## Product Positioning

Build a bilingual iOS app that helps creators, small businesses, and sellers generate publish-ready social content packages and poster images in about one minute.

The app is not a generic chatbot. It is a structured content production workspace.

## Target Users

- Chinese creators publishing on Xiaohongshu, Douyin, WeChat Moments, and Video Channels.
- English creators publishing on TikTok, Instagram, YouTube Shorts, and Pinterest.
- Small businesses that need quick product posters and social captions.
- Solo creators who do not want to write prompts manually.

## First Version Goal

Users can enter a product, topic, or idea, then receive:

- Viral titles
- Opening hooks
- Platform-specific captions
- Selling points
- Hashtags
- Poster copy
- AI-generated visual background
- Template-rendered poster image
- Copy/share/export actions

Video generation is not part of the first version. The first version focuses on image and text output.

## Core User Flow

1. User selects language: Chinese or English.
2. User selects platform: Xiaohongshu, Douyin, WeChat, TikTok, Instagram, YouTube Shorts.
3. User selects goal: grow audience, sell product, drive traffic, build personal brand.
4. User enters topic or product details.
5. App generates content package.
6. User selects a poster style.
7. App generates or selects a visual background.
8. App renders the final poster locally with editable text.
9. User saves, shares, copies, or favorites the result.

## MVP Screens And Modules

### 1. HomeView

Purpose: start a new generation.

Elements:

- Language segmented control: Chinese / English
- Platform picker
- Goal picker
- Topic/product text input
- Optional audience input
- Optional product photo upload
- Generate button
- Remaining free quota indicator

### 2. ResultView

Purpose: show generated content package.

Sections:

- Top titles
- Hooks
- Caption/body copy
- Selling points
- Hashtags
- Poster headline and subtitle
- Regenerate and rewrite actions
- Copy buttons per section

Actions:

- Make poster
- Save to history
- Favorite
- Share text

### 3. PosterEditorView

Purpose: create final image output.

Elements:

- Poster preview
- Template picker
- Background style picker
- Editable headline
- Editable subtitle
- CTA/tagline field
- Color palette picker
- Save to Photos
- Share image

Implementation note:

- Important Chinese/English text should be rendered by SwiftUI, not embedded directly inside AI images.
- AI image models generate background, product scenes, and visual style.

### 4. HistoryView

Purpose: retrieve prior generations. In the Canva-like IA, this is folded into AssetsView rather than being a primary tab.

Elements:

- List/grid of saved projects
- Filter by platform/language
- Favorites
- Reopen content package
- Re-export poster

### 5. PaywallView

Purpose: convert users to Pro.

Free:

- 3 content generations per day
- 1 poster export per day
- Basic templates

Pro:

- Higher or unlimited text generations
- More poster exports
- Premium templates
- Batch generation
- No watermark
- AI background generation
- Saved brand profile

### 6. TemplatesView

Purpose: provide a Canva-like starting point instead of forcing every user to begin from a blank prompt.

Elements:

- Template categories: Covers, Product, Knowledge, Promo, Story
- Platform-specific templates
- Free and Pro template states
- Template preview cards
- Use Template action

### 7. BrandKitView

Purpose: keep generated content consistent with the user's brand and account positioning.

Elements:

- Brand name
- Industry
- Target audience
- Tone of voice
- Banned words or claims
- Default platform
- Brand color
- Logo/product asset placeholders

### 8. AssetsView

Purpose: collect prior work and reusable assets in one place.

Elements:

- Projects
- Poster exports
- Favorites
- Uploaded product images placeholder
- Generated backgrounds placeholder
- Copy snippets placeholder

### 9. BatchCreateView

Purpose: support Canva-style bulk creation for campaigns.

Elements:

- Product/campaign brief
- Batch size
- Platform selection
- Planned outputs: titles, hooks, poster copy, content calendar

## Module Data Flow

### Template To Project

```text
TemplatesView
  -> TemplateDetailView
  -> AppModel.draft(from: template)
  -> AppModel.generateProject(from: draft)
  -> ResultView
```

Template-generated drafts carry:

- templateName
- templatePromptHint
- templateStyle
- platform
- goal

### Brand Kit To Generation

```text
BrandKitView
  -> AppModel.brandProfile
  -> AppModel.draftApplyingBrand(to:)
  -> ContentGenerating.generateContent(from:)
```

Brand Kit can fill:

- audience
- tone
- brandName
- default platform when no explicit template platform is selected

### Poster Export To Assets

```text
PosterEditorView
  -> ImageRenderer
  -> AppModel.savePosterExport(for:poster:)
  -> AssetsView / Posters
```

Poster assets track:

- projectId
- projectTopic
- headline
- platform
- style
- createdAt

### Batch Campaign Preview

```text
BatchCreateView
  -> AppModel.batchIdeas(for:platforms:count:)
  -> CampaignIdea list
```

The first version creates a local preview. Later this should call the backend to generate platform-specific campaigns, then save selected ideas as projects.

## Primary Navigation

```text
Create / Templates / Brand / Assets / Pro
```

History is part of Assets, not a separate first-level tab.

## Model Strategy

### Chinese Version

Text generation:

- Primary: Alibaba Qwen
- Default: qwen-plus class model
- Premium/scoring: qwen-max class model

Image/poster background:

- Primary: Volcengine Seedream

Product background fallback:

- Alibaba Wanxiang product background generation

### English Version

Text generation:

- OpenAI text model

Image/poster background:

- OpenAI image model

## Backend Architecture

The iOS app must never call model providers directly.

```text
iOS App
  -> App Backend
    -> AI Provider Adapter
      -> Qwen / Seedream / OpenAI
    -> Database
    -> Object Storage
    -> Subscription Validation
```

## iOS Service Layer

The app has a switchable content generation service:

```text
ContentGenerating
  -> MockContentService
  -> BackendContentService
```

`ContentServiceFactory` reads `BACKEND_BASE_URL` from `Info.plist`.

- If `BACKEND_BASE_URL` is empty, the app uses `MockContentService`.
- If `BACKEND_BASE_URL` is set, the app uses `BackendContentService`.

This keeps API keys out of the iOS app and lets the app run without a backend during prototype work.

### Model Routing

The iOS app sends a routing hint to the backend, but the backend should make the final provider decision.

```text
Chinese:
  textProvider: qwen
  textModel: qwen-plus
  imageProvider: seedream
  imageModel: seedream-4.5

English:
  textProvider: openai
  textModel: gpt-5.4
  imageProvider: openai
  imageModel: gpt-image-2
```

### Backend Provider Modes

```text
AI_PROVIDER_MODE=mock
```

Uses local mock providers and requires no API keys.

```text
AI_PROVIDER_MODE=live
```

Routes:

- Chinese text generation to Qwen.
- English text generation to OpenAI.
- Chinese poster background generation to Seedream.
- English poster background generation to OpenAI image generation.

Provider keys are read from backend environment variables only.

### Prototype SQLite Store

The backend currently uses local SQLite through Node's built-in `node:sqlite` module:

```text
backend/data/viralforge.sqlite
```

The database is ignored by git through `backend/.gitignore`.

The SQLite layer persists:

- `GET /api/quota`
- `GET /api/projects`
- `POST /api/project/save`
- `GET /api/templates`
- `GET /api/brand`
- `POST /api/brand`

Quota is keyed by `x-user-id`, defaulting to `demo-user` during local testing.

Later this should move to a production database and App Store receipt-aware entitlement service.

## Backend API

The local prototype backend lives in:

```text
backend/
```

Run it with:

```sh
cd backend
npm start
```

Validate syntax with:

```sh
cd backend
npm run check
```

### POST /api/content/generate

Request:

```json
{
  "language": "zh",
  "platform": "xiaohongshu",
  "goal": "sell_product",
  "topic": "便携榨汁杯，适合上班族女生",
  "audience": "25-35岁上班族女性",
  "tone": "真实、种草、不夸张"
}
```

Response:

```json
{
  "projectId": "project_123",
  "titles": [
    {
      "text": "上班族女生真的需要这个便携榨汁杯吗？",
      "score": 91,
      "reason": "目标人群明确，带有疑问和购买场景"
    }
  ],
  "hooks": [],
  "caption": "",
  "sellingPoints": [],
  "hashtags": [],
  "poster": {
    "headline": "",
    "subtitle": "",
    "cta": ""
  }
}
```

### POST /api/poster/background

Request:

```json
{
  "projectId": "project_123",
  "language": "zh",
  "style": "clean_product",
  "aspectRatio": "3:4",
  "prompt": "便携榨汁杯，小红书清新商品海报背景"
}
```

Response:

```json
{
  "imageUrl": "https://cdn.example.com/posters/bg_123.png"
}
```

### POST /api/project/save

Saves generated copy, selected template, poster export URL, and metadata.

### GET /api/projects

Returns user's content history.

### GET /api/quota

Returns free/pro quota state.

## Data Model

### User

- id
- email/appleUserId
- locale
- subscriptionStatus
- dailyGenerationCount
- dailyPosterCount
- createdAt

### BrandProfile

- id
- userId
- brandName
- industry
- targetAudience
- tone
- bannedWords
- defaultPlatforms

### ContentProject

- id
- userId
- language
- platform
- goal
- topic
- inputJSON
- resultJSON
- posterJSON
- favorite
- createdAt
- updatedAt

### PosterExport

- id
- projectId
- templateId
- backgroundImageUrl
- finalImageUrl
- aspectRatio
- createdAt

## iOS Tech Stack

- SwiftUI for UI
- SwiftData for local history cache
- StoreKit 2 for subscriptions
- PhotosUI for image upload
- ImageRenderer for poster export
- ShareLink for sharing
- URLSession or a small API client for backend calls

## Poster Rendering Strategy

Use SwiftUI templates:

- 3:4 Xiaohongshu cover
- 9:16 Douyin/TikTok cover
- 1:1 social post
- 4:5 Instagram post

Each template supports:

- Background image
- Headline
- Subtitle
- CTA
- Tags
- Logo/watermark
- Palette

Export:

- Render SwiftUI view to UIImage with ImageRenderer.
- Save PNG/JPEG to Photos.
- Share through system share sheet.

## Monetization

Free plan:

- 3 text generations per day
- 1 poster export per day
- Limited templates
- Watermark

Pro monthly:

- More generations
- More poster exports
- Premium templates
- No watermark
- Brand profile memory

Pro yearly:

- Same features with discount.

Optional later:

- Credit packs for high-cost AI image/video generation.

## Two-Week Build Plan

### Days 1-2

- Create iOS project.
- Build HomeView, ResultView, PosterEditorView shell.
- Define local models and mock API responses.

### Days 3-4

- Implement backend skeleton.
- Implement content generation endpoint.
- Add provider abstraction for Chinese and English models.

### Days 5-6

- Implement poster templates in SwiftUI.
- Implement local poster export.
- Add save/share actions.

### Days 7-8

- Connect real text model.
- Add structured JSON parsing and error handling.
- Add basic quota tracking.

### Days 9-10

- Connect image background generation.
- Add loading states and retry states.
- Store generated background image URLs.

### Days 11-12

- Add HistoryView.
- Add SwiftData local cache.
- Add favorites.

### Days 13-14

- Add StoreKit 2 paywall skeleton.
- Polish UI.
- Test Chinese and English flows.
- Prepare TestFlight build checklist.

## Version 2 Ideas

- Material-to-video generation with user-uploaded images.
- AI voiceover.
- Auto subtitles.
- Batch content calendar.
- Trending topic suggestions.
- Competitor account inspiration.
- Team workspace for small businesses.
