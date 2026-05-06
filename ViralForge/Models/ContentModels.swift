import Foundation
import SwiftUI

enum ContentLanguage: String, CaseIterable, Identifiable, Codable {
    case chinese = "Chinese"
    case english = "English"

    var id: String { rawValue }

    var apiCode: String {
        switch self {
        case .chinese: "zh"
        case .english: "en"
        }
    }

    static func from(apiCode: String?) -> ContentLanguage {
        switch apiCode {
        case "en": .english
        default: .chinese
        }
    }

    static var preferredDeviceLanguage: ContentLanguage {
        let preferredLanguage = Locale.preferredLanguages.first?.lowercased() ?? ""
        return preferredLanguage.hasPrefix("zh") ? .chinese : .english
    }

    static var defaultGenerationLanguage: ContentLanguage {
        preferredDeviceLanguage
    }

    var displayName: String {
        switch self {
        case .chinese: AppText.localized("Chinese", "中文")
        case .english: AppText.localized("English", "英文")
        }
    }
}

enum SocialPlatform: String, CaseIterable, Identifiable, Codable {
    case xiaohongshu = "Xiaohongshu"
    case douyin = "Douyin"
    case weChat = "WeChat"
    case tikTok = "TikTok"
    case instagram = "Instagram"
    case youtubeShorts = "YouTube Shorts"

    var id: String { rawValue }

    static let chinaLaunchPlatforms: [SocialPlatform] = [.xiaohongshu, .douyin, .weChat]
    static let englishLaunchPlatforms: [SocialPlatform] = [.tikTok, .instagram, .youtubeShorts]

    static var launchPlatforms: [SocialPlatform] {
        launchPlatforms(for: .defaultGenerationLanguage)
    }

    static func launchPlatforms(for language: ContentLanguage) -> [SocialPlatform] {
        switch language {
        case .chinese: chinaLaunchPlatforms
        case .english: englishLaunchPlatforms
        }
    }

    static var defaultLaunchPlatform: SocialPlatform {
        defaultPlatform(for: .defaultGenerationLanguage)
    }

    static func defaultPlatform(for language: ContentLanguage) -> SocialPlatform {
        switch language {
        case .chinese: .xiaohongshu
        case .english: .tikTok
        }
    }

    var apiValue: String {
        switch self {
        case .xiaohongshu: "xiaohongshu"
        case .douyin: "douyin"
        case .weChat: "wechat"
        case .tikTok: "tiktok"
        case .instagram: "instagram"
        case .youtubeShorts: "youtube_shorts"
        }
    }

    static func from(apiValue: String?) -> SocialPlatform {
        switch apiValue {
        case "douyin": .douyin
        case "wechat": .weChat
        case "tiktok": .tikTok
        case "instagram": .instagram
        case "youtube_shorts": .youtubeShorts
        default: .xiaohongshu
        }
    }

    var displayName: String {
        switch self {
        case .xiaohongshu: AppText.localized("Xiaohongshu", "小红书")
        case .douyin: AppText.localized("Douyin", "抖音")
        case .weChat: AppText.localized("WeChat", "微信")
        case .tikTok: "TikTok"
        case .instagram: "Instagram"
        case .youtubeShorts: "YouTube Shorts"
        }
    }

    var posterSafeLabel: String {
        switch self {
        case .xiaohongshu: AppText.localized("Seeding Note", "种草笔记")
        case .douyin: AppText.localized("Short Video Cover", "短视频封面")
        case .weChat: AppText.localized("Private Share Poster", "私域海报")
        case .tikTok: AppText.localized("Short Video Cover", "短视频封面")
        case .instagram: AppText.localized("Lifestyle Post", "生活方式分享")
        case .youtubeShorts: AppText.localized("Vertical Video Cover", "竖版视频封面")
        }
    }
}

enum ContentGoal: String, CaseIterable, Identifiable, Codable {
    case growAudience = "Grow audience"
    case sellProduct = "Sell product"
    case driveTraffic = "Drive traffic"
    case personalBrand = "Personal brand"

    var id: String { rawValue }

    var apiValue: String {
        switch self {
        case .growAudience: "grow_audience"
        case .sellProduct: "sell_product"
        case .driveTraffic: "drive_traffic"
        case .personalBrand: "personal_brand"
        }
    }

    static func from(apiValue: String?) -> ContentGoal {
        switch apiValue {
        case "sell_product": .sellProduct
        case "drive_traffic": .driveTraffic
        case "personal_brand": .personalBrand
        default: .growAudience
        }
    }

    var displayName: String {
        switch self {
        case .growAudience: AppText.localized("Grow audience", "涨粉")
        case .sellProduct: AppText.localized("Sell product", "卖产品")
        case .driveTraffic: AppText.localized("Drive traffic", "引流")
        case .personalBrand: AppText.localized("Personal brand", "个人品牌")
        }
    }
}

struct QuotaState: Equatable, Codable {
    var remainingTextGenerations: Int
    var remainingPosterExports: Int
    var isPro: Bool
}

struct GenerationDraft: Hashable, Codable {
    var language: ContentLanguage = .defaultGenerationLanguage
    var platform: SocialPlatform = .defaultLaunchPlatform
    var goal: ContentGoal = .sellProduct
    var topic = ""
    var audience = ""
    var tone = ""
    var templateName = ""
    var templatePromptHint = ""
    var templateStyle: PosterStyle = .cleanProduct
    var brandName = ""
    var brandIndustry = ""
    var bannedWords = ""
}

extension GenerationDraft {
    var topicValidationMessage: String? {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTopic.isEmpty {
            return AppText.localized("Enter a product or topic first.", "请先输入主题或产品。")
        }

        let meaningfulScalars = trimmedTopic.unicodeScalars.filter { scalar in
            CharacterSet.letters.contains(scalar) || CharacterSet.decimalDigits.contains(scalar)
        }

        if meaningfulScalars.count < 2 {
            return AppText.localized("The topic is too short to generate a useful pack.", "主题太短，无法生成有效内容。")
        }

        return nil
    }

    var isReadyToGenerate: Bool {
        topicValidationMessage == nil
    }
}

struct BrandProfile: Hashable, Codable {
    var brandName = ""
    var industry = ""
    var audience = ""
    var tone = ""
    var bannedWords = ""
    var defaultPlatform: SocialPlatform = .defaultLaunchPlatform
    var primaryColorName = "Emerald"
}

extension BrandProfile {
    var hasSavedMemory: Bool {
        !brandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !industry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !audience.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !tone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !bannedWords.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var memorySummary: String {
        var parts: [String] = []
        if !brandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append(brandName)
        }
        if !audience.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append(audience)
        }
        if !tone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append(tone)
        }
        return parts.isEmpty
            ? AppText.localized("No brand memory saved yet.", "还没有保存品牌记忆。")
            : parts.joined(separator: " · ")
    }
}

struct ContentProject: Identifiable, Hashable, Codable {
    let id: UUID
    var createdAt: Date
    var draft: GenerationDraft
    var result: ContentResult
    var poster: PosterDraft
    var isFavorite: Bool
    var hasPosterExport: Bool
}

extension ContentProject {
    var formattedPublishPackage: String {
        switch draft.language {
        case .chinese:
            return formattedChinesePublishPackage
        case .english:
            return formattedEnglishPublishPackage
        }
    }

    private var bestTitle: String {
        result.titles.first?.text ?? poster.headline
    }

    private var bestHook: String {
        result.hooks.first?.text ?? ""
    }

    private var formattedChinesePublishPackage: String {
        [
            "【平台】\(draft.platform.displayName)",
            "【主题】\(draft.topic)",
            "",
            "【标题】",
            bestTitle,
            "",
            "【开头钩子】",
            bestHook,
            "",
            "【正文】",
            result.caption,
            "",
            "【卖点】",
            result.sellingPoints.map { "- \($0)" }.joined(separator: "\n"),
            "",
            "【标签】",
            result.hashtags.joined(separator: " "),
            "",
            "【海报文案】",
            "\(poster.headline)\n\(poster.subtitle)\n\(poster.cta)"
        ]
        .joined(separator: "\n")
    }

    private var formattedEnglishPublishPackage: String {
        [
            "Platform: \(draft.platform.displayName)",
            "Topic: \(draft.topic)",
            "",
            "Title",
            bestTitle,
            "",
            "Opening Hook",
            bestHook,
            "",
            "Caption",
            result.caption,
            "",
            "Selling Points",
            result.sellingPoints.map { "- \($0)" }.joined(separator: "\n"),
            "",
            "Hashtags",
            result.hashtags.joined(separator: " "),
            "",
            "Poster Copy",
            "\(poster.headline)\n\(poster.subtitle)\n\(poster.cta)"
        ]
        .joined(separator: "\n")
    }
}

struct ContentResult: Hashable, Codable {
    var titles: [ScoredLine]
    var hooks: [ScoredLine]
    var caption: String
    var sellingPoints: [String]
    var hashtags: [String]
}

struct ScoredLine: Identifiable, Hashable, Codable {
    let id: UUID
    var text: String
    var score: Int
    var reason: String

    init(id: UUID = UUID(), text: String, score: Int, reason: String) {
        self.id = id
        self.text = text
        self.score = score
        self.reason = reason
    }
}

struct PosterBackgroundVersion: Identifiable, Hashable, Codable {
    var id: UUID
    var imageURL: URL
    var createdAt: Date
    var backgroundDirection: PosterBackgroundDirection?
    var productImageIntegratedInBackground: Bool?

    init(
        id: UUID = UUID(),
        imageURL: URL,
        createdAt: Date = .now,
        backgroundDirection: PosterBackgroundDirection? = nil,
        productImageIntegratedInBackground: Bool? = nil
    ) {
        self.id = id
        self.imageURL = imageURL
        self.createdAt = createdAt
        self.backgroundDirection = backgroundDirection
        self.productImageIntegratedInBackground = productImageIntegratedInBackground
    }
}

enum PosterBackgroundDirection: String, CaseIterable, Identifiable, Hashable, Codable {
    case clean = "Clean"
    case lifestyle = "Lifestyle"
    case premiumCommerce = "Premium Commerce"
    case negativeSpace = "Negative Space"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .clean: AppText.localized("Cleaner", "更干净")
        case .lifestyle: AppText.localized("More Lifestyle", "更生活化")
        case .premiumCommerce: AppText.localized("Premium Commerce", "更高端电商")
        case .negativeSpace: AppText.localized("More Negative Space", "更强留白")
        }
    }

    var icon: String {
        switch self {
        case .clean: "sparkle.magnifyingglass"
        case .lifestyle: "cup.and.saucer.fill"
        case .premiumCommerce: "bag.fill"
        case .negativeSpace: "rectangle.dashed"
        }
    }

    var tint: Color {
        switch self {
        case .clean: VFStyle.teal
        case .lifestyle: VFStyle.sunset
        case .premiumCommerce: VFStyle.primaryRed
        case .negativeSpace: VFStyle.electricCyan
        }
    }

    var accessibilitySuffix: String {
        switch self {
        case .clean: "clean"
        case .lifestyle: "lifestyle"
        case .premiumCommerce: "premiumCommerce"
        case .negativeSpace: "negativeSpace"
        }
    }

    func promptInstruction(for language: ContentLanguage) -> String {
        switch language {
        case .english:
            switch self {
            case .clean:
                return "clean minimal product photography, uncluttered surface, restrained props, fresh bright lighting"
            case .lifestyle:
                return "natural daily-use lifestyle scene, believable home or office context, warm human-scale atmosphere, no people required"
            case .premiumCommerce:
                return "premium ecommerce hero shot, refined studio lighting, elevated materials, polished reflections, luxury retail quality"
            case .negativeSpace:
                return "strong negative space for app-rendered headline and CTA, simple composition, product kept visually clear without crowding"
            }
        case .chinese:
            switch self {
            case .clean:
                return "更干净的极简商品摄影，桌面不杂乱，道具克制，光线清爽明亮"
            case .lifestyle:
                return "更生活化的真实使用场景，像家里或办公室自然摆放，有日常氛围但不需要出现人物"
            case .premiumCommerce:
                return "更高端电商主图质感，精致棚拍光线，高级材质，反光干净，适合商业投放"
            case .negativeSpace:
                return "更强留白，方便 App 后续叠加标题和 CTA，构图简单，产品主体清楚且不拥挤"
            }
        }
    }
}

enum ProductImageIntegrationMode: String, CaseIterable, Identifiable, Hashable, Codable {
    case preserve = "Preserve"
    case natural = "Natural"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .preserve: AppText.localized("Preserve Product", "严格保留外观")
        case .natural: AppText.localized("Natural Blend", "更自然融入")
        }
    }

    var subtitle: String {
        switch self {
        case .preserve:
            AppText.localized("Prioritize exact shape and details", "优先保留真实形状和细节")
        case .natural:
            AppText.localized("Blend with scene lighting and perspective", "强化场景光线和透视融合")
        }
    }

    var icon: String {
        switch self {
        case .preserve: "scope"
        case .natural: "camera.macro"
        }
    }

    var tint: Color {
        switch self {
        case .preserve: VFStyle.electricCyan
        case .natural: VFStyle.teal
        }
    }

    var accessibilitySuffix: String {
        switch self {
        case .preserve: "preserve"
        case .natural: "natural"
        }
    }

    func promptInstruction(for language: ContentLanguage) -> String {
        switch language {
        case .english:
            switch self {
            case .preserve:
                return "Prioritize exact product fidelity above scene styling. Keep the product's real silhouette, proportions, color, material, transparent parts, seams, buttons, blade/window details, and physically printed marks as unchanged as possible."
            case .natural:
                return "Prioritize a believable integrated commercial scene while preserving product identity. Natural blending must not change the product identity, silhouette, proportions, key materials, transparent window, or recognizable details. Match the product to the new scene with coherent perspective, contact shadows, reflections, rim light, and surface interaction; do not make it look pasted on."
            }
        case .chinese:
            switch self {
            case .preserve:
                return "优先严格保留真实产品外观，高于场景风格。尽量不改变产品轮廓、比例、颜色、材质、透明结构、接缝、按钮、刀头/窗口细节和产品本体上的物理印刷标识。"
            case .natural:
                return "优先让真实产品自然融入商业摄影场景，同时保留产品身份。自然融入也不能改变产品身份、轮廓、比例、关键材质、透明窗口和可识别细节。让产品与新场景的透视、接触阴影、反光、轮廓光和桌面关系一致，不能像简单贴图。"
            }
        }
    }
}

struct PosterDraft: Hashable, Codable {
    var headline: String
    var subtitle: String
    var cta: String
    var channelLabel: String? = nil
    var style: PosterStyle
    var backgroundDirection: PosterBackgroundDirection = .clean
    var productImageIntegrationMode: ProductImageIntegrationMode = .natural
    var backgroundImageURL: URL? = nil
    var productImageData: Data? = nil
    var productImageIntegratedInBackground: Bool? = nil
    var backgroundHistory: [PosterBackgroundVersion] = []

    init(
        headline: String,
        subtitle: String,
        cta: String,
        channelLabel: String? = nil,
        style: PosterStyle,
        backgroundDirection: PosterBackgroundDirection = .clean,
        productImageIntegrationMode: ProductImageIntegrationMode = .natural,
        backgroundImageURL: URL? = nil,
        productImageData: Data? = nil,
        productImageIntegratedInBackground: Bool? = nil,
        backgroundHistory: [PosterBackgroundVersion] = []
    ) {
        self.headline = headline
        self.subtitle = subtitle
        self.cta = cta
        self.channelLabel = channelLabel
        self.style = style
        self.backgroundDirection = backgroundDirection
        self.productImageIntegrationMode = productImageIntegrationMode
        self.backgroundImageURL = backgroundImageURL
        self.productImageData = productImageData
        self.productImageIntegratedInBackground = productImageIntegratedInBackground
        self.backgroundHistory = backgroundHistory
    }

    private enum CodingKeys: String, CodingKey {
        case headline
        case subtitle
        case cta
        case channelLabel
        case style
        case backgroundDirection
        case productImageIntegrationMode
        case backgroundImageURL
        case productImageData
        case productImageIntegratedInBackground
        case backgroundHistory
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        headline = try container.decode(String.self, forKey: .headline)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        cta = try container.decode(String.self, forKey: .cta)
        channelLabel = try container.decodeIfPresent(String.self, forKey: .channelLabel)
        style = try container.decode(PosterStyle.self, forKey: .style)
        backgroundDirection = try container.decodeIfPresent(PosterBackgroundDirection.self, forKey: .backgroundDirection) ?? .clean
        productImageIntegrationMode = try container.decodeIfPresent(ProductImageIntegrationMode.self, forKey: .productImageIntegrationMode) ?? .natural
        backgroundImageURL = try container.decodeIfPresent(URL.self, forKey: .backgroundImageURL)
        productImageData = try container.decodeIfPresent(Data.self, forKey: .productImageData)
        productImageIntegratedInBackground = try container.decodeIfPresent(Bool.self, forKey: .productImageIntegratedInBackground)
        backgroundHistory = try container.decodeIfPresent([PosterBackgroundVersion].self, forKey: .backgroundHistory) ?? []
    }

    func resolvedChannelLabel(for platform: SocialPlatform) -> String {
        let trimmedLabel = channelLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedLabel.isEmpty ? platform.posterSafeLabel : trimmedLabel
    }

    var shouldOverlayProductImage: Bool {
        productImageData != nil && productImageIntegratedInBackground != true
    }

    func recordingBackgroundVersion(imageURL: URL, usedProductReference: Bool?) -> PosterDraft {
        var updatedPoster = self
        var versions = backgroundHistory

        if let backgroundImageURL,
           !versions.contains(where: { $0.imageURL == backgroundImageURL }) {
            versions.insert(PosterBackgroundVersion(
                imageURL: backgroundImageURL,
                backgroundDirection: backgroundDirection,
                productImageIntegratedInBackground: productImageIntegratedInBackground
            ), at: 0)
        }

        versions.removeAll { $0.imageURL == imageURL }
        versions.insert(PosterBackgroundVersion(
            imageURL: imageURL,
            backgroundDirection: backgroundDirection,
            productImageIntegratedInBackground: usedProductReference
        ), at: 0)

        updatedPoster.backgroundImageURL = imageURL
        updatedPoster.productImageIntegratedInBackground = usedProductReference
        updatedPoster.backgroundHistory = Array(versions.prefix(6))
        return updatedPoster
    }

    func selectingBackgroundVersion(_ version: PosterBackgroundVersion) -> PosterDraft {
        var updatedPoster = self
        updatedPoster.backgroundImageURL = version.imageURL
        if let backgroundDirection = version.backgroundDirection {
            updatedPoster.backgroundDirection = backgroundDirection
        }
        updatedPoster.productImageIntegratedInBackground = version.productImageIntegratedInBackground
        return updatedPoster
    }
}

enum PosterStyle: String, CaseIterable, Identifiable, Hashable, Codable {
    case cleanProduct = "Clean"
    case boldLaunch = "Bold"
    case softLifestyle = "Soft"
    case editorial = "Editorial"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cleanProduct: AppText.localized("Clean", "简洁")
        case .boldLaunch: AppText.localized("Bold", "醒目")
        case .softLifestyle: AppText.localized("Soft", "柔和")
        case .editorial: AppText.localized("Editorial", "杂志")
        }
    }

    var palette: PosterPalette {
        switch self {
        case .cleanProduct:
            PosterPalette(background: Color(red: 0.96, green: 0.97, blue: 0.95), primary: .black, accent: Color(red: 0.10, green: 0.48, blue: 0.40))
        case .boldLaunch:
            PosterPalette(background: Color(red: 0.10, green: 0.10, blue: 0.12), primary: .white, accent: Color(red: 0.98, green: 0.78, blue: 0.20))
        case .softLifestyle:
            PosterPalette(background: Color(red: 0.98, green: 0.93, blue: 0.90), primary: Color(red: 0.16, green: 0.14, blue: 0.13), accent: Color(red: 0.72, green: 0.23, blue: 0.32))
        case .editorial:
            PosterPalette(background: Color(red: 0.90, green: 0.92, blue: 0.94), primary: Color(red: 0.08, green: 0.12, blue: 0.16), accent: Color(red: 0.21, green: 0.33, blue: 0.84))
        }
    }
}

struct PosterPalette: Hashable {
    var background: Color
    var primary: Color
    var accent: Color
}

enum PosterCanvasTarget: String, CaseIterable, Identifiable, Hashable {
    case xiaohongshuCover = "xiaohongshu_3_4"
    case douyinVertical = "douyin_9_16"
    case weChatSquare = "wechat_1_1"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .xiaohongshuCover: AppText.localized("Instagram 3:4", "小红书 3:4")
        case .douyinVertical: AppText.localized("Shorts 9:16", "抖音 9:16")
        case .weChatSquare: AppText.localized("Instagram 1:1", "微信 1:1")
        }
    }

    var aspectRatio: CGFloat {
        switch self {
        case .xiaohongshuCover: 3.0 / 4.0
        case .douyinVertical: 9.0 / 16.0
        case .weChatSquare: 1.0
        }
    }

    var apiAspectRatio: String {
        switch self {
        case .xiaohongshuCover: "3:4"
        case .douyinVertical: "9:16"
        case .weChatSquare: "1:1"
        }
    }

    var exportSize: CGSize {
        switch self {
        case .xiaohongshuCover: CGSize(width: 1080, height: 1440)
        case .douyinVertical: CGSize(width: 1080, height: 1920)
        case .weChatSquare: CGSize(width: 1080, height: 1080)
        }
    }

    static func defaultTarget(for platform: SocialPlatform) -> PosterCanvasTarget {
        switch platform {
        case .douyin, .tikTok, .youtubeShorts: .douyinVertical
        case .weChat, .instagram: .weChatSquare
        case .xiaohongshu: .xiaohongshuCover
        }
    }
}

enum TemplateCategory: String, CaseIterable, Identifiable, Hashable {
    case productSeeding = "Product Seeding"
    case storeTraffic = "Store Traffic"
    case personalBrand = "Personal Brand"
    case liveLaunch = "Live Launch"
    case seasonalPromo = "Seasonal Promo"
    case newLaunch = "New Launch"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .productSeeding: AppText.localized("Product Seeding", "产品种草")
        case .storeTraffic: AppText.localized("Store Traffic", "探店引流")
        case .personalBrand: AppText.localized("Personal Brand", "个人IP")
        case .liveLaunch: AppText.localized("Live Launch", "直播预热")
        case .seasonalPromo: AppText.localized("Seasonal Promo", "节日促销")
        case .newLaunch: AppText.localized("New Launch", "新品发布")
        }
    }

    static func from(apiValue: String?) -> TemplateCategory {
        switch apiValue {
        case "Product Seeding", "Product": .productSeeding
        case "Store Traffic": .storeTraffic
        case "Personal Brand", "Story", "Knowledge": .personalBrand
        case "Live Launch": .liveLaunch
        case "Seasonal Promo", "Promo": .seasonalPromo
        case "New Launch", "Covers": .newLaunch
        default: .productSeeding
        }
    }

    var defaultGoal: ContentGoal {
        switch self {
        case .productSeeding, .seasonalPromo, .newLaunch, .liveLaunch:
            .sellProduct
        case .storeTraffic:
            .driveTraffic
        case .personalBrand:
            .personalBrand
        }
    }

    var defaultAudience: String {
        switch self {
        case .productSeeding:
            AppText.localized("Value-conscious shoppers who need a real use case", "有明确场景需求、愿意被真实体验打动的人群")
        case .storeTraffic:
            AppText.localized("Local users comparing where to go next", "正在比较去哪消费的同城用户")
        case .personalBrand:
            AppText.localized("Followers who trust founder stories and expertise", "关注创始人故事、专业经验和长期陪伴的用户")
        case .liveLaunch:
            AppText.localized("Warm leads who need a reason to enter the live room", "已被种草但需要理由进入直播间的潜在用户")
        case .seasonalPromo:
            AppText.localized("Deal-sensitive users with an immediate holiday need", "有节日消费需求、关注优惠和时效的人群")
        case .newLaunch:
            AppText.localized("Early adopters who like trying new products first", "愿意尝鲜、关注新品亮点和第一波体验的人群")
        }
    }

    var defaultTone: String {
        switch self {
        case .productSeeding:
            AppText.localized("Authentic, useful, lightly persuasive", "真实体验、实用、轻种草")
        case .storeTraffic:
            AppText.localized("Specific, visual, easy to decide", "具体、有画面感、方便决策")
        case .personalBrand:
            AppText.localized("Trustworthy, warm, opinionated", "可信、有温度、有观点")
        case .liveLaunch:
            AppText.localized("Urgent, energetic, benefit-led", "有紧迫感、热闹、利益点清晰")
        case .seasonalPromo:
            AppText.localized("Festive, clear, conversion-focused", "节日氛围、清晰、促转化")
        case .newLaunch:
            AppText.localized("Fresh, confident, curiosity-driven", "新鲜、自信、激发好奇")
        }
    }
}

struct CreativeTemplate: Identifiable, Hashable {
    let id: UUID
    var name: String
    var category: TemplateCategory
    var platform: SocialPlatform
    var style: PosterStyle
    var promptHint: String
    var lockedToPro: Bool

    init(
        id: UUID = UUID(),
        name: String,
        category: TemplateCategory,
        platform: SocialPlatform,
        style: PosterStyle,
        promptHint: String,
        lockedToPro: Bool = false
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.platform = platform
        self.style = style
        self.promptHint = promptHint
        self.lockedToPro = lockedToPro
    }
}

extension CreativeTemplate {
    var defaultAudience: String {
        category.defaultAudience
    }

    var defaultTone: String {
        category.defaultTone
    }

    var contentStructure: [String] {
        switch category {
        case .productSeeding:
            [
                AppText.localized("Pain point hook", "痛点钩子"),
                AppText.localized("Real use scene", "真实使用场景"),
                AppText.localized("Three buying reasons", "三个购买理由"),
                AppText.localized("Soft CTA", "轻行动引导")
            ]
        case .storeTraffic:
            [
                AppText.localized("Who should go", "适合谁去"),
                AppText.localized("Signature scene", "核心场景"),
                AppText.localized("Decision tips", "决策信息"),
                AppText.localized("Save/share prompt", "收藏转发引导")
            ]
        case .personalBrand:
            [
                AppText.localized("Personal belief", "个人观点"),
                AppText.localized("Short story proof", "经历证明"),
                AppText.localized("Practical takeaway", "可执行建议"),
                AppText.localized("Follower interaction", "互动提问")
            ]
        case .liveLaunch:
            [
                AppText.localized("Live room reason", "进直播间理由"),
                AppText.localized("Limited benefit", "限时权益"),
                AppText.localized("Product proof", "产品背书"),
                AppText.localized("Reminder CTA", "预约提醒")
            ]
        case .seasonalPromo:
            [
                AppText.localized("Holiday context", "节日场景"),
                AppText.localized("Offer clarity", "优惠说明"),
                AppText.localized("Gift/use reason", "送礼/自用理由"),
                AppText.localized("Deadline CTA", "截止时间引导")
            ]
        case .newLaunch:
            [
                AppText.localized("Newness hook", "新品亮点钩子"),
                AppText.localized("What changed", "核心升级"),
                AppText.localized("First-use benefit", "首波体验收益"),
                AppText.localized("Try-now CTA", "尝鲜行动引导")
            ]
        }
    }

    var outputBadges: [String] {
        [
            AppText.localized("Copy", "文案"),
            visualOutputBadge,
            AppText.localized("Publish Pack", "发布包")
        ]
    }

    private var visualOutputBadge: String {
        let lowercasedName = name.lowercased()
        let lowercasedHint = promptHint.lowercased()
        if lowercasedName.contains("海报") || lowercasedHint.contains("海报") || lowercasedName.contains("poster") || lowercasedHint.contains("poster") {
            return AppText.localized("Poster", "海报")
        }
        if lowercasedName.contains("封面") || lowercasedHint.contains("封面") || lowercasedName.contains("cover") || lowercasedHint.contains("cover") {
            return AppText.localized("Cover", "封面")
        }
        if lowercasedName.contains("视觉") || lowercasedHint.contains("图片") || lowercasedName.contains("visual") || lowercasedHint.contains("image") {
            return AppText.localized("Image Direction", "图片方向")
        }
        return AppText.localized("Poster Direction", "海报方向")
    }

    var isVisualTemplate: Bool {
        let lowercasedName = name.lowercased()
        let lowercasedHint = promptHint.lowercased()
        let text = "\(lowercasedName) \(lowercasedHint)"
        return ["海报", "封面", "图片", "视觉", "图文", "首帧", "清单", "poster", "cover", "image", "visual", "card", "story", "first-frame", "carousel", "checklist", "lineup"]
            .contains { text.contains($0) }
    }

    var sampleOutcome: String {
        switch category {
        case .productSeeding:
            AppText.localized("3 hooks, one social caption, key selling points, hashtags, and a poster direction for seeding.", "生成 3 个标题、正文、卖点、标签和一张种草海报方向。")
        case .storeTraffic:
            AppText.localized("A visit-worthy post package with decision details and shareable visual copy.", "生成一套适合探店引流的内容包，包含决策信息和可分享海报文案。")
        case .personalBrand:
            AppText.localized("A founder/IP post that builds trust before introducing the offer.", "生成一篇先建立信任、再自然带出产品或服务的个人 IP 文案。")
        case .liveLaunch:
            AppText.localized("A warm-up pack for live room reminders, benefits, and urgency.", "生成直播预热内容包，突出预约理由、福利和紧迫感。")
        case .seasonalPromo:
            AppText.localized("A campaign-ready promo pack for seasonal offers and conversion posts.", "生成节日促销内容包，可用于限时活动和转化发布。")
        case .newLaunch:
            AppText.localized("A launch pack that turns product newness into curiosity and first-wave demand.", "生成新品发布内容包，把新品感转成好奇心和第一波需求。")
        }
    }
}

struct PosterAsset: Identifiable, Hashable {
    let id: UUID
    var projectId: UUID
    var projectTopic: String
    var headline: String
    var platform: SocialPlatform
    var style: PosterStyle
    var backgroundImageURL: URL?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        projectId: UUID,
        projectTopic: String,
        headline: String,
        platform: SocialPlatform,
        style: PosterStyle,
        backgroundImageURL: URL? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.projectId = projectId
        self.projectTopic = projectTopic
        self.headline = headline
        self.platform = platform
        self.style = style
        self.backgroundImageURL = backgroundImageURL
        self.createdAt = createdAt
    }
}

struct CampaignIdea: Identifiable, Hashable {
    let id: UUID
    var day: Int
    var platform: SocialPlatform
    var pillar: String
    var objective: String
    var title: String
    var hook: String
    var posterAngle: String
    var cta: String

    init(
        id: UUID = UUID(),
        day: Int,
        platform: SocialPlatform,
        pillar: String,
        objective: String,
        title: String,
        hook: String,
        posterAngle: String,
        cta: String
    ) {
        self.id = id
        self.day = day
        self.platform = platform
        self.pillar = pillar
        self.objective = objective
        self.title = title
        self.hook = hook
        self.posterAngle = posterAngle
        self.cta = cta
    }
}
