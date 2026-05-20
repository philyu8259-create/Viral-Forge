import SwiftUI

struct FeedAdPlaceholderView: View {
    let placement: AdFeedPlacement

    var body: some View {
        if placement.isSDKBacked {
            #if canImport(BUAdSDK)
            PangleNativeFeedAdView(placement: placement)
            #else
            EmptyView()
            #endif
        } else {
            placeholderCard
        }
    }

    private var placeholderCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "megaphone.fill")
                    .font(.title3.weight(.black))
                    .foregroundStyle(VFStyle.primaryRed)
                    .frame(width: 34, height: 34)
                    .background(VFStyle.primaryRed.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(placement.title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(VFStyle.ink)

                    Text(placement.subtitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VFStyle.secondaryText)

                    Text(placement.actionLabel)
                        .font(.caption.weight(.black))
                        .foregroundStyle(VFStyle.primaryRed)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(VFStyle.primaryRed.opacity(0.12), in: Capsule())
                }

                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.84), lineWidth: 1)
        }
        .accessibilityIdentifier("vf.ad.feedCard.\(placement.surface.rawValue)")
    }
}
