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
                .font(.headline.weight(.bold))
                .foregroundStyle(quota.isPro ? VFStyle.sunset : VFStyle.primaryRed)
                Spacer()
                if quota.isPro {
                    Text(AppText.localized("Unlimited copy", "文案不限"))
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(VFStyle.sunset, in: Capsule())
                }
            }

            HStack(spacing: 10) {
                quotaMetric(
                    title: AppText.localized("Copy", "文案"),
                    value: quota.isPro ? AppText.localized("Unlimited", "不限") : "\(quota.remainingTextGenerations)",
                    icon: "doc.text",
                    tint: VFStyle.electricCyan
                )
                quotaMetric(
                    title: AppText.localized("AI Background", "AI 背景"),
                    value: quota.isPro ? AppText.localized("Pro", "会员") : "\(quota.remainingPosterExports)",
                    icon: "sparkles.rectangle.stack",
                    tint: VFStyle.purpleFlow
                )
            }
        }
        .padding(compact ? 12 : 14)
        .background(.white.opacity(0.68), in: RoundedRectangle(cornerRadius: 21))
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 21))
        .overlay {
            RoundedRectangle(cornerRadius: 21)
                .stroke(.white.opacity(0.84), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.03), radius: 14, x: 0, y: 8)
    }

    private func quotaMetric(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(tint, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(VFStyle.secondaryText)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(VFStyle.ink)
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
