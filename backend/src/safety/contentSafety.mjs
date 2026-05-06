const maxTopicLength = 500;
const maxPromptLength = 1600;
const maxProductImageDataUrlLength = 8_000_000;

const riskRules = [
  {
    code: "illegal_or_dangerous",
    message: "This request appears to involve illegal or dangerous activity. Please change the topic.",
    pattern: /(赌博|博彩|洗钱|诈骗|套现|代写论文|盗版|黑产|毒品|枪支|爆炸物|违法|犯罪|hack|malware|phishing|scam|fraud|weapon|explosive|illegal)/iu
  },
  {
    code: "medical_claim",
    message: "Medical treatment or cure claims are not supported. Please use neutral wellness language.",
    pattern: /(治疗|治愈|根治|疗效|处方|降血糖|降血压|抗癌|抑郁症|焦虑症|cure|treat|diagnose|prescription|anti[-\s]?cancer|blood pressure|blood sugar)/iu
  },
  {
    code: "financial_claim",
    message: "Guaranteed income or investment-return claims are not supported. Please use compliant wording.",
    pattern: /(稳赚|保本|guaranteed profit|guaranteed return|risk[-\s]?free|翻倍收益|日入|月入\d|年化\d|暴富|躺赚|investment guarantee)/iu
  },
  {
    code: "absolute_ad_claim",
    message: "Absolute or unverifiable advertising claims are not supported. Please soften the claim.",
    pattern: /(全网第一|行业第一|最有效|永久有效|100%|百分百|无副作用|零风险|guaranteed|best ever|number one|no side effects|zero risk)/iu
  }
];

export function assertSafeContentRequest(body) {
  const topic = cleanText(body.topic);
  if (topic.length < 2) {
    throwSafetyError("invalid_topic", "Please provide a clearer product or content topic.", 400);
  }
  if (topic.length > maxTopicLength) {
    throwSafetyError("topic_too_long", `Topic is too long. Keep it under ${maxTopicLength} characters.`, 400);
  }

  const text = [
    body.topic,
    body.audience,
    body.tone,
    body.goal,
    body.templateName,
    body.templatePromptHint,
    body.brandName,
    body.brandIndustry
  ].map(cleanText).join("\n");

  assertSafeText(text);
}

export function assertSafePosterRequest(body) {
  const prompt = cleanText(body.prompt);
  if (prompt.length > maxPromptLength) {
    throwSafetyError("prompt_too_long", `Poster prompt is too long. Keep it under ${maxPromptLength} characters.`, 400);
  }
  if (typeof body.productImageDataUrl === "string" && body.productImageDataUrl.length > maxProductImageDataUrlLength) {
    throwSafetyError("product_image_too_large", "Product image is too large. Please upload a smaller image.", 400);
  }
  assertSafeText([body.prompt, body.style, body.aspectRatio].map(cleanText).join("\n"));
}

function assertSafeText(text) {
  for (const rule of riskRules) {
    if (rule.pattern.test(text)) {
      throwSafetyError(rule.code, rule.message, 422);
    }
  }
}

function cleanText(value) {
  return typeof value === "string" ? value.trim() : "";
}

function throwSafetyError(code, message, statusCode) {
  const error = new Error(message);
  error.statusCode = statusCode;
  error.code = code;
  throw error;
}
