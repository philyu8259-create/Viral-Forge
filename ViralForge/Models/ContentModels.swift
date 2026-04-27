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

struct PosterDraft: Hashable, Codable {
    var headline: String
    var subtitle: String
    var cta: String
    var style: PosterStyle
    var backgroundImageURL: URL? = nil
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
    case cover = "Covers"
    case product = "Product"
    case knowledge = "Knowledge"
    case promotion = "Promo"
    case story = "Story"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cover: AppText.localized("Covers", "封面")
        case .product: AppText.localized("Product", "商品")
        case .knowledge: AppText.localized("Knowledge", "知识")
        case .promotion: AppText.localized("Promo", "促销")
        case .story: AppText.localized("Story", "故事")
        }
    }

    static func from(apiValue: String?) -> TemplateCategory {
        switch apiValue {
        case "Product": .product
        case "Knowledge": .knowledge
        case "Promo": .promotion
        case "Story": .story
        default: .cover
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
