import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var draft = GenerationDraft()
    @State private var generatedProject: ContentProject?
    @State private var activeEditor: StrategyEditor?
    @State private var pasteStatusMessage: String?
    @State private var appliedWorkflow: AppliedTemplateWorkflow?

    private var canGenerate: Bool {
        !appModel.isGenerating && draft.isReadyToGenerate
    }

    private var visibleTopicValidationMessage: String? {
        draft.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : draft.topicValidationMessage
    }

    private var hasTopic: Bool {
        !draft.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasStrategyContext: Bool {
        hasTopic || appliedWorkflow != nil
    }

    private var launchPlatforms: [SocialPlatform] {
        appModel.launchPlatforms
    }

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                let contentWidth = max(proxy.size.width - 40, 0)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        studioHeader
                        mainCreationCard
                        contentPipelineSection
                        templatePreviewSection
                        brandKitShortcut
                        workflowShortcuts

                        if let generationError = appModel.generationError {
                            errorCard(generationError)
                        }
                    }
                    .frame(width: contentWidth, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 126)
                }
            }
        }
        .background {
            StudioDashboardBackground()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.light)
        .navigationDestination(item: $generatedProject) { project in
            ResultView(project: project)
        }
        .sheet(item: $activeEditor) { editor in
            StrategyEditorSheet(editor: editor, draft: $draft)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .task {
            await appModel.refreshQuota()
            applyPendingTemplateWorkflow()
        }
        .onChange(of: draft) { _, _ in
            appModel.generationError = nil
        }
        .onChange(of: appModel.pendingTemplateWorkflow) { _, _ in
            applyPendingTemplateWorkflow()
        }
    }

    private var studioHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("ViralForge Studio")
                    .font(.system(size: 29, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [VFStudioDesign.primaryRed, VFStudioDesign.sunset, VFStudioDesign.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                HStack(spacing: 7) {
                    Image(systemName: appModel.quota.isPro ? "crown.fill" : "bolt.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStudioDesign.sunset)
                    Text(appModel.quota.isPro ? AppText.localized("Pro creator workspace", "专业版会员工作间") : AppText.localized("Creator workspace", "爆款创作工作间"))
                        .lineLimit(1)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(VFStudioDesign.secondaryText)
            }

            Spacer()

            QuotaRingBadge(
                text: quotaRingText,
                progress: quotaProgress,
                tint: VFStudioDesign.primaryRed
            )
        }
    }

    private var mainCreationCard: some View {
        StudioGlassCard(level: .thick) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    ForEach(launchPlatforms) { platform in
                        Button {
                            Haptics.selection()
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                                draft.platform = platform
                            }
                        } label: {
                            StudioPlatformPill(
                                platform: platform,
                                isActive: draft.platform == platform
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let appliedWorkflow {
                    appliedTemplateCard(appliedWorkflow)
                }

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.white.opacity(0.70))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.black.opacity(0.045), lineWidth: 1)
                        }
                        .shadow(color: .white.opacity(0.72), radius: 8, x: -3, y: -3)
                        .shadow(color: .black.opacity(0.025), radius: 8, x: 3, y: 4)

                    TextEditor(text: $draft.topic)
                        .font(.body.weight(.medium))
                        .foregroundStyle(VFStudioDesign.ink)
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                        .padding(.bottom, 46)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .accessibilityIdentifier("vf.home.topicEditor")

                    if draft.topic.isEmpty {
                        Text(AppText.localized(
                            "Enter your product angle or today's content theme...",
                            "输入你的产品核心点或今日主题..."
                        ))
                        .font(.body.weight(.medium))
                        .foregroundStyle(VFStudioDesign.secondaryText.opacity(0.72))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 22)
                        .allowsHitTesting(false)
                    }

                    VStack {
                        HStack {
                            Spacer()
                            magicPasteButton
                        }
                        Spacer()
                    }
                    .padding(12)

                    HStack {
                        if let pasteStatusMessage {
                            Text(pasteStatusMessage)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(VFStudioDesign.secondaryText)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        Spacer()

                        HStack(spacing: 14) {
                            Image(systemName: "mic.fill")
                            Image(systemName: "photo.on.rectangle")
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStudioDesign.secondaryText.opacity(0.44))
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 15)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .frame(minHeight: 154)

                if let message = visibleTopicValidationMessage {
                    Label(message, systemImage: "exclamationmark.circle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(VFStudioDesign.warning)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 7) {
                        Image(systemName: hasStrategyContext ? "sparkles" : "lightbulb")
                        Text(strategyHintText)
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(hasStrategyContext ? VFStudioDesign.primaryRed : VFStudioDesign.secondaryText)

                    if hasStrategyContext {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            StrategyMiniChip(
                                icon: "paperplane.fill",
                                title: AppText.localized("Platform", "平台"),
                                value: draft.platform.displayName,
                                tint: VFStudioDesign.primaryRed
                            ) {
                                Haptics.selection()
                            }

                            StrategyMiniChip(
                                icon: "person.3.fill",
                                title: AppText.localized("Audience", "受众画像"),
                                value: draft.audience.isEmpty ? AppText.localized("Recommended persona", "智能推荐画像") : draft.audience,
                                tint: VFStudioDesign.electricCyan
                            ) {
                                Haptics.selection()
                                activeEditor = .audience
                            }

                            StrategyMiniChip(
                                icon: "mouth.fill",
                                title: AppText.localized("Tone", "内容语气"),
                                value: draft.tone.isEmpty ? AppText.localized("Professional seeding", "专业种草") : draft.tone,
                                tint: VFStudioDesign.sunset
                            ) {
                                Haptics.selection()
                                activeEditor = .tone
                            }

                            StrategyMiniChip(
                                icon: "paintpalette.fill",
                                title: AppText.localized("Poster style", "海报风格"),
                                value: AppText.localized("Minimal white", "极简白系"),
                                tint: brandAccentColor
                            ) {
                                Haptics.selection()
                                activeEditor = .brand
                            }
                        }
                        .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .top)), removal: .opacity))
                    }
                }
                .animation(.spring(response: 0.36, dampingFraction: 0.86), value: hasStrategyContext)

                generateFAB
                    .padding(.top, 2)
            }
        }
    }

    private var magicPasteButton: some View {
        Button {
            magicPaste()
        } label: {
            Label(AppText.localized("Magic Paste", "智能粘贴"), systemImage: "doc.on.clipboard")
                .labelStyle(.iconOnly)
                .font(.caption.weight(.bold))
                .foregroundStyle(VFStudioDesign.primaryRed)
                .frame(width: 34, height: 34)
                .background(.white.opacity(0.86), in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.96), lineWidth: 1)
                }
                .shadow(color: VFStudioDesign.primaryRed.opacity(0.18), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(AppText.localized("Magic Paste", "智能粘贴"))
    }

    private func appliedTemplateCard(_ workflow: AppliedTemplateWorkflow) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VFGradientIcon(icon: "rectangle.on.rectangle.fill", tint: VFStudioDesign.platformTint(workflow.platform), size: 38)

            VStack(alignment: .leading, spacing: 5) {
                Text(AppText.localized("Template applied", "已套用模板"))
                    .font(.caption.weight(.black))
                    .foregroundStyle(VFStudioDesign.platformTint(workflow.platform))
                Text(workflow.templateName)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(VFStudioDesign.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text("\(workflow.platform.displayName) · \(workflow.category.displayName) · \(workflow.draft.tone)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(VFStudioDesign.secondaryText)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Button {
                Haptics.selection()
                withAnimation(.spring(response: 0.30, dampingFraction: 0.86)) {
                    appliedWorkflow = nil
                    draft = GenerationDraft(language: appModel.launchLanguage, platform: SocialPlatform.defaultPlatform(for: appModel.launchLanguage))
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.black))
                    .foregroundStyle(VFStudioDesign.secondaryText)
                    .frame(width: 30, height: 30)
                    .background(.white.opacity(0.70), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppText.localized("Clear applied template", "清除已套用模板"))
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [VFStudioDesign.platformTint(workflow.platform).opacity(0.12), .white.opacity(0.66)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.84), lineWidth: 1)
        }
        .shadow(color: VFStudioDesign.platformTint(workflow.platform).opacity(0.12), radius: 14, x: 0, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("vf.home.appliedTemplateCard")
    }

    private var templatePreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(
                    title: AppText.localized("Hot templates", "热门创作模板"),
                    subtitle: AppText.localized("Commerce-ready starting points", "电商种草快速起稿")
                )

                Spacer()

                NavigationLink {
                    TemplatesView()
                } label: {
                    Text(AppText.localized("More", "更多"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStudioDesign.primaryRed)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(appModel.visibleTemplates.prefix(4))) { template in
                        NavigationLink {
                            TemplateDetailView(template: template)
                        } label: {
                            HotTemplateCard(template: template)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var contentPipelineSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: AppText.localized("In progress", "正在进行中"),
                subtitle: AppText.localized("Recent drafts and active creation jobs", "最近草稿与当前创作任务")
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    if appModel.isGenerating {
                        PipelineItem(
                            title: draft.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppText.localized("New content pack", "新内容资产包") : draft.topic,
                            status: AppText.localized("Generating copy and poster direction", "正在生成文案与海报方向"),
                            progress: 0.64,
                            tint: VFStudioDesign.accent
                        )
                    }

                    ForEach(Array(appModel.projects.prefix(3))) { project in
                        PipelineItem(
                            title: pipelineTitle(for: project),
                            status: project.hasPosterExport ? AppText.localized("Poster exported", "海报已导出") : AppText.localized("Copy pack ready", "内容包已就绪"),
                            progress: project.hasPosterExport ? 1.0 : 0.76,
                            tint: project.hasPosterExport ? VFStudioDesign.teal : VFStudioDesign.sky
                        )
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var brandKitShortcut: some View {
        NavigationLink {
            BrandKitView()
        } label: {
            StudioGlassCard(level: .thin) {
                HStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(brandAccentColor.opacity(0.18))
                            .frame(width: 46, height: 46)
                            .blur(radius: 12)

                        Circle()
                            .fill(brandAccentColor)
                            .frame(width: 18, height: 18)
                            .shadow(color: brandAccentColor.opacity(0.42), radius: 10, x: 0, y: 4)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(AppText.localized("Brand Memory", "品牌记忆"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(VFStudioDesign.ink)
                        Text(appModel.brandProfile.hasSavedMemory ? appModel.brandProfile.memorySummary : AppText.localized("Set brand colors, audience, tone, and banned claims.", "设置品牌色、人群、语气与禁用表述。"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(VFStudioDesign.secondaryText)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStudioDesign.secondaryText.opacity(0.56))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var workflowShortcuts: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: AppText.localized("Pro Studio tools", "专业工作室工具"),
                subtitle: AppText.localized("Move from one-off assets to repeatable production", "从单次生成进入持续生产")
            )

            HStack(spacing: 14) {
                NavigationLink {
                    BatchCreateView()
                } label: {
                    StudioToolTile(
                        icon: "calendar.badge.plus",
                        title: AppText.localized("Batch", "批量创作"),
                        subtitle: AppText.localized("7/14-day content calendar", "7/14 天内容日历"),
                        tint: VFStudioDesign.teal
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    TemplatesView()
                } label: {
                    StudioToolTile(
                        icon: "rectangle.on.rectangle.fill",
                        title: AppText.localized("Templates", "模板开始"),
                        subtitle: AppText.localized("TikTok, Instagram, Shorts", "国内平台创意格式"),
                        tint: VFStudioDesign.accent
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var generateFAB: some View {
        Button {
            Haptics.impact()
            generate()
        } label: {
            HStack(spacing: 10) {
                if appModel.isGenerating {
                    ProgressView()
                        .tint(canGenerate ? .white : VFStudioDesign.secondaryText)
                } else {
                    Image(systemName: "wand.and.stars")
                        .font(.headline.weight(.bold))
                        .symbolEffect(.pulse, options: .repeating, isActive: appModel.isGenerating)
                }
                Text(appModel.isGenerating ? AppText.localized("Creating...", "正在创作...") : AppText.localized("Start Viral Creation", "开启爆款创作"))
                    .font(.headline.weight(.bold))
            }
            .foregroundStyle(canGenerate ? .white : VFStudioDesign.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 26)
            .padding(.vertical, 16)
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: canGenerate
                                ? [VFStudioDesign.primaryRed, VFStudioDesign.sunset, VFStudioDesign.accent]
                                : [Color.white.opacity(0.72), Color.white.opacity(0.54)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                Capsule()
                    .stroke(canGenerate ? .white.opacity(0.45) : .white.opacity(0.78), lineWidth: 1)
                    .overlay {
                        if canGenerate {
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.0), .white.opacity(0.76), .white.opacity(0.0)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.3
                                )
                                .blur(radius: 0.4)
                        }
                    }
            }
            .shadow(color: VFStudioDesign.primaryRed.opacity(canGenerate ? 0.28 : 0.08), radius: 22, x: 0, y: 11)
            .opacity(canGenerate ? 1 : 0.86)
        }
        .buttonStyle(.plain)
        .disabled(!canGenerate)
        .accessibilityIdentifier("vf.home.generateButton")
    }

    private var quotaRingText: String {
        appModel.quota.isPro ? "Pro" : "\(appModel.quota.remainingTextGenerations)"
    }

    private var quotaProgress: Double {
        if appModel.quota.isPro {
            return 1
        }
        return min(1, max(0.08, Double(appModel.quota.remainingTextGenerations) / 10))
    }

    private var brandAccentColor: Color {
        switch appModel.brandProfile.primaryColorName {
        case "Indigo": VFStudioDesign.accent
        case "Rose": Color(red: 0.95, green: 0.36, blue: 0.52)
        case "Sky": VFStudioDesign.electricCyan
        case "Amber": VFStudioDesign.sunset
        default: VFStudioDesign.electricCyan
        }
    }

    private var strategyHintText: String {
        if appliedWorkflow != nil {
            return AppText.localized("Template strategy is ready", "模板策略已准备")
        }
        return hasTopic
            ? AppText.localized("Strategy suggestions are ready", "智能策略已准备")
            : AppText.localized("Add a topic to unlock strategy suggestions", "输入主题后展开智能策略")
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(VFStudioDesign.ink)
            Text(subtitle)
                .font(.caption.weight(.medium))
                .foregroundStyle(VFStudioDesign.secondaryText)
        }
        .padding(.leading, 4)
    }

    private func pipelineTitle(for project: ContentProject) -> String {
        let topic = project.draft.topic.trimmingCharacters(in: .whitespacesAndNewlines)
        if !topic.isEmpty {
            return topic
        }
        return project.result.titles.first?.text ?? AppText.localized("Untitled content pack", "未命名内容包")
    }

    private func errorCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(VFStudioDesign.warning)

            HStack(spacing: 12) {
                Button {
                    generate()
                } label: {
                    Label(AppText.localized("Retry", "重试"), systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(VFStudioDesign.accent)
                }
                .disabled(!canGenerate)
                .accessibilityIdentifier("vf.home.generationError.retryButton")

                if shouldOfferProRecovery(for: message) {
                    Button {
                        Haptics.selection()
                        appModel.generationError = nil
                        appModel.selectedTab = .pro
                    } label: {
                        Label(AppText.localized("Upgrade Pro", "升级 Pro"), systemImage: "crown.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                LinearGradient(
                                    colors: [VFStudioDesign.primaryRed, VFStudioDesign.sunset],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                            .shadow(color: VFStudioDesign.primaryRed.opacity(0.18), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(AppText.localized("Upgrade Pro", "升级 Pro"))
                    .accessibilityIdentifier("vf.home.generationError.upgradeButton")
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(VFStudioDesign.warning.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.035), radius: 16, x: 0, y: 8)
        .accessibilityIdentifier("vf.home.generationError")
    }

    private func shouldOfferProRecovery(for message: String) -> Bool {
        !appModel.quota.isPro && !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func generate() {
        Task {
            generatedProject = await appModel.generateProject(from: draft)
        }
    }

    private func applyPendingTemplateWorkflow() {
        guard let workflow = appModel.consumeTemplateWorkflow() else { return }
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            draft = workflow.draft
            appliedWorkflow = workflow
        }
        Haptics.success()
        showPasteStatus(AppText.localized("Template preset loaded", "模板参数已载入"))
    }

    private func magicPaste() {
        Haptics.selection()
        let pasted = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !pasted.isEmpty else {
            showPasteStatus(AppText.localized("Clipboard is empty", "剪贴板暂无可用内容"))
            return
        }

        let compacted = pasted
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")

        draft.topic = String(compacted.prefix(240))
        Haptics.success()
        showPasteStatus(AppText.localized("Brief imported from clipboard", "已从剪贴板导入简报"))
    }

    private func showPasteStatus(_ message: String) {
        withAnimation(.easeOut(duration: 0.18)) {
            pasteStatusMessage = message
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeOut(duration: 0.18)) {
                pasteStatusMessage = nil
            }
        }
    }
}

private enum VFStudioDesign {
    static let primaryRed = Color(red: 1.0, green: 0.23, blue: 0.19)
    static let sunset = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let auroraPink = Color(red: 1.0, green: 0.27, blue: 0.57)
    static let purpleFlow = Color(red: 0.69, green: 0.32, blue: 0.87)
    static let electricCyan = Color(red: 0.0, green: 0.76, blue: 0.95)
    static let primaryBlue = Color(red: 0.0, green: 0.48, blue: 1.0)
    static let accent = Color(red: 0.35, green: 0.34, blue: 0.84)
    static let ink = Color(red: 0.13, green: 0.16, blue: 0.22)
    static let graphite = Color(red: 0.30, green: 0.34, blue: 0.42)
    static let secondaryText = Color(red: 0.48, green: 0.53, blue: 0.60)
    static let sky = electricCyan
    static let teal = Color(red: 0.29, green: 0.79, blue: 0.73)
    static let coral = Color(red: 0.95, green: 0.55, blue: 0.38)
    static let warning = Color(red: 0.86, green: 0.34, blue: 0.22)

    static func platformTint(_ platform: SocialPlatform) -> Color {
        switch platform {
        case .xiaohongshu: primaryRed
        case .douyin: purpleFlow
        case .weChat: teal
        case .tikTok: accent
        case .instagram: auroraPink
        case .youtubeShorts: sunset
        }
    }
}

private enum Haptics {
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func impact() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

private struct StudioDashboardBackground: View {
    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation) { timeline in
                let seconds = timeline.date.timeIntervalSinceReferenceDate
                let rotation = Angle.degrees(seconds.truncatingRemainder(dividingBy: 18) * 20)

                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.985, blue: 0.975),
                            Color(red: 0.965, green: 0.978, blue: 1.0),
                            Color(red: 0.995, green: 0.998, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [VFStudioDesign.primaryRed.opacity(0.14), VFStudioDesign.auroraPink.opacity(0.05), .clear],
                                center: .center,
                                startRadius: 12,
                                endRadius: 280
                            )
                        )
                        .frame(width: 560, height: 560)
                        .blur(radius: 54)
                        .offset(x: -220, y: -300)
                        .rotationEffect(rotation)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [VFStudioDesign.sunset.opacity(0.16), VFStudioDesign.primaryRed.opacity(0.05), .clear],
                                center: .center,
                                startRadius: 8,
                                endRadius: 230
                            )
                        )
                        .frame(width: 430, height: 430)
                        .blur(radius: 60)
                        .offset(x: 210, y: -110)
                        .rotationEffect(-rotation)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [VFStudioDesign.electricCyan.opacity(0.13), VFStudioDesign.purpleFlow.opacity(0.06), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 250
                            )
                        )
                        .frame(width: 500, height: 500)
                        .blur(radius: 72)
                        .offset(x: 170, y: 455)
                        .rotationEffect(Angle.degrees(rotation.degrees * 0.6))

                    StudioNoiseOverlay()
                        .opacity(0.30)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
            }
        }
        .ignoresSafeArea()
    }
}

private struct StudioNoiseOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                for index in 0..<150 {
                    let xSeed = Double((index * 37) % 101) / 100
                    let ySeed = Double((index * 53) % 127) / 126
                    let rect = CGRect(
                        x: size.width * xSeed,
                        y: size.height * ySeed,
                        width: 1,
                        height: 1
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(index.isMultiple(of: 3) ? 0.34 : 0.18)))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

private struct StudioGlassCard<Content: View>: View {
    enum Level {
        case thin
        case thick
    }

    let level: Level
    let content: Content

    init(level: Level = .thin, @ViewBuilder content: () -> Content) {
        self.level = level
        self.content = content()
    }

    var body: some View {
        content
            .padding(level == .thick ? 20 : 17)
            .background(.white.opacity(level == .thick ? 0.82 : 0.68), in: RoundedRectangle(cornerRadius: 28))
            .background(level == .thick ? .thinMaterial : .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(level == .thick ? 0.92 : 0.80), lineWidth: 1.2)
            }
            .shadow(color: .white.opacity(0.72), radius: 14, x: -4, y: -6)
            .shadow(color: .black.opacity(level == .thick ? 0.04 : 0.026), radius: level == .thick ? 24 : 18, x: 0, y: level == .thick ? 12 : 8)
    }
}

private struct QuotaRingBadge: View {
    let text: String
    let progress: Double
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.055), lineWidth: 3.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tint, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(text)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(VFStudioDesign.ink)
                .minimumScaleFactor(0.72)
        }
        .frame(width: 42, height: 42)
        .background(.white.opacity(0.56), in: Circle())
        .overlay {
            Circle()
                .stroke(.white.opacity(0.82), lineWidth: 1)
        }
        .shadow(color: tint.opacity(0.16), radius: 12, x: 0, y: 7)
    }
}

private struct StudioPlatformPill: View {
    let platform: SocialPlatform
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
            Text(platform.displayName)
                .font(.system(size: 12, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(isActive ? .white : VFStudioDesign.ink)
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background {
            Capsule()
                .fill(
                    isActive
                        ? LinearGradient(colors: [tint, tint.opacity(0.78)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [.white.opacity(0.74), .white.opacity(0.48)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        }
        .overlay {
            Capsule()
                .stroke(isActive ? .white.opacity(0.34) : .white.opacity(0.74), lineWidth: 1)
        }
        .shadow(color: isActive ? tint.opacity(0.26) : .black.opacity(0.025), radius: isActive ? 10 : 5, x: 0, y: isActive ? 6 : 3)
    }

    private var tint: Color {
        VFStudioDesign.platformTint(platform)
    }

    private var icon: String {
        switch platform {
        case .xiaohongshu: "camera.fill"
        case .douyin: "video.fill"
        case .weChat: "bubble.left.fill"
        case .tikTok: "music.note"
        case .instagram: "camera.fill"
        case .youtubeShorts: "play.square.stack.fill"
        }
    }
}

private struct StrategyMiniChip: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        LinearGradient(colors: [tint.opacity(0.95), tint.opacity(0.68)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Circle()
                    )
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.54), lineWidth: 1)
                    }
                    .shadow(color: tint.opacity(0.28), radius: 8, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(VFStudioDesign.secondaryText)
                    Text(value)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStudioDesign.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }

                Spacer(minLength: 0)
            }
            .padding(11)
            .background(
                LinearGradient(
                    colors: [tint.opacity(0.10), .white.opacity(0.64)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.72), lineWidth: 1)
            }
            .shadow(color: tint.opacity(0.06), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

private struct PipelineItem: View {
    let title: String
    let status: String
    let progress: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(VFStudioDesign.ink)
                        .lineLimit(2)
                        .frame(minHeight: 34, alignment: .topLeading)

                    Text(status)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VFStudioDesign.secondaryText)
                        .lineLimit(1)
                }

                Spacer()

                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)
                    .shadow(color: tint.opacity(0.38), radius: 7, x: 0, y: 3)
            }

            ProgressView(value: progress)
                .tint(tint)
                .scaleEffect(x: 1, y: 0.55, anchor: .center)
        }
        .frame(width: 172)
        .padding(15)
        .background(.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 19))
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 19))
        .overlay {
            RoundedRectangle(cornerRadius: 19)
                .stroke(.white.opacity(0.85), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.03), radius: 14, x: 0, y: 8)
    }
}

private struct HotTemplateCard: View {
    let template: CreativeTemplate

    private var tint: Color {
        VFStudioDesign.platformTint(template.platform)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                TemplatePosterPreview(template: template)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                if template.lockedToPro {
                    Image(systemName: "crown.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStudioDesign.sunset)
                        .frame(width: 25, height: 25)
                        .background(.white.opacity(0.88), in: Circle())
                        .padding(9)
                }
            }
            .frame(height: 112)
            .shadow(color: tint.opacity(0.18), radius: 14, x: 0, y: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(VFStudioDesign.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(template.promptHint)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(VFStudioDesign.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .frame(width: 154)
        .background(.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 22))
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.86), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.035), radius: 16, x: 0, y: 8)
    }
}

private struct StudioToolTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(
                    LinearGradient(colors: [tint.opacity(0.96), tint.opacity(0.66)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 13)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(.white.opacity(0.42), lineWidth: 1)
                }
                .shadow(color: tint.opacity(0.28), radius: 10, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(VFStudioDesign.ink)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(VFStudioDesign.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [tint.opacity(0.09), .white.opacity(0.60)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 21)
        )
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 21))
        .overlay {
            RoundedRectangle(cornerRadius: 21)
                .stroke(.white.opacity(0.82), lineWidth: 1.1)
        }
        .shadow(color: .black.opacity(0.03), radius: 14, x: 0, y: 8)
    }
}

private enum StrategyEditor: String, Identifiable {
    case goal
    case audience
    case tone
    case brand

    var id: String { rawValue }
}

private struct StrategyEditorSheet: View {
    let editor: StrategyEditor
    @Binding var draft: GenerationDraft
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                switch editor {
                case .goal:
                    ForEach(ContentGoal.allCases) { goal in
                        Button {
                            draft.goal = goal
                            dismiss()
                        } label: {
                            HStack {
                                Text(goal.displayName)
                                Spacer()
                                if draft.goal == goal {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                case .audience:
                    Section(AppText.localized("Audience", "目标人群")) {
                        TextField(AppText.localized("Example: office workers aged 25-35", "例如：25-35 岁上班族女性"), text: $draft.audience, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                    }
                case .tone:
                    Section(AppText.localized("Tone", "语气风格")) {
                        TextField(AppText.localized("Example: authentic, persuasive, not exaggerated", "例如：真实、种草、不夸张"), text: $draft.tone, axis: .vertical)
                            .lineLimit(3, reservesSpace: true)
                    }
                case .brand:
                    Section {
                        Text(AppText.localized(
                            "Brand memory is managed in the Brand tab and automatically applied during generation.",
                            "品牌记忆在「品牌」页管理，生成时会自动套用。"
                        ))
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(editorTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppText.localized("Done", "完成")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var editorTitle: String {
        switch editor {
        case .goal: AppText.localized("Goal", "目标")
        case .audience: AppText.localized("Audience", "目标人群")
        case .tone: AppText.localized("Tone", "语气风格")
        case .brand: AppText.localized("Brand memory", "品牌记忆")
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(AppModel())
    }
}
