import SwiftUI

struct PaywallView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selectedPlan = SubscriptionPlan.yearly

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("ViralForge Pro")
                        .font(.largeTitle.weight(.bold))
                    Text(AppText.localized(
                        "Unlock higher generation limits, premium poster templates, brand memory, and watermark-free exports.",
                        "解锁更高生成额度、会员海报模板、品牌记忆和无水印导出。"
                    ))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                QuotaStatusView(quota: appModel.quota)

                VStack(spacing: 12) {
                    feature(AppText.localized("Unlimited copy generation", "不限文案生成"), icon: "sparkles")
                    feature(AppText.localized("100 AI backgrounds per month", "每月 100 张 AI 背景"), icon: "sparkles.rectangle.stack")
                    feature(AppText.localized("Batch creation and premium templates", "批量创作和会员模板"), icon: "rectangle.3.group")
                    feature(AppText.localized("No watermark exports", "无水印导出"), icon: "checkmark.seal")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(AppText.localized("Choose Plan", "选择方案"))
                        .font(.headline)

                    ForEach(SubscriptionPlan.all) { plan in
                        Button {
                            selectedPlan = plan
                        } label: {
                            SubscriptionPlanRow(
                                plan: plan,
                                productPrice: appModel.product(for: plan)?.displayPrice,
                                isSelected: selectedPlan == plan
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(spacing: 12) {
                    Button {
                        Task {
                            await appModel.purchaseSubscription(plan: selectedPlan)
                        }
                    } label: {
                        Text(primaryButtonTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(appModel.quota.isPro || appModel.isPurchasingSubscription || appModel.isLoadingStoreProducts)

                    Button {
                        Task {
                            await appModel.restorePurchases()
                        }
                    } label: {
                        Text(AppText.localized("Restore Purchases", "恢复购买"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(appModel.isPurchasingSubscription)

                    if let purchaseStatusMessage = appModel.purchaseStatusMessage {
                        Text(purchaseStatusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Text(AppText.localized(
                        "Purchases use StoreKit. Local testing uses the bundled StoreKit configuration; production products must also be created in App Store Connect.",
                        "购买已接入 StoreKit。本地测试使用内置 StoreKit 配置；正式上架还需要在 App Store Connect 创建同 ID 商品。"
                    ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                NavigationLink {
                    BackendSettingsView()
                } label: {
                    Label(AppText.localized("Backend Settings", "后端设置"), systemImage: "server.rack")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
            }
            .padding()
        }
        .navigationTitle(AppText.localized("Pro", "会员"))
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

    private func feature(_ text: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 28)
            Text(text)
                .font(.headline)
            Spacer()
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SubscriptionPlanRow: View {
    let plan: SubscriptionPlan
    let productPrice: String?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(plan.title)
                        .font(.headline)
                    if let savingsBadge = plan.savingsBadge {
                        Text(savingsBadge)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.thinMaterial, in: Capsule())
                    }
                }
                Text(plan.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(plan.id)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(plan.localizedPriceHint)
                    .font(.headline)
                Text("\(productPrice ?? plan.displayPrice) \(plan.billingPeriod)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        }
    }
}

#Preview {
    NavigationStack {
        PaywallView()
            .environment(AppModel())
    }
}
