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
            DashboardBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ViralForge")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 0.78, green: 0.89, blue: 0.92)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(AppText.localized("Production dashboard for viral content assets", "爆款内容资产生产台"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                NavigationLink {
                    BrandKitView()
                } label: {
                    Image(systemName: "briefcase.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.14), lineWidth: 1)
                        }
                        .shadow(color: Color(red: 0.10, green: 0.78, blue: 0.82).opacity(0.22), radius: 16, y: 8)
                }
                .accessibilityLabel(AppText.localized("Brand Kit", "品牌资料"))
            }

            quotaPanel
        }
    }

    private var quotaPanel: some View {
        HStack(spacing: 12) {
            quotaMetric(
                title: AppText.localized("Copy left", "文案额度"),
                value: appModel.quota.isPro ? AppText.localized("Unlimited", "不限") : "\(appModel.quota.remainingTextGenerations)",
                icon: "doc.text.fill",
                tint: Color(red: 0.12, green: 0.88, blue: 0.88)
            )

            quotaMetric(
                title: AppText.localized("AI background", "AI 背景"),
                value: appModel.quota.isPro ? AppText.localized("Pro", "会员") : "\(appModel.quota.remainingPosterExports)",
                icon: "sparkles.rectangle.stack.fill",
                tint: Color(red: 0.66, green: 0.44, blue: 0.98)
            )
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }

    private func quotaMetric(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.54))
                Text(value)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private var platformSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(AppText.localized("Target platform", "目标平台"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SocialPlatform.chinaLaunchPlatforms) { platform in
                        Button {
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                                draft.platform = platform
                            }
                        } label: {
                            PlatformPill(
                                platform: platform,
                                isSelected: draft.platform == platform
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var briefCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(AppText.localized("Product brief", "产品或主题简报"))

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 22)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.34), radius: 20, x: 0, y: 12)

                TextEditor(text: $draft.topic)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(16)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)

                if draft.topic.isEmpty {
                    Text(AppText.localized(
                        "Example: a portable blender for office workers, focused on fast breakfast and easy cleaning...",
                        "例如：一款适合上班族的便携榨汁杯，主打快速早餐、好清洗、适合办公室..."
                    ))
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.32))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .allowsHitTesting(false)
                }
            }
            .frame(minHeight: 152)
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.16), .white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }

            if let message = visibleTopicValidationMessage {
                Label(message, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color(red: 1.0, green: 0.62, blue: 0.48))
            }
        }
    }

    private var strategyGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(AppText.localized("Content strategy", "内容策略"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StrategyCard(
                    icon: "target",
                    title: AppText.localized("Goal", "目标"),
                    value: draft.goal.displayName,
                    tint: Color(red: 0.66, green: 0.44, blue: 0.98)
                ) {
                    activeEditor = .goal
                }

                StrategyCard(
                    icon: "person.2.fill",
                    title: AppText.localized("Audience", "目标人群"),
                    value: draft.audience.isEmpty ? AppText.localized("Tap to set", "点击设置") : draft.audience,
                    tint: Color(red: 0.14, green: 0.82, blue: 0.82)
                ) {
                    activeEditor = .audience
                }

                StrategyCard(
                    icon: "quote.bubble.fill",
                    title: AppText.localized("Tone", "语气风格"),
                    value: draft.tone.isEmpty ? AppText.localized("Tap to set", "点击设置") : draft.tone,
                    tint: Color(red: 0.98, green: 0.62, blue: 0.36)
                ) {
                    activeEditor = .tone
                }

                StrategyCard(
                    icon: "brain.head.profile",
                    title: AppText.localized("Brand memory", "品牌记忆"),
                    value: appModel.brandProfile.hasSavedMemory ? appModel.brandProfile.memorySummary : AppText.localized("Not set", "未设置"),
                    tint: Color(red: 0.56, green: 0.82, blue: 0.38)
                ) {
                    activeEditor = .brand
                }
            }
        }
    }

    private var workflowShortcuts: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(AppText.localized("Creation tools", "创作工具"))

            HStack(spacing: 12) {
                NavigationLink {
                    BatchCreateView()
                } label: {
                    WorkflowTile(
                        icon: "square.grid.2x2.fill",
                        title: AppText.localized("Batch", "批量创作"),
                        subtitle: AppText.localized("7/14-day calendar", "7/14 天日历")
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    TemplatesView()
                } label: {
                    WorkflowTile(
                        icon: "rectangle.on.rectangle.fill",
                        title: AppText.localized("Templates", "模板开始"),
                        subtitle: AppText.localized("China-first layouts", "国内平台模板")
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
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.48, green: 0.26, blue: 0.92),
                                Color(red: 0.08, green: 0.76, blue: 0.80),
                                Color(red: 0.14, green: 0.70, blue: 0.42)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.20), lineWidth: 1)
            }
            .shadow(color: Color(red: 0.08, green: 0.76, blue: 0.80).opacity(0.28), radius: 22, y: 10)
            .opacity(canGenerate ? 1 : 0.48)
        }
        .buttonStyle(.plain)
        .disabled(!canGenerate)
    }

    private func errorCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(red: 1.0, green: 0.66, blue: 0.52))

            Button {
                generate()
            } label: {
                Label(AppText.localized("Retry", "重试"), systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
            }
            .disabled(!canGenerate)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.44, green: 0.12, blue: 0.10).opacity(0.34), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(red: 1.0, green: 0.55, blue: 0.42).opacity(0.24), lineWidth: 1)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white.opacity(0.70))
            .textCase(.uppercase)
    }

    private func generate() {
        Task {
            generatedProject = await appModel.generateProject(from: draft)
        }
    }
}

private struct DashboardBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.035, green: 0.038, blue: 0.044),
                    Color(red: 0.055, green: 0.058, blue: 0.072),
                    Color(red: 0.025, green: 0.030, blue: 0.035)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 0.12, green: 0.86, blue: 0.82).opacity(0.20),
                    .clear
                ],
                center: .topLeading,
                startRadius: 60,
                endRadius: 520
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 0.62, green: 0.34, blue: 0.98).opacity(0.16),
                    .clear
                ],
                center: .topTrailing,
                startRadius: 80,
                endRadius: 560
            )
            .ignoresSafeArea()
        }
    }
}

private struct PlatformPill: View {
    let platform: SocialPlatform
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: platformIcon)
                .font(.headline)
            Text(platform.displayName)
                .font(.subheadline.weight(.bold))
        }
        .foregroundStyle(isSelected ? .white : .white.opacity(0.58))
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(isSelected ? .white.opacity(0.14) : .white.opacity(0.055))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(isSelected ? Color(red: 0.12, green: 0.88, blue: 0.88).opacity(0.58) : .white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: isSelected ? Color(red: 0.12, green: 0.88, blue: 0.88).opacity(0.22) : .clear, radius: 14, y: 7)
    }

    private var platformIcon: String {
        switch platform {
        case .xiaohongshu: "book.closed.fill"
        case .douyin: "play.rectangle.fill"
        case .weChat: "message.fill"
        case .tikTok: "music.note"
        case .instagram: "camera.fill"
        case .youtubeShorts: "play.square.stack.fill"
        }
    }
}

private struct StrategyCard: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.headline)
                        .foregroundStyle(tint)
                        .frame(width: 32, height: 32)
                        .background(tint.opacity(0.14), in: Circle())
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.34))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.48))
                    Text(value)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                        .frame(minHeight: 36, alignment: .topLeading)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(.white.opacity(0.09), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct WorkflowTile: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color(red: 0.12, green: 0.88, blue: 0.88))
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.48))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
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
