import SwiftUI

struct MyView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        VFPage {
            VFPageHeader(
                title: AppText.localized("Me", "我的"),
                subtitle: AppText.localized("Plan, brand memory, settings, and support", "会员、品牌记忆、设置与支持"),
                icon: "person.crop.circle.fill",
                tint: VFStyle.primaryRed
            )

            VStack(spacing: 12) {
                NavigationLink {
                    PaywallView()
                } label: {
                    MyHubRow(
                        icon: appModel.quota.isPro ? "crown.fill" : "crown",
                        title: appModel.quota.isPro ? AppText.localized("ViralForge Pro Active", "ViralForge Pro 已开通") : AppText.localized("Upgrade to Pro", "开通会员"),
                        subtitle: proSubtitle,
                        tint: VFStyle.sunset
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("vf.my.proButton")

                NavigationLink {
                    BrandKitView()
                } label: {
                    MyHubRow(
                        icon: "brain.head.profile",
                        title: AppText.localized("Brand Memory", "品牌记忆"),
                        subtitle: appModel.brandProfile.hasSavedMemory ? appModel.brandProfile.memorySummary : AppText.localized("Save your brand tone, audience, colors, and banned words.", "保存品牌语气、目标人群、品牌色和禁用词。"),
                        tint: VFStyle.purpleFlow
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("vf.my.brandButton")

                NavigationLink {
                    TemplatesView()
                } label: {
                    MyHubRow(
                        icon: "rectangle.on.rectangle.fill",
                        title: AppText.localized("Template Library", "模板库"),
                        subtitle: AppText.localized("Pick a preset when you do not want to start from scratch.", "不想从空白开始时，直接套用预设。"),
                        tint: VFStyle.electricCyan
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("vf.my.templatesButton")

                NavigationLink {
                    SettingsView()
                } label: {
                    MyHubRow(
                        icon: "gearshape.fill",
                        title: AppText.localized("Settings & Support", "设置与支持"),
                        subtitle: AppText.localized("Privacy, terms, restore purchases, backend, and data deletion.", "隐私、协议、恢复购买、后端与数据删除。"),
                        tint: VFStyle.ink
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("vf.my.settingsButton")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("vf.my.screen")
    }

    private var proSubtitle: String {
        if let subscriptionValidityText = appModel.subscriptionValidityText {
            return subscriptionValidityText
        }
        if appModel.quota.isPro {
            return AppText.localized("Premium limits, no-watermark export, and member templates are available.", "高级额度、无水印导出和会员模板已可用。")
        }
        return AppText.localized("View plans, restore purchases, and check member benefits.", "查看方案、恢复购买并了解会员权益。")
    }
}

private struct MyHubRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color

    var body: some View {
        VFGlassCard {
            HStack(spacing: 13) {
                VFGradientIcon(icon: icon, tint: tint, size: 42)

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(VFStyle.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(subtitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(VFStyle.secondaryText.opacity(0.56))
            }
        }
    }
}

#Preview {
    NavigationStack {
        MyView()
            .environment(AppModel())
    }
}
