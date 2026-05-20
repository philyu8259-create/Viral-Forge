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
                    title: quota.isPro ? AppText.localized("Copy", "文案") : AppText.localized("Copy / day", "文案/天"),
                    value: quota.isPro ? AppText.localized("Unlimited", "不限") : "\(displayedFreeTextQuotaRemaining)/\(freeTextQuotaDailyLimit)",
                    icon: "doc.text",
                    tint: VFStyle.electricCyan
                )
                quotaMetric(
                    title: quota.isPro ? AppText.localized("AI Background", "AI 背景") : AppText.localized("AI Background total", "AI 背景总额"),
                    value: posterQuotaValue,
                    icon: "sparkles.rectangle.stack",
                    tint: VFStyle.purpleFlow
                )
            }

            if quota.isPro, let proPosterUsage = quota.proPosterUsage {
                Text(AppText.localized(
                    "Monthly AI background usage: \(proPosterUsage.monthlyUsed)/\(proPosterUsage.monthlyLimit)",
                    "本月 AI 背景用量：\(proPosterUsage.monthlyUsed)/\(proPosterUsage.monthlyLimit)"
                ))
                .font(.caption2.weight(.bold))
                .foregroundStyle(VFStyle.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if !quota.isPro {
                Text(AppText.localized(
                    "Free copy generation resets to 3 every day. Free AI background generation includes 3 total uses and does not reset.",
                    "免费文案每天限额生成 3 次，次日重置。免费 AI 背景生成一共 3 次，用完不重置。"
                ))
                .font(.caption2.weight(.bold))
                .foregroundStyle(VFStyle.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
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

    private var posterQuotaValue: String {
        guard quota.isPro else { return "\(quota.remainingPosterExports)" }
        guard let proPosterUsage = quota.proPosterUsage else {
            return AppText.localized("0/10 today", "今日 0/10")
        }
        return AppText.localized(
            "\(proPosterUsage.dailyUsed)/\(proPosterUsage.dailyLimit) today",
            "今日 \(proPosterUsage.dailyUsed)/\(proPosterUsage.dailyLimit)"
        )
    }

    private var freeTextQuotaDailyLimit: Int { 3 }

    private var displayedFreeTextQuotaRemaining: Int {
        min(max(0, quota.remainingTextGenerations), freeTextQuotaDailyLimit)
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
        QuotaStatusView(quota: QuotaState(remainingTextGenerations: 3, remainingPosterExports: 3, isPro: false))
        QuotaStatusView(quota: QuotaState(
            remainingTextGenerations: 0,
            remainingPosterExports: 0,
            isPro: true,
            proPosterUsage: ProPosterUsage(dailyUsed: 2, dailyLimit: 10, monthlyUsed: 24, monthlyLimit: 200, dailyKey: "2026-05-08", monthlyKey: "2026-05")
        ))
    }
    .padding()
}
