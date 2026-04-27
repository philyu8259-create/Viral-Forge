import { db, nowISO } from "../db/database.mjs";

const defaultTemplates = [
  { templateId: "xhs-product-seeding-note", name: "小红书真实种草笔记", category: "Product Seeding", platform: "xiaohongshu", style: "Clean", promptHint: "按痛点、场景、体验、购买理由组织小红书种草笔记", lockedToPro: false },
  { templateId: "douyin-product-hook", name: "抖音 3 秒产品钩子", category: "Product Seeding", platform: "douyin", style: "Bold", promptHint: "用短视频前三秒冲突和产品结果抓住注意力", lockedToPro: false },
  { templateId: "xhs-local-visit-save-card", name: "同城探店收藏卡", category: "Store Traffic", platform: "xiaohongshu", style: "Soft", promptHint: "适合餐饮、美业、亲子、生活方式门店的收藏型探店内容", lockedToPro: false },
  { templateId: "wechat-store-traffic-invite", name: "微信私域到店邀约", category: "Store Traffic", platform: "wechat", style: "Editorial", promptHint: "把门店特色、适合人群和预约理由写成朋友圈/社群转化文案", lockedToPro: false },
  { templateId: "wechat-founder-trust-story", name: "创始人信任故事", category: "Personal Brand", platform: "wechat", style: "Editorial", promptHint: "用个人经历和价值观建立信任，再自然带出产品或服务", lockedToPro: false },
  { templateId: "xhs-expert-pov-post", name: "小红书专家人设帖", category: "Personal Brand", platform: "xiaohongshu", style: "Soft", promptHint: "用观点、方法和案例强化个人 IP 的专业感", lockedToPro: false },
  { templateId: "douyin-live-warmup", name: "直播间预约预热", category: "Live Launch", platform: "douyin", style: "Bold", promptHint: "突出直播福利、限时权益和进直播间的明确理由", lockedToPro: true },
  { templateId: "wechat-live-benefit-list", name: "微信直播福利清单", category: "Live Launch", platform: "wechat", style: "Bold", promptHint: "适合社群和朋友圈的直播预告，强调福利、时间和行动按钮", lockedToPro: true },
  { templateId: "wechat-holiday-gift-promo", name: "节日送礼促销海报", category: "Seasonal Promo", platform: "wechat", style: "Bold", promptHint: "适合节日礼赠、限时优惠和社群转化的促销内容", lockedToPro: false },
  { templateId: "xhs-seasonal-list", name: "小红书节日清单种草", category: "Seasonal Promo", platform: "xiaohongshu", style: "Clean", promptHint: "用清单式结构包装节日场景、预算和购买理由", lockedToPro: false },
  { templateId: "xhs-new-launch-teaser", name: "新品首发悬念帖", category: "New Launch", platform: "xiaohongshu", style: "Clean", promptHint: "把新品升级点写成有悬念、有记忆点的首发内容", lockedToPro: false },
  { templateId: "douyin-new-launch-script", name: "抖音新品发布脚本", category: "New Launch", platform: "douyin", style: "Editorial", promptHint: "用新品变化、第一波体验和行动号召组织短视频脚本", lockedToPro: false },
  { templateId: "tiktok-product-seeding-hook", name: "TikTok Product Seeding Hook", category: "Product Seeding", platform: "tiktok", style: "Bold", promptHint: "Short-form hook, real use case, proof, and clear product payoff", lockedToPro: false },
  { templateId: "instagram-save-worthy-carousel", name: "Instagram Save-Worthy Carousel", category: "Product Seeding", platform: "instagram", style: "Clean", promptHint: "A carousel-ready seeding structure built around a useful promise", lockedToPro: false },
  { templateId: "instagram-local-visit-reel", name: "Local Visit Reel", category: "Store Traffic", platform: "instagram", style: "Soft", promptHint: "Visit-worthy short-form structure for restaurants, salons, gyms, or pop-ups", lockedToPro: false },
  { templateId: "shorts-destination-teaser", name: "Shorts Destination Teaser", category: "Store Traffic", platform: "youtube_shorts", style: "Editorial", promptHint: "Fast decision-making content for places, events, and local experiences", lockedToPro: false },
  { templateId: "instagram-founder-trust-story", name: "Founder Trust Story", category: "Personal Brand", platform: "instagram", style: "Editorial", promptHint: "Founder or creator story that builds trust before the offer", lockedToPro: false },
  { templateId: "tiktok-expert-pov", name: "TikTok Expert POV", category: "Personal Brand", platform: "tiktok", style: "Soft", promptHint: "Opinion-led expert content with a practical takeaway and audience prompt", lockedToPro: false },
  { templateId: "tiktok-live-shopping-warmup", name: "Live Shopping Warmup", category: "Live Launch", platform: "tiktok", style: "Bold", promptHint: "Live-room warmup with benefits, timing, urgency, and reminder CTA", lockedToPro: true },
  { templateId: "instagram-live-drop-alert", name: "Instagram Live Drop Alert", category: "Live Launch", platform: "instagram", style: "Bold", promptHint: "Story/Reel copy for a live product drop or limited event", lockedToPro: true },
  { templateId: "instagram-holiday-gift-promo", name: "Holiday Gift Promo", category: "Seasonal Promo", platform: "instagram", style: "Bold", promptHint: "Seasonal offer copy for gifting, urgency, and conversion", lockedToPro: false },
  { templateId: "tiktok-seasonal-finds", name: "TikTok Seasonal Finds", category: "Seasonal Promo", platform: "tiktok", style: "Clean", promptHint: "A list-style seasonal product angle with fast reasons to buy", lockedToPro: false },
  { templateId: "instagram-new-product-teaser", name: "New Product Launch Teaser", category: "New Launch", platform: "instagram", style: "Clean", promptHint: "Launch teaser that turns what is new into curiosity and demand", lockedToPro: false },
  { templateId: "shorts-launch-script", name: "YouTube Shorts Launch Script", category: "New Launch", platform: "youtube_shorts", style: "Editorial", promptHint: "A short launch script built around product changes, first-use benefit, and CTA", lockedToPro: false }
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
