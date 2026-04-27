import Foundation

enum SampleData {
    static let templates: [CreativeTemplate] = [
        CreativeTemplate(name: "小红书种草封面", category: .cover, platform: .xiaohongshu, style: .cleanProduct, promptHint: "适合产品种草的大标题封面，突出卖点和生活场景"),
        CreativeTemplate(name: "抖音 3 秒钩子封面", category: .cover, platform: .douyin, style: .boldLaunch, promptHint: "高对比短视频封面，用前三秒钩子抓住注意力"),
        CreativeTemplate(name: "朋友圈/社群促销海报", category: .promotion, platform: .weChat, style: .boldLaunch, promptHint: "适合微信转发的促销海报，保留优惠和行动按钮区域", lockedToPro: true),
        CreativeTemplate(name: "小红书知识清单卡", category: .knowledge, platform: .xiaohongshu, style: .softLifestyle, promptHint: "适合收藏的知识清单卡，用编号结构降低阅读压力"),
        CreativeTemplate(name: "抖音产品测评脚本", category: .product, platform: .douyin, style: .editorial, promptHint: "用真实试用口吻组织卖点、槽点和转化话术", lockedToPro: true),
        CreativeTemplate(name: "微信成交转化文案", category: .story, platform: .weChat, style: .editorial, promptHint: "适合朋友圈/社群的故事式种草文案，先建立信任再引导咨询")
    ]

    static let projects: [ContentProject] = [
        ContentProject(
            id: UUID(),
            createdAt: .now.addingTimeInterval(-3600),
            draft: GenerationDraft(language: .chinese, platform: .xiaohongshu, goal: .sellProduct, topic: "便携榨汁杯", audience: "25-35岁上班族女性", tone: "真实、种草、不夸张"),
            result: ContentResult(
                titles: [
                    ScoredLine(text: "上班族女生真的需要便携榨汁杯吗？", score: 92, reason: "目标人群明确，适合小红书封面。")
                ],
                hooks: [
                    ScoredLine(text: "如果你总说没时间照顾自己，可以先从一杯水果饮开始。", score: 88, reason: "生活方式切入自然。")
                ],
                caption: "一个适合办公室和通勤的小习惯工具。",
                sellingPoints: ["轻便", "好清洗", "适合办公室"],
                hashtags: ["#小红书种草", "#上班族好物"]
            ),
            poster: PosterDraft(headline: "下班后也能轻松补充维C", subtitle: "便携榨汁杯", cta: "3个场景告诉你值不值得买", style: .cleanProduct),
            isFavorite: true,
            hasPosterExport: false
        )
    ]
}
