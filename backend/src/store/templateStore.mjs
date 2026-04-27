import { db, nowISO } from "../db/database.mjs";

const defaultTemplates = [
  {
    templateId: "xhs-clean-product-cover",
    name: "小红书种草封面",
    category: "Covers",
    platform: "xiaohongshu",
    style: "Clean",
    promptHint: "适合产品种草的大标题封面，突出卖点和生活场景",
    lockedToPro: false
  },
  {
    templateId: "douyin-bold-hook",
    name: "抖音 3 秒钩子封面",
    category: "Covers",
    platform: "douyin",
    style: "Bold",
    promptHint: "高对比短视频封面，用前三秒钩子抓住注意力",
    lockedToPro: false
  },
  {
    templateId: "promo-flash-sale",
    name: "朋友圈/社群促销海报",
    category: "Promo",
    platform: "wechat",
    style: "Bold",
    promptHint: "适合微信转发的促销海报，保留优惠和行动按钮区域",
    lockedToPro: true
  },
  {
    templateId: "knowledge-list-card",
    name: "小红书知识清单卡",
    category: "Knowledge",
    platform: "xiaohongshu",
    style: "Soft",
    promptHint: "适合收藏的知识清单卡，用编号结构降低阅读压力",
    lockedToPro: false
  },
  {
    templateId: "douyin-product-trial",
    name: "抖音产品测评脚本",
    category: "Product",
    platform: "douyin",
    style: "Editorial",
    promptHint: "用真实试用口吻组织卖点、槽点和转化话术",
    lockedToPro: true
  },
  {
    templateId: "wechat-conversion-story",
    name: "微信成交转化文案",
    category: "Story",
    platform: "wechat",
    style: "Editorial",
    promptHint: "适合朋友圈/社群的故事式种草文案，先建立信任再引导咨询",
    lockedToPro: false
  },
  {
    templateId: "tiktok-bold-hook",
    name: "TikTok 3-Second Hook",
    category: "Covers",
    platform: "tiktok",
    style: "Bold",
    promptHint: "Short-form opening frame with a strong first-line hook and product payoff",
    lockedToPro: false
  },
  {
    templateId: "instagram-carousel-cover",
    name: "Instagram Carousel Cover",
    category: "Covers",
    platform: "instagram",
    style: "Clean",
    promptHint: "Save-worthy carousel opener with a clear promise and visual hierarchy",
    lockedToPro: false
  },
  {
    templateId: "youtube-shorts-product-teaser",
    name: "YouTube Shorts Product Teaser",
    category: "Product",
    platform: "youtube_shorts",
    style: "Editorial",
    promptHint: "Fast product trial structure for Shorts with a curiosity-led intro",
    lockedToPro: true
  },
  {
    templateId: "instagram-promo-story",
    name: "Instagram Promo Story",
    category: "Promo",
    platform: "instagram",
    style: "Bold",
    promptHint: "Conversion-focused Story frame with offer, proof, and CTA zones",
    lockedToPro: true
  },
  {
    templateId: "tiktok-myth-vs-fact",
    name: "TikTok Myth vs Fact",
    category: "Knowledge",
    platform: "tiktok",
    style: "Soft",
    promptHint: "Educational short-form angle that corrects one misconception quickly",
    lockedToPro: false
  },
  {
    templateId: "shorts-founder-story",
    name: "Shorts Founder Story",
    category: "Story",
    platform: "youtube_shorts",
    style: "Editorial",
    promptHint: "Personal brand story script that builds trust before the product mention",
    lockedToPro: false
  }
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

  db.prepare(`
    DELETE FROM templates
    WHERE template_id IN ('instagram-editorial-card', 'tiktok-product-trial')
  `).run();
}
