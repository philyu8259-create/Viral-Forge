import SwiftUI

struct QuotaStatusView: View {
    let quota: QuotaState
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            HStack {
                Label(
                    quota.isPro ? AppText.localized("Pro Active", "会员已开通") : AppText.localized("Free Plan", "免费版"),
                    systemImage: quota.isPro ? "crown.fill" : "sparkles"
                )
                .font(.headline)
                Spacer()
                if quota.isPro {
                    Text(AppText.localized("Unlimited copy", "文案不限"))
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.thinMaterial, in: Capsule())
                }
            }

            HStack(spacing: 10) {
                quotaMetric(
                    title: AppText.localized("Copy", "文案"),
                    value: quota.isPro ? AppText.localized("Unlimited", "不限") : "\(quota.remainingTextGenerations)",
                    icon: "doc.text"
                )
                quotaMetric(
                    title: AppText.localized("AI Background", "AI 背景"),
                    value: quota.isPro ? AppText.localized("Pro", "会员") : "\(quota.remainingPosterExports)",
                    icon: "sparkles.rectangle.stack"
                )
            }
        }
        .padding(compact ? 12 : 14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
    }

    private func quotaMetric(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack {
        QuotaStatusView(quota: QuotaState(remainingTextGenerations: 3, remainingPosterExports: 1, isPro: false))
        QuotaStatusView(quota: QuotaState(remainingTextGenerations: 0, remainingPosterExports: 0, isPro: true))
    }
    .padding()
}
