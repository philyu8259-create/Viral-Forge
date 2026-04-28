import { db, nowISO } from "../db/database.mjs";

const defaultTemplates = [
  { templateId: "xhs-product-seeding-note", name: "小红书真实种草笔记", category: "Product Seeding", platform: "xiaohongshu", style: "Clean", promptHint: "按痛点、场景、体验、购买理由组织小红书种草笔记", lockedToPro: false },
  { templateId: "douyin-product-hook", name: "抖音 3 秒产品钩子", category: "Product Seeding", platform: "douyin", style: "Bold", promptHint: "用短视频前三秒冲突和产品结果抓住注意力", lockedToPro: false },
  { templateId: "xhs-product-cover-poster", name: "小红书产品封面海报", category: "Product Seeding", platform: "xiaohongshu", style: "Clean", promptHint: "产出小红书 3:4 封面海报方向，突出产品名、核心利益点和可读性", lockedToPro: false },
  { templateId: "douyin-thumb-cover", name: "抖音竖版爆点封面", category: "Product Seeding", platform: "douyin", style: "Bold", promptHint: "产出 9:16 竖版视频封面/首帧方向，用强钩子和大字标题提高停留", lockedToPro: false },
  { templateId: "xhs-real-review-comparison", name: "小红书真实测评对比", category: "Product Seeding", platform: "xiaohongshu", style: "Editorial", promptHint: "把产品体验写成真实测评和对比结构，适合横向比较同类产品", lockedToPro: false },
  { templateId: "douyin-unboxing-first-frame", name: "抖音开箱首帧脚本", category: "Product Seeding", platform: "douyin", style: "Bold", promptHint: "产出开箱短视频脚本和首帧封面方向，前三秒突出惊喜点和结果", lockedToPro: false },
  { templateId: "xhs-local-visit-save-card", name: "同城探店收藏卡", category: "Store Traffic", platform: "xiaohongshu", style: "Soft", promptHint: "适合餐饮、美业、亲子、生活方式门店的收藏型探店内容", lockedToPro: false },
  { templateId: "wechat-store-traffic-invite", name: "微信私域到店邀约", category: "Store Traffic", platform: "wechat", style: "Editorial", promptHint: "把门店特色、适合人群和预约理由写成朋友圈/社群转化文案", lockedToPro: false },
  { templateId: "xhs-local-visit-poster", name: "同城门店打卡海报", category: "Store Traffic", platform: "xiaohongshu", style: "Soft", promptHint: "产出适合收藏和转发的门店打卡海报方向，包含地址感、招牌项目和预约理由", lockedToPro: false },
  { templateId: "xhs-queue-worthy-list", name: "小红书排队理由清单", category: "Store Traffic", platform: "xiaohongshu", style: "Clean", promptHint: "用清单方式包装门店值得排队的理由，强调必点项目、预算和避坑信息", lockedToPro: false },
  { templateId: "wechat-repeat-visit-reminder", name: "微信老客复购提醒", category: "Store Traffic", platform: "wechat", style: "Editorial", promptHint: "面向私域老客生成复购提醒、到店权益和轻促销话术", lockedToPro: false },
  { templateId: "wechat-founder-trust-story", name: "创始人信任故事", category: "Personal Brand", platform: "wechat", style: "Editorial", promptHint: "用个人经历和价值观建立信任，再自然带出产品或服务", lockedToPro: false },
  { templateId: "xhs-expert-pov-post", name: "小红书专家人设帖", category: "Personal Brand", platform: "xiaohongshu", style: "Soft", promptHint: "用观点、方法和案例强化个人 IP 的专业感", lockedToPro: false },
  { templateId: "xhs-ip-pov-cover", name: "个人 IP 观点封面", category: "Personal Brand", platform: "xiaohongshu", style: "Editorial", promptHint: "产出观点型封面海报方向，用一句主张建立专家感并引导阅读", lockedToPro: false },
  { templateId: "wechat-founder-mistake-list", name: "创始人避坑清单", category: "Personal Brand", platform: "wechat", style: "Editorial", promptHint: "用创始人视角整理用户常见误区，先给价值再自然带出解决方案", lockedToPro: false },
  { templateId: "xhs-expert-case-breakdown", name: "专家案例拆解帖", category: "Personal Brand", platform: "xiaohongshu", style: "Soft", promptHint: "把一个真实案例拆成问题、判断、方法和结果，强化专业信任", lockedToPro: false },
  { templateId: "douyin-live-warmup", name: "直播间预约预热", category: "Live Launch", platform: "douyin", style: "Bold", promptHint: "突出直播福利、限时权益和进直播间的明确理由", lockedToPro: true },
  { templateId: "wechat-live-benefit-list", name: "微信直播福利清单", category: "Live Launch", platform: "wechat", style: "Bold", promptHint: "适合社群和朋友圈的直播预告，强调福利、时间和行动按钮", lockedToPro: true },
  { templateId: "douyin-live-benefit-poster", name: "直播间福利封面海报", category: "Live Launch", platform: "douyin", style: "Bold", promptHint: "产出直播预热封面海报方向，明确时间、福利、爆品和预约动作", lockedToPro: true },
  { templateId: "douyin-live-countdown-hero", name: "直播间爆品倒计时", category: "Live Launch", platform: "douyin", style: "Bold", promptHint: "生成直播倒计时内容和封面方向，强调爆品、库存、时间和提醒动作", lockedToPro: true },
  { templateId: "wechat-live-booking-card", name: "微信社群直播预约卡", category: "Live Launch", platform: "wechat", style: "Bold", promptHint: "生成适合社群转发的直播预约图片方向和短促预约话术", lockedToPro: true },
  { templateId: "wechat-holiday-gift-promo", name: "节日送礼促销海报", category: "Seasonal Promo", platform: "wechat", style: "Bold", promptHint: "适合节日礼赠、限时优惠和社群转化的促销内容", lockedToPro: false },
  { templateId: "xhs-seasonal-list", name: "小红书节日清单种草", category: "Seasonal Promo", platform: "xiaohongshu", style: "Clean", promptHint: "用清单式结构包装节日场景、预算和购买理由", lockedToPro: false },
  { templateId: "wechat-community-promo-image", name: "微信社群促销图片", category: "Seasonal Promo", platform: "wechat", style: "Bold", promptHint: "产出适合社群转发的促销图片方向，突出优惠、截止时间和下单入口", lockedToPro: false },
  { templateId: "xhs-gift-guide-cover", name: "小红书节日礼物封面", category: "Seasonal Promo", platform: "xiaohongshu", style: "Clean", promptHint: "产出节日礼物清单封面方向，突出预算、人群和送礼场景", lockedToPro: false },
  { templateId: "wechat-limited-group-buy-poster", name: "微信限时团购海报", category: "Seasonal Promo", platform: "wechat", style: "Bold", promptHint: "生成社群团购海报方向，明确团购价、截止时间和下单路径", lockedToPro: false },
  { templateId: "xhs-new-launch-teaser", name: "新品首发悬念帖", category: "New Launch", platform: "xiaohongshu", style: "Clean", promptHint: "把新品升级点写成有悬念、有记忆点的首发内容", lockedToPro: false },
  { templateId: "douyin-new-launch-script", name: "抖音新品发布脚本", category: "New Launch", platform: "douyin", style: "Editorial", promptHint: "用新品变化、第一波体验和行动号召组织短视频脚本", lockedToPro: false },
  { templateId: "xhs-launch-key-visual", name: "新品首发主视觉海报", category: "New Launch", platform: "xiaohongshu", style: "Clean", promptHint: "产出新品首发主视觉海报方向，强调新品名、升级点和第一波购买理由", lockedToPro: false },
  { templateId: "xhs-new-product-comparison-card", name: "新品卖点对比图", category: "New Launch", platform: "xiaohongshu", style: "Editorial", promptHint: "把新品升级点做成对比图方向，突出新旧差异、核心收益和适合人群", lockedToPro: false },
  { templateId: "douyin-new-product-first-frame", name: "抖音新品种草首帧", category: "New Launch", platform: "douyin", style: "Bold", promptHint: "产出新品短视频首帧封面和脚本结构，用一个结果型钩子吸引停留", lockedToPro: false },
  { templateId: "tiktok-product-seeding-hook", name: "TikTok Product Seeding Hook", category: "Product Seeding", platform: "tiktok", style: "Bold", promptHint: "Short-form hook, real use case, proof, and clear product payoff", lockedToPro: false },
  { templateId: "instagram-save-worthy-carousel", name: "Instagram Save-Worthy Carousel", category: "Product Seeding", platform: "instagram", style: "Clean", promptHint: "A carousel-ready seeding structure built around a useful promise", lockedToPro: false },
  { templateId: "instagram-product-cover-poster", name: "Instagram Product Cover Poster", category: "Product Seeding", platform: "instagram", style: "Clean", promptHint: "Create a clean square or 3:4 product poster direction with headline, benefit, and visual hierarchy", lockedToPro: false },
  { templateId: "tiktok-thumb-stopping-cover", name: "TikTok Thumb-Stopping Cover", category: "Product Seeding", platform: "tiktok", style: "Bold", promptHint: "Create a 9:16 cover or first-frame image direction with a high-contrast hook and product payoff", lockedToPro: false },
  { templateId: "tiktok-ugc-review-script", name: "TikTok UGC Review Script", category: "Product Seeding", platform: "tiktok", style: "Soft", promptHint: "Turn a product into a first-person UGC review with problem, proof, and natural CTA", lockedToPro: false },
  { templateId: "instagram-before-after-cover", name: "Instagram Before After Cover", category: "Product Seeding", platform: "instagram", style: "Editorial", promptHint: "Create a before-and-after cover image direction plus concise carousel copy", lockedToPro: false },
  { templateId: "instagram-local-visit-reel", name: "Local Visit Reel", category: "Store Traffic", platform: "instagram", style: "Soft", promptHint: "Visit-worthy short-form structure for restaurants, salons, gyms, or pop-ups", lockedToPro: false },
  { templateId: "shorts-destination-teaser", name: "Shorts Destination Teaser", category: "Store Traffic", platform: "youtube_shorts", style: "Editorial", promptHint: "Fast decision-making content for places, events, and local experiences", lockedToPro: false },
  { templateId: "instagram-local-save-poster", name: "Local Visit Save Poster", category: "Store Traffic", platform: "instagram", style: "Soft", promptHint: "Create a save-worthy visit poster direction with place cues, signature offer, and decision details", lockedToPro: false },
  { templateId: "instagram-local-offer-card", name: "Instagram Local Offer Card", category: "Store Traffic", platform: "instagram", style: "Clean", promptHint: "Create a local offer card with who it is for, what to book, and why to save it", lockedToPro: false },
  { templateId: "shorts-visit-checklist", name: "YouTube Shorts Visit Checklist", category: "Store Traffic", platform: "youtube_shorts", style: "Editorial", promptHint: "Build a quick checklist script for deciding whether a place is worth visiting", lockedToPro: false },
  { templateId: "instagram-founder-trust-story", name: "Founder Trust Story", category: "Personal Brand", platform: "instagram", style: "Editorial", promptHint: "Founder or creator story that builds trust before the offer", lockedToPro: false },
  { templateId: "tiktok-expert-pov", name: "TikTok Expert POV", category: "Personal Brand", platform: "tiktok", style: "Soft", promptHint: "Opinion-led expert content with a practical takeaway and audience prompt", lockedToPro: false },
  { templateId: "instagram-creator-pov-cover", name: "Creator POV Cover Image", category: "Personal Brand", platform: "instagram", style: "Editorial", promptHint: "Create a bold POV cover image direction that turns one opinion into a readable visual asset", lockedToPro: false },
  { templateId: "instagram-founder-lesson-carousel", name: "Founder Lesson Carousel", category: "Personal Brand", platform: "instagram", style: "Editorial", promptHint: "Turn one founder lesson into a carousel structure that builds trust and saves", lockedToPro: false },
  { templateId: "tiktok-expert-case-breakdown", name: "Expert Case Breakdown", category: "Personal Brand", platform: "tiktok", style: "Soft", promptHint: "Break down a client or product case into problem, method, result, and takeaway", lockedToPro: false },
  { templateId: "tiktok-live-shopping-warmup", name: "Live Shopping Warmup", category: "Live Launch", platform: "tiktok", style: "Bold", promptHint: "Live-room warmup with benefits, timing, urgency, and reminder CTA", lockedToPro: true },
  { templateId: "instagram-live-drop-alert", name: "Instagram Live Drop Alert", category: "Live Launch", platform: "instagram", style: "Bold", promptHint: "Story/Reel copy for a live product drop or limited event", lockedToPro: true },
  { templateId: "tiktok-live-deal-poster", name: "Live Deal Poster", category: "Live Launch", platform: "tiktok", style: "Bold", promptHint: "Create a live shopping poster direction with time, offer, hero product, and reminder CTA", lockedToPro: true },
  { templateId: "tiktok-countdown-live-cover", name: "TikTok Countdown Live Cover", category: "Live Launch", platform: "tiktok", style: "Bold", promptHint: "Create a countdown cover and warmup script for a live deal or product demo", lockedToPro: true },
  { templateId: "instagram-reminder-story", name: "Instagram Reminder Story", category: "Live Launch", platform: "instagram", style: "Bold", promptHint: "Create a story image direction and reminder copy for a live event", lockedToPro: true },
  { templateId: "instagram-holiday-gift-promo", name: "Holiday Gift Promo", category: "Seasonal Promo", platform: "instagram", style: "Bold", promptHint: "Seasonal offer copy for gifting, urgency, and conversion", lockedToPro: false },
  { templateId: "tiktok-seasonal-finds", name: "TikTok Seasonal Finds", category: "Seasonal Promo", platform: "tiktok", style: "Clean", promptHint: "A list-style seasonal product angle with fast reasons to buy", lockedToPro: false },
  { templateId: "instagram-seasonal-sale-story-image", name: "Seasonal Sale Story Image", category: "Seasonal Promo", platform: "instagram", style: "Bold", promptHint: "Create a promo image direction for Stories with offer clarity, deadline, and swipe/tap CTA", lockedToPro: false },
  { templateId: "instagram-gift-guide-poster", name: "Instagram Gift Guide Poster", category: "Seasonal Promo", platform: "instagram", style: "Clean", promptHint: "Create a gift guide poster direction with budget, recipient, and seasonal reason to buy", lockedToPro: false },
  { templateId: "tiktok-limited-deal-hook", name: "TikTok Limited Deal Hook", category: "Seasonal Promo", platform: "tiktok", style: "Bold", promptHint: "Create a limited-time deal hook and first-frame direction built around urgency", lockedToPro: false },
  { templateId: "instagram-new-product-teaser", name: "New Product Launch Teaser", category: "New Launch", platform: "instagram", style: "Clean", promptHint: "Launch teaser that turns what is new into curiosity and demand", lockedToPro: false },
  { templateId: "shorts-launch-script", name: "YouTube Shorts Launch Script", category: "New Launch", platform: "youtube_shorts", style: "Editorial", promptHint: "A short launch script built around product changes, first-use benefit, and CTA", lockedToPro: false },
  { templateId: "instagram-launch-key-visual", name: "Launch Key Visual Poster", category: "New Launch", platform: "instagram", style: "Clean", promptHint: "Create a launch key visual poster direction with product name, newness, proof, and first-wave CTA", lockedToPro: false },
  { templateId: "instagram-product-comparison-launch", name: "Product Comparison Launch Card", category: "New Launch", platform: "instagram", style: "Editorial", promptHint: "Create a comparison card showing what changed, why it matters, and who should try it", lockedToPro: false },
  { templateId: "shorts-first-look-cover", name: "Shorts First Look Cover", category: "New Launch", platform: "youtube_shorts", style: "Bold", promptHint: "Create a first-look cover and short script for a new product reveal", lockedToPro: false }
];

const retiredTemplateIds = [
  "xhs-clean-product-cover",
  "douyin-bold-hook",
  "promo-flash-sale",
  "knowledge-list-card",
  "douyin-product-trial",
  "wechat-conversion-story",
  "tiktok-bold-hook",
  "instagram-carousel-cover",
  "youtube-shorts-product-teaser",
  "instagram-promo-story",
  "tiktok-myth-vs-fact",
  "shorts-founder-story",
  "instagram-editorial-card",
  "tiktok-product-trial"
];

seedTemplates();

export function listTemplates() {
  return db.prepare(`
    SELECT
      template_id,
      name,
      category,
      platform,
      style,
      prompt_hint,
      locked_to_pro
    FROM templates
    ORDER BY locked_to_pro ASC, name ASC
  `)
    .all()
    .map((row) => ({
      templateId: row.template_id,
      name: row.name,
      category: row.category,
      platform: row.platform,
      style: row.style,
      promptHint: row.prompt_hint,
      lockedToPro: Boolean(row.locked_to_pro)
    }));
}

function seedTemplates() {
  const insert = db.prepare(`
    INSERT INTO templates (
      template_id,
      name,
      category,
      platform,
      style,
      prompt_hint,
      locked_to_pro,
      updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(template_id) DO UPDATE SET
      name = excluded.name,
      category = excluded.category,
      platform = excluded.platform,
      style = excluded.style,
      prompt_hint = excluded.prompt_hint,
      locked_to_pro = excluded.locked_to_pro,
      updated_at = excluded.updated_at
  `);

  for (const template of defaultTemplates) {
    insert.run(
      template.templateId,
      template.name,
      template.category,
      template.platform,
      template.style,
      template.promptHint,
      template.lockedToPro ? 1 : 0,
      nowISO()
    );
  }

  const remove = db.prepare("DELETE FROM templates WHERE template_id = ?");
  for (const templateId of retiredTemplateIds) {
    remove.run(templateId);
  }
}
