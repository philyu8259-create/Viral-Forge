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
            BrightDashboardBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    headerSection
                    quotaSection
                    platformSelector
                    briefCard
                    strategyGrid
                    workflowShortcuts

                    if let generationError = appModel.generationError {
                        errorCard(generationError)
                    }

                    generateButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 120)
            }
        }
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

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 7) {
                Text("ViralForge")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BrightPalette.graphite, BrightPalette.ink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(AppText.localized("Production dashboard for viral content assets", "爆款内容资产生产平台"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BrightPalette.secondaryText)
            }

            Spacer()

            NavigationLink {
                BrandKitView()
            } label: {
                Image(systemName: "briefcase.fill")
                    .font(.headline)
                    .foregroundStyle(BrightPalette.sky)
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(0.74), in: Circle())
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.92), lineWidth: 1.4)
                    }
                    .shadow(color: BrightPalette.sky.opacity(0.18), radius: 18, x: 0, y: 10)
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            }
            .accessibilityLabel(AppText.localized("Brand Kit", "品牌资料"))
        }
    }

    private var quotaSection: some View {
        HStack(spacing: 14) {
            QuotaGlassCard(
                title: AppText.localized("Copy left", "文案额度"),
                value: appModel.quota.isPro ? AppText.localized("Unlimited", "不限") : "\(appModel.quota.remainingTextGenerations)",
                icon: "doc.text.fill",
                color: BrightPalette.teal
            )

            QuotaGlassCard(
                title: AppText.localized("AI background", "AI 背景"),
                value: appModel.quota.isPro ? AppText.localized("Pro", "会员") : "\(appModel.quota.remainingPosterExports)",
                icon: "sparkles",
                color: BrightPalette.lavender
            )
        }
    }

    private var platformSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(AppText.localized("Target platform", "目标平台"))

            HStack(spacing: 12) {
                ForEach(SocialPlatform.chinaLaunchPlatforms) { platform in
                    Button {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                            draft.platform = platform
                        }
                    } label: {
                        PlatformButton(
                            platform: platform,
                            isSelected: draft.platform == platform
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var briefCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(AppText.localized("Product brief", "产品或主题简报"))

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(0.42))
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.035), radius: 18, x: 0, y: 12)
                    .shadow(color: BrightPalette.sky.opacity(0.06), radius: 28, x: 0, y: 10)

                TextEditor(text: $draft.topic)
                    .font(.body.weight(.medium))
                    .foregroundStyle(BrightPalette.ink)
                    .padding(18)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)

                if draft.topic.isEmpty {
                    Text(AppText.localized(
                        "Example: a portable blender for office workers, focused on fast breakfast and easy cleaning...",
                        "例如：一款适合上班族的便携榨汁杯，主打快速早餐、好清洗、适合办公室..."
                    ))
                    .font(.body.weight(.medium))
                    .foregroundStyle(BrightPalette.secondaryText.opacity(0.74))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 26)
                    .allowsHitTesting(false)
                }
            }
            .frame(minHeight: 176)
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.88), lineWidth: 1.5)
            }

            if let message = visibleTopicValidationMessage {
                Label(message, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BrightPalette.warning)
            }
        }
    }

    private var strategyGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(AppText.localized("Content strategy", "内容策略"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                StrategyGlassCard(
                    icon: "target",
                    title: AppText.localized("Goal", "目标"),
                    value: draft.goal.displayName,
                    tint: BrightPalette.sky
                ) {
                    activeEditor = .goal
                }

                StrategyGlassCard(
                    icon: "person.2.fill",
                    title: AppText.localized("Audience", "目标人群"),
                    value: draft.audience.isEmpty ? AppText.localized("Tap to set", "点击设置") : draft.audience,
                    tint: BrightPalette.teal
                ) {
                    activeEditor = .audience
                }

                StrategyGlassCard(
                    icon: "quote.bubble.fill",
                    title: AppText.localized("Tone", "语气风格"),
                    value: draft.tone.isEmpty ? AppText.localized("Not set", "未设置") : draft.tone,
                    tint: BrightPalette.coral
                ) {
                    activeEditor = .tone
                }

                StrategyGlassCard(
                    icon: "building.2.fill",
                    title: AppText.localized("Brand memory", "品牌背景"),
                    value: appModel.brandProfile.hasSavedMemory ? appModel.brandProfile.memorySummary : AppText.localized("Not set", "未设置"),
                    tint: BrightPalette.lavender
                ) {
                    activeEditor = .brand
                }
            }
        }
    }

    private var workflowShortcuts: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(AppText.localized("Creation tools", "创作工具"))

            HStack(spacing: 14) {
                NavigationLink {
                    BatchCreateView()
                } label: {
                    WorkflowGlassTile(
                        icon: "square.grid.2x2.fill",
                        title: AppText.localized("Batch", "批量创作"),
                        subtitle: AppText.localized("7/14-day calendar", "7/14 天日历"),
                        tint: BrightPalette.teal
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    TemplatesView()
                } label: {
                    WorkflowGlassTile(
                        icon: "rectangle.on.rectangle.fill",
                        title: AppText.localized("Templates", "模板开始"),
                        subtitle: AppText.localized("China-first layouts", "国内平台模板"),
                        tint: BrightPalette.sky
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var generateButton: some View {
        Button {
            generate()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: appModel.isGenerating ? "sparkles" : "wand.and.stars")
                    .symbolEffect(.pulse, options: .repeating, isActive: appModel.isGenerating)
                Text(appModel.isGenerating ? AppText.localized("Generating asset pack...", "正在生成内容资产...") : AppText.localized("Generate content pack", "立即生成内容方案"))
                    .fontWeight(.bold)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background {
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [BrightPalette.aqua, BrightPalette.sky, BrightPalette.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(.white.opacity(0.52), lineWidth: 1.2)
            }
            .shadow(color: BrightPalette.sky.opacity(0.34), radius: 18, x: 0, y: 10)
            .opacity(canGenerate ? 1 : 0.46)
        }
        .buttonStyle(.plain)
        .disabled(!canGenerate)
    }

    private func errorCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(BrightPalette.warning)

            Button {
                generate()
            } label: {
                Label(AppText.localized("Retry", "重试"), systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(BrightPalette.sky)
            }
            .disabled(!canGenerate)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(BrightPalette.warning.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.035), radius: 16, x: 0, y: 8)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(BrightPalette.ink)
    }

    private func generate() {
        Task {
            generatedProject = await appModel.generateProject(from: draft)
        }
    }
}

private enum BrightPalette {
    static let ink = Color(red: 0.17, green: 0.22, blue: 0.28)
    static let graphite = Color(red: 0.29, green: 0.34, blue: 0.41)
    static let secondaryText = Color(red: 0.47, green: 0.53, blue: 0.60)
    static let sky = Color(red: 0.39, green: 0.70, blue: 0.93)
    static let aqua = Color(red: 0.50, green: 0.84, blue: 0.91)
    static let teal = Color(red: 0.31, green: 0.82, blue: 0.77)
    static let lavender = Color(red: 0.72, green: 0.58, blue: 0.96)
    static let coral = Color(red: 0.96, green: 0.58, blue: 0.40)
    static let warning = Color(red: 0.86, green: 0.34, blue: 0.22)
}

private struct BrightDashboardBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .white,
                    Color(red: 0.96, green: 0.985, blue: 1.0),
                    Color(red: 0.93, green: 0.965, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 0.86, green: 0.96, blue: 1.0),
                    .white.opacity(0.0)
                ],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 620
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(red: 0.88, green: 0.91, blue: 1.0).opacity(0.62))
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: -210, y: 90)

            Circle()
                .fill(Color(red: 0.78, green: 0.96, blue: 0.95).opacity(0.36))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 160, y: 380)
        }
    }
}

private struct QuotaGlassCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.86), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(BrightPalette.secondaryText)
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(BrightPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 18))
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.92), lineWidth: 1.2)
        }
        .shadow(color: .black.opacity(0.035), radius: 16, x: 0, y: 10)
    }
}

private struct PlatformButton: View {
    let platform: SocialPlatform
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: platformIcon)
                .font(.subheadline.weight(.bold))
            Text(platform.displayName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .foregroundStyle(isSelected ? Color(red: 0.17, green: 0.42, blue: 0.69) : BrightPalette.secondaryText)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color(red: 0.92, green: 0.975, blue: 1.0) : .white.opacity(0.54), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? BrightPalette.sky.opacity(0.58) : .white.opacity(0.88), lineWidth: 1.4)
        }
        .shadow(color: isSelected ? BrightPalette.sky.opacity(0.16) : .black.opacity(0.025), radius: isSelected ? 14 : 8, x: 0, y: isSelected ? 8 : 4)
    }

    private var platformIcon: String {
        switch platform {
        case .xiaohongshu: "book.closed.fill"
        case .douyin: "play.rectangle.fill"
        case .weChat: "bubble.left.fill"
        case .tikTok: "music.note"
        case .instagram: "camera.fill"
        case .youtubeShorts: "play.square.stack.fill"
        }
    }
}

private struct StrategyGlassCard: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: icon)
                        .font(.headline)
                        .foregroundStyle(tint)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(BrightPalette.secondaryText.opacity(0.52))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(BrightPalette.secondaryText)
                    Text(value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BrightPalette.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.80)
                        .frame(minHeight: 38, alignment: .topLeading)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.52), in: RoundedRectangle(cornerRadius: 20))
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.88), lineWidth: 1.2)
            }
            .shadow(color: .black.opacity(0.03), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

private struct WorkflowGlassTile: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.88), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(BrightPalette.ink)
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(BrightPalette.secondaryText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.56), in: RoundedRectangle(cornerRadius: 20))
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.88), lineWidth: 1.2)
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
