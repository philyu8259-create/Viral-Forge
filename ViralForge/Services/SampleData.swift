import Foundation

enum SampleData {
    static var templates: [CreativeTemplate] {
        templates(for: .defaultGenerationLanguage)
    }

    static func templates(for language: ContentLanguage) -> [CreativeTemplate] {
        switch language {
        case .chinese: chineseTemplates
        case .english: englishTemplates
        }
    }

    static var allTemplates: [CreativeTemplate] {
        chineseTemplates + englishTemplates
    }

    private static let chineseTemplates: [CreativeTemplate] = [
        CreativeTemplate(name: "小红书真实种草笔记", category: .productSeeding, platform: .xiaohongshu, style: .cleanProduct, promptHint: "按痛点、场景、体验、购买理由组织小红书种草笔记"),
        CreativeTemplate(name: "抖音 3 秒产品钩子", category: .productSeeding, platform: .douyin, style: .boldLaunch, promptHint: "用短视频前三秒冲突和产品结果抓住注意力"),
        CreativeTemplate(name: "小红书产品封面海报", category: .productSeeding, platform: .xiaohongshu, style: .cleanProduct, promptHint: "产出小红书 3:4 封面海报方向，突出产品名、核心利益点和可读性"),
        CreativeTemplate(name: "抖音竖版爆点封面", category: .productSeeding, platform: .douyin, style: .boldLaunch, promptHint: "产出 9:16 竖版视频封面/首帧方向，用强钩子和大字标题提高停留"),
        CreativeTemplate(name: "小红书真实测评对比", category: .productSeeding, platform: .xiaohongshu, style: .editorial, promptHint: "把产品体验写成真实测评和对比结构，适合横向比较同类产品"),
        CreativeTemplate(name: "抖音开箱首帧脚本", category: .productSeeding, platform: .douyin, style: .boldLaunch, promptHint: "产出开箱短视频脚本和首帧封面方向，前三秒突出惊喜点和结果"),
        CreativeTemplate(name: "同城探店收藏卡", category: .storeTraffic, platform: .xiaohongshu, style: .softLifestyle, promptHint: "适合餐饮、美业、亲子、生活方式门店的收藏型探店内容"),
        CreativeTemplate(name: "微信私域到店邀约", category: .storeTraffic, platform: .weChat, style: .editorial, promptHint: "把门店特色、适合人群和预约理由写成朋友圈/社群转化文案"),
        CreativeTemplate(name: "同城门店打卡海报", category: .storeTraffic, platform: .xiaohongshu, style: .softLifestyle, promptHint: "产出适合收藏和转发的门店打卡海报方向，包含地址感、招牌项目和预约理由"),
        CreativeTemplate(name: "小红书排队理由清单", category: .storeTraffic, platform: .xiaohongshu, style: .cleanProduct, promptHint: "用清单方式包装门店值得排队的理由，强调必点项目、预算和避坑信息"),
        CreativeTemplate(name: "微信老客复购提醒", category: .storeTraffic, platform: .weChat, style: .editorial, promptHint: "面向私域老客生成复购提醒、到店权益和轻促销话术"),
        CreativeTemplate(name: "创始人信任故事", category: .personalBrand, platform: .weChat, style: .editorial, promptHint: "用个人经历和价值观建立信任，再自然带出产品或服务"),
        CreativeTemplate(name: "小红书专家人设帖", category: .personalBrand, platform: .xiaohongshu, style: .softLifestyle, promptHint: "用观点、方法和案例强化个人 IP 的专业感"),
        CreativeTemplate(name: "个人 IP 观点封面", category: .personalBrand, platform: .xiaohongshu, style: .editorial, promptHint: "产出观点型封面海报方向，用一句主张建立专家感并引导阅读"),
        CreativeTemplate(name: "创始人避坑清单", category: .personalBrand, platform: .weChat, style: .editorial, promptHint: "用创始人视角整理用户常见误区，先给价值再自然带出解决方案"),
        CreativeTemplate(name: "专家案例拆解帖", category: .personalBrand, platform: .xiaohongshu, style: .softLifestyle, promptHint: "把一个真实案例拆成问题、判断、方法和结果，强化专业信任"),
        CreativeTemplate(name: "直播间预约预热", category: .liveLaunch, platform: .douyin, style: .boldLaunch, promptHint: "突出直播福利、限时权益和进直播间的明确理由", lockedToPro: true),
        CreativeTemplate(name: "微信直播福利清单", category: .liveLaunch, platform: .weChat, style: .boldLaunch, promptHint: "适合社群和朋友圈的直播预告，强调福利、时间和行动按钮", lockedToPro: true),
        CreativeTemplate(name: "直播间福利封面海报", category: .liveLaunch, platform: .douyin, style: .boldLaunch, promptHint: "产出直播预热封面海报方向，明确时间、福利、爆品和预约动作", lockedToPro: true),
        CreativeTemplate(name: "直播间爆品倒计时", category: .liveLaunch, platform: .douyin, style: .boldLaunch, promptHint: "生成直播倒计时内容和封面方向，强调爆品、库存、时间和提醒动作", lockedToPro: true),
        CreativeTemplate(name: "微信社群直播预约卡", category: .liveLaunch, platform: .weChat, style: .boldLaunch, promptHint: "生成适合社群转发的直播预约图片方向和短促预约话术", lockedToPro: true),
        CreativeTemplate(name: "节日送礼促销海报", category: .seasonalPromo, platform: .weChat, style: .boldLaunch, promptHint: "适合节日礼赠、限时优惠和社群转化的促销内容"),
        CreativeTemplate(name: "小红书节日清单种草", category: .seasonalPromo, platform: .xiaohongshu, style: .cleanProduct, promptHint: "用清单式结构包装节日场景、预算和购买理由"),
        CreativeTemplate(name: "微信社群促销图片", category: .seasonalPromo, platform: .weChat, style: .boldLaunch, promptHint: "产出适合社群转发的促销图片方向，突出优惠、截止时间和下单入口"),
        CreativeTemplate(name: "小红书节日礼物封面", category: .seasonalPromo, platform: .xiaohongshu, style: .cleanProduct, promptHint: "产出节日礼物清单封面方向，突出预算、人群和送礼场景"),
        CreativeTemplate(name: "微信限时团购海报", category: .seasonalPromo, platform: .weChat, style: .boldLaunch, promptHint: "生成社群团购海报方向，明确团购价、截止时间和下单路径"),
        CreativeTemplate(name: "新品首发悬念帖", category: .newLaunch, platform: .xiaohongshu, style: .cleanProduct, promptHint: "把新品升级点写成有悬念、有记忆点的首发内容"),
        CreativeTemplate(name: "抖音新品发布脚本", category: .newLaunch, platform: .douyin, style: .editorial, promptHint: "用新品变化、第一波体验和行动号召组织短视频脚本"),
        CreativeTemplate(name: "新品首发主视觉海报", category: .newLaunch, platform: .xiaohongshu, style: .cleanProduct, promptHint: "产出新品首发主视觉海报方向，强调新品名、升级点和第一波购买理由"),
        CreativeTemplate(name: "新品卖点对比图", category: .newLaunch, platform: .xiaohongshu, style: .editorial, promptHint: "把新品升级点做成对比图方向，突出新旧差异、核心收益和适合人群"),
        CreativeTemplate(name: "抖音新品种草首帧", category: .newLaunch, platform: .douyin, style: .boldLaunch, promptHint: "产出新品短视频首帧封面和脚本结构，用一个结果型钩子吸引停留")
    ]

    private static let englishTemplates: [CreativeTemplate] = [
        CreativeTemplate(name: "TikTok Product Seeding Hook", category: .productSeeding, platform: .tikTok, style: .boldLaunch, promptHint: "Short-form hook, real use case, proof, and clear product payoff"),
        CreativeTemplate(name: "Instagram Save-Worthy Carousel", category: .productSeeding, platform: .instagram, style: .cleanProduct, promptHint: "A carousel-ready seeding structure built around a useful promise"),
        CreativeTemplate(name: "Instagram Product Cover Poster", category: .productSeeding, platform: .instagram, style: .cleanProduct, promptHint: "Create a clean square or 3:4 product poster direction with headline, benefit, and visual hierarchy"),
        CreativeTemplate(name: "TikTok Thumb-Stopping Cover", category: .productSeeding, platform: .tikTok, style: .boldLaunch, promptHint: "Create a 9:16 cover or first-frame image direction with a high-contrast hook and product payoff"),
        CreativeTemplate(name: "TikTok UGC Review Script", category: .productSeeding, platform: .tikTok, style: .softLifestyle, promptHint: "Turn a product into a first-person UGC review with problem, proof, and natural CTA"),
        CreativeTemplate(name: "Instagram Before After Cover", category: .productSeeding, platform: .instagram, style: .editorial, promptHint: "Create a before-and-after cover image direction plus concise carousel copy"),
        CreativeTemplate(name: "Local Visit Reel", category: .storeTraffic, platform: .instagram, style: .softLifestyle, promptHint: "Visit-worthy short-form structure for restaurants, salons, gyms, or pop-ups"),
        CreativeTemplate(name: "Shorts Destination Teaser", category: .storeTraffic, platform: .youtubeShorts, style: .editorial, promptHint: "Fast decision-making content for places, events, and local experiences"),
        CreativeTemplate(name: "Local Visit Save Poster", category: .storeTraffic, platform: .instagram, style: .softLifestyle, promptHint: "Create a save-worthy visit poster direction with place cues, signature offer, and decision details"),
        CreativeTemplate(name: "Instagram Local Offer Card", category: .storeTraffic, platform: .instagram, style: .cleanProduct, promptHint: "Create a local offer card with who it is for, what to book, and why to save it"),
        CreativeTemplate(name: "YouTube Shorts Visit Checklist", category: .storeTraffic, platform: .youtubeShorts, style: .editorial, promptHint: "Build a quick checklist script for deciding whether a place is worth visiting"),
        CreativeTemplate(name: "Founder Trust Story", category: .personalBrand, platform: .instagram, style: .editorial, promptHint: "Founder or creator story that builds trust before the offer"),
        CreativeTemplate(name: "TikTok Expert POV", category: .personalBrand, platform: .tikTok, style: .softLifestyle, promptHint: "Opinion-led expert content with a practical takeaway and audience prompt"),
        CreativeTemplate(name: "Creator POV Cover Image", category: .personalBrand, platform: .instagram, style: .editorial, promptHint: "Create a bold POV cover image direction that turns one opinion into a readable visual asset"),
        CreativeTemplate(name: "Founder Lesson Carousel", category: .personalBrand, platform: .instagram, style: .editorial, promptHint: "Turn one founder lesson into a carousel structure that builds trust and saves"),
        CreativeTemplate(name: "Expert Case Breakdown", category: .personalBrand, platform: .tikTok, style: .softLifestyle, promptHint: "Break down a client or product case into problem, method, result, and takeaway"),
        CreativeTemplate(name: "Live Shopping Warmup", category: .liveLaunch, platform: .tikTok, style: .boldLaunch, promptHint: "Live-room warmup with benefits, timing, urgency, and reminder CTA", lockedToPro: true),
        CreativeTemplate(name: "Instagram Live Drop Alert", category: .liveLaunch, platform: .instagram, style: .boldLaunch, promptHint: "Story/Reel copy for a live product drop or limited event", lockedToPro: true),
        CreativeTemplate(name: "Live Deal Poster", category: .liveLaunch, platform: .tikTok, style: .boldLaunch, promptHint: "Create a live shopping poster direction with time, offer, hero product, and reminder CTA", lockedToPro: true),
        CreativeTemplate(name: "TikTok Countdown Live Cover", category: .liveLaunch, platform: .tikTok, style: .boldLaunch, promptHint: "Create a countdown cover and warmup script for a live deal or product demo", lockedToPro: true),
        CreativeTemplate(name: "Instagram Reminder Story", category: .liveLaunch, platform: .instagram, style: .boldLaunch, promptHint: "Create a story image direction and reminder copy for a live event", lockedToPro: true),
        CreativeTemplate(name: "Holiday Gift Promo", category: .seasonalPromo, platform: .instagram, style: .boldLaunch, promptHint: "Seasonal offer copy for gifting, urgency, and conversion"),
        CreativeTemplate(name: "TikTok Seasonal Finds", category: .seasonalPromo, platform: .tikTok, style: .cleanProduct, promptHint: "A list-style seasonal product angle with fast reasons to buy"),
        CreativeTemplate(name: "Seasonal Sale Story Image", category: .seasonalPromo, platform: .instagram, style: .boldLaunch, promptHint: "Create a promo image direction for Stories with offer clarity, deadline, and swipe/tap CTA"),
        CreativeTemplate(name: "Instagram Gift Guide Poster", category: .seasonalPromo, platform: .instagram, style: .cleanProduct, promptHint: "Create a gift guide poster direction with budget, recipient, and seasonal reason to buy"),
        CreativeTemplate(name: "TikTok Limited Deal Hook", category: .seasonalPromo, platform: .tikTok, style: .boldLaunch, promptHint: "Create a limited-time deal hook and first-frame direction built around urgency"),
        CreativeTemplate(name: "New Product Launch Teaser", category: .newLaunch, platform: .instagram, style: .cleanProduct, promptHint: "Launch teaser that turns what is new into curiosity and demand"),
        CreativeTemplate(name: "YouTube Shorts Launch Script", category: .newLaunch, platform: .youtubeShorts, style: .editorial, promptHint: "A short launch script built around product changes, first-use benefit, and CTA"),
        CreativeTemplate(name: "Launch Key Visual Poster", category: .newLaunch, platform: .instagram, style: .cleanProduct, promptHint: "Create a launch key visual poster direction with product name, newness, proof, and first-wave CTA"),
        CreativeTemplate(name: "Product Comparison Launch Card", category: .newLaunch, platform: .instagram, style: .editorial, promptHint: "Create a comparison card showing what changed, why it matters, and who should try it"),
        CreativeTemplate(name: "Shorts First Look Cover", category: .newLaunch, platform: .youtubeShorts, style: .boldLaunch, promptHint: "Create a first-look cover and short script for a new product reveal")
    ]

    static var projects: [ContentProject] {
        projects(for: .defaultGenerationLanguage)
    }

    static func projects(for language: ContentLanguage) -> [ContentProject] {
        switch language {
        case .chinese: chineseProjects
        case .english: englishProjects
        }
    }

    private static let chineseProjects: [ContentProject] = [
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

    private static let englishProjects: [ContentProject] = [
        ContentProject(
            id: UUID(),
            createdAt: .now.addingTimeInterval(-3600),
            draft: GenerationDraft(language: .english, platform: .tikTok, goal: .sellProduct, topic: "portable blender", audience: "busy creators and office workers", tone: "practical, upbeat, not exaggerated"),
            result: ContentResult(
                titles: [
                    ScoredLine(text: "Is a portable blender actually worth it for busy mornings?", score: 91, reason: "Clear product and short-form curiosity angle.")
                ],
                hooks: [
                    ScoredLine(text: "If your healthy routine keeps failing before 9 AM, the problem might be friction.", score: 90, reason: "Starts with a relatable routine problem.")
                ],
                caption: "I tried a portable blender for workdays. It is not magic, but it removes enough friction to make a small healthy habit easier to repeat.",
                sellingPoints: ["Fits in a work bag", "Quick rinse cleanup", "Useful after workouts"],
                hashtags: ["#creatorfinds", "#healthyroutine", "#productreview"]
            ),
            poster: PosterDraft(headline: "A smoother routine in 60 seconds", subtitle: "Portable Blender", cta: "3 moments where it actually helps", style: .editorial),
            isFavorite: true,
            hasPosterExport: false
        )
    ]
}
