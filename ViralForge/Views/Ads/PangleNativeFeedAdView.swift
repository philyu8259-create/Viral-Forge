#if canImport(BUAdSDK)
import BUAdSDK
import SwiftUI
import UIKit

struct PangleNativeFeedAdView: View {
    let placement: AdFeedPlacement
    @State private var renderedHeight: CGFloat = 180

    var body: some View {
        GeometryReader { proxy in
            PangleNativeExpressAdContainer(
                placementID: placement.placementID,
                width: max(proxy.size.width, 1),
                renderedHeight: $renderedHeight
            )
        }
        .frame(height: renderedHeight)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .accessibilityIdentifier("vf.ad.nativeFeed.\(placement.surface.rawValue)")
    }
}

private struct PangleNativeExpressAdContainer: UIViewRepresentable {
    let placementID: String
    let width: CGFloat
    @Binding var renderedHeight: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(renderedHeight: $renderedHeight)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.loadIfNeeded(
            placementID: placementID,
            width: width,
            in: uiView
        )
    }

    final class Coordinator: NSObject, @preconcurrency BUNativeExpressAdViewDelegate, BUCustomEventProtocol {
        private let renderedHeight: Binding<CGFloat>
        private var manager: BUNativeExpressAdManager?
        private weak var containerView: UIView?
        private var loadedPlacementID: String?
        private var loadedWidth: CGFloat = 0

        init(renderedHeight: Binding<CGFloat>) {
            self.renderedHeight = renderedHeight
        }

        @MainActor
        func loadIfNeeded(placementID: String, width: CGFloat, in containerView: UIView) {
            guard width > 1 else { return }
            let roundedWidth = floor(width)
            guard loadedPlacementID != placementID || abs(loadedWidth - roundedWidth) > 1 else {
                return
            }

            self.containerView = containerView
            loadedPlacementID = placementID
            loadedWidth = roundedWidth
            containerView.subviews.forEach { $0.removeFromSuperview() }
            renderedHeight.wrappedValue = 180
            vfNativeAdLog("feed load placement=\(placementID) width=\(roundedWidth)")

            let slot = BUAdSlot()
            slot.id = placementID
            slot.adType = .feed
            slot.position = .feed
            let imageSize = BUSize()
            imageSize.width = Int(roundedWidth)
            imageSize.height = 0
            slot.imgSize = imageSize

            let manager = BUNativeExpressAdManager(
                slot: slot,
                adSize: CGSize(width: roundedWidth, height: 0)
            )
            manager.delegate = self
            self.manager = manager
            manager.mediation?.addParam(true, withKey: "show_adn_load_error_detail")
            manager.loadAdData(withCount: 1)
        }

        @MainActor
        func nativeExpressAdSuccess(toLoad nativeExpressAdManager: BUNativeExpressAdManager, views: [BUNativeExpressAdView]) {
            vfNativeAdLog("feed load success views=\(views.count)")
            guard let adView = views.first else { return }
            adView.rootViewController = UIApplication.vfTopViewController
            adView.render()
        }

        @MainActor
        func nativeExpressAdFail(toLoad nativeExpressAdManager: BUNativeExpressAdManager, error: Error?) {
            vfNativeAdLog("feed load fail error=\(vfDescribeNativeAdError(error))")
            vfNativeAdLog("feed waterfall info=\(vfDescribeNativeAdLoadInfos(nativeExpressAdManager.mediation?.getAdLoadInfoList()))")
            vfNativeAdLog("feed waterfall messages=\(String(describing: nativeExpressAdManager.mediation?.waterfallFillFailMessages()))")
            renderedHeight.wrappedValue = 0.1
        }

        @MainActor
        func nativeExpressAdViewRenderSuccess(_ nativeExpressAdView: BUNativeExpressAdView) {
            vfNativeAdLog("feed render success height=\(nativeExpressAdView.bounds.height) frameHeight=\(nativeExpressAdView.frame.height)")
            guard let containerView else { return }

            containerView.subviews.forEach { $0.removeFromSuperview() }
            nativeExpressAdView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(nativeExpressAdView)

            NSLayoutConstraint.activate([
                nativeExpressAdView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                nativeExpressAdView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                nativeExpressAdView.topAnchor.constraint(equalTo: containerView.topAnchor),
                nativeExpressAdView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])

            let measuredHeight = max(nativeExpressAdView.bounds.height, nativeExpressAdView.frame.height, 120)
            renderedHeight.wrappedValue = measuredHeight
        }

        @MainActor
        func nativeExpressAdViewRenderFail(_ nativeExpressAdView: BUNativeExpressAdView, error: Error?) {
            vfNativeAdLog("feed render fail error=\(vfDescribeNativeAdError(error))")
            renderedHeight.wrappedValue = 0.1
        }

        @MainActor
        func nativeExpressAdViewDidRemoved(_ nativeExpressAdView: BUNativeExpressAdView) {
            vfNativeAdLog("feed removed")
            renderedHeight.wrappedValue = 0.1
        }
    }
}

private func vfNativeAdLog(_ message: String) {
    #if DEBUG
    print("vf_ad_debug: \(message)")
    #endif
}

private func vfDescribeNativeAdError(_ error: Error?) -> String {
    guard let error else { return "nil" }
    let nsError = error as NSError
    return "\(nsError.domain)(\(nsError.code)): \(nsError.localizedDescription) userInfo=\(nsError.userInfo)"
}

private func vfDescribeNativeAdLoadInfos(_ infos: [BUMAdLoadInfo]?) -> String {
    guard let infos, !infos.isEmpty else { return "[]" }
    return infos.map { info in
        let userInfo = info.errUserInfo.map { String(describing: $0) } ?? "nil"
        return "{adn=\(info.adnName), custom=\(info.customAdnName ?? "nil"), rit=\(info.mediationRit), code=\(info.errCode), msg=\(info.errMsg), userInfo=\(userInfo)}"
    }.joined(separator: " | ")
}
#endif
