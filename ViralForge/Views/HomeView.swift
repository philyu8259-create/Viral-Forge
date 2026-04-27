import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var draft = GenerationDraft()
    @State private var generatedProject: ContentProject?
    @State private var activeEditor: StrategyEditor?

    private var canGenerate: Bool {
        !appModel.isGenerating && draft.isReadyToGenerate
    }

    private var visibleTopicValidationMessage: String? {
        draft.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : draft.topicValidationMessage
    }

    var body: some View {
        ZStack {
            StudioDashboardBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    studioHeader
                    mainCreationCard
                    contentPipelineSection
                    brandKitShortcut
                    workflowShortcuts

                    if let generationError = appModel.generationError {
                        errorCard(generationError)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 126)
            }
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
        }
        .onChange(of: draft) { _, _ in
            appModel.generationError = nil
        }
    }

    private var studioHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("ViralForge Studio")
                    .font(.system(size: 29, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [VFStudioDesign.accent, VFStudioDesign.ink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                HStack(spacing: 7) {
                    Image(systemName: appModel.brandProfile.hasSavedMemory ? "link" : "link.badge.plus")
                        .font(.caption.weight(.bold))
                    Text(appModel.brandProfile.hasSavedMemory ? appModel.brandProfile.memorySummary : AppText.localized("Connect a brand memory", "连接品牌记忆"))
                        .lineLimit(1)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(VFStudioDesign.secondaryText)
            }

            Spacer()

            QuotaRingBadge(
                text: quotaRingText,
                progress: quotaProgress,
                tint: VFStudioDesign.accent
            )
        }
    }

    private var mainCreationCard: some View {
        StudioGlassCard(level: .thick) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    ForEach(SocialPlatform.chinaLaunchPlatforms) { platform in
                        Button {
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

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.white.opacity(0.46))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.black.opacity(0.045), lineWidth: 1)
                        }
                        .shadow(color: .white.opacity(0.72), radius: 8, x: -3, y: -3)
                        .shadow(color: .black.opacity(0.025), radius: 8, x: 3, y: 4)

                    TextEditor(text: $draft.topic)
                        .font(.body.weight(.medium))
                        .foregroundStyle(VFStudioDesign.ink)
                        .padding(14)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)

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
                }
                .frame(minHeight: 126)

                if let message = visibleTopicValidationMessage {
                    Label(message, systemImage: "exclamationmark.circle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(VFStudioDesign.warning)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    StrategyMiniChip(
                        icon: "target",
                        title: AppText.localized("Goal", "目标"),
                        value: draft.goal.displayName,
                        tint: VFStudioDesign.accent
                    ) {
                        activeEditor = .goal
                    }

                    StrategyMiniChip(
                        icon: "person.2.fill",
                        title: AppText.localized("Audience", "人群"),
                        value: draft.audience.isEmpty ? AppText.localized("Tap to set", "点击设置") : draft.audience,
                        tint: VFStudioDesign.teal
                    ) {
                        activeEditor = .audience
                    }

                    StrategyMiniChip(
                        icon: "quote.bubble.fill",
                        title: AppText.localized("Tone", "语气"),
                        value: draft.tone.isEmpty ? AppText.localized("Not set", "未设置") : draft.tone,
                        tint: VFStudioDesign.coral
                    ) {
                        activeEditor = .tone
                    }

                    StrategyMiniChip(
                        icon: "building.2.fill",
                        title: AppText.localized("Brand", "品牌"),
                        value: appModel.brandProfile.hasSavedMemory ? appModel.brandProfile.memorySummary : AppText.localized("Not set", "未设置"),
                        tint: brandAccentColor
                    ) {
                        activeEditor = .brand
                    }
                }

                generateFAB
                    .padding(.top, 2)
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
                title: AppText.localized("Studio tools", "工作室工具"),
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
                        subtitle: AppText.localized("China-first creative formats", "国内平台创意格式"),
                        tint: VFStudioDesign.accent
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var generateFAB: some View {
        Button {
            generate()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: appModel.isGenerating ? "sparkles" : "sparkles")
                    .font(.headline.weight(.bold))
                    .symbolEffect(.pulse, options: .repeating, isActive: appModel.isGenerating)
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
                                ? [VFStudioDesign.accent, VFStudioDesign.sky]
                                : [Color.white.opacity(0.72), Color.white.opacity(0.54)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                Capsule()
                    .stroke(canGenerate ? .white.opacity(0.45) : .white.opacity(0.78), lineWidth: 1)
            }
            .shadow(color: VFStudioDesign.accent.opacity(0.30), radius: 18, x: 0, y: 11)
            .opacity(canGenerate ? 1 : 0.86)
        }
        .buttonStyle(.plain)
        .disabled(!canGenerate)
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
        case "Sky": VFStudioDesign.sky
        case "Amber": Color(red: 0.95, green: 0.64, blue: 0.23)
        default: VFStudioDesign.teal
        }
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

            Button {
                generate()
            } label: {
                Label(AppText.localized("Retry", "重试"), systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(VFStudioDesign.accent)
            }
            .disabled(!canGenerate)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(VFStudioDesign.warning.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.035), radius: 16, x: 0, y: 8)
    }

    private func generate() {
        Task {
            generatedProject = await appModel.generateProject(from: draft)
        }
    }
}

private enum VFStudioDesign {
    static let accent = Color(red: 0.37, green: 0.36, blue: 0.90)
    static let ink = Color(red: 0.13, green: 0.16, blue: 0.22)
    static let graphite = Color(red: 0.30, green: 0.34, blue: 0.42)
    static let secondaryText = Color(red: 0.48, green: 0.53, blue: 0.60)
    static let sky = Color(red: 0.38, green: 0.70, blue: 0.93)
    static let teal = Color(red: 0.29, green: 0.79, blue: 0.73)
    static let coral = Color(red: 0.95, green: 0.55, blue: 0.38)
    static let warning = Color(red: 0.86, green: 0.34, blue: 0.22)
}

private struct StudioDashboardBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.975, green: 0.985, blue: 1.0),
                    Color(red: 0.90, green: 0.93, blue: 1.0),
                    .white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(VFStudioDesign.sky.opacity(0.18))
                .frame(width: 330, height: 330)
                .blur(radius: 64)
                .offset(x: 170, y: -220)

            Circle()
                .fill(VFStudioDesign.accent.opacity(0.11))
                .frame(width: 250, height: 250)
                .blur(radius: 58)
                .offset(x: -170, y: 110)

            Circle()
                .fill(VFStudioDesign.teal.opacity(0.12))
                .frame(width: 270, height: 270)
                .blur(radius: 74)
                .offset(x: 160, y: 440)

            StudioNoiseOverlay()
                .opacity(0.28)
                .ignoresSafeArea()
        }
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
            .background(.white.opacity(level == .thick ? 0.62 : 0.44), in: RoundedRectangle(cornerRadius: 24))
            .background(level == .thick ? .thinMaterial : .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(level == .thick ? 0.74 : 0.58), lineWidth: 1.4)
            }
            .shadow(color: .white.opacity(0.58), radius: 12, x: -4, y: -5)
            .shadow(color: .black.opacity(level == .thick ? 0.045 : 0.03), radius: level == .thick ? 22 : 16, x: 0, y: level == .thick ? 12 : 8)
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
        .background(isActive ? VFStudioDesign.accent : .white.opacity(0.52), in: Capsule())
        .overlay {
            Capsule()
                .stroke(isActive ? .white.opacity(0.34) : .white.opacity(0.74), lineWidth: 1)
        }
        .shadow(color: isActive ? VFStudioDesign.accent.opacity(0.23) : .black.opacity(0.025), radius: isActive ? 10 : 5, x: 0, y: isActive ? 6 : 3)
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
                    .foregroundStyle(tint)
                    .frame(width: 26, height: 26)
                    .background(tint.opacity(0.11), in: Circle())

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
            .background(.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.72), lineWidth: 1)
            }
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
                .background(tint, in: RoundedRectangle(cornerRadius: 13))
                .shadow(color: tint.opacity(0.24), radius: 9, x: 0, y: 5)

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
        .background(.white.opacity(0.54), in: RoundedRectangle(cornerRadius: 21))
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
