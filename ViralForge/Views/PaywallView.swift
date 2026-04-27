import SwiftUI

struct PaywallView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedPlan = SubscriptionPlan.yearly

    var body: some View {
        VFPage {
            proHero
            QuotaStatusView(quota: appModel.quota)
            featureGrid
            planPicker
            purchaseCard
            backendSettingsCard
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var proHero: some View {
        VFGlassCard(level: .thick) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ViralForge Pro")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(VFStyle.brandGradient)
                        Text(AppText.localized(
                            "Unlock higher generation limits, premium poster templates, brand memory, and watermark-free exports.",
                            "解锁更高生成额度、会员海报模板、品牌记忆和无水印导出。"
                        ))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)
                    }

                    Spacer()

                    VFGradientIcon(icon: "crown.fill", tint: VFStyle.sunset, size: 50)
                }

                Text(appModel.quota.isPro ? AppText.localized("Your Pro workspace is active", "你的 Pro 工作台已开通") : AppText.localized("Designed for serious content production", "为持续内容生产设计"))
                    .font(.caption.weight(.black))
                    .foregroundStyle(appModel.quota.isPro ? VFStyle.teal : VFStyle.primaryRed)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background((appModel.quota.isPro ? VFStyle.teal : VFStyle.primaryRed).opacity(0.10), in: Capsule())
            }
        }
    }

    private var featureGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            VFSectionHeader(
                title: AppText.localized("Pro Benefits", "会员权益"),
                subtitle: AppText.localized("Built for batch creation and polished output", "面向批量创作和高质量输出")
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                feature(AppText.localized("Unlimited copy", "不限文案"), icon: "sparkles", tint: VFStyle.primaryRed)
                feature(AppText.localized("100 AI backgrounds", "100 张 AI 背景"), icon: "sparkles.rectangle.stack", tint: VFStyle.purpleFlow)
                feature(AppText.localized("Premium templates", "会员模板"), icon: "rectangle.3.group", tint: VFStyle.sunset)
                feature(AppText.localized("No watermark", "无水印导出"), icon: "checkmark.seal.fill", tint: VFStyle.electricCyan)
            }
        }
    }

    private var planPicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            VFSectionHeader(
                title: AppText.localized("Choose Plan", "选择方案"),
                subtitle: AppText.localized("China-first pricing is configured for local StoreKit testing", "本地 StoreKit 已按中国区价格配置")
            )

            VStack(spacing: 12) {
                ForEach(SubscriptionPlan.all) { plan in
                    Button {
                        withAnimation(.snappy) {
                            selectedPlan = plan
                        }
                    } label: {
                        SubscriptionPlanCard(
                            plan: plan,
                            productPrice: appModel.product(for: plan)?.displayPrice,
                            isSelected: selectedPlan == plan
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var purchaseCard: some View {
        VFGlassCard {
            VStack(spacing: 13) {
                VFPrimaryButton(
                    title: primaryButtonTitle,
                    icon: appModel.quota.isPro ? "checkmark.circle.fill" : "bolt.fill",
                    isLoading: appModel.isPurchasingSubscription || appModel.isLoadingStoreProducts,
                    isEnabled: !appModel.quota.isPro && !appModel.isPurchasingSubscription && !appModel.isLoadingStoreProducts
                ) {
                    Task {
                        await appModel.purchaseSubscription(plan: selectedPlan)
                    }
                }

                Button {
                    Task {
                        await appModel.restorePurchases()
                    }
                } label: {
                    Text(AppText.localized("Restore Purchases", "恢复购买"))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(VFStyle.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(.white.opacity(0.62), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(.white.opacity(0.80), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .disabled(appModel.isPurchasingSubscription)

                if let purchaseStatusMessage = appModel.purchaseStatusMessage {
                    Text(purchaseStatusMessage)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)
                        .multilineTextAlignment(.center)
                }

                Text(AppText.localized(
                    "Purchases use StoreKit. Local testing uses the bundled StoreKit configuration; production products must also be created in App Store Connect.",
                    "购买已接入 StoreKit。本地测试使用内置 StoreKit 配置；正式上架还需要在 App Store Connect 创建同 ID 商品。"
                ))
                .font(.caption2.weight(.medium))
                .foregroundStyle(VFStyle.secondaryText)
                .multilineTextAlignment(.center)
            }
        }
    }

    private var backendSettingsCard: some View {
        NavigationLink {
            BackendSettingsView()
        } label: {
            VFGlassCard {
                HStack(spacing: 13) {
                    VFGradientIcon(icon: "server.rack", tint: VFStyle.electricCyan, size: 38)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(AppText.localized("Backend Settings", "后端设置"))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(VFStyle.ink)
                        Text(AppText.localized("Switch mock/backend modes and endpoints", "切换 Mock/后端模式与接口地址"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(VFStyle.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(VFStyle.secondaryText.opacity(0.55))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var primaryButtonTitle: String {
        if appModel.quota.isPro {
            return AppText.localized("Pro Active", "会员已开通")
        }

        if appModel.isLoadingStoreProducts {
            return AppText.localized("Loading Products...", "正在加载商品...")
        }

        if appModel.isPurchasingSubscription {
            return AppText.localized("Purchasing...", "正在购买...")
        }

        return AppText.localized("Continue", "继续购买")
    }

    private func feature(_ text: String, icon: String, tint: Color) -> some View {
        VFGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                VFGradientIcon(icon: icon, tint: tint, size: 38)
                Text(text)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(VFStyle.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let productPrice: String?
    let isSelected: Bool

    private var tint: Color {
        plan == .yearly ? VFStyle.sunset : VFStyle.primaryRed
    }

    var body: some View {
        VFGlassCard(level: isSelected ? .thick : .thin) {
            HStack(spacing: 13) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(isSelected ? tint : VFStyle.secondaryText.opacity(0.7))

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.headline.weight(.black))
                            .foregroundStyle(VFStyle.ink)
                        if let savingsBadge = plan.savingsBadge {
                            Text(savingsBadge)
                                .font(.caption2.weight(.black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(VFStyle.sunset, in: Capsule())
                        }
                    }
                    Text(plan.subtitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)
                    Text(plan.id)
                        .font(.caption2.monospaced())
                        .foregroundStyle(VFStyle.secondaryText.opacity(0.68))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(plan.localizedPriceHint)
                        .font(.headline.weight(.black))
                        .foregroundStyle(tint)
                    Text("\(productPrice ?? plan.displayPrice) \(plan.billingPeriod)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(VFStyle.secondaryText)
                }
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: isSelected ? 26 : 21)
                .stroke(isSelected ? tint.opacity(0.35) : .clear, lineWidth: 1.4)
        }
    }
}

#Preview {
    NavigationStack {
        PaywallView()
            .environment(AppModel())
    }
}
