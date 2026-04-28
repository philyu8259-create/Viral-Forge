import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const tempDir = mkdtempSync(join(tmpdir(), "viralforge-template-check-"));
process.env.SQLITE_PATH = join(tempDir, "viralforge.sqlite");

try {
  const { listTemplates } = await import("../src/store/templateStore.mjs");
  const templates = listTemplates();

  assert(templates.length >= 60, `expected at least 60 templates, got ${templates.length}`);
  assertNoDuplicates(templates, "templateId");
  assertNoDuplicates(templates, "name");

  const requiredCategories = [
    "Product Seeding",
    "Store Traffic",
    "Personal Brand",
    "Live Launch",
    "Seasonal Promo",
    "New Launch"
  ];
  const requiredChinaPlatforms = ["xiaohongshu", "douyin", "wechat"];
  const requiredEnglishPlatforms = ["tiktok", "instagram", "youtube_shorts"];

  for (const category of requiredCategories) {
    assert(
      templates.some((template) => template.category === category),
      `missing category ${category}`
    );
  }

  for (const platform of [...requiredChinaPlatforms, ...requiredEnglishPlatforms]) {
    assert(
      templates.some((template) => template.platform === platform),
      `missing platform ${platform}`
    );
  }

  const visualKeywords = ["海报", "封面", "图片", "视觉", "图文", "首帧", "清单", "poster", "cover", "image", "visual", "card", "story", "first-frame", "carousel", "checklist", "lineup"];
  const visualTemplates = templates.filter((template) => {
    const text = `${template.name} ${template.promptHint}`.toLowerCase();
    return visualKeywords.some((keyword) => text.includes(keyword.toLowerCase()));
  });

  assert(visualTemplates.length >= 24, `expected at least 24 visual templates, got ${visualTemplates.length}`);
  assert(
    visualTemplates.some((template) => requiredChinaPlatforms.includes(template.platform)),
    "missing China visual templates"
  );
  assert(
    visualTemplates.some((template) => requiredEnglishPlatforms.includes(template.platform)),
    "missing English visual templates"
  );

  console.log(`Template catalog check passed with ${templates.length} templates and ${visualTemplates.length} visual templates.`);
} finally {
  rmSync(tempDir, { recursive: true, force: true });
}

function assertNoDuplicates(items, key) {
  const seen = new Set();
  for (const item of items) {
    assert(!seen.has(item[key]), `duplicate ${key}: ${item[key]}`);
    seen.add(item[key]);
  }
}
