import Foundation

enum SubscriptionProductID {
    static let monthly = "viralforge_pro_monthly"
    static let yearly = "viralforge_pro_yearly"
    static let all = [monthly, yearly]

    static func sortIndex(for productID: String) -> Int {
        all.firstIndex(of: productID) ?? all.count
    }
}

struct SubscriptionPlan: Identifiable, Hashable {
    let id: String
    var title: String
    var subtitle: String
    var displayPrice: String
    var localizedPriceHint: String
    var billingPeriod: String
    var savingsBadge: String?

    static let monthly = SubscriptionPlan(
        id: SubscriptionProductID.monthly,
        title: AppText.localized("ViralForge Pro Monthly", "ViralForge Pro 月度会员"),
        subtitle: AppText.localized("Flexible monthly access", "按月灵活使用"),
        displayPrice: "¥39.8",
        localizedPriceHint: "¥39.8/月",
        billingPeriod: AppText.localized("per month", "每月"),
        savingsBadge: nil
    )

    static let yearly = SubscriptionPlan(
        id: SubscriptionProductID.yearly,
        title: AppText.localized("ViralForge Pro Yearly", "ViralForge Pro 年度会员"),
        subtitle: AppText.localized("Best value for serious creators", "适合长期创作"),
        displayPrice: "¥398",
        localizedPriceHint: "¥398/年",
        billingPeriod: AppText.localized("per year", "每年"),
        savingsBadge: AppText.localized("Best Value", "更划算")
    )

    static let all = [monthly, yearly]
}
