import SwiftUI
import UIKit

enum VFStyle {
    static let primaryRed = Color(red: 1.0, green: 0.23, blue: 0.19)
    static let sunset = Color(red: 1.0, green: 0.58, blue: 0.0)
    static let auroraPink = Color(red: 1.0, green: 0.27, blue: 0.57)
    static let purpleFlow = Color(red: 0.69, green: 0.32, blue: 0.87)
    static let electricCyan = Color(red: 0.0, green: 0.76, blue: 0.95)
    static let teal = Color(red: 0.29, green: 0.79, blue: 0.73)
    static let accent = Color(red: 0.35, green: 0.34, blue: 0.84)
    static let ink = Color(red: 0.13, green: 0.16, blue: 0.22)
    static let secondaryText = Color(red: 0.48, green: 0.53, blue: 0.60)
    static let warning = Color(red: 0.86, green: 0.34, blue: 0.22)

    static let brandGradient = LinearGradient(
        colors: [primaryRed, sunset, accent],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let ctaGradient = LinearGradient(
        colors: [primaryRed, sunset, accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func platformTint(_ platform: SocialPlatform) -> Color {
        switch platform {
        case .xiaohongshu: primaryRed
        case .douyin: purpleFlow
        case .weChat: teal
        case .tikTok: accent
        case .instagram: auroraPink
        case .youtubeShorts: sunset
        }
    }

    static func templateTint(_ category: TemplateCategory) -> Color {
        switch category {
        case .productSeeding: primaryRed
        case .storeTraffic: electricCyan
        case .personalBrand: purpleFlow
        case .liveLaunch: sunset
        case .seasonalPromo: auroraPink
        case .newLaunch: teal
        }
    }
}

struct VFBackground: View {
    var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation) { timeline in
                let seconds = timeline.date.timeIntervalSinceReferenceDate
                let rotation = Angle.degrees(seconds.truncatingRemainder(dividingBy: 18) * 20)

                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.985, blue: 0.975),
                            Color(red: 0.965, green: 0.978, blue: 1.0),
                            Color(red: 0.995, green: 0.998, blue: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [VFStyle.primaryRed.opacity(0.13), VFStyle.auroraPink.opacity(0.05), .clear],
                                center: .center,
                                startRadius: 12,
                                endRadius: 280
                            )
                        )
                        .frame(width: 560, height: 560)
                        .blur(radius: 54)
                        .offset(x: -220, y: -300)
                        .rotationEffect(rotation)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [VFStyle.sunset.opacity(0.14), VFStyle.primaryRed.opacity(0.05), .clear],
                                center: .center,
                                startRadius: 8,
                                endRadius: 230
                            )
                        )
                        .frame(width: 430, height: 430)
                        .blur(radius: 60)
                        .offset(x: 210, y: -110)
                        .rotationEffect(-rotation)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [VFStyle.electricCyan.opacity(0.12), VFStyle.purpleFlow.opacity(0.06), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 250
                            )
                        )
                        .frame(width: 500, height: 500)
                        .blur(radius: 72)
                        .offset(x: 170, y: 455)
                        .rotationEffect(Angle.degrees(rotation.degrees * 0.6))
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
            }
        }
        .ignoresSafeArea()
    }
}

struct VFPage<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    content
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 110)
            }
            .scrollDismissesKeyboard(.interactively)
            .simultaneousGesture(
                TapGesture().onEnded {
                    UIApplication.shared.vfDismissKeyboard()
                }
            )
        }
        .background {
            VFBackground()
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .preferredColorScheme(.light)
    }
}

private extension UIApplication {
    func vfDismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct VFPageHeader: View {
    let title: String
    let subtitle: String
    var icon: String = "sparkles"
    var tint: Color = VFStyle.primaryRed

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(VFStyle.brandGradient)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(VFStyle.secondaryText)
            }

            Spacer()

            VFGradientIcon(icon: icon, tint: tint, size: 44)
        }
    }
}

struct VFSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(VFStyle.ink)
            Text(subtitle)
                .font(.caption.weight(.medium))
                .foregroundStyle(VFStyle.secondaryText)
        }
        .padding(.leading, 4)
    }
}

struct VFGlassCard<Content: View>: View {
    enum Level {
        case thin
        case thick
    }

    var level: Level = .thin
    let content: Content

    init(level: Level = .thin, @ViewBuilder content: () -> Content) {
        self.level = level
        self.content = content()
    }

    var body: some View {
        content
            .padding(level == .thick ? 18 : 15)
            .background(.white.opacity(level == .thick ? 0.80 : 0.64), in: RoundedRectangle(cornerRadius: level == .thick ? 26 : 21))
            .background(level == .thick ? .thinMaterial : .ultraThinMaterial, in: RoundedRectangle(cornerRadius: level == .thick ? 26 : 21))
            .overlay {
                RoundedRectangle(cornerRadius: level == .thick ? 26 : 21)
                    .stroke(.white.opacity(level == .thick ? 0.90 : 0.80), lineWidth: 1.1)
            }
            .shadow(color: .white.opacity(0.70), radius: 12, x: -4, y: -5)
            .shadow(color: .black.opacity(level == .thick ? 0.04 : 0.028), radius: level == .thick ? 22 : 16, x: 0, y: level == .thick ? 11 : 8)
    }
}

struct VFGradientIcon: View {
    let icon: String
    var tint: Color = VFStyle.primaryRed
    var size: CGFloat = 38

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.42, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: [tint.opacity(0.98), tint.opacity(0.66)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: size * 0.34)
            )
            .overlay {
                RoundedRectangle(cornerRadius: size * 0.34)
                    .stroke(.white.opacity(0.44), lineWidth: 1)
            }
            .shadow(color: tint.opacity(0.28), radius: 10, x: 0, y: 6)
    }
}

struct VFEmptyMomentumVisual: View {
    let icon: String
    let tint: Color
    var secondary: Color = VFStyle.sunset

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.16))
                .frame(width: 160, height: 160)
                .blur(radius: 22)
                .offset(x: -42, y: -28)

            Circle()
                .fill(secondary.opacity(0.15))
                .frame(width: 132, height: 132)
                .blur(radius: 24)
                .offset(x: 48, y: 26)

            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.76))
                .frame(width: 190, height: 118)
                .rotationEffect(.degrees(-5))
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 8) {
                        Capsule()
                            .fill(tint.opacity(0.72))
                            .frame(width: 68, height: 10)
                        Capsule()
                            .fill(VFStyle.ink.opacity(0.12))
                            .frame(width: 118, height: 8)
                        Capsule()
                            .fill(VFStyle.ink.opacity(0.08))
                            .frame(width: 92, height: 8)
                    }
                    .padding(18)
                }
                .shadow(color: tint.opacity(0.13), radius: 20, x: 0, y: 12)

            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.95), secondary.opacity(0.90)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 78, height: 100)
                .rotationEffect(.degrees(8))
                .offset(x: 52, y: 6)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(.white)
                }
                .shadow(color: tint.opacity(0.24), radius: 18, x: 0, y: 10)

            Image(systemName: "sparkles")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(secondary)
                .offset(x: -72, y: -52)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 148)
    }
}

struct VFPrimaryButton: View {
    let title: String
    let icon: String
    var isLoading = false
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(isEnabled ? .white : VFStyle.secondaryText)
                } else {
                    Image(systemName: icon)
                        .font(.headline.weight(.bold))
                }
                Text(title)
                    .font(.headline.weight(.bold))
            }
            .foregroundStyle(isEnabled ? .white : VFStyle.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                Capsule()
                    .fill(isEnabled ? VFStyle.ctaGradient : LinearGradient(colors: [.white.opacity(0.74), .white.opacity(0.54)], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .overlay {
                Capsule()
                    .stroke(isEnabled ? .white.opacity(0.48) : .white.opacity(0.80), lineWidth: 1)
            }
            .shadow(color: VFStyle.primaryRed.opacity(isEnabled ? 0.24 : 0.06), radius: 18, x: 0, y: 9)
            .opacity(isEnabled ? 1 : 0.86)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
