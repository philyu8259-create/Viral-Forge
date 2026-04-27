import { normalizeContentResponse } from "../src/providers/contentSchema.mjs";

const request = {
  language: "zh-Hans",
  topic: "便携榨汁杯，适合上班族女生",
  audience: "25-35岁上班族女性",
  templateStyle: "Clean"
};

const driftedModelOutput = {
  titles: [
    { text: "一杯燕麦奶拿铁，承包你的通勤时刻", score: 88, reason: "Example drift" }
  ],
  hooks: [
    { text: "每天早上来一杯暖暖的拿铁。", score: 80, reason: "Example drift" }
  ],
  caption: "这是一款适合办公室的燕麦奶拿铁。",
  sellingPoints: ["口感顺滑", "早餐方便"],
  hashtags: ["#通勤早餐"],
  poster: {
    headline: "真燕麦，真暖胃",
    subtitle: "办公室拿铁",
    cta: "立即下单",
    style: "Clean"
  }
};

const normalized = normalizeContentResponse(driftedModelOutput, request);
const joined = [
  ...normalized.titles.map((line) => line.text),
  ...normalized.hooks.map((line) => line.text),
  normalized.caption,
  ...normalized.sellingPoints,
  normalized.poster.headline,
  normalized.poster.subtitle
].join("\n");

assert(joined.includes("便携榨汁杯"), "normalized content should include the requested product");
assert(normalized.poster.subtitle.includes("便携榨汁杯"), "poster subtitle should be anchored to the requested product");

console.log("Content guard check passed.");

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}
