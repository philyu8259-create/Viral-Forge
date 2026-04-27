import SwiftUI

struct BatchCreateView: View {
    @Environment(AppModel.self) private var appModel
    @State private var productBrief = ""
    @State private var selectedPlatforms: Set<SocialPlatform> = [.xiaohongshu, .douyin]
    @State private var batchSize = 7
    @State private var ideas: [CampaignIdea] = []
    @State private var generatedProject: ContentProject?

    private var canGenerateCalendar: Bool {
        productBrief.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 && !selectedPlatforms.isEmpty
    }

    var body: some View {
        VFPage {
            VFPageHeader(
                title: AppText.localized("Batch Campaign", "批量创作"),
                subtitle: AppText.localized("Turn one product brief into a content calendar", "把一个产品简报变成内容日历"),
                icon: "calendar.badge.plus",
                tint: VFStyle.teal
            )

            briefCard

            if appModel.brandProfile.hasSavedMemory {
                VFGlassCard {
                    Label(appModel.brandProfile.memorySummary, systemImage: "brain")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(VFStyle.secondaryText)
                }
            }

            VFPrimaryButton(
                title: AppText.localized("Generate Content Calendar", "生成内容日历"),
                icon: "calendar.badge.sparkles",
                isEnabled: canGenerateCalendar
            ) {
                generateCalendar()
            }

            if !ideas.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    VFSectionHeader(
                        title: AppText.localized("Content Calendar", "内容日历"),
                        subtitle: AppText.localized("Each day can become a full content pack", "每一天都可以继续生成完整内容包")
                    )

                    LazyVStack(spacing: 14) {
                        ForEach(ideas) { idea in
                            CampaignIdeaCard(idea: idea) {
                                generateProject(from: idea)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $generatedProject) { project in
            ResultView(project: project)
        }
    }

    private var briefCard: some View {
        VFGlassCard(level: .thick) {
            VStack(alignment: .leading, spacing: 16) {
                VFSectionHeader(
                    title: AppText.localized("Campaign Brief", "活动简报"),
                    subtitle: AppText.localized("Set the product, calendar length, and target platforms", "设置产品、周期和目标平台")
                )

                TextField(AppText.localized("Product or campaign", "产品或活动"), text: $productBrief, axis: .vertical)
                    .lineLimit(4, reservesSpace: true)
                    .font(.subheadline.weight(.semibold))
                    .padding(14)
                    .background(.white.opacity(0.66), in: RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.82), lineWidth: 1)
                    }

                Picker(AppText.localized("Calendar length", "日历周期"), selection: $batchSize) {
                    Text(AppText.localized("7 days", "7 天")).tag(7)
                    Text(AppText.localized("14 days", "14 天")).tag(14)
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 10) {
                    Text(AppText.localized("Platforms", "平台"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStyle.secondaryText)

                    HStack(spacing: 10) {
                        ForEach(SocialPlatform.chinaLaunchPlatforms) { platform in
                            Button {
                                toggle(platform)
                            } label: {
                                Text(platform.displayName)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(selectedPlatforms.contains(platform) ? .white : VFStyle.ink)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedPlatforms.contains(platform) ? VFStyle.platformTint(platform) : .white.opacity(0.62), in: Capsule())
                                    .overlay {
                                        Capsule()
                                            .stroke(.white.opacity(0.78), lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func generateCalendar() {
        ideas = appModel.batchIdeas(
            for: productBrief,
            platforms: Array(selectedPlatforms).sorted { $0.rawValue < $1.rawValue },
            count: batchSize
        )
    }

    private func generateProject(from idea: CampaignIdea) {
        let draft = appModel.draft(from: idea, productBrief: productBrief)
        Task {
            generatedProject = await appModel.generateProject(from: draft)
        }
    }

    private func toggle(_ platform: SocialPlatform) {
        if selectedPlatforms.contains(platform) {
            selectedPlatforms.remove(platform)
        } else {
            selectedPlatforms.insert(platform)
        }
    }
}

private struct CampaignIdeaCard: View {
    let idea: CampaignIdea
    let generate: () -> Void

    var body: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(AppText.localized("Day \(idea.day)", "第 \(idea.day) 天"))
                                .font(.caption.weight(.black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(VFStyle.platformTint(idea.platform), in: Capsule())
                            Text(idea.platform.displayName)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(VFStyle.secondaryText)
                        }

                        Text(idea.pillar)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(VFStyle.secondaryText)
                    }
                    Spacer()
                    Text(idea.objective)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(VFStyle.secondaryText.opacity(0.75))
                }

                Text(idea.title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(VFStyle.ink)
                Text(idea.hook)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(VFStyle.secondaryText)

                HStack(spacing: 10) {
                    miniMeta(idea.posterAngle, icon: "photo.on.rectangle", tint: VFStyle.sunset)
                    miniMeta(idea.cta, icon: "hand.tap.fill", tint: VFStyle.electricCyan)
                }

                Button {
                    generate()
                } label: {
                    Label(AppText.localized("Generate This Day", "生成当天完整内容"), systemImage: "wand.and.stars")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(VFStyle.primaryRed)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.62), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func miniMeta(_ text: String, icon: String, tint: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.bold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.10), in: Capsule())
    }
}

#Preview {
    NavigationStack {
        BatchCreateView()
            .environment(AppModel())
    }
}
