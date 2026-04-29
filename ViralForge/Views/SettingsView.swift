import SwiftUI

enum AppLegalLinks {
    private static let baseURL = "https://philyu8259-create.github.io/Viral-Forge"

    static var privacy: URL {
        localizedURL(chinesePath: "zh/privacy.html", englishPath: "en/privacy.html")
    }

    static var terms: URL {
        localizedURL(chinesePath: "zh/terms.html", englishPath: "en/terms.html")
    }

    static var support: URL {
        localizedURL(chinesePath: "zh/support.html", englishPath: "en/support.html")
    }

    static let supportEmail = URL(string: "mailto:philyu2023@qq.com?subject=ViralForge%20Support")!
    static let dataDeletionEmail = URL(string: "mailto:philyu2023@qq.com?subject=ViralForge%20Data%20Deletion%20Request")!

    private static func localizedURL(chinesePath: String, englishPath: String) -> URL {
        URL(string: "\(baseURL)/\(AppText.isChinese ? chinesePath : englishPath)")!
    }
}

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openURL) private var openURL
    @State private var showClearLocalDataConfirmation = false

    var body: some View {
        VFPage {
            VFPageHeader(
                title: AppText.localized("Settings", "设置"),
                subtitle: AppText.localized("Subscription, support, privacy, and release links", "会员、支持、隐私与上架必需入口"),
                icon: "gearshape.fill",
                tint: VFStyle.ink
            )

            accountCard
            legalCard
            dataCard
            appInfoCard
        }
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("vf.settings.screen")
        .alert(AppText.localized("Clear local data?", "清空本机数据？"), isPresented: $showClearLocalDataConfirmation) {
            Button(AppText.localized("Cancel", "取消"), role: .cancel) {}
            Button(AppText.localized("Clear", "清空"), role: .destructive) {
                appModel.clearLocalWorkspaceData()
            }
        } message: {
            Text(AppText.localized(
                "This removes local projects, poster assets, snippets, and brand memory from this device. Subscriptions are not affected.",
                "这会从本机移除项目、海报素材、文案片段和品牌记忆，不影响订阅。"
            ))
        }
    }

    private var accountCard: some View {
        VFGlassCard(level: .thick) {
            VStack(alignment: .leading, spacing: 14) {
                VFSectionHeader(
                    title: AppText.localized("Subscription", "会员订阅"),
                    subtitle: AppText.localized("Restore purchases and check Pro status", "恢复购买并查看会员状态")
                )

                HStack(spacing: 13) {
                    VFGradientIcon(icon: appModel.quota.isPro ? "crown.fill" : "crown", tint: VFStyle.sunset, size: 42)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appModel.quota.isPro ? AppText.localized("Pro Active", "会员已开通") : AppText.localized("Free Workspace", "免费工作台"))
                            .font(.headline.weight(.black))
                            .foregroundStyle(VFStyle.ink)
                        Text(appModel.quota.isPro ? AppText.localized("Premium generation limits are active.", "会员生成权益已生效。") : AppText.localized("Upgrade anytime from the Pro tab.", "可随时在会员页升级。"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(VFStyle.secondaryText)
                    }
                    Spacer()
                }

                VFPrimaryButton(
                    title: appModel.isPurchasingSubscription ? AppText.localized("Restoring...", "正在恢复...") : AppText.localized("Restore Purchases", "恢复购买"),
                    icon: "arrow.clockwise",
                    isLoading: appModel.isPurchasingSubscription,
                    isEnabled: !appModel.isPurchasingSubscription
                ) {
                    Task {
                        await appModel.restorePurchases()
                    }
                }
                .accessibilityIdentifier("vf.settings.restorePurchasesButton")

                if let purchaseStatusMessage = appModel.purchaseStatusMessage {
                    Text(purchaseStatusMessage)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(.white.opacity(0.52), in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    private var legalCard: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                VFSectionHeader(
                    title: AppText.localized("Legal & Support", "协议与支持"),
                    subtitle: AppText.localized("Privacy, terms, and ways to contact us", "隐私、协议与联系支持")
                )

                settingsLink(
                    title: AppText.localized("Privacy Policy", "隐私政策"),
                    subtitle: AppText.localized("How ViralForge handles app data and AI requests", "ViralForge 如何处理 App 数据与 AI 请求"),
                    icon: "hand.raised.fill",
                    tint: VFStyle.teal,
                    url: AppLegalLinks.privacy,
                    identifier: "vf.settings.privacyLink"
                )

                settingsLink(
                    title: AppText.localized("Terms of Use", "用户协议"),
                    subtitle: AppText.localized("Subscription, usage, and generated-content terms", "订阅、使用与生成内容条款"),
                    icon: "doc.text.fill",
                    tint: VFStyle.purpleFlow,
                    url: AppLegalLinks.terms,
                    identifier: "vf.settings.termsLink"
                )

                settingsLink(
                    title: AppText.localized("Support", "联系支持"),
                    subtitle: AppText.localized("Help, restore purchases, and troubleshooting", "帮助、恢复购买与问题排查"),
                    icon: "questionmark.bubble.fill",
                    tint: VFStyle.electricCyan,
                    url: AppLegalLinks.support,
                    identifier: "vf.settings.supportLink"
                )

                settingsLink(
                    title: AppText.localized("Email Support", "邮件联系"),
                    subtitle: "philyu2023@qq.com",
                    icon: "envelope.fill",
                    tint: VFStyle.primaryRed,
                    url: AppLegalLinks.supportEmail,
                    identifier: "vf.settings.emailSupportLink"
                )
            }
        }
    }

    private var dataCard: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                VFSectionHeader(
                    title: AppText.localized("Data & Deletion", "数据与删除"),
                    subtitle: AppText.localized("Manage saved drafts and request data deletion", "管理本机草稿并申请数据删除")
                )

                HStack(alignment: .top, spacing: 12) {
                    VFGradientIcon(icon: "trash.fill", tint: VFStyle.warning, size: 38)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(AppText.localized("Request account/data deletion", "申请账号/数据删除"))
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(VFStyle.ink)
                        Text(AppText.localized(
                            "Send us an email if you want help deleting app data associated with your use of ViralForge.",
                            "如需协助删除与你使用 ViralForge 相关的数据，请通过邮件联系我们。"
                        ))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Button {
                    openURL(AppLegalLinks.dataDeletionEmail)
                } label: {
                    Label(AppText.localized("Email Data Deletion Request", "发送数据删除邮件"), systemImage: "paperplane.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(VFStyle.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(.white.opacity(0.62), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(.white.opacity(0.82), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("vf.settings.dataDeletionLink")

                Button {
                    showClearLocalDataConfirmation = true
                } label: {
                    Label(AppText.localized("Clear Local Workspace Data", "清空本机工作台数据"), systemImage: "trash.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(VFStyle.warning)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(VFStyle.warning.opacity(0.10), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(VFStyle.warning.opacity(0.22), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("vf.settings.clearLocalDataButton")

                if let localDataStatusMessage = appModel.localDataStatusMessage {
                    Text(localDataStatusMessage)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(.white.opacity(0.56), in: RoundedRectangle(cornerRadius: 16))
                        .accessibilityIdentifier("vf.settings.localDataStatus")
                }
            }
        }
    }

    private var appInfoCard: some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                VFSectionHeader(
                    title: AppText.localized("App Info", "应用信息"),
                    subtitle: AppText.localized("Current installed version", "当前安装版本")
                )

                infoRow(AppText.localized("Version", "版本"), value: appVersionText, icon: "number", tint: VFStyle.accent)
            }
        }
    }

    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func settingsLink(title: String, subtitle: String, icon: String, tint: Color, url: URL, identifier: String) -> some View {
        Button {
            openURL(url)
        } label: {
            HStack(spacing: 12) {
                VFGradientIcon(icon: icon, tint: tint, size: 38)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(VFStyle.ink)
                    Text(subtitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.black))
                    .foregroundStyle(VFStyle.secondaryText.opacity(0.62))
            }
            .padding(12)
            .background(.white.opacity(0.52), in: RoundedRectangle(cornerRadius: 17))
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .stroke(.white.opacity(0.80), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }

    private func infoRow(_ title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            VFGradientIcon(icon: icon, tint: tint, size: 34)
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(VFStyle.ink)
            Spacer()
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(VFStyle.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(12)
        .background(.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppModel())
    }
}
