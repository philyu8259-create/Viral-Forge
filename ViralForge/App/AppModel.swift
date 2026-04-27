import Foundation
import CryptoKit
import Observation
import StoreKit

@MainActor
@Observable
final class AppModel {
    var projects: [ContentProject] = SampleData.projects
    var templates: [CreativeTemplate] = SampleData.templates
    var posterAssets: [PosterAsset] = []
    var brandProfile = BrandProfile()
    var quota = QuotaState(remainingTextGenerations: 3, remainingPosterExports: 1, isPro: false)
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
    var subscriptionProducts: [Product] = []
    var purchasedSubscriptionIDs: Set<String> = []

    private let fallbackContentService: ContentGenerating
    private var didConfigureStoreKit = false
    private var transactionUpdatesTask: Task<Void, Never>?

    init(contentService: ContentGenerating = MockContentService(), settings: BackendSettings = BackendSettingsStore.load()) {
        let isUITesting = ProcessInfo.processInfo.arguments.contains("VF_UI_TESTING")
        self.fallbackContentService = contentService
        self.backendSettings = isUITesting ? BackendSettings() : settings
        self.brandProfile = BrandProfileStore.load()
        self.projects = LocalProjectStore.load()
        self.posterAssets = assetsFromProjects(projects)
        if isUITesting {
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
            generationError = AppText.localized("Free generations are used up for today.", "今日免费文案额度已用完。")
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
            generationError = AppText.localized(
                "Generation failed: \(error.localizedDescription)",
                "生成失败：\(error.localizedDescription)"
            )
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

    func generatePosterBackground(for project: ContentProject, poster: PosterDraft, aspectRatio: String = "9:16") async -> URL? {
        guard quota.remainingPosterExports > 0 || quota.isPro else {
            posterGenerationError = "Free poster exports are used up for today."
            return nil
        }
        guard backendSettings.mode == .backend, let apiClient = makeAPIClient() else {
            posterGenerationError = "Backend mode is required for AI image generation."
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
                modelRoute: ModelRoute.route(for: project.draft.language)
            )
            let response: PosterBackgroundResponse = try await apiClient.post("/api/poster/background", body: request)
            var updatedPoster = poster
            updatedPoster.backgroundImageURL = response.imageUrl
            await savePosterDraft(for: project, poster: updatedPoster)
            await refreshQuota()
            return response.imageUrl
        } catch {
            posterGenerationError = "Poster background failed: \(error.localizedDescription)"
            return nil
        }
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

    func draft(from template: CreativeTemplate) -> GenerationDraft {
        GenerationDraft(
            language: .defaultGenerationLanguage,
            platform: template.platform,
            goal: template.category == .promotion || template.category == .product ? .sellProduct : .growAudience,
            topic: "",
            audience: brandProfile.audience,
            tone: brandProfile.tone,
            templateName: template.name,
            templatePromptHint: template.promptHint,
            templateStyle: template.style,
            brandName: brandProfile.brandName,
            brandIndustry: brandProfile.industry,
            bannedWords: brandProfile.bannedWords
        )
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
        backendStatusMessage = settings.mode == .backend ? "Backend mode saved." : "Mock mode is active."
    }

    func testBackendConnection() async {
        guard let dataService = makeBackendDataService() else {
            backendStatusMessage = "Backend URL is invalid."
            return
        }

        isSyncingBackend = true
        defer { isSyncingBackend = false }

        do {
            let response = try await dataService.health()
            backendStatusMessage = "\(response.service): \(response.status)"
        } catch {
            backendStatusMessage = "Connection failed: \(error.localizedDescription)"
        }
    }

    func syncFromBackend() async {
        guard backendSettings.mode == .backend else { return }
        guard let dataService = makeBackendDataService() else {
            backendStatusMessage = "Backend URL is invalid."
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
            backendStatusMessage = "Synced from backend."
        } catch {
            backendStatusMessage = "Sync failed: \(error.localizedDescription)"
        }
    }

    func refreshQuota() async {
        guard backendSettings.mode == .backend, let dataService = makeBackendDataService() else { return }
        if let remoteQuota = try? await dataService.quota() {
            quota = remoteQuota
        }
    }

    func updateProStatus(_ isPro: Bool) async {
        if backendSettings.mode == .backend, let dataService = makeBackendDataService() {
            do {
                quota = try await dataService.updateProStatus(isPro: isPro)
                backendStatusMessage = isPro ? "Pro mode enabled." : "Pro mode disabled."
            } catch {
                backendStatusMessage = "Pro update failed: \(error.localizedDescription)"
            }
        } else {
            quota.isPro = isPro
        }
    }

    func configureStoreKitIfNeeded() async {
        guard !didConfigureStoreKit else { return }
        didConfigureStoreKit = true

        await loadSubscriptionProducts()
        await refreshStoreEntitlements(syncBackend: false)
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
                    "No StoreKit products were returned. Check the StoreKit configuration or App Store Connect products.",
                    "没有加载到 StoreKit 商品。请检查本地 StoreKit 配置或 App Store Connect 商品。"
                )
            }
        } catch {
            purchaseStatusMessage = AppText.localized(
                "StoreKit products failed to load: \(error.localizedDescription)",
                "StoreKit 商品加载失败：\(error.localizedDescription)"
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
            brandStatusMessage = AppText.localized("Saved locally. Backend sync failed.", "已保存到本机，后端同步失败。")
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
        if project.draft.language == .english {
            return [
                "Generate a clean commercial social poster background for \(project.draft.platform.displayName).",
                "Product or topic: \(project.draft.topic).",
                "Audience: \(project.draft.audience.isEmpty ? brandProfile.audience : project.draft.audience).",
                "Poster headline meaning: \(poster.headline).",
                "Style: \(poster.style.displayName).",
                "Do not generate any text, logos, watermarks, or QR codes.",
                "Leave clean negative space in the upper or middle area so the app can overlay title and CTA text."
            ].joined(separator: " ")
        }

        return [
            "为\(project.draft.platform.displayName)商业海报生成一张背景图。",
            "产品或主题：\(project.draft.topic)。",
            "目标人群：\(project.draft.audience.isEmpty ? brandProfile.audience : project.draft.audience)。",
            "海报标题含义：\(poster.headline)。",
            "风格：\(poster.style.displayName)。",
            "不要生成任何文字、logo、水印或二维码。",
            "画面中上部或中部保留干净留白，方便 App 叠加标题和按钮。"
        ].joined(separator: " ")
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

    private func persistProjectIfNeeded(_ project: ContentProject) async {
        guard backendSettings.mode == .backend, let dataService = makeBackendDataService() else {
            persistProjectsLocally()
            return
        }
        do {
            if let savedProject = try await dataService.saveProject(project),
               let index = projects.firstIndex(where: { $0.id == savedProject.id }) {
                projects[index] = savedProject
                upsertPosterAsset(for: savedProject)
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
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified:
            throw StoreKitVerificationError.failed
        }
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
}

private enum LocalProjectStore {
    private static let storageKey = "viralforge.localProjects"

    static func load() -> [ContentProject] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let projects = try? JSONDecoder().decode([ContentProject].self, from: data) else {
            return SampleData.projects
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
        AppText.localized("StoreKit transaction could not be verified.", "StoreKit 交易无法通过验证。")
    }
}

private enum BackendAccountToken {
    static func uuid(for userId: String) -> UUID {
        let normalizedUserId = userId.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let stableInput = "com.phil.viralforge.appAccountToken:\(normalizedUserId.isEmpty ? "demo-user" : normalizedUserId)"
        let digest = SHA256.hash(data: Data(stableInput.utf8))
        var bytes = Array(digest.prefix(16))
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
}
