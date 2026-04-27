import SwiftUI

struct TemplatesView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedCategory: TemplateCategory = .cover

    private var filteredTemplates: [CreativeTemplate] {
        appModel.templates.filter { $0.category == selectedCategory }
    }

    var body: some View {
        List {
            Section {
                Picker(AppText.localized("Category", "分类"), selection: $selectedCategory) {
                    ForEach(TemplateCategory.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(AppText.localized("Template Library", "模板库")) {
                ForEach(filteredTemplates) { template in
                    NavigationLink {
                        TemplateDetailView(template: template)
                    } label: {
                        TemplateRow(template: template)
                    }
                }
            }

            Section(AppText.localized("Canva-like MVP Modules", "类 Canva 模块")) {
                Label(AppText.localized("Template variants for each platform", "各平台模板变体"), systemImage: "rectangle.3.group")
                Label(AppText.localized("One-click resize targets", "一键适配尺寸"), systemImage: "arrow.up.left.and.arrow.down.right")
                Label(AppText.localized("Batch creation from one product brief", "从一个产品简报批量创作"), systemImage: "tablecells")
            }
            .foregroundStyle(.secondary)
        }
        .navigationTitle(AppText.localized("Templates", "模板"))
        .task {
            await appModel.refreshTemplatesIfNeeded()
        }
    }
}

private struct TemplateRow: View {
    let template: CreativeTemplate

    var body: some View {
        HStack(spacing: 14) {
            PosterPreview(
                poster: PosterDraft(headline: template.name, subtitle: template.platform.displayName, cta: template.category.displayName, style: template.style),
                platform: template.platform
            )
            .frame(width: 70, height: 96)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(template.name)
                        .font(.headline)
                    if template.lockedToPro {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                    }
                }
                Text(template.promptHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
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
            headline: template.category == .knowledge ? "3 steps to make it easier" : "Make it worth stopping for",
            subtitle: template.name,
            cta: template.platform.displayName,
            style: template.style
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PosterPreview(poster: samplePoster, platform: template.platform)
                    .frame(height: 520)

                VStack(alignment: .leading, spacing: 10) {
                    Text(template.name)
                        .font(.title2.weight(.semibold))
                    Text(template.promptHint)
                        .foregroundStyle(.secondary)
                    Label(template.lockedToPro ? AppText.localized("Pro template", "会员模板") : AppText.localized("Free template", "免费模板"), systemImage: template.lockedToPro ? "crown.fill" : "checkmark.circle")
                        .foregroundStyle(template.lockedToPro ? .yellow : .green)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(AppText.localized("Generate From Template", "从模板生成"))
                        .font(.headline)
                    TextField(AppText.localized("Topic or product", "主题或产品"), text: $draft.topic, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                    TextField(AppText.localized("Audience", "目标人群"), text: $draft.audience)
                    TextField(AppText.localized("Tone", "语气风格"), text: $draft.tone)
                    if appModel.brandProfile.hasSavedMemory {
                        Label(appModel.brandProfile.memorySummary, systemImage: "brain")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    if let message = visibleTopicValidationMessage {
                        Label(message, systemImage: "exclamationmark.circle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .textFieldStyle(.roundedBorder)

                Button {
                    generate()
                } label: {
                    Label(appModel.isGenerating ? AppText.localized("Generating...", "生成中...") : AppText.localized("Use Template", "使用模板"), systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canGenerate)

                if let generationError = appModel.generationError {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(generationError, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)

                        Button {
                            generate()
                        } label: {
                            Label(AppText.localized("Retry", "重试"), systemImage: "arrow.clockwise")
                        }
                        .disabled(!canGenerate)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(AppText.localized("Template", "模板"))
        .navigationDestination(item: $generatedProject) { project in
            ResultView(project: project)
        }
        .onChange(of: draft) { _, _ in
            appModel.generationError = nil
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
