import SwiftUI

struct AdSplashPlaceholderView: View {
    let onClose: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.14, green: 0.16, blue: 0.28), Color(red: 0.23, green: 0.17, blue: 0.38)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("ViralForge")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(AppText.localized(
                        "Ad experience placeholder",
                        "广告位占位（当前环境未接入真实 SDK）"
                    ))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.86))
                    .multilineTextAlignment(.center)
                }

                RoundedRectangle(cornerRadius: 22)
                    .fill(.white.opacity(0.12))
                    .frame(height: 220)
                    .overlay(
                        VStack(spacing: 10) {
                            Image(systemName: "sparkles.rectangle.stack")
                                .font(.system(size: 42, weight: .black))
                                .foregroundStyle(.white)

                            Text(AppText.localized(
                                "Sponsored experience placeholder",
                                "示例广告位"
                            ))
                            .font(.subheadline.weight(.black))
                            .foregroundStyle(.white)

                            Text(AppText.localized(
                                "Integrate PangleAppOpenAd SDK with real placement IDs in production.",
                                "待接入 PangleAppOpenAd，并使用正式 Placement ID。"
                            ))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                        }
                    )
                    .padding(.horizontal, 32)

                Button {
                    onClose()
                } label: {
                    Text(AppText.localized("Continue", "继续"))
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color(red: 0.16, green: 0.16, blue: 0.16))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white, in: Capsule())
                }
                .padding(.horizontal, 48)
                .accessibilityIdentifier("vf.ad.splash.closeButton")
            }
            .padding(20)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.92))
            }
            .padding(.top, 16)
            .padding(.trailing, 16)
            .accessibilityLabel(AppText.localized("Close", "关闭"))
            .accessibilityIdentifier("vf.ad.splash.closeIcon")
        }
        .accessibilityIdentifier("vf.ad.splash")
    }
}

