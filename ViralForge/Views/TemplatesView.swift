import SwiftUI

struct TemplatesView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedCategory: TemplateCategory = .productSeeding

    private var filteredTemplates: [CreativeTemplate] {
        appModel.visibleTemplates.filter { $0.category == selectedCategory }
    }

    var body: some View {
        VFPage {
            VFPageHeader(
                title: AppText.localized("Templates", "模板"),
                subtitle: AppText.localized("Ready-made workflows for repeatable content production", "可复用的内容生产工作流"),
                icon: "rectangle.on.rectangle.fill",
                tint: VFStyle.purpleFlow
            )

            categoryStrip

            VStack(alignment: .leading, spacing: 14) {
                VFSectionHeader(
                    title: AppText.localized("Template Library", "模板库"),
                    subtitle: AppText.localized("Pick a template, fill the product, and generate a structured pack", "选择模板，填入产品，一键生成结构化内容包")
                )

                LazyVStack(spacing: 14) {
                    ForEach(filteredTemplates) { template in
                        NavigationLink {
                            TemplateDetailView(template: template)
                        } label: {
                            TemplateCard(template: template)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("vf.templateCard.\(template.name)")
                    }
                }
            }

            VFGlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label(AppText.localized("Viral Template Studio", "爆款模板工作台"), systemImage: "sparkles.rectangle.stack")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(VFStyle.ink)

                    VStack(spacing: 12) {
                        moduleRow(AppText.localized("Six monetization-focused template modules", "六类变现导向模板模块"), icon: "rectangle.3.group", tint: VFStyle.primaryRed)
                        moduleRow(AppText.localized("Built-in audience, tone, and content structure", "内置人群、语气和内容结构"), icon: "list.bullet.rectangle", tint: VFStyle.electricCyan)
                        moduleRow(AppText.localized("One template can produce copy, poster or image direction, and publish pack", "一个模板同时产出文案、海报/图片方向和发布包"), icon: "sparkles", tint: VFStyle.sunset)
                        moduleRow(AppText.localized("Visual templates open directly into AI background and poster editing", "视觉模板可直接进入 AI 背景和海报编辑"), icon: "photo.on.rectangle.angled", tint: VFStyle.purpleFlow)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await appModel.refreshTemplatesIfNeeded()
        }
    }

    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TemplateCategory.allCases) { category in
                    Button {
                        withAnimation(.snappy) {
                            selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: categoryIcon(category))
                            Text(category.displayName)
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(selectedCategory == category ? .white : VFStyle.ink)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 9)
                        .background {
                            Capsule()
                                .fill(selectedCategory == category ? VFStyle.templateTint(category) : .white.opacity(0.68))
                        }
                        .overlay {
                            Capsule()
                                .stroke(.white.opacity(0.78), lineWidth: 1)
                        }
                        .shadow(color: VFStyle.templateTint(category).opacity(selectedCategory == category ? 0.22 : 0.04), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func moduleRow(_ text: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            VFGradientIcon(icon: icon, tint: tint, size: 34)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(VFStyle.ink)
            Spacer()
        }
    }

    private func categoryIcon(_ category: TemplateCategory) -> String {
        switch category {
        case .productSeeding: "shippingbox.fill"
        case .storeTraffic: "mappin.and.ellipse"
        case .personalBrand: "person.crop.square.filled.and.at.rectangle"
        case .liveLaunch: "dot.radiowaves.left.and.right"
        case .seasonalPromo: "gift.fill"
        case .newLaunch: "sparkles.rectangle.stack.fill"
        }
    }
}

private struct TemplateCard: View {
    let template: CreativeTemplate

    private var tint: Color {
        VFStyle.platformTint(template.platform)
    }

    var body: some View {
        VFGlassCard(level: .thin) {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    PosterPreview(
                        poster: PosterDraft(
                            headline: template.name,
                            subtitle: template.platform.displayName,
                            cta: template.category.displayName,
                            style: template.style
                        ),
                        platform: template.platform
                    )
                    .frame(width: 86, height: 116)
                    .clipShape(RoundedRectangle(cornerRadius: 17))
                    .shadow(color: tint.opacity(0.16), radius: 12, x: 0, y: 7)

                    if template.lockedToPro {
                        Image(systemName: "crown.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(VFStyle.sunset)
                            .frame(width: 23, height: 23)
                            .background(.white.opacity(0.90), in: Circle())
                            .offset(x: 5, y: -5)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 7) {
                        Text(template.platform.displayName)
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(tint, in: Capsule())
                        Text(template.category.displayName)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(VFStyle.secondaryText)
                    }

                    Text(template.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(VFStyle.ink)
                        .lineLimit(2)

                    Text(template.promptHint)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        ForEach(template.outputBadges.prefix(3), id: \.self) { item in
                            Text(item)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(tint)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(tint.opacity(0.10), in: Capsule())
                        }
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(VFStyle.secondaryText.opacity(0.55))
            }
        }
    }
}

struct TemplateDetailView: View {
    @Environment(AppModel.self) private var appModel
    let template: CreativeTemplate

    @State private var draft: GenerationDraft
    @State private var generatedProject: ContentProject?

    private var canGenerate: Bool {
        !appModel.isGenerating && draft.isReadyToGenerate
    }

    private var visibleTopicValidationMessage: String? {
        draft.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : draft.topicValidationMessage
    }

    init(template: CreativeTemplate) {
        self.template = template
        _draft = State(initialValue: GenerationDraft(platform: template.platform, goal: template.category.defaultGoal, audience: template.defaultAudience, tone: template.defaultTone, templateName: template.name, templatePromptHint: template.promptHint, templateStyle: template.style))
    }

    private var samplePoster: PosterDraft {
        PosterDraft(
            headline: template.category == .newLaunch
                ? AppText.localized("New angle, clear demand", "新品亮点，一眼种草")
                : AppText.localized("Make it worth stopping for", "让用户愿意停下来"),
            subtitle: template.name,
            cta: template.platform.displayName,
            style: template.style
        )
    }

    var body: some View {
        VFPage {
            VFPageHeader(
                title: AppText.localized("Template", "模板"),
                subtitle: template.name,
                icon: "rectangle.on.rectangle.fill",
                tint: VFStyle.platformTint(template.platform)
            )

            PosterPreview(poster: samplePoster, platform: template.platform)
                .frame(height: 500)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: VFStyle.platformTint(template.platform).opacity(0.14), radius: 20, x: 0, y: 12)

            VFGlassCard(level: .thick) {
                VStack(alignment: .leading, spacing: 15) {
                    Label(template.lockedToPro ? AppText.localized("Pro template", "会员模板") : AppText.localized("Free template", "免费模板"), systemImage: template.lockedToPro ? "crown.fill" : "checkmark.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(template.lockedToPro ? VFStyle.sunset : VFStyle.teal)

                    Text(template.name)
                        .font(.title3.weight(.black))
                        .foregroundStyle(VFStyle.ink)
                    Text(template.promptHint)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)

                    VStack(spacing: 12) {
                        detailInfoRow(
                            title: AppText.localized("Best for", "适合人群"),
                            value: template.defaultAudience,
                            icon: "person.2.fill",
                            tint: VFStyle.electricCyan
                        )
                        detailInfoRow(
                            title: AppText.localized("Tone", "语气"),
                            value: template.defaultTone,
                            icon: "quote.bubble.fill",
                            tint: VFStyle.sunset
                        )
                    }

                    structureCard

                    VStack(spacing: 12) {
                        glassTextField(AppText.localized("Topic or product", "主题或产品"), text: $draft.topic, lines: 3)
                        glassTextField(AppText.localized("Audience", "目标人群"), text: $draft.audience, lines: 1)
                        glassTextField(AppText.localized("Tone", "语气风格"), text: $draft.tone, lines: 1)
                    }

                    if appModel.brandProfile.hasSavedMemory {
                        Label(appModel.brandProfile.memorySummary, systemImage: "brain")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(VFStyle.secondaryText)
                    }
                    if let message = visibleTopicValidationMessage {
                        Label(message, systemImage: "exclamationmark.circle")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(VFStyle.warning)
                    }

                    Button {
                        appModel.applyTemplateToStudio(template, draft: draft)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.pencil")
                                .font(.headline.weight(.bold))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(AppText.localized("Apply to Studio", "套用到创作台"))
                                    .font(.headline.weight(.bold))
                                Text(AppText.localized("Fill the product brief on the Create page", "回到创作页补产品主题"))
                                    .font(.caption.weight(.semibold))
                                    .opacity(0.78)
                            }
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title3.weight(.bold))
                        }
                        .foregroundStyle(VFStyle.ink)
                        .padding(15)
                        .background(.white.opacity(0.66), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(.white.opacity(0.86), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("vf.templateDetail.applyToStudioButton")

                    VFPrimaryButton(
                        title: appModel.isGenerating ? AppText.localized("Generating...", "生成中...") : AppText.localized("Use Template", "使用模板"),
                        icon: "wand.and.stars",
                        isLoading: appModel.isGenerating,
                        isEnabled: canGenerate
                    ) {
                        generate()
                    }
                    .accessibilityIdentifier("vf.templateDetail.useTemplateButton")

                    if let generationError = appModel.generationError {
                        templateErrorCard(generationError)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $generatedProject) { project in
            ResultView(project: project)
        }
        .onChange(of: draft) { _, _ in
            appModel.generationError = nil
        }
    }

    private var structureCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VFSectionHeader(
                title: AppText.localized("Output Structure", "内容结构"),
                subtitle: template.sampleOutcome
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Array(template.contentStructure.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 8) {
                        Text("\(index + 1)")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(VFStyle.templateTint(template.category), in: Circle())
                        Text(item)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(VFStyle.ink)
                            .lineLimit(2)
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .background(.white.opacity(0.60), in: RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(.white.opacity(0.84), lineWidth: 1)
                    }
                }
            }
        }
        .padding(14)
        .background(VFStyle.templateTint(template.category).opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.70), lineWidth: 1)
        }
    }

    private func detailInfoRow(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 11) {
            VFGradientIcon(icon: icon, tint: tint, size: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(VFStyle.secondaryText)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(VFStyle.ink)
            }
            Spacer(minLength: 0)
        }
        .padding(13)
        .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.82), lineWidth: 1)
        }
    }

    private func glassTextField(_ placeholder: String, text: Binding<String>, lines: Int) -> some View {
        TextField(placeholder, text: text, axis: .vertical)
            .lineLimit(lines, reservesSpace: true)
            .font(.subheadline.weight(.semibold))
            .padding(13)
            .background(.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.82), lineWidth: 1)
            }
    }

    private func generate() {
        Task {
            var templateDraft = appModel.draft(from: template)
            templateDraft.topic = draft.topic
            templateDraft.audience = draft.audience
            templateDraft.tone = draft.tone
            generatedProject = await appModel.generateProject(from: templateDraft)
        }
    }

    private func templateErrorCard(_ message: String) -> some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(VFStyle.warning)

                HStack(spacing: 12) {
                    Button {
                        generate()
                    } label: {
                        Label(AppText.localized("Retry", "重试"), systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(VFStyle.accent)
                    }
                    .disabled(!canGenerate)
                    .accessibilityIdentifier("vf.templateDetail.generationError.retryButton")

                    if !appModel.quota.isPro {
                        Button {
                            appModel.generationError = nil
                            appModel.selectedTab = .pro
                        } label: {
                            Label(AppText.localized("Upgrade Pro", "升级 Pro"), systemImage: "crown.fill")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(
                                    LinearGradient(colors: [VFStyle.primaryRed, VFStyle.sunset], startPoint: .leading, endPoint: .trailing),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(AppText.localized("Upgrade Pro", "升级 Pro"))
                        .accessibilityIdentifier("vf.templateDetail.generationError.upgradeButton")
                    }
                }
            }
        }
        .accessibilityIdentifier("vf.templateDetail.generationError")
    }
}

#Preview {
    NavigationStack {
        TemplatesView()
            .environment(AppModel())
    }
}
