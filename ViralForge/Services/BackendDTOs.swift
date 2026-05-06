import Foundation

struct HealthResponse: Decodable {
    var status: String
    var service: String
}

struct QuotaResponse: Decodable {
    var remainingTextGenerations: Int
    var remainingPosterExports: Int
    var isPro: Bool

    var state: QuotaState {
        QuotaState(
            remainingTextGenerations: remainingTextGenerations,
            remainingPosterExports: remainingPosterExports,
            isPro: isPro
        )
    }
}

struct QuotaProUpdateRequest: Encodable {
    var isPro: Bool
}

struct SubscriptionSyncRequest: Encodable {
    var productId: String
    var transactionId: String
    var originalTransactionId: String
    var appAccountToken: UUID
    var purchaseDate: Date
    var expirationDate: Date?
    var environment: String
    var signedTransactionInfo: String
}

struct GenerateContentRequest: Encodable {
    var language: String
    var platform: String
    var goal: String
    var topic: String
    var audience: String
    var tone: String
    var templateName: String
    var templatePromptHint: String
    var templateStyle: String
    var brandName: String
    var brandIndustry: String
    var bannedWords: String
    var modelRoute: ModelRoute

    init(draft: GenerationDraft) {
        self.language = draft.language.apiCode
        self.platform = draft.platform.apiValue
        self.goal = draft.goal.apiValue
        self.topic = draft.topic
        self.audience = draft.audience
        self.tone = draft.tone
        self.templateName = draft.templateName
        self.templatePromptHint = draft.templatePromptHint
        self.templateStyle = draft.templateStyle.rawValue
        self.brandName = draft.brandName
        self.brandIndustry = draft.brandIndustry
        self.bannedWords = draft.bannedWords
        self.modelRoute = ModelRoute.route(for: draft.language)
    }
}

struct GenerateContentResponse: Decodable {
    var projectId: String?
    var titles: [ScoredLineResponse]
    var hooks: [ScoredLineResponse]
    var caption: String
    var sellingPoints: [String]
    var hashtags: [String]
    var poster: PosterResponse
}

struct ScoredLineResponse: Decodable {
    var text: String
    var score: Int
    var reason: String

    var line: ScoredLine {
        ScoredLine(text: text, score: score, reason: reason)
    }
}

struct PosterResponse: Decodable {
    var headline: String
    var subtitle: String
    var cta: String
    var channelLabel: String?
    var style: String?
    var textPlacement: String?
    var backgroundDirection: String?
    var productImageIntegrationMode: String?
    var backgroundImageUrl: URL?
    var productImageIntegratedInBackground: Bool?

    func draft(fallbackStyle: PosterStyle) -> PosterDraft {
        PosterDraft(
            headline: headline,
            subtitle: subtitle,
            cta: cta,
            channelLabel: channelLabel,
            style: style.flatMap { PosterStyle(rawValue: $0) } ?? fallbackStyle,
            textPlacement: textPlacement.flatMap { PosterTextPlacement(rawValue: $0) } ?? .automatic,
            backgroundDirection: backgroundDirection.flatMap { PosterBackgroundDirection(rawValue: $0) } ?? .clean,
            productImageIntegrationMode: productImageIntegrationMode.flatMap { ProductImageIntegrationMode(rawValue: $0) } ?? .natural,
            backgroundImageURL: backgroundImageUrl,
            productImageIntegratedInBackground: productImageIntegratedInBackground
        )
    }
}

struct PosterBackgroundRequest: Encodable {
    var projectId: String
    var language: String
    var style: String
    var aspectRatio: String
    var prompt: String
    var modelRoute: ModelRoute
    var productImageDataUrl: String?
}

struct PosterBackgroundResponse: Decodable {
    var imageUrl: URL
    var usedProductReference: Bool?
}

struct TemplateListResponse: Decodable {
    var templates: [TemplateResponse]
}

struct TemplateResponse: Decodable {
    var templateId: String
    var name: String
    var category: String
    var platform: String
    var style: String
    var promptHint: String
    var lockedToPro: Bool

    var template: CreativeTemplate {
        CreativeTemplate(
            id: UUID(uuidString: templateId) ?? UUID(),
            name: name,
            category: TemplateCategory.from(apiValue: category),
            platform: SocialPlatform.from(apiValue: platform),
            style: PosterStyle(rawValue: style) ?? .cleanProduct,
            promptHint: promptHint,
            lockedToPro: lockedToPro
        )
    }
}

struct BrandProfileEnvelope: Decodable {
    var profile: BrandProfileResponse

    var brandProfile: BrandProfile {
        profile.brandProfile
    }
}

struct BrandProfileRequest: Encodable {
    var profile: BrandProfilePayload

    init(profile: BrandProfile) {
        self.profile = BrandProfilePayload(profile: profile)
    }
}

struct BrandProfilePayload: Codable {
    var brandName: String
    var industry: String
    var audience: String
    var tone: String
    var bannedWords: String
    var defaultPlatform: String
    var primaryColorName: String

    init(profile: BrandProfile) {
        self.brandName = profile.brandName
        self.industry = profile.industry
        self.audience = profile.audience
        self.tone = profile.tone
        self.bannedWords = profile.bannedWords
        self.defaultPlatform = profile.defaultPlatform.apiValue
        self.primaryColorName = profile.primaryColorName
    }
}

struct BrandProfileResponse: Decodable {
    var brandName: String
    var industry: String
    var audience: String
    var tone: String
    var bannedWords: String
    var defaultPlatform: String
    var primaryColorName: String

    var brandProfile: BrandProfile {
        BrandProfile(
            brandName: brandName,
            industry: industry,
            audience: audience,
            tone: tone,
            bannedWords: bannedWords,
            defaultPlatform: SocialPlatform.from(apiValue: defaultPlatform),
            primaryColorName: primaryColorName
        )
    }
}

struct ProjectListResponse: Decodable {
    var projects: [ProjectResponse]
}

struct SaveProjectResponse: Decodable {
    var project: ProjectResponse
}

struct DeleteProjectResponse: Decodable {
    var deleted: Bool
}

struct ProjectSaveRequest: Encodable {
    var projectId: String
    var createdAt: Date
    var hasPosterExport: Bool
    var isFavorite: Bool
    var input: ProjectInputPayload
    var result: ProjectResultPayload

    init(project: ContentProject) {
        self.projectId = project.id.uuidString
        self.createdAt = project.createdAt
        self.hasPosterExport = project.hasPosterExport
        self.isFavorite = project.isFavorite
        self.input = ProjectInputPayload(draft: project.draft)
        self.result = ProjectResultPayload(project: project)
    }
}

struct ProjectInputPayload: Encodable {
    var language: String
    var platform: String
    var goal: String
    var topic: String
    var audience: String
    var tone: String
    var templateName: String
    var templatePromptHint: String
    var templateStyle: String
    var brandName: String
    var brandIndustry: String
    var bannedWords: String
    var modelRoute: ModelRoute

    init(draft: GenerationDraft) {
        self.language = draft.language.apiCode
        self.platform = draft.platform.apiValue
        self.goal = draft.goal.apiValue
        self.topic = draft.topic
        self.audience = draft.audience
        self.tone = draft.tone
        self.templateName = draft.templateName
        self.templatePromptHint = draft.templatePromptHint
        self.templateStyle = draft.templateStyle.rawValue
        self.brandName = draft.brandName
        self.brandIndustry = draft.brandIndustry
        self.bannedWords = draft.bannedWords
        self.modelRoute = ModelRoute.route(for: draft.language)
    }
}

struct ProjectResultPayload: Encodable {
    var projectId: String
    var titles: [ScoredLinePayload]
    var hooks: [ScoredLinePayload]
    var caption: String
    var sellingPoints: [String]
    var hashtags: [String]
    var poster: PosterPayload

    init(project: ContentProject) {
        self.projectId = project.id.uuidString
        self.titles = project.result.titles.map(ScoredLinePayload.init(line:))
        self.hooks = project.result.hooks.map(ScoredLinePayload.init(line:))
        self.caption = project.result.caption
        self.sellingPoints = project.result.sellingPoints
        self.hashtags = project.result.hashtags
        self.poster = PosterPayload(poster: project.poster)
    }
}

struct ScoredLinePayload: Encodable {
    var text: String
    var score: Int
    var reason: String

    init(line: ScoredLine) {
        self.text = line.text
        self.score = line.score
        self.reason = line.reason
    }
}

struct PosterPayload: Encodable {
    var headline: String
    var subtitle: String
    var cta: String
    var channelLabel: String?
    var style: String
    var textPlacement: String
    var backgroundDirection: String
    var productImageIntegrationMode: String
    var backgroundImageUrl: URL?
    var productImageIntegratedInBackground: Bool?

    init(poster: PosterDraft) {
        self.headline = poster.headline
        self.subtitle = poster.subtitle
        self.cta = poster.cta
        self.channelLabel = poster.channelLabel
        self.style = poster.style.rawValue
        self.textPlacement = poster.textPlacement.rawValue
        self.backgroundDirection = poster.backgroundDirection.rawValue
        self.productImageIntegrationMode = poster.productImageIntegrationMode.rawValue
        self.backgroundImageUrl = poster.backgroundImageURL
        self.productImageIntegratedInBackground = poster.productImageIntegratedInBackground
    }
}

struct ProjectResponse: Decodable {
    var projectId: String?
    var createdAt: String?
    var hasPosterExport: Bool?
    var isFavorite: Bool?
    var input: ProjectInputResponse?
    var result: GenerateContentResponse?

    func project() -> ContentProject? {
        guard let input, let result else { return nil }
        let draft = input.draft()
        let fallbackStyle = draft.templateStyle

        return ContentProject(
            id: projectId.flatMap(UUID.init(uuidString:)) ?? result.projectId.flatMap(UUID.init(uuidString:)) ?? UUID(),
            createdAt: BackendDateParser.parse(createdAt) ?? .now,
            draft: draft,
            result: ContentResult(
                titles: result.titles.map(\.line),
                hooks: result.hooks.map(\.line),
                caption: result.caption,
                sellingPoints: result.sellingPoints,
                hashtags: result.hashtags
            ),
            poster: result.poster.draft(fallbackStyle: fallbackStyle),
            isFavorite: isFavorite ?? false,
            hasPosterExport: hasPosterExport ?? false
        )
    }
}

struct ProjectInputResponse: Decodable {
    var language: String?
    var platform: String?
    var goal: String?
    var topic: String?
    var audience: String?
    var tone: String?
    var templateName: String?
    var templatePromptHint: String?
    var templateStyle: String?
    var brandName: String?
    var brandIndustry: String?
    var bannedWords: String?

    func draft() -> GenerationDraft {
        GenerationDraft(
            language: ContentLanguage.from(apiCode: language),
            platform: SocialPlatform.from(apiValue: platform),
            goal: ContentGoal.from(apiValue: goal),
            topic: topic ?? "",
            audience: audience ?? "",
            tone: tone ?? "",
            templateName: templateName ?? "",
            templatePromptHint: templatePromptHint ?? "",
            templateStyle: templateStyle.flatMap { PosterStyle(rawValue: $0) } ?? .cleanProduct,
            brandName: brandName ?? "",
            brandIndustry: brandIndustry ?? "",
            bannedWords: bannedWords ?? ""
        )
    }
}

private enum BackendDateParser {
    static func parse(_ rawValue: String?) -> Date? {
        guard let rawValue else { return nil }

        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: rawValue) {
            return date
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: rawValue)
    }
}
