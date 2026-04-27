import SwiftUI

struct BrandKitView: View {
    @Environment(AppModel.self) private var appModel
    @State private var profile = BrandProfile()
    @State private var didSave = false

    var body: some View {
        Form {
            Section(AppText.localized("Brand Profile", "品牌资料")) {
                TextField(AppText.localized("Brand name", "品牌名称"), text: $profile.brandName)
                TextField(AppText.localized("Industry", "行业"), text: $profile.industry)
                TextField(AppText.localized("Target audience", "目标人群"), text: $profile.audience, axis: .vertical)
                    .lineLimit(2, reservesSpace: true)
                TextField(AppText.localized("Tone", "语气风格"), text: $profile.tone)
            }

            Section(AppText.localized("Content Rules", "内容规则")) {
                TextField(AppText.localized("Banned words or claims", "禁用词或禁用表述"), text: $profile.bannedWords, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                Picker(AppText.localized("Default platform", "默认平台"), selection: $profile.defaultPlatform) {
                    ForEach(SocialPlatform.chinaLaunchPlatforms) { platform in
                        Text(platform.displayName).tag(platform)
                    }
                }
                Picker(AppText.localized("Brand color", "品牌色"), selection: $profile.primaryColorName) {
                    Text(AppText.localized("Emerald", "青绿")).tag("Emerald")
                    Text(AppText.localized("Coral", "珊瑚")).tag("Coral")
                    Text(AppText.localized("Indigo", "靛蓝")).tag("Indigo")
                    Text(AppText.localized("Graphite", "石墨")).tag("Graphite")
                }
            }

            Section(AppText.localized("Brand Assets", "品牌素材")) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(AppText.localized("Active generation memory", "当前生成记忆"), systemImage: "brain")
                        .font(.headline)
                    Text(profile.memorySummary)
                        .foregroundStyle(.secondary)
                }

                Label(AppText.localized("Brand name, audience, tone, industry, and banned claims are applied automatically when generating.", "生成时会自动套用品牌名称、目标人群、语气、行业和禁用表述。"), systemImage: "wand.and.stars")
            }

            Section {
                Button {
                    Task {
                        await appModel.saveBrandProfile(profile)
                        didSave = true
                    }
                } label: {
                    Label(didSave ? AppText.localized("Saved", "已保存") : AppText.localized("Save Brand Kit", "保存品牌资料"), systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }

                if let brandStatusMessage = appModel.brandStatusMessage {
                    Text(brandStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if appModel.backendSettings.mode == .backend {
                    Button {
                        Task {
                            await appModel.syncFromBackend()
                            profile = appModel.brandProfile
                            appModel.brandStatusMessage = AppText.localized("Brand memory synced from backend.", "已从后端同步品牌记忆。")
                        }
                    } label: {
                        Label(AppText.localized("Sync From Backend", "从后端同步"), systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }

                    Text(appModel.backendStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(AppText.localized("Brand Kit", "品牌"))
        .onAppear {
            profile = appModel.brandProfile
        }
        .onChange(of: profile) { _, _ in
            didSave = false
            appModel.brandStatusMessage = nil
        }
    }
}

#Preview {
    NavigationStack {
        BrandKitView()
            .environment(AppModel())
    }
}
