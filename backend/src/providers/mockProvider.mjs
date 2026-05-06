import { randomUUID } from "node:crypto";

export async function mockGenerateContent(request) {
  const language = request.language === "en" ? "en" : "zh";
  return language === "en" ? englishResponse(request) : chineseResponse(request);
}

export async function mockGeneratePosterBackground(request) {
  const style = request.style || "Clean";
  const palette = posterPalette(style);
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1536" viewBox="0 0 1024 1536"><defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${palette.start}"/><stop offset="0.52" stop-color="${palette.mid}"/><stop offset="1" stop-color="${palette.end}"/></linearGradient><radialGradient id="glow" cx="35%" cy="18%" r="60%"><stop offset="0" stop-color="${palette.glow}" stop-opacity="0.65"/><stop offset="1" stop-color="${palette.glow}" stop-opacity="0"/></radialGradient></defs><rect width="1024" height="1536" fill="url(#bg)"/><circle cx="260" cy="260" r="390" fill="url(#glow)"/><circle cx="860" cy="420" r="290" fill="${palette.accent}" opacity="0.18"/><rect x="185" y="250" width="560" height="690" rx="80" fill="#ffffff" opacity="0.38" transform="rotate(-8 465 595)"/><rect x="540" y="360" width="260" height="500" rx="72" fill="${palette.accent}" opacity="0.72" transform="rotate(8 670 610)"/><circle cx="748" cy="310" r="42" fill="#ffffff" opacity="0.74"/><circle cx="815" cy="945" r="70" fill="#ffffff" opacity="0.46"/></svg>`;
  return {
    imageUrl: `data:image/svg+xml,${encodeURIComponent(svg)}`,
    usedProductReference: false
  };
}

function posterPalette(style) {
  switch (style) {
    case "Bold":
      return { start: "#18071f", mid: "#79182b", end: "#ff6a1a", glow: "#ffcc33", accent: "#ff3b30" };
    case "Soft":
      return { start: "#fff4f0", mid: "#ffd9df", end: "#f6f9ff", glow: "#ff8fb3", accent: "#b84a62" };
    case "Editorial":
      return { start: "#eef2f7", mid: "#dbe7ff", end: "#ffffff", glow: "#4c6fff", accent: "#3554d1" };
    default:
      return { start: "#f6fff8", mid: "#e6fbf2", end: "#ffffff", glow: "#31c8a7", accent: "#1a7a66" };
  }
}

function chineseResponse(request) {
  const topic = normalizedTopic(request.topic, "便携榨汁杯");
  const brandPrefix = request.brandName ? `${request.brandName}: ` : "";
  const templateReason = request.templateName
    ? `Using ${request.templateName} as the structured content template.`
    : "Clear audience and concrete scenario.";

  return {
    projectId: randomUUID(),
    titles: [
      {
        text: `${brandPrefix}上班族女生真的需要这个${topic}吗？`,
        score: 92,
        reason: templateReason
      },
      {
        text: `我用了 7 天，才发现${topic}最该这样选`,
        score: 88,
        reason: "Trial-based angle builds trust."
      },
      {
        text: `别再乱买了，${topic}看这 3 点就够`,
        score: 86,
        reason: "Checklist format is easy to save and share."
      }
    ],
    hooks: [
      {
        text: "如果你每天都说没时间照顾自己，这个小东西可能比你想的更实用。",
        score: 90,
        reason: "Starts from a daily pain point."
      },
      {
        text: "我以前以为它是智商税，用过之后发现是我场景没选对。",
        score: 87,
        reason: "Reversal hook improves retention."
      }
    ],
    caption: `最近试了一个适合通勤和办公室用的${topic}。它不是那种夸张的神器，更像是把一个小习惯变得更容易坚持。`,
    sellingPoints: ["通勤包能放下", "清洗步骤少", "适合办公室和健身后", "颜值适合拍照分享"],
    hashtags: ["#小红书种草", "#上班族好物", "#健康生活", "#自律日常"],
    poster: {
      headline: "下班后也能轻松补充维C",
      subtitle: topic,
      cta: request.templateName || "3个场景告诉你值不值得买",
      style: request.templateStyle || "Clean"
    }
  };
}

function englishResponse(request) {
  const topic = normalizedTopic(request.topic, "portable blender");
  const brandPrefix = request.brandName ? `${request.brandName}: ` : "";
  const templateReason = request.templateName
    ? `Uses ${request.templateName} as the creative structure.`
    : "Clear audience and curiosity-driven framing.";

  return {
    projectId: randomUUID(),
    titles: [
      {
        text: `${brandPrefix}Is this ${topic} actually worth it for busy mornings?`,
        score: 91,
        reason: templateReason
      },
      {
        text: `I tested a ${topic} for 7 days. Here is what surprised me.`,
        score: 89,
        reason: "Personal trial formats perform well."
      },
      {
        text: `Before you buy a ${topic}, check these 3 details.`,
        score: 86,
        reason: "Decision-helper angle with save potential."
      }
    ],
    hooks: [
      {
        text: "If your healthy routine keeps failing before 9 AM, the problem might be friction.",
        score: 90,
        reason: "Starts with a relatable problem."
      },
      {
        text: "I thought this was a gimmick until I used it in the exact right scenario.",
        score: 87,
        reason: "Reversal creates attention."
      }
    ],
    caption: `I tried a ${topic} for busy workdays. It is not magic, but it removes just enough friction to make a small healthy habit easier to repeat.`,
    sellingPoints: ["Fits in a work bag", "Quick rinse cleanup", "Useful after workouts", "Easy to photograph"],
    hashtags: ["#creatorfinds", "#healthyroutine", "#workdayessentials", "#productreview"],
    poster: {
      headline: "A smoother routine in 60 seconds",
      subtitle: titleCase(topic),
      cta: request.templateName || "3 moments where it actually helps",
      style: request.templateStyle || "Editorial"
    }
  };
}

function normalizedTopic(value, fallback) {
  return typeof value === "string" && value.trim() ? value.trim() : fallback;
}

function titleCase(value) {
  return value.replace(/\b\w/g, (letter) => letter.toUpperCase());
}
