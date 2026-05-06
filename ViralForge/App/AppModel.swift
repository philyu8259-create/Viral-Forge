import Foundation
import Observation
import StoreKit

enum AppTab: Hashable {
    case create
    case templates
    case brand
    case assets
    case pro
}

struct AppliedTemplateWorkflow: Identifiable, Hashable {
    let id = UUID()
    var templateName: String
    var platform: SocialPlatform
    var category: TemplateCategory
    var draft: GenerationDraft
}

@MainActor
@Observable
final class AppModel {
    var selectedTab: AppTab = .create
    var projects: [ContentProject] = []
    var templates: [CreativeTemplate] = SampleData.templates
    var posterAssets: [PosterAsset] = []
    var brandProfile = BrandProfile()
    var quota = QuotaState(remainingTextGenerations: 3, remainingPosterExports: 3, isPro: false)
    var backendSettings: BackendSettings
    var backendStatusMessage = "Mock mode is active."
    var isSyncingBackend = false
    var isGenerating = false
    var isGeneratingPosterBackground = false
    var isLoadingStoreProducts = false
    var isPurchasingSubscription = false
    var generationError: String?
    var posterGenerationError: String?
    var brandStatusMessage: String?
    var purchaseStatusMessage: String?
    var localDataStatusMessage: String?
    var paywallReasonMessage: String?
    var subscriptionProducts: [Product] = []
    var purchasedSubscriptionIDs: Set<String> = []
    var pendingTemplateWorkflow: AppliedTemplateWorkflow?

    private let fallbackContentService: ContentGenerating
    private var didConfigureStoreKit = false
    private var transactionUpdatesTask: Task<Void, Never>?

    init(contentService: ContentGenerating = MockContentService(), settings: BackendSettings = BackendSettingsStore.load()) {
        let processInfo = ProcessInfo.processInfo
        let isUITesting = processInfo.arguments.contains("VF_UI_TESTING")
        let isLiveBackendTesting = processInfo.arguments.contains("VF_LIVE_BACKEND_TESTING")
        self.fallbackContentService = contentService
        self.backendSettings = if isUITesting {
            BackendSettings()
        } else if isLiveBackendTesting {
            Self.liveBackendTestSettings(processInfo: processInfo)
        } else {
            settings
        }
        self.brandProfile = BrandProfileStore.load()
        self.projects = LocalProjectStore.load()
        self.posterAssets = assetsFromProjects(projects)
        if isUITesting {
            if ProcessInfo.processInfo.arguments.contains("VF_UI_TEST_EMPTY_LIBRARY") {
                projects = []
                posterAssets = []
            }
            quota = QuotaState(remainingTextGenerations: 10, remainingPosterExports: 10, isPro: false)
            if ProcessInfo.processInfo.arguments.contains("VF_UI_TEST_NO_QUOTA") {
                quota = QuotaState(remainingTextGenerations: 0, remainingPosterExports: 0, isPro: false)
            } else if ProcessInfo.processInfo.arguments.contains("VF_UI_TEST_LOW_POSTER_QUOTA") {
                quota = QuotaState(remainingTextGenerations: 10, remainingPosterExports: 2, isPro: false)
            }
        }
        if isLiveBackendTesting {
            projects = []
            posterAssets = []
            brandProfile = BrandProfile()
            quota = QuotaState(remainingTextGenerations: 10, remainingPosterExports: 10, isPro: false)
        }
        startTransactionListener()
    }

    var hasActiveStoreSubscription: Bool {
        !purchasedSubscriptionIDs.isDisjoint(with: SubscriptionProductID.all)
    }

    var launchLanguage: ContentLanguage {
        .defaultGenerationLanguage
    }

    var launchPlatforms: [SocialPlatform] {
        SocialPlatform.launchPlatforms(for: launchLanguage)
    }

    var visibleTemplates: [CreativeTemplate] {
        let platforms = Set(launchPlatforms)
        let filteredTemplates = templates.filter { platforms.contains($0.platform) }
        return filteredTemplates.isEmpty ? SampleData.templates(for: launchLanguage) : filteredTemplates
    }

    private var appAccountToken: UUID {
        BackendAccountToken.uuid(for: backendSettings.userId)
    }

    func generateProject(from draft: GenerationDraft) async -> ContentProject? {
        if let topicValidationMessage = draft.topicValidationMessage {
            generationError = topicValidationMessage
            return nil
        }

        guard quota.remainingTextGenerations > 0 || quota.isPro else {
            generationError = AppText.localized(
                "Free generations are used up for today. Upgrade to Pro to keep creating.",
                "今日免费文案额度已用完。升级 Pro 后可继续创作。"
            )
            openPaywall(reason: generationError)
            return nil
        }

        isGenerating = true
        generationError = nil
        defer { isGenerating = false }

        do {
            let project = try await activeContentService().generateContent(from: draftApplyingBrand(to: draft))
            projects.insert(project, at: 0)
            persistProjectsLocally()
            if backendSettings.mode == .backend {
                await refreshQuota()
            } else if !quota.isPro {
                quota.remainingTextGenerations = max(0, quota.remainingTextGenerations - 1)
            }
            return project
        } catch {
            generationError = userFacingGenerationError(for: error)
            return nil
        }
    }

    func savePosterDraft(for project: ContentProject, poster: PosterDraft, markExported: Bool = false) async {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index].poster = poster
        if markExported {
            projects[index].hasPosterExport = true
        }

        let updatedProject = projects[index]
        upsertPosterAsset(for: updatedProject)
        persistProjectsLocally()
        await persistProjectIfNeeded(updatedProject)
    }

    func saveContentResult(for project: ContentProject, result: ContentResult) async {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index].result = result

        let updatedProject = projects[index]
        persistProjectsLocally()
        await persistProjectIfNeeded(updatedProject)
    }

    func generatePosterBackground(for project: ContentProject, poster: PosterDraft, aspectRatio: String = "9:16") async -> PosterDraft? {
        guard quota.remainingPosterExports > 0 || quota.isPro else {
            posterGenerationError = AppText.localized(
                "Free AI background exports are used up for today. Upgrade to Pro to keep generating visuals.",
                "今日免费 AI 背景额度已用完。升级 Pro 后可继续生成视觉素材。"
            )
            openPaywall(reason: posterGenerationError)
            return nil
        }
        if ProcessInfo.processInfo.arguments.contains("VF_UI_TEST_POSTER_BACKGROUND_GENERATION") {
            return await generateUITestPosterBackground(for: project, poster: poster)
        }
        guard backendSettings.mode == .backend, let apiClient = makeAPIClient() else {
            posterGenerationError = AppText.localized(
                "AI image generation is not available right now. Please try again later.",
                "AI 图片生成暂时不可用，请稍后再试。"
            )
            return nil
        }

        isGeneratingPosterBackground = true
        posterGenerationError = nil
        defer { isGeneratingPosterBackground = false }

        do {
            let request = PosterBackgroundRequest(
                projectId: project.id.uuidString,
                language: project.draft.language.apiCode,
                style: poster.style.rawValue,
                aspectRatio: aspectRatio,
                prompt: posterBackgroundPrompt(for: project, poster: poster),
                modelRoute: ModelRoute.route(for: project.draft.language),
                productImageDataUrl: productImageDataURL(from: poster.productImageData)
            )
            let response: PosterBackgroundResponse = try await apiClient.post("/api/poster/background", body: request)
            let updatedPoster = poster.recordingBackgroundVersion(
                imageURL: response.imageUrl,
                usedProductReference: response.usedProductReference ?? false
            )
            await savePosterDraft(for: project, poster: updatedPoster)
            await refreshQuota()
            return updatedPoster
        } catch {
            posterGenerationError = userFacingPosterError(for: error)
            return nil
        }
    }

    private func generateUITestPosterBackground(for project: ContentProject, poster: PosterDraft) async -> PosterDraft? {
        isGeneratingPosterBackground = true
        posterGenerationError = nil
        defer { isGeneratingPosterBackground = false }

        try? await Task.sleep(for: .milliseconds(350))
        let accent: String
        switch poster.backgroundDirection {
        case .clean:
            accent = "#24c6a5"
        case .lifestyle:
            accent = "#ffb23f"
        case .premiumCommerce:
            accent = "#ff4c4c"
        case .negativeSpace:
            accent = "#5ba7ff"
        }
        let marker = UUID().uuidString.prefix(8)
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1440" viewBox="0 0 1080 1440">
          <defs>
            <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0" stop-color="#f7fff9"/>
              <stop offset="0.58" stop-color="#e6fbf2"/>
              <stop offset="1" stop-color="#ffffff"/>
            </linearGradient>
          </defs>
          <rect width="1080" height="1440" fill="url(#bg)"/>
          <circle cx="260" cy="250" r="220" fill="\(accent)" opacity="0.22"/>
          <rect x="610" y="260" width="220" height="520" rx="72" fill="\(accent)" opacity="0.58" transform="rotate(8 720 520)"/>
          <rect x="190" y="320" width="480" height="620" rx="92" fill="#ffffff" opacity="0.44" transform="rotate(-7 430 630)"/>
          <circle cx="850" cy="910" r="76" fill="#ffffff" opacity="0.52"/>
          <text x="68" y="1352" fill="#1a7a66" opacity="0.26" font-size="34" font-family="Helvetica">ui-test-\(marker)</text>
        </svg>
        """
        var dataURLAllowedCharacters = CharacterSet.alphanumerics
        dataURLAllowedCharacters.insert(charactersIn: "-._~")
        guard let encodedSVG = svg.addingPercentEncoding(withAllowedCharacters: dataURLAllowedCharacters),
              let imageURL = URL(string: "data:image/svg+xml,\(encodedSVG)") else {
            posterGenerationError = AppText.localized("AI background test image could not be generated.", "测试背景图生成失败。")
            return nil
        }

        let updatedPoster = poster.recordingBackgroundVersion(imageURL: imageURL, usedProductReference: false)
        await savePosterDraft(for: project, poster: updatedPoster)
        return updatedPoster
    }

    func toggleFavorite(_ project: ContentProject) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index].isFavorite.toggle()
        let updatedProject = projects[index]
        persistProjectsLocally()
        Task {
            await persistProjectIfNeeded(updatedProject)
        }
    }

    func deleteProjects(_ projectsToDelete: [ContentProject]) {
        let deletedProjectIDs = Set(projectsToDelete.map(\.id))
        guard !deletedProjectIDs.isEmpty else { return }

        projects.removeAll { deletedProjectIDs.contains($0.id) }
        posterAssets.removeAll { deletedProjectIDs.contains($0.projectId) }
        persistProjectsLocally()

        Task {
            for projectID in deletedProjectIDs {
                await deleteProjectFromBackendIfNeeded(projectID)
            }
        }
    }

    func removePosterAsset(_ poster: PosterAsset) {
        posterAssets.removeAll { $0.projectId == poster.projectId }
        if let index = projects.firstIndex(where: { $0.id == poster.projectId }) {
            projects[index].hasPosterExport = false
            projects[index].poster.backgroundImageURL = nil
            projects[index].poster.productImageIntegratedInBackground = nil
            projects[index].poster.backgroundHistory = []
            let updatedProject = projects[index]
            persistProjectsLocally()
            Task {
                await persistProjectIfNeeded(updatedProject)
            }
        } else {
            persistProjectsLocally()
        }
    }

    func clearLocalWorkspaceData() {
        projects = []
        posterAssets = []
        brandProfile = BrandProfile()
        pendingTemplateWorkflow = nil
        generationError = nil
        posterGenerationError = nil
        brandStatusMessage = nil

        LocalProjectStore.save([])
        BrandProfileStore.clear()

        localDataStatusMessage = AppText.localized(
            "Local projects, poster assets, snippets, and brand memory were cleared on this device.",
            "本机项目、海报素材、文案片段和品牌记忆已清空。"
        )
    }

    func draft(from template: CreativeTemplate) -> GenerationDraft {
        GenerationDraft(
            language: .defaultGenerationLanguage,
            platform: template.platform,
            goal: template.category.defaultGoal,
            topic: "",
            audience: brandProfile.audience.isEmpty ? template.defaultAudience : brandProfile.audience,
            tone: brandProfile.tone.isEmpty ? template.defaultTone : brandProfile.tone,
            templateName: template.name,
            templatePromptHint: template.promptHint,
            templateStyle: template.style,
            brandName: brandProfile.brandName,
            brandIndustry: brandProfile.industry,
            bannedWords: brandProfile.bannedWords
        )
    }

    func applyTemplateToStudio(_ template: CreativeTemplate, draft customDraft: GenerationDraft? = nil) {
        var appliedDraft = customDraft ?? draft(from: template)
        appliedDraft.language = launchLanguage
        appliedDraft.platform = template.platform
        appliedDraft.goal = template.category.defaultGoal
        appliedDraft.templateName = template.name
        appliedDraft.templatePromptHint = template.promptHint
        appliedDraft.templateStyle = template.style

        pendingTemplateWorkflow = AppliedTemplateWorkflow(
            templateName: template.name,
            platform: template.platform,
            category: template.category,
            draft: appliedDraft
        )
        generationError = nil
        selectedTab = .create
    }

    func consumeTemplateWorkflow() -> AppliedTemplateWorkflow? {
        let workflow = pendingTemplateWorkflow
        pendingTemplateWorkflow = nil
        return workflow
    }

    func batchIdeas(for brief: String, platforms: [SocialPlatform], count: Int) -> [CampaignIdea] {
        guard !platforms.isEmpty else { return [] }

        let trimmedBrief = brief.trimmingCharacters(in: .whitespacesAndNewlines)
        let topic = trimmedBrief.isEmpty ? AppText.localized("New campaign", "新活动") : trimmedBrief
        let plans = campaignPlanTemplates(topic: topic)
        return (0..<count).map { index in
            let platform = platforms[index % platforms.count]
            let day = index + 1
            let plan = plans[index % plans.count]
            return CampaignIdea(
                day: day,
                platform: platform,
                pillar: plan.pillar,
                objective: plan.objective,
                title: platformAdjustedTitle(plan.title, platform: platform),
                hook: plan.hook,
                posterAngle: plan.posterAngle,
                cta: plan.cta
            )
        }
    }

    func draft(from idea: CampaignIdea, productBrief: String) -> GenerationDraft {
        GenerationDraft(
            language: .defaultGenerationLanguage,
            platform: idea.platform,
            goal: .sellProduct,
            topic: productBrief.trimmingCharacters(in: .whitespacesAndNewlines),
            audience: brandProfile.audience,
            tone: brandProfile.tone,
            templateName: AppText.localized("Batch Content Calendar", "批量内容日历"),
            templatePromptHint: [
                AppText.localized("Calendar day", "日历天数") + ": \(idea.day)",
                AppText.localized("Pillar", "内容支柱") + ": \(idea.pillar)",
                AppText.localized("Objective", "目标") + ": \(idea.objective)",
                AppText.localized("Angle", "选题") + ": \(idea.title)",
                AppText.localized("Opening hook", "开头钩子") + ": \(idea.hook)",
                AppText.localized("Poster angle", "海报角度") + ": \(idea.posterAngle)",
                AppText.localized("CTA", "行动按钮") + ": \(idea.cta)"
            ].joined(separator: "\n"),
            templateStyle: .cleanProduct,
            brandName: brandProfile.brandName,
            brandIndustry: brandProfile.industry,
            bannedWords: brandProfile.bannedWords
        )
    }

    private func campaignPlanTemplates(topic: String) -> [(pillar: String, objective: String, title: String, hook: String, posterAngle: String, cta: String)] {
        [
            (
                AppText.localized("Pain point", "痛点"),
                AppText.localized("Create recognition", "制造共鸣"),
                AppText.localized("Why busy people keep failing at this routine", "上班族为什么总坚持不了这个小习惯？"),
                AppText.localized("Start from the exact moment the user gives up.", "从用户最容易放弃的那个瞬间切入。"),
                AppText.localized("Before/after daily routine card", "前后对比生活场景海报"),
                AppText.localized("Save this checklist", "收藏这份清单")
            ),
            (
                AppText.localized("Scenario", "场景"),
                AppText.localized("Show everyday usefulness", "展示日常用途"),
                AppText.localized("3 real moments where \(topic) is useful", "\(topic)真正有用的 3 个场景"),
                AppText.localized("Use commute, office, and after-work scenes.", "用通勤、办公室、下班后三个场景串起来。"),
                AppText.localized("Three-scene grid poster", "三场景拼图海报"),
                AppText.localized("Check if it fits you", "看看适不适合你")
            ),
            (
                AppText.localized("Decision", "决策"),
                AppText.localized("Reduce purchase hesitation", "降低购买犹豫"),
                AppText.localized("Before buying \(topic), check these details", "买\(topic)前先看这几个细节"),
                AppText.localized("Help the user avoid a bad purchase.", "站在用户角度帮 TA 避坑。"),
                AppText.localized("Buying checklist poster", "购买清单海报"),
                AppText.localized("Compare before buying", "买前先对比")
            ),
            (
                AppText.localized("Trust", "信任"),
                AppText.localized("Make the claim feel grounded", "让卖点更可信"),
                AppText.localized("I used \(topic) for 7 days. Here is the honest result", "我用了 7 天\(topic)，真实感受是这样"),
                AppText.localized("Use a diary-style opening with concrete observations.", "用日记口吻写具体体验。"),
                AppText.localized("7-day note poster", "7 天体验记录海报"),
                AppText.localized("Read the honest review", "看真实体验")
            ),
            (
                AppText.localized("Tutorial", "教程"),
                AppText.localized("Teach quick usage", "教用户快速上手"),
                AppText.localized("A 60-second setup for \(topic)", "\(topic)的 60 秒上手流程"),
                AppText.localized("Break the process into 3 simple steps.", "拆成 3 个简单步骤。"),
                AppText.localized("Step-by-step poster", "三步教程海报"),
                AppText.localized("Try this method", "照这个方法试试")
            ),
            (
                AppText.localized("Comparison", "对比"),
                AppText.localized("Differentiate the product", "突出差异"),
                AppText.localized("The small details that make \(topic) easier to use", "\(topic)好不好用，关键看这些小细节"),
                AppText.localized("Compare friction, cleanup, portability, and repeat usage.", "对比使用阻力、清洁、便携、复用频率。"),
                AppText.localized("Feature comparison poster", "功能对比海报"),
                AppText.localized("Pick by scenario", "按场景选择")
            ),
            (
                AppText.localized("Conversion", "转化"),
                AppText.localized("Drive action without overpromising", "温和促单"),
                AppText.localized("If you only use \(topic) in one scene, make it this one", "如果只在一个场景用\(topic)，我建议是这个"),
                AppText.localized("Lead with the strongest use case and a low-pressure CTA.", "用最强场景开头，结尾轻促单。"),
                AppText.localized("Hero product benefit poster", "主卖点海报"),
                AppText.localized("Start with this scenario", "从这个场景开始")
            )
        ]
    }

    private func platformAdjustedTitle(_ title: String, platform: SocialPlatform) -> String {
        switch platform {
        case .douyin:
            "\(title)｜15 秒讲清楚"
        case .weChat:
            "\(title)｜适合发朋友圈/社群"
        case .tikTok:
            "\(title) | 15-second hook"
        case .instagram:
            "\(title) | Reel or carousel angle"
        case .youtubeShorts:
            "\(title) | Shorts-ready"
        default:
            title
        }
    }

    func updateBackendSettings(_ settings: BackendSettings) {
        backendSettings = settings
        BackendSettingsStore.save(settings)
        backendStatusMessage = settings.mode == .backend
            ? AppText.localized("Backend mode saved. Test the connection before generating live content.", "后端模式已保存。生成真实内容前请先测试连接。")
            : AppText.localized("Mock mode is active. You can keep building locally without a server.", "Mock 模式已启用。无需服务器也可以继续本地开发。")
    }

    func testBackendConnection() async {
        guard let dataService = makeBackendDataService() else {
            backendStatusMessage = AppText.localized(
                "Backend URL is invalid. Use a full URL such as http://localhost:8787 or a public HTTPS endpoint.",
                "后端地址无效。请填写完整地址，例如 http://localhost:8787 或公网 HTTPS 地址。"
            )
            return
        }

        isSyncingBackend = true
        defer { isSyncingBackend = false }

        do {
            let response = try await dataService.health()
            backendStatusMessage = AppText.localized(
                "\(response.service) is reachable: \(response.status).",
                "\(response.service) 连接正常：\(response.status)。"
            )
        } catch {
            backendStatusMessage = userFacingBackendError(prefix: AppText.localized("Connection failed", "连接失败"), error: error)
        }
    }

    func syncFromBackend() async {
        guard backendSettings.mode == .backend else { return }
        guard let dataService = makeBackendDataService() else {
            backendStatusMessage = AppText.localized(
                "Backend URL is invalid. Check the endpoint and try again.",
                "后端地址无效。请检查接口地址后重试。"
            )
            return
        }

        isSyncingBackend = true
        defer { isSyncingBackend = false }

        do {
            async let remoteQuota = dataService.quota()
            async let remoteTemplates = dataService.templates()
            async let remoteBrand = dataService.brandProfile()
            async let remoteProjects = dataService.projects()

            quota = try await remoteQuota
            templates = try await remoteTemplates
            brandProfile = try await remoteBrand
            projects = try await remoteProjects
            posterAssets = assetsFromProjects(projects)
            persistProjectsLocally()
            backendStatusMessage = AppText.localized("Synced from backend.", "已从后端同步数据。")
        } catch {
            backendStatusMessage = userFacingBackendError(prefix: AppText.localized("Sync failed", "同步失败"), error: error)
        }
    }

    func refreshQuota() async {
        guard backendSettings.mode == .backend, let dataService = makeBackendDataService() else { return }
        if let remoteQuota = try? await dataService.quota() {
            quota = quotaKeepingActiveStoreSubscription(remoteQuota)
        }
    }

    func updateProStatus(_ isPro: Bool) async {
        if backendSettings.mode == .backend, let dataService = makeBackendDataService() {
            do {
                quota = try await dataService.updateProStatus(isPro: isPro)
                backendStatusMessage = isPro
                    ? AppText.localized("Pro mode enabled.", "Pro 模式已开启。")
                    : AppText.localized("Pro mode disabled.", "Pro 模式已关闭。")
            } catch {
                backendStatusMessage = userFacingBackendError(prefix: AppText.localized("Pro update failed", "Pro 状态更新失败"), error: error)
            }
        } else {
            quota.isPro = isPro
        }
    }

    func openPaywall(reason: String? = nil) {
        if let reason, !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            paywallReasonMessage = reason
        }
        selectedTab = .pro
    }

    func configureStoreKitIfNeeded() async {
        guard !didConfigureStoreKit else { return }
        didConfigureStoreKit = true

        await loadSubscriptionProducts()
        await refreshStoreEntitlements(syncBackend: true)
    }

    func product(for plan: SubscriptionPlan) -> Product? {
        subscriptionProducts.first { $0.id == plan.id }
    }

    func loadSubscriptionProducts() async {
        guard !isLoadingStoreProducts else { return }

        isLoadingStoreProducts = true
        purchaseStatusMessage = nil
        defer { isLoadingStoreProducts = false }

        do {
            let products = try await Product.products(for: SubscriptionProductID.all)
            subscriptionProducts = products.sorted { lhs, rhs in
                SubscriptionProductID.sortIndex(for: lhs.id) < SubscriptionProductID.sortIndex(for: rhs.id)
            }
            if subscriptionProducts.isEmpty {
                purchaseStatusMessage = AppText.localized(
                    "Subscription plans are temporarily unavailable. Please try again later.",
                    "订阅方案暂时无法加载，请稍后再试。"
                )
            }
        } catch {
            purchaseStatusMessage = AppText.localized(
                "Subscription plans failed to load. Please check your connection and try again.",
                "订阅方案加载失败，请检查网络后重试。"
            )
        }
    }

    func purchaseSubscription(plan: SubscriptionPlan) async {
        guard !isPurchasingSubscription else { return }
        guard let product = product(for: plan) else {
            purchaseStatusMessage = AppText.localized(
                "This product is not loaded yet. Try again in a moment.",
                "该商品还没有加载完成，请稍后再试。"
            )
            await loadSubscriptionProducts()
            return
        }

        isPurchasingSubscription = true
        purchaseStatusMessage = nil
        defer { isPurchasingSubscription = false }

        do {
            let result = try await product.purchase(options: [.appAccountToken(appAccountToken)])
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                await transaction.finish()
                await syncSubscriptionWithBackend(transaction: transaction, signedTransactionInfo: verification.jwsRepresentation)
                await refreshStoreEntitlements(syncBackend: false)
                purchaseStatusMessage = AppText.localized("Pro is active.", "会员已开通。")
            case .userCancelled:
                purchaseStatusMessage = AppText.localized("Purchase cancelled.", "购买已取消。")
            case .pending:
                purchaseStatusMessage = AppText.localized("Purchase is pending approval.", "购买正在等待确认。")
            @unknown default:
                purchaseStatusMessage = AppText.localized("Purchase did not complete.", "购买未完成。")
            }
        } catch {
            purchaseStatusMessage = AppText.localized(
                "Purchase failed: \(error.localizedDescription)",
                "购买失败：\(error.localizedDescription)"
            )
        }
    }

    func restorePurchases() async {
        purchaseStatusMessage = nil
        do {
            try await AppStore.sync()
            await refreshStoreEntitlements(syncBackend: true)
            purchaseStatusMessage = hasActiveStoreSubscription
                ? AppText.localized("Purchase restored.", "购买已恢复。")
                : AppText.localized("No active Pro subscription was found.", "未找到有效会员订阅。")
        } catch {
            purchaseStatusMessage = AppText.localized(
                "Restore failed: \(error.localizedDescription)",
                "恢复购买失败：\(error.localizedDescription)"
            )
        }
    }

    func refreshTemplatesIfNeeded() async {
        guard backendSettings.mode == .backend, let dataService = makeBackendDataService() else { return }
        if let remoteTemplates = try? await dataService.templates() {
            templates = remoteTemplates
        }
    }

    func refreshProjectsIfNeeded() async {
        guard backendSettings.mode == .backend, let dataService = makeBackendDataService() else { return }
        if let remoteProjects = try? await dataService.projects() {
            projects = remoteProjects
            posterAssets = assetsFromProjects(remoteProjects)
            persistProjectsLocally()
        }
    }

    func saveBrandProfile(_ profile: BrandProfile) async {
        brandProfile = profile
        BrandProfileStore.save(profile)
        brandStatusMessage = AppText.localized("Brand memory saved on this device.", "品牌记忆已保存到本机。")
        guard backendSettings.mode == .backend, let dataService = makeBackendDataService() else { return }

        do {
            brandProfile = try await dataService.saveBrandProfile(profile)
            BrandProfileStore.save(brandProfile)
            brandStatusMessage = AppText.localized("Brand memory saved and synced.", "品牌记忆已保存并同步。")
            backendStatusMessage = "Brand Kit saved to backend."
        } catch {
            brandStatusMessage = AppText.localized("Saved on this device. Sync did not complete this time.", "已保存到本机，本次同步暂未完成。")
            backendStatusMessage = "Brand save failed: \(error.localizedDescription)"
        }
    }

    private func draftApplyingBrand(to draft: GenerationDraft) -> GenerationDraft {
        var enrichedDraft = draft
        if enrichedDraft.audience.isEmpty {
            enrichedDraft.audience = brandProfile.audience
        }
        if enrichedDraft.tone.isEmpty {
            enrichedDraft.tone = brandProfile.tone
        }
        if enrichedDraft.brandName.isEmpty {
            enrichedDraft.brandName = brandProfile.brandName
        }
        if enrichedDraft.brandIndustry.isEmpty {
            enrichedDraft.brandIndustry = brandProfile.industry
        }
        if enrichedDraft.bannedWords.isEmpty {
            enrichedDraft.bannedWords = brandProfile.bannedWords
        }
        let defaultPlatform = SocialPlatform.defaultPlatform(for: enrichedDraft.language)
        let allowedBrandPlatforms = SocialPlatform.launchPlatforms(for: enrichedDraft.language)
        if enrichedDraft.platform == defaultPlatform,
           brandProfile.defaultPlatform != defaultPlatform,
           allowedBrandPlatforms.contains(brandProfile.defaultPlatform),
           !brandProfile.brandName.isEmpty,
           enrichedDraft.templateName.isEmpty {
            enrichedDraft.platform = brandProfile.defaultPlatform
        }
        return enrichedDraft
    }

    private func posterBackgroundPrompt(for project: ContentProject, poster: PosterDraft) -> String {
        let scene = posterVisualScene(for: project, poster: poster)
        let channelLabel = poster.resolvedChannelLabel(for: project.draft.platform)
        let hasProductReference = poster.productImageData != nil
        let backgroundDirection = poster.backgroundDirection.promptInstruction(for: project.draft.language)
        let productIntegration = poster.productImageIntegrationMode.promptInstruction(for: project.draft.language)
        let textPlacement = poster.textPlacement.promptInstruction(for: project.draft.language, poster: poster)
        if project.draft.language == .english {
            return [
                "Generate a pure commercial photography background layer, not a finished poster design.",
                "It will be used as a \(channelLabel) background, but the image itself must not contain platform UI.",
                hasProductReference ? "Use the supplied product reference image only for the hero product identity. Preserve the product's real shape, proportions, color, material, texture, transparent windows, visible internal parts, and packaging details. Do not add liquid, fruit, props, labels, or decorative content inside transparent product areas unless they already exist in the reference product. Ignore and do not reproduce the reference image background, watermark, non-product text, or non-product logos. Do not replace it with a similar product or redesign it. Build a natural commercial scene around that exact product with coherent lighting, perspective, contact shadows, and reflections." : nil,
                hasProductReference ? "Product reference integration mode: \(productIntegration)." : nil,
                "Product or topic: \(project.draft.topic).",
                "Audience: \(project.draft.audience.isEmpty ? brandProfile.audience : project.draft.audience).",
                "Scene direction: \(scene).",
                "Background direction: \(backgroundDirection).",
                "The app will overlay this headline later: \(poster.headline).",
                "Style: \(poster.style.displayName).",
                "Copy-safe layout: \(textPlacement)",
                hasProductReference ? "Do not add or copy any non-product text, letters, numbers, logos, brand marks, watermarks, QR codes, labels, stickers, buttons, captions, or interface elements. Only preserve marks that are physically printed on the supplied product itself." : "Strictly no text, letters, numbers, logos, brand marks, watermarks, QR codes, labels, stickers, buttons, captions, or interface elements anywhere in the image.",
                "Realistic high-end product photography, clean lighting, strong commercial quality."
            ].compactMap { $0 }.joined(separator: " ")
        }

        return [
            "生成一张纯商业摄影背景底图，不要生成成品海报设计。",
            "用途是\(channelLabel)背景，但画面里不能出现平台界面。",
            hasProductReference ? "上传的参考图只用于识别主商品本体。保留产品真实的外形、比例、颜色、材质、纹理、透明窗口、可见内部结构和包装细节；不要在产品透明区域里新增液体、水果、道具、标签或装饰内容，除非参考图产品本身已有。忽略并不要复刻参考图里的背景、水印、非产品文字或非产品 logo。不要替换成相似产品，也不要重新设计产品。围绕这个真实产品生成自然商业摄影场景，让光线、透视、接触阴影和环境反射一致。" : nil,
            hasProductReference ? "产品参考图融合模式：\(productIntegration)" : nil,
            "产品或主题：\(project.draft.topic)。",
            "目标人群：\(project.draft.audience.isEmpty ? brandProfile.audience : project.draft.audience)。",
            "场景方向：\(scene)。",
            "背景方向：\(backgroundDirection)。",
            "App 后续会叠加这个标题：\(poster.headline)。",
            "风格：\(poster.style.displayName)。",
            "文案安全区：\(textPlacement)",
            hasProductReference ? "不要新增或复制任何非产品文字、汉字、英文字母、数字、logo、品牌标识、水印、二维码、标签、贴纸、按钮、字幕或 UI 元素；只允许保留真实产品本体上物理印刷的可见标识。" : "画面里严禁出现任何文字、汉字、英文字母、数字、logo、品牌标识、水印、二维码、标签、贴纸、按钮、字幕或 UI 元素。",
            "真实高级商品摄影质感，光线干净，适合电商种草。"
        ].compactMap { $0 }.joined(separator: " ")
    }

    private func productImageDataURL(from data: Data?) -> String? {
        guard let data else { return nil }
        return "data:image/jpeg;base64,\(data.base64EncodedString())"
    }

    private func posterVisualScene(for project: ContentProject, poster: PosterDraft) -> String {
        let draft = project.draft
        let topic = draft.topic.trimmingCharacters(in: .whitespacesAndNewlines)
        let templateContext = [
            draft.templateName,
            draft.templatePromptHint,
            draft.goal.rawValue,
            poster.style.rawValue
        ].joined(separator: " ").lowercased()

        if draft.language == .english {
            if matches(templateContext, keywords: ["store", "traffic", "local", "visit", "restaurant", "cafe", "shop"]) {
                return "A warm local shop or cafe visit scene with the featured product naturally placed on a table, lifestyle depth, no signage or readable menus."
            }
            if matches(templateContext, keywords: ["live", "stream", "launch room"]) {
                return "A livestream product setup with soft studio lighting, product display props, phone tripod silhouette, energetic but clean, no screens with text."
            }
            if matches(templateContext, keywords: ["season", "holiday", "promo", "festival", "gift"]) {
                return "A festive product still life with tasteful seasonal props, ribbons, soft glow, premium ecommerce styling, no printed words."
            }
            if matches(templateContext, keywords: ["new", "launch", "drop", "release"]) {
                return "A new product launch hero shot on a clean pedestal with crisp light beams, premium minimal backdrop, generous negative space."
            }
            if matches(templateContext, keywords: ["personal", "brand", "expert", "coach", "founder"]) {
                return "A creator workspace scene with notebook, camera, soft daylight, professional personal-brand atmosphere, no visible text."
            }
            return "A realistic product still life for \(topic), placed in a bright daily-use scene with premium props and clean negative space."
        }

        if matches(templateContext, keywords: ["探店", "门店", "到店", "店铺", "餐厅", "咖啡", "打卡", "store", "traffic"]) {
            return "真实探店场景，产品自然摆放在门店桌面或橱窗光线里，有生活氛围和空间纵深，但不要出现招牌、菜单或任何可读文字。"
        }
        if matches(templateContext, keywords: ["直播", "live", "预热", "开播"]) {
            return "直播间产品陈列场景，柔和补光、桌面道具、手机支架剪影、热闹但干净，不要出现屏幕文字或直播界面。"
        }
        if matches(templateContext, keywords: ["节日", "促销", "季节", "双11", "春节", "礼物", "season", "promo"]) {
            return "节日促销商品静物场景，搭配高级礼盒、丝带、暖光和季节道具，质感丰富但不出现任何印刷字。"
        }
        if matches(templateContext, keywords: ["新品", "发布", "上新", "new", "launch"]) {
            return "新品发布主视觉，产品放在干净展台或亚克力台面上，光束清晰、背景极简、留白充足。"
        }
        if matches(templateContext, keywords: ["个人", "ip", "专家", "创始人", "人设", "personal", "brand"]) {
            return "个人品牌创作者工作台场景，有笔记本、相机、柔和自然光和专业感道具，但不要出现纸面文字。"
        }
        return "真实商品静物场景，\(topic) 放在明亮日常使用环境中，搭配高级道具和干净留白。"
    }

    private func matches(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.localizedCaseInsensitiveContains($0) }
    }

    private func activeContentService() -> ContentGenerating {
        guard backendSettings.mode == .backend,
              let apiClient = makeAPIClient() else {
            return fallbackContentService
        }

        return BackendContentService(apiClient: apiClient)
    }

    private func makeBackendDataService() -> BackendDataService? {
        guard let apiClient = makeAPIClient() else { return nil }
        return BackendDataService(apiClient: apiClient)
    }

    private func makeAPIClient() -> APIClient? {
        guard let baseURL = backendSettings.baseURL else { return nil }
        return APIClient(baseURL: baseURL, userId: backendSettings.userId)
    }

    private static func liveBackendTestSettings(processInfo: ProcessInfo) -> BackendSettings {
        let baseURLString = processInfo.environment["VF_LIVE_BACKEND_URL"]
            ?? launchArgumentValue(named: "VF_LIVE_BACKEND_URL", arguments: processInfo.arguments)
            ?? "http://127.0.0.1:8787"
        let userId = processInfo.environment["VF_LIVE_BACKEND_USER_ID"]
            ?? launchArgumentValue(named: "VF_LIVE_BACKEND_USER_ID", arguments: processInfo.arguments)
            ?? "live-ui-test"

        return BackendSettings(mode: .backend, baseURLString: baseURLString, userId: userId)
    }

    private static func launchArgumentValue(named name: String, arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: name) else { return nil }
        let valueIndex = arguments.index(after: index)
        guard arguments.indices.contains(valueIndex) else { return nil }
        return arguments[valueIndex]
    }

    private func persistProjectIfNeeded(_ project: ContentProject) async {
        guard backendSettings.mode == .backend, let dataService = makeBackendDataService() else {
            persistProjectsLocally()
            return
        }
        do {
            if let savedProject = try await dataService.saveProject(project),
               let index = projects.firstIndex(where: { $0.id == savedProject.id }) {
                var mergedProject = savedProject
                if mergedProject.poster.productImageData == nil {
                    mergedProject.poster.productImageData = project.poster.productImageData
                }
                if mergedProject.poster.channelLabel == nil {
                    mergedProject.poster.channelLabel = project.poster.channelLabel
                }
                if mergedProject.poster.backgroundHistory.isEmpty {
                    mergedProject.poster.backgroundHistory = project.poster.backgroundHistory
                }
                projects[index] = mergedProject
                upsertPosterAsset(for: mergedProject)
                persistProjectsLocally()
            }
        } catch {
            backendStatusMessage = "Project save failed: \(error.localizedDescription)"
        }
    }

    private func deleteProjectFromBackendIfNeeded(_ projectID: UUID) async {
        guard backendSettings.mode == .backend, let dataService = makeBackendDataService() else { return }
        do {
            _ = try await dataService.deleteProject(id: projectID)
        } catch {
            backendStatusMessage = "Project delete failed: \(error.localizedDescription)"
        }
    }

    private func persistProjectsLocally() {
        LocalProjectStore.save(projects)
    }

    private func upsertPosterAsset(for project: ContentProject) {
        guard project.hasPosterExport || project.poster.backgroundImageURL != nil else { return }
        let asset = PosterAsset(
            projectId: project.id,
            projectTopic: project.draft.topic,
            headline: project.poster.headline,
            platform: project.draft.platform,
            style: project.poster.style,
            backgroundImageURL: project.poster.backgroundImageURL,
            createdAt: project.createdAt
        )

        if let index = posterAssets.firstIndex(where: { $0.projectId == project.id }) {
            posterAssets[index] = asset
        } else {
            posterAssets.insert(asset, at: 0)
        }
    }

    private func assetsFromProjects(_ projects: [ContentProject]) -> [PosterAsset] {
        projects
            .filter { $0.hasPosterExport || $0.poster.backgroundImageURL != nil }
            .map { project in
                PosterAsset(
                    projectId: project.id,
                    projectTopic: project.draft.topic,
                    headline: project.poster.headline,
                    platform: project.draft.platform,
                    style: project.poster.style,
                    backgroundImageURL: project.poster.backgroundImageURL,
                    createdAt: project.createdAt
                )
            }
    }

    private func startTransactionListener() {
        transactionUpdatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                await self.handle(transactionUpdate: result)
            }
        }
    }

    private func handle(transactionUpdate result: VerificationResult<Transaction>) async {
        do {
            let transaction = try verified(result)
            await transaction.finish()
            await syncSubscriptionWithBackend(transaction: transaction, signedTransactionInfo: result.jwsRepresentation)
            await refreshStoreEntitlements(syncBackend: false)
        } catch {
            purchaseStatusMessage = AppText.localized(
                "Transaction verification failed.",
                "交易验证失败。"
            )
        }
    }

    private func refreshStoreEntitlements(syncBackend: Bool) async {
        var activeSubscriptionIDs = Set<String>()
        var latestActiveTransaction: Transaction?
        var latestSignedTransactionInfo = ""

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verified(result),
                  SubscriptionProductID.all.contains(transaction.productID),
                  transaction.revocationDate == nil else {
                continue
            }

            activeSubscriptionIDs.insert(transaction.productID)
            if latestActiveTransaction == nil || transaction.purchaseDate > latestActiveTransaction!.purchaseDate {
                latestActiveTransaction = transaction
                latestSignedTransactionInfo = result.jwsRepresentation
            }
        }

        purchasedSubscriptionIDs = activeSubscriptionIDs
        if !activeSubscriptionIDs.isEmpty {
            quota.isPro = true
        } else if backendSettings.mode != .backend {
            quota.isPro = false
        }

        guard syncBackend else { return }
        if let latestActiveTransaction {
            await syncSubscriptionWithBackend(transaction: latestActiveTransaction, signedTransactionInfo: latestSignedTransactionInfo)
        } else {
            await updateProStatus(false)
        }
    }

    private func syncSubscriptionWithBackend(transaction: Transaction, signedTransactionInfo: String) async {
        guard backendSettings.mode == .backend, let dataService = makeBackendDataService() else {
            quota.isPro = true
            return
        }

        let request = SubscriptionSyncRequest(
            productId: transaction.productID,
            transactionId: String(transaction.id),
            originalTransactionId: String(transaction.originalID),
            appAccountToken: appAccountToken,
            purchaseDate: transaction.purchaseDate,
            expirationDate: transaction.expirationDate,
            environment: String(describing: transaction.environment),
            signedTransactionInfo: signedTransactionInfo
        )

        do {
            quota = try await dataService.syncSubscription(request)
            backendStatusMessage = "Subscription synced."
        } catch {
            backendStatusMessage = "Subscription sync failed: \(error.localizedDescription)"
            quota.isPro = true
            if let fallbackQuota = try? await dataService.updateProStatus(isPro: true) {
                quota = quotaKeepingActiveStoreSubscription(fallbackQuota)
                backendStatusMessage = "Subscription sync failed; Pro status was enabled on backend."
            }
        }
    }

    private func quotaKeepingActiveStoreSubscription(_ remoteQuota: QuotaState) -> QuotaState {
        guard hasActiveStoreSubscription else { return remoteQuota }

        var mergedQuota = remoteQuota
        mergedQuota.isPro = true
        return mergedQuota
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw StoreKitVerificationError.failed
        }
    }

    private func userFacingGenerationError(for error: Error) -> String {
        if let apiError = error as? APIClientError {
            switch apiError.serverCode {
            case "medical_claim", "financial_claim", "absolute_ad_claim", "illegal_or_dangerous":
                return AppText.localized(
                    "This brief contains high-risk claims. Soften the wording and avoid medical, financial, illegal, or absolute promises.",
                    "这段简报包含高风险表述。请弱化措辞，避免医疗、金融、违法或绝对化承诺。"
                )
            case "rate_limited":
                return AppText.localized(
                    "You are generating too quickly. Wait a moment, then retry.",
                    "生成太频繁了，请稍等片刻再重试。"
                )
            case "quota_exhausted":
                return AppText.localized(
                    "Free generations are used up for today. Upgrade to Pro or try again tomorrow.",
                    "今日免费文案额度已用完。可以升级 Pro，或明天再试。"
                )
            case "upstream_timeout":
                return AppText.localized(
                    "The AI provider is taking longer than expected. Please retry; your brief is still saved.",
                    "AI 服务响应超时。请稍后重试，当前简报不会丢失。"
                )
            default:
                if apiError.statusCode == 502 {
                    return AppText.localized(
                        "The AI provider is temporarily unavailable. Please retry in a moment.",
                        "AI 服务暂时不可用，请稍后重试。"
                    )
                }
                if let detail = apiError.serverDetail, !detail.isEmpty {
                    return AppText.localized("Generation failed: \(detail)", "生成失败：\(detail)")
                }
            }
        }

        return AppText.localized(
            "Generation failed: \(error.localizedDescription)",
            "生成失败：\(error.localizedDescription)"
        )
    }

    private func userFacingPosterError(for error: Error) -> String {
        if let apiError = error as? APIClientError {
            switch apiError.serverCode {
            case "medical_claim", "financial_claim", "absolute_ad_claim", "illegal_or_dangerous":
                return AppText.localized(
                    "The poster prompt contains high-risk claims. Simplify the visual direction and avoid risky wording.",
                    "海报提示词包含高风险表述。请简化视觉方向，避免风险措辞。"
                )
            case "rate_limited":
                return AppText.localized(
                    "AI background requests are too frequent. Wait a moment, then retry.",
                    "AI 背景请求太频繁了，请稍等片刻再重试。"
                )
            case "quota_exhausted":
                return AppText.localized(
                    "Free AI background exports are used up for today.",
                    "今日免费 AI 背景额度已用完。"
                )
            case "upstream_timeout":
                return AppText.localized(
                    "AI background generation timed out. Retry, or render the current poster first.",
                    "AI 背景生成超时。你可以重试，或先生成当前海报。"
                )
            default:
                if apiError.statusCode == 502 {
                    return AppText.localized(
                        "The image provider is temporarily unavailable. Please retry in a moment.",
                        "图片生成服务暂时不可用，请稍后重试。"
                    )
                }
                if let detail = apiError.serverDetail, !detail.isEmpty {
                    return AppText.localized("Poster background failed: \(detail)", "AI 背景生成失败：\(detail)")
                }
            }
        }

        return AppText.localized(
            "Poster background failed: \(error.localizedDescription)",
            "AI 背景生成失败：\(error.localizedDescription)"
        )
    }

    private func userFacingBackendError(prefix: String, error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return AppText.localized(
                    "\(prefix): no internet connection. You can switch to Mock mode and keep working locally.",
                    "\(prefix)：当前没有网络。你可以切回 Mock 模式继续本地创作。"
                )
            case .cannotConnectToHost, .cannotFindHost, .timedOut:
                return AppText.localized(
                    "\(prefix): backend is unreachable. Check whether the server is running or switch to Mock mode.",
                    "\(prefix)：后端暂时不可用。请确认服务是否启动，或切回 Mock 模式。"
                )
            default:
                break
            }
        }

        return AppText.localized(
            "\(prefix): \(error.localizedDescription). You can switch to Mock mode and retry later.",
            "\(prefix)：\(error.localizedDescription)。可以先切回 Mock 模式，稍后再试。"
        )
    }
}

private enum BrandProfileStore {
    private static let storageKey = "viralforge.brandProfile"

    static func load() -> BrandProfile {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let profile = try? JSONDecoder().decode(BrandProfile.self, from: data) else {
            return BrandProfile()
        }
        return profile
    }

    static func save(_ profile: BrandProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

private enum LocalProjectStore {
    private static let storageKey = "viralforge.localProjects"

    static func load() -> [ContentProject] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let projects = try? JSONDecoder().decode([ContentProject].self, from: data) else {
            return []
        }
        return projects
    }

    static func save(_ projects: [ContentProject]) {
        guard let data = try? JSONEncoder().encode(projects) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

private enum StoreKitVerificationError: LocalizedError {
    case failed

    var errorDescription: String? {
        AppText.localized("Purchase could not be verified. Please try restoring purchases.", "购买无法验证，请尝试恢复购买。")
    }
}

private enum BackendAccountToken {
    static func uuid(for userId: String) -> UUID {
        let normalizedUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let stableInput = "com.phil.viralforge.appAccountToken:\(normalizedUserId.isEmpty ? "demo-user" : normalizedUserId)"
        var bytes = stableTokenBytes(from: stableInput)
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80

        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5],
            bytes[6], bytes[7],
            bytes[8], bytes[9],
            bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    private static func stableTokenBytes(from input: String) -> [UInt8] {
        var high: UInt64 = 0xcbf29ce484222325
        var low: UInt64 = 0x84222325cbf29ce4

        for byte in input.utf8 {
            high ^= UInt64(byte)
            high &*= 0x100000001b3
            low ^= UInt64(byte).byteSwapped
            low &*= 0x100000001b3
        }

        return withUnsafeBytes(of: high.bigEndian, Array.init) + withUnsafeBytes(of: low.bigEndian, Array.init)
    }
}
