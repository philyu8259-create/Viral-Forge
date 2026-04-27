import SwiftUI

struct BatchCreateView: View {
    @Environment(AppModel.self) private var appModel
    @State private var productBrief = ""
    @State private var selectedPlatforms: Set<SocialPlatform> = [.xiaohongshu, .douyin]
    @State private var batchSize = 7
    @State private var ideas: [CampaignIdea] = []
    @State private var generatedProject: ContentProject?
    @State private var calendarVersion = 0

    private let calendarSectionID = "batch-content-calendar"

    private var canGenerateCalendar: Bool {
        productBrief.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 && !selectedPlatforms.isEmpty
    }

    var body: some View {
        ScrollViewReader { proxy in
            Form {
                Section(AppText.localized("Campaign Brief", "活动简报")) {
                    TextField(AppText.localized("Product or campaign", "产品或活动"), text: $productBrief, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                    Picker(AppText.localized("Calendar length", "日历周期"), selection: $batchSize) {
                        Text(AppText.localized("7 days", "7 天")).tag(7)
                        Text(AppText.localized("14 days", "14 天")).tag(14)
                    }
                    .pickerStyle(.segmented)
                }

                Section(AppText.localized("Platforms", "平台")) {
                    ForEach(SocialPlatform.chinaLaunchPlatforms) { platform in
                        Toggle(platform.displayName, isOn: binding(for: platform))
                    }
                }

                if appModel.brandProfile.hasSavedMemory {
                    Section(AppText.localized("Brand Memory", "品牌记忆")) {
                        Label(appModel.brandProfile.memorySummary, systemImage: "brain")
                    }
                }

                Section {
                    Button {
                        generateCalendar()
                    } label: {
                        Label(AppText.localized("Generate Content Calendar", "生成内容日历"), systemImage: "calendar.badge.sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!canGenerateCalendar)
                } footer: {
                    Text(AppText.localized(
                        "Each calendar day can become a full copy pack and poster draft.",
                        "每一天都可以继续生成完整文案包和海报草稿。"
                    ))
                }

                if !ideas.isEmpty {
                    Section(AppText.localized("Content Calendar", "内容日历")) {
                        ForEach(ideas) { idea in
                            CampaignIdeaRow(idea: idea) {
                                generateProject(from: idea)
                            }
                        }
                    }
                    .id(calendarSectionID)

                    Section {
                        Color.clear
                            .frame(height: 72)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(AppText.localized("Batch Campaign", "批量创作"))
            .onChange(of: calendarVersion) { _, _ in
                guard !ideas.isEmpty else { return }
                DispatchQueue.main.async {
                    withAnimation(.snappy) {
                        proxy.scrollTo(calendarSectionID, anchor: .top)
                    }
                }
            }
            .navigationDestination(item: $generatedProject) { project in
                ResultView(project: project)
            }
        }
    }

    private func generateCalendar() {
        ideas = appModel.batchIdeas(
            for: productBrief,
            platforms: Array(selectedPlatforms).sorted { $0.rawValue < $1.rawValue },
            count: batchSize
        )
        calendarVersion += 1
    }

    private func generateProject(from idea: CampaignIdea) {
        let draft = appModel.draft(from: idea, productBrief: productBrief)
        Task {
            generatedProject = await appModel.generateProject(from: draft)
        }
    }

    private func binding(for platform: SocialPlatform) -> Binding<Bool> {
        Binding {
            selectedPlatforms.contains(platform)
        } set: { isSelected in
            if isSelected {
                selectedPlatforms.insert(platform)
            } else {
                selectedPlatforms.remove(platform)
            }
        }
    }
}

private struct CampaignIdeaRow: View {
    let idea: CampaignIdea
    let generate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(AppText.localized("Day \(idea.day)", "第 \(idea.day) 天"))
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.thinMaterial, in: Capsule())
                        Text(idea.platform.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(idea.pillar)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(idea.objective)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(idea.title)
                .font(.headline)
            Text(idea.hook)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Label(idea.posterAngle, systemImage: "photo.on.rectangle")
                Label(idea.cta, systemImage: "hand.tap")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Button {
                generate()
            } label: {
                Label(AppText.localized("Generate This Day", "生成当天完整内容"), systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack {
        BatchCreateView()
            .environment(AppModel())
    }
}
