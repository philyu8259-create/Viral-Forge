import SwiftUI

struct TemplatesView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedCategory: TemplateCategory = .cover

    private var filteredTemplates: [CreativeTemplate] {
        appModel.visibleTemplates.filter { $0.category == selectedCategory }
    }

    var body: some View {
        VFPage {
            VFPageHeader(
                title: AppText.localized("Templates", "模板"),
                subtitle: AppText.localized("Locale-ready creative formats for faster production", "国内平台创意格式，快速起稿"),
                icon: "rectangle.on.rectangle.fill",
                tint: VFStyle.purpleFlow
            )

            categoryStrip

            VStack(alignment: .leading, spacing: 14) {
                VFSectionHeader(
                    title: AppText.localized("Template Library", "模板库"),
                    subtitle: AppText.localized("Pick a ready-made commerce workflow", "选择一个可直接生产的电商工作流")
                )

                LazyVStack(spacing: 14) {
                    ForEach(filteredTemplates) { template in
                        NavigationLink {
                            TemplateDetailView(template: template)
                        } label: {
                            TemplateCard(template: template)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VFGlassCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label(AppText.localized("Canva-like MVP Modules", "类 Canva 模块"), systemImage: "sparkles.rectangle.stack")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(VFStyle.ink)

                    VStack(spacing: 12) {
                        moduleRow(AppText.localized("Template variants for each platform", "各平台模板变体"), icon: "rectangle.3.group", tint: VFStyle.primaryRed)
                        moduleRow(AppText.localized("One-click resize targets", "一键适配尺寸"), icon: "arrow.up.left.and.arrow.down.right", tint: VFStyle.electricCyan)
                        moduleRow(AppText.localized("Batch creation from one product brief", "从一个产品简报批量创作"), icon: "tablecells", tint: VFStyle.sunset)
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
        case .cover: "photo.on.rectangle"
        case .product: "shippingbox.fill"
        case .knowledge: "list.bullet.rectangle.fill"
        case .promotion: "tag.fill"
        case .story: "quote.bubble.fill"
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
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(VFStyle.secondaryText.opacity(0.55))
            }
        }
    }
}

private struct TemplateDetailView: View {
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
        _draft = State(initialValue: GenerationDraft(platform: template.platform, goal: template.category == .promotion || template.category == .product ? .sellProduct : .growAudience, templateName: template.name, templatePromptHint: template.promptHint, templateStyle: template.style))
    }

    private var samplePoster: PosterDraft {
        PosterDraft(
            headline: template.category == .knowledge
                ? AppText.localized("3 steps to make it easier", "3 个步骤讲清楚")
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

                    VFPrimaryButton(
                        title: appModel.isGenerating ? AppText.localized("Generating...", "生成中...") : AppText.localized("Use Template", "使用模板"),
                        icon: "wand.and.stars",
                        isLoading: appModel.isGenerating,
                        isEnabled: canGenerate
                    ) {
                        generate()
                    }

                    if let generationError = appModel.generationError {
                        Label(generationError, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(VFStyle.warning)
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
}

#Preview {
    NavigationStack {
        TemplatesView()
            .environment(AppModel())
    }
}
