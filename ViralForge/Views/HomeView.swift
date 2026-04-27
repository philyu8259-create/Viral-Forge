import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var draft = GenerationDraft()
    @State private var generatedProject: ContentProject?

    private var canGenerate: Bool {
        !appModel.isGenerating && draft.isReadyToGenerate
    }

    private var visibleTopicValidationMessage: String? {
        draft.topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : draft.topicValidationMessage
    }

    var body: some View {
        Form {
            Section {
                Picker(AppText.localized("Platform", "平台"), selection: $draft.platform) {
                    ForEach(SocialPlatform.chinaLaunchPlatforms) { platform in
                        Text(platform.displayName).tag(platform)
                    }
                }

                Picker(AppText.localized("Goal", "目标"), selection: $draft.goal) {
                    ForEach(ContentGoal.allCases) { goal in
                        Text(goal.displayName).tag(goal)
                    }
                }
            }

            Section {
                TextField(AppText.localized("Topic or product", "主题或产品"), text: $draft.topic, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                TextField(AppText.localized("Audience", "目标人群"), text: $draft.audience)
                TextField(AppText.localized("Tone", "语气风格"), text: $draft.tone)
            } header: {
                Text(AppText.localized("Brief", "创作需求"))
            }
            footer: {
                if let message = visibleTopicValidationMessage {
                    Label(message, systemImage: "exclamationmark.circle")
                }
            }

            Section(AppText.localized("Campaign Tools", "创作工具")) {
                NavigationLink {
                    BatchCreateView()
                } label: {
                    Label(AppText.localized("Batch Campaign", "批量创作"), systemImage: "square.grid.2x2")
                }

                NavigationLink {
                    TemplatesView()
                } label: {
                    Label(AppText.localized("Start from Template", "从模板开始"), systemImage: "rectangle.on.rectangle")
                }
            }

            Section(AppText.localized("Quota", "额度")) {
                QuotaStatusView(quota: appModel.quota, compact: true)
            }

            if appModel.brandProfile.hasSavedMemory {
                Section(AppText.localized("Brand Memory", "品牌记忆")) {
                    Label(appModel.brandProfile.memorySummary, systemImage: "brain")
                }
            }

            Section {
                Button {
                    generate()
                } label: {
                    Label(appModel.isGenerating ? AppText.localized("Generating...", "生成中...") : AppText.localized("Generate Content Pack", "生成内容方案"), systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!canGenerate)
            } footer: {
                Text(AppText.localized("Backend mode controls live AI calls and quota.", "后端模式会控制真实 AI 调用和额度。"))
            }

            if let generationError = appModel.generationError {
                Section {
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

            Section {
                Color.clear
                    .frame(height: 72)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("ViralForge")
        .navigationDestination(item: $generatedProject) { project in
            ResultView(project: project)
        }
        .task {
            await appModel.refreshQuota()
        }
        .onChange(of: draft) { _, _ in
            appModel.generationError = nil
        }
    }

    private func generate() {
        Task {
            generatedProject = await appModel.generateProject(from: draft)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(AppModel())
    }
}
