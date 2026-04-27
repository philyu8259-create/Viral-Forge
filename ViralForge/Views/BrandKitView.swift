import SwiftUI

struct BrandKitView: View {
    @Environment(AppModel.self) private var appModel
    @State private var profile = BrandProfile()
    @State private var didSave = false

    var body: some View {
        VFPage {
            VFPageHeader(
                title: AppText.localized("Brand Kit", "品牌"),
                subtitle: AppText.localized("Keep every asset on-brand automatically", "让每次生成自动贴合品牌"),
                icon: "person.text.rectangle.fill",
                tint: brandColor
            )

            brandMemoryCard
            profileCard
            rulesCard
            saveCard
            settingsCard
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            profile = appModel.brandProfile
            normalizeDefaultPlatform()
        }
        .onChange(of: profile) { _, _ in
            didSave = false
            appModel.brandStatusMessage = nil
        }
    }

    private var brandColor: Color {
        switch profile.primaryColorName {
        case "Coral": VFStyle.primaryRed
        case "Indigo": VFStyle.accent
        case "Graphite": VFStyle.ink
        default: VFStyle.teal
        }
    }

    private var launchPlatforms: [SocialPlatform] {
        appModel.launchPlatforms
    }

    private var brandMemoryCard: some View {
        VFGlassCard(level: .thick) {
            HStack(spacing: 15) {
                ZStack {
                    Circle()
                        .fill(brandColor.opacity(0.18))
                        .frame(width: 62, height: 62)
                        .blur(radius: 10)
                    Circle()
                        .fill(brandColor)
                        .frame(width: 28, height: 28)
                        .shadow(color: brandColor.opacity(0.38), radius: 12, x: 0, y: 5)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(AppText.localized("Active generation memory", "当前生成记忆"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(VFStyle.ink)
                    Text(profile.memorySummary)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)
                        .lineLimit(3)

                    if !profile.hasSavedMemory {
                        HStack(spacing: 6) {
                            setupChip(AppText.localized("Audience", "人群"))
                            setupChip(AppText.localized("Tone", "语气"))
                            setupChip(AppText.localized("Banned claims", "禁用表述"))
                        }
                        .padding(.top, 4)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    private func setupChip(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.black))
            .foregroundStyle(brandColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(brandColor.opacity(0.10), in: Capsule())
    }

    private var profileCard: some View {
        VFGlassCard(level: .thick) {
            VStack(alignment: .leading, spacing: 14) {
                VFSectionHeader(
                    title: AppText.localized("Brand Profile", "品牌资料"),
                    subtitle: AppText.localized("Basic fields used in every prompt", "每次生成都会使用的基础资料")
                )

                brandedField(AppText.localized("Brand name", "品牌名称"), text: $profile.brandName, icon: "signature", tint: VFStyle.primaryRed)
                brandedField(AppText.localized("Industry", "行业"), text: $profile.industry, icon: "building.2.fill", tint: VFStyle.sunset)
                brandedField(AppText.localized("Target audience", "目标人群"), text: $profile.audience, icon: "person.3.fill", tint: VFStyle.electricCyan, lines: 2)
                brandedField(AppText.localized("Tone", "语气风格"), text: $profile.tone, icon: "quote.bubble.fill", tint: VFStyle.purpleFlow)
            }
        }
    }

    private var rulesCard: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                VFSectionHeader(
                    title: AppText.localized("Content Rules", "内容规则"),
                    subtitle: AppText.localized("Control platform, visual tone, and risky claims", "控制平台、视觉调性与风险表述")
                )

                brandedField(AppText.localized("Banned words or claims", "禁用词或禁用表述"), text: $profile.bannedWords, icon: "exclamationmark.shield.fill", tint: VFStyle.warning, lines: 3)

                VStack(alignment: .leading, spacing: 10) {
                    Text(AppText.localized("Default platform", "默认平台"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStyle.secondaryText)

                    HStack(spacing: 10) {
                        ForEach(launchPlatforms) { platform in
                            Button {
                                profile.defaultPlatform = platform
                            } label: {
                                Text(platform.displayName)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(profile.defaultPlatform == platform ? .white : VFStyle.ink)
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 9)
                                    .frame(maxWidth: .infinity)
                                    .background(profile.defaultPlatform == platform ? VFStyle.platformTint(platform) : .white.opacity(0.62), in: Capsule())
                                    .overlay {
                                        Capsule()
                                            .stroke(.white.opacity(0.78), lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(AppText.localized("Brand color", "品牌色"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStyle.secondaryText)

                    HStack(spacing: 12) {
                        colorSwatch(AppText.localized("Emerald", "青绿"), value: "Emerald", color: VFStyle.teal)
                        colorSwatch(AppText.localized("Coral", "珊瑚"), value: "Coral", color: VFStyle.primaryRed)
                        colorSwatch(AppText.localized("Indigo", "靛蓝"), value: "Indigo", color: VFStyle.accent)
                        colorSwatch(AppText.localized("Graphite", "石墨"), value: "Graphite", color: VFStyle.ink)
                    }
                }
            }
        }
    }

    private var saveCard: some View {
        VFGlassCard {
            VStack(spacing: 13) {
                VFPrimaryButton(
                    title: didSave ? AppText.localized("Saved", "已保存") : AppText.localized("Save Brand Kit", "保存品牌资料"),
                    icon: didSave ? "checkmark.circle.fill" : "checkmark.circle"
                ) {
                    Task {
                        await appModel.saveBrandProfile(profile)
                        didSave = true
                    }
                }

                if let brandStatusMessage = appModel.brandStatusMessage {
                    Text(brandStatusMessage)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)
                        .multilineTextAlignment(.center)
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
                            .font(.subheadline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.58), in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Text(appModel.backendStatusMessage)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)
                }
            }
        }
    }

    private var settingsCard: some View {
        NavigationLink {
            SettingsView()
        } label: {
            VFGlassCard {
                HStack(spacing: 13) {
                    VFGradientIcon(icon: "gearshape.fill", tint: VFStyle.ink, size: 38)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(AppText.localized("Settings", "设置"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(VFStyle.ink)
                        Text(AppText.localized("Privacy, terms, support, data deletion, and restore purchases", "隐私、协议、支持、数据删除与恢复购买"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(VFStyle.secondaryText)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStyle.secondaryText.opacity(0.55))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("vf.brand.settingsLink")
    }

    private func brandedField(_ placeholder: String, text: Binding<String>, icon: String, tint: Color, lines: Int = 1) -> some View {
        HStack(alignment: lines > 1 ? .top : .center, spacing: 12) {
            VFGradientIcon(icon: icon, tint: tint, size: 34)
            TextField(placeholder, text: text, axis: .vertical)
                .lineLimit(lines, reservesSpace: lines > 1)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(VFStyle.ink)
                .padding(12)
                .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: 15))
                .overlay {
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(.white.opacity(0.82), lineWidth: 1)
                }
        }
    }

    private func colorSwatch(_ label: String, value: String, color: Color) -> some View {
        Button {
            profile.primaryColorName = value
        } label: {
            VStack(spacing: 7) {
                Circle()
                    .fill(color)
                    .frame(width: 28, height: 28)
                    .overlay {
                        if profile.primaryColorName == value {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.black))
                                .foregroundStyle(.white)
                        }
                    }
                    .shadow(color: color.opacity(0.28), radius: 8, x: 0, y: 4)
                Text(label)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(VFStyle.secondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(profile.primaryColorName == value ? color.opacity(0.10) : .white.opacity(0.52), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(profile.primaryColorName == value ? color.opacity(0.42) : .white.opacity(0.76), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func normalizeDefaultPlatform() {
        guard !launchPlatforms.contains(profile.defaultPlatform) else { return }
        profile.defaultPlatform = SocialPlatform.defaultPlatform(for: appModel.launchLanguage)
    }
}

#Preview {
    NavigationStack {
        BrandKitView()
            .environment(AppModel())
    }
}
