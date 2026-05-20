import Foundation

#if canImport(BUAdSDK)
import AdSupport
import AppTrackingTransparency
import BUAdSDK
import UIKit

private let adLoadDetailDebugParamKey = "show_adn_load_error_detail"

final class PangleAdService: NSObject, AdService {
    private let configuration: AppAdConfiguration
    private var didStartSDK = false
    private var splashPresenter: PangleSplashAdPresenter?
    private var rewardedPresenter: PangleRewardedAdPresenter?

    init(configuration: AppAdConfiguration) {
        self.configuration = configuration
    }

    var isEnabled: Bool {
        configuration.isEnabled && configuration.hasConfiguredAppId
    }

    var isRewardedTextGenerationEnabled: Bool {
        isEnabled && configuration.rewardedTextGenerationEnabled && configuration.hasConfiguredRewardPlacement
    }

    func bootstrap() async {
        guard isEnabled else {
            vfAdLog("sdk bootstrap skipped: disabled appId=\(configuration.appId)")
            return
        }
        guard !didStartSDK else {
            vfAdLog("sdk bootstrap skipped: already started")
            return
        }
        didStartSDK = true

        await requestTrackingAuthorizationIfNeeded()

        await MainActor.run {
            let sdkConfiguration = BUAdSDKConfiguration.configuration()
            sdkConfiguration.appID = configuration.appId
            sdkConfiguration.useMediation = true
            #if DEBUG
            sdkConfiguration.sdkdebug = true
            sdkConfiguration.debugLog = NSNumber(value: 1)
            #endif
            vfAdLog("sdk configuration appId=\(configuration.appId) useMediation=true")
        }

        do {
            try await BUAdSDKManager.startWithAsyncCompletionHandler()
            vfAdLog("sdk start success")
            try? await Task.sleep(nanoseconds: 1_200_000_000)
        } catch {
            vfAdLog("sdk start error=\(describeAdError(error))")
        }
    }

    func requestAppOpenAd() async -> AdPresentationResult {
        guard isEnabled, configuration.appOpenEnabled, configuration.hasConfiguredAppOpenPlacement else {
            vfAdLog("appOpen skipped enabled=\(isEnabled) appOpenEnabled=\(configuration.appOpenEnabled) placement=\(configuration.appOpenPlacementID)")
            return .unavailable
        }

        await bootstrap()

        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                guard let rootViewController = UIApplication.vfTopViewController else {
                    vfAdLog("appOpen unavailable: missing rootViewController")
                    continuation.resume(returning: .unavailable)
                    return
                }

                vfAdLog("appOpen load placement=\(configuration.appOpenPlacementID) root=\(type(of: rootViewController))")
                let presenter = PangleSplashAdPresenter(
                    slotID: configuration.appOpenPlacementID,
                    rootViewController: rootViewController
                ) { [weak self] result in
                    vfAdLog("appOpen completion result=\(result)")
                    self?.splashPresenter = nil
                    continuation.resume(returning: result)
                }
                splashPresenter = presenter
                presenter.load()
            }
        }
    }

    func requestRewardedTextGeneration() async -> AdRewardResult {
        guard isRewardedTextGenerationEnabled else {
            vfAdLog("reward skipped enabled=\(isEnabled) rewardEnabled=\(configuration.rewardedTextGenerationEnabled) placement=\(configuration.rewardedTextGenerationPlacementID)")
            return .unavailable
        }

        await bootstrap()

        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                guard let rootViewController = UIApplication.vfTopViewController else {
                    vfAdLog("reward unavailable: missing rootViewController")
                    continuation.resume(returning: .unavailable)
                    return
                }

                vfAdLog("reward load placement=\(configuration.rewardedTextGenerationPlacementID) root=\(type(of: rootViewController))")
                let presenter = PangleRewardedAdPresenter(
                    slotID: configuration.rewardedTextGenerationPlacementID,
                    rootViewController: rootViewController
                ) { [weak self] result in
                    vfAdLog("reward completion result=\(result)")
                    self?.rewardedPresenter = nil
                    continuation.resume(returning: result)
                }
                rewardedPresenter = presenter
                presenter.load()
            }
        }
    }

    func feedPlacement(for surface: AdSurface) -> AdFeedPlacement? {
        guard isEnabled, configuration.nativeFeedEnabled else {
            vfAdLog("feed skipped surface=\(surface.rawValue) enabled=\(isEnabled) nativeFeedEnabled=\(configuration.nativeFeedEnabled)")
            return nil
        }

        let placementID: String
        switch surface {
        case .templatesList:
            placementID = configuration.templatesFeedPlacementID
        case .projectsList:
            placementID = configuration.projectsFeedPlacementID
        case .historyList:
            placementID = configuration.historyFeedPlacementID
        case .appOpen, .rewardedTextGeneration:
            return nil
        }

        guard placementID != AppAdConfiguration.placeholderPlacementID else {
            vfAdLog("feed skipped surface=\(surface.rawValue) reason=placeholder")
            return nil
        }

        vfAdLog("feed configured surface=\(surface.rawValue) placement=\(placementID)")
        return AdFeedPlacement(
            surface: surface,
            placementID: placementID,
            isSDKBacked: true,
            title: "Sponsored",
            subtitle: "Native feed ad",
            actionLabel: "Ad"
        )
    }
}

@MainActor
private func requestTrackingAuthorizationIfNeeded() async {
    let status = ATTrackingManager.trackingAuthorizationStatus
    if status == .notDetermined {
        let updatedStatus = await ATTrackingManager.requestTrackingAuthorization()
        vfAdLog("tracking authorization status=\(updatedStatus.vfDebugName)")
    } else {
        vfAdLog("tracking authorization status=\(status.vfDebugName)")
    }

    #if DEBUG
    let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
    vfAdLog("idfa=\(idfa)")
    #endif
}

private extension ATTrackingManager.AuthorizationStatus {
    var vfDebugName: String {
        switch self {
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorized:
            return "authorized"
        @unknown default:
            return "unknown"
        }
    }
}

private final class PangleSplashAdPresenter: NSObject, BUSplashAdDelegate {
    private let rootViewController: UIViewController
    private let completion: (AdPresentationResult) -> Void
    private var ad: BUSplashAd?
    private var didShow = false
    private var didFinish = false

    init(slotID: String, rootViewController: UIViewController, completion: @escaping (AdPresentationResult) -> Void) {
        self.rootViewController = rootViewController
        self.completion = completion
        super.init()

        let ad = BUSplashAd(slotID: slotID, adSize: UIScreen.main.bounds.size)
        ad.delegate = self
        ad.tolerateTimeout = 3
        self.ad = ad
    }

    func load() {
        vfAdLog("splash loadData")
        ad?.mediation?.addParam(true, withKey: adLoadDetailDebugParamKey)
        ad?.loadData()
    }

    func splashAdLoadSuccess(_ splashAd: BUSplashAd) {
        vfAdLog("splash load success")
        splashAd.showSplashView(inRootViewController: rootViewController)
    }

    func splashAdLoadFail(_ splashAd: BUSplashAd, error: BUAdError?) {
        vfAdLog("splash load fail error=\(describeAdError(error))")
        vfAdLog("splash waterfall info=\(describeAdLoadInfos(splashAd.mediation?.getAdLoadInfoList()))")
        vfAdLog("splash waterfall messages=\(String(describing: splashAd.mediation?.waterfallFillFailMessages()))")
        finish(.unavailable)
    }

    func splashAdRenderFail(_ splashAd: BUSplashAd, error: BUAdError?) {
        vfAdLog("splash render fail error=\(describeAdError(error))")
        vfAdLog("splash waterfall info=\(describeAdLoadInfos(splashAd.mediation?.getAdLoadInfoList()))")
        finish(.unavailable)
    }

    func splashAdRenderSuccess(_ splashAd: BUSplashAd) {
        vfAdLog("splash render success")
    }

    func splashAdWillShow(_ splashAd: BUSplashAd) {
        vfAdLog("splash will show")
    }

    func splashAdDidShow(_ splashAd: BUSplashAd) {
        vfAdLog("splash did show")
        didShow = true
    }

    func splashAdDidClick(_ splashAd: BUSplashAd) {
        vfAdLog("splash did click")
    }

    func splashAdDidClose(_ splashAd: BUSplashAd, closeType: BUSplashAdCloseType) {
        vfAdLog("splash did close closeType=\(closeType.rawValue) didShow=\(didShow)")
        finish(didShow ? .presentedBySDK : .suppressed)
    }

    func splashAdViewControllerDidClose(_ splashAd: BUSplashAd) {
        vfAdLog("splash view controller did close didShow=\(didShow)")
        finish(didShow ? .presentedBySDK : .suppressed)
    }

    func splashDidCloseOtherController(_ splashAd: BUSplashAd, interactionType: BUInteractionType) {}

    func splashVideoAdDidPlayFinish(_ splashAd: BUSplashAd, didFailWithError error: Error?) {
        vfAdLog("splash video finish error=\(describeAdError(error))")
    }

    private func finish(_ result: AdPresentationResult) {
        guard !didFinish else { return }
        didFinish = true
        ad = nil
        completion(result)
    }
}

private final class PangleRewardedAdPresenter: NSObject, BUMNativeExpressRewardedVideoAdDelegate {
    private let rootViewController: UIViewController
    private let completion: (AdRewardResult) -> Void
    private var ad: BUNativeExpressRewardedVideoAd?
    private var didEarnReward = false
    private var didFinish = false

    init(slotID: String, rootViewController: UIViewController, completion: @escaping (AdRewardResult) -> Void) {
        self.rootViewController = rootViewController
        self.completion = completion
        super.init()

        let model = BURewardedVideoModel()
        model.userId = UUID().uuidString
        model.rewardName = "text_generation"
        model.rewardAmount = 1

        let ad = BUNativeExpressRewardedVideoAd(slotID: slotID, rewardedVideoModel: model)
        ad.delegate = self
        self.ad = ad
    }

    func load() {
        vfAdLog("reward loadData")
        ad?.mediation?.addParam(true, withKey: adLoadDetailDebugParamKey)
        ad?.loadData()
    }

    func nativeExpressRewardedVideoAd(_ rewardedVideoAd: BUNativeExpressRewardedVideoAd, didFailWithError error: Error?) {
        vfAdLog("reward load fail error=\(describeAdError(error))")
        vfAdLog("reward waterfall info=\(describeAdLoadInfos(rewardedVideoAd.mediation?.getAdLoadInfoList()))")
        vfAdLog("reward waterfall messages=\(String(describing: rewardedVideoAd.mediation?.waterfallFillFailMessages()))")
        finish(.unavailable)
    }

    func nativeExpressRewardedVideoAdDidLoad(_ rewardedVideoAd: BUNativeExpressRewardedVideoAd) {
        vfAdLog("reward did load")
    }

    func nativeExpressRewardedVideoAdDidDownLoadVideo(_ rewardedVideoAd: BUNativeExpressRewardedVideoAd) {
        vfAdLog("reward video downloaded")
        guard rewardedVideoAd.show(fromRootViewController: rootViewController) else {
            vfAdLog("reward show returned false")
            finish(.failed)
            return
        }
    }

    func nativeExpressRewardedVideoAdDidPlayFinish(_ rewardedVideoAd: BUNativeExpressRewardedVideoAd, didFailWithError error: Error?) {
        vfAdLog("reward play finish error=\(describeAdError(error))")
        if error == nil {
            didEarnReward = true
        }
    }

    func nativeExpressRewardedVideoAdServerRewardDidSucceed(_ rewardedVideoAd: BUNativeExpressRewardedVideoAd, verify: Bool) {
        vfAdLog("reward server success verify=\(verify)")
        didEarnReward = verify
    }

    func nativeExpressRewardedVideoAdServerRewardDidFail(_ rewardedVideoAd: BUNativeExpressRewardedVideoAd, error: Error?) {
        vfAdLog("reward server fail error=\(describeAdError(error))")
    }

    func nativeExpressRewardedVideoAdDidShowFailed(_ rewardedVideoAd: BUNativeExpressRewardedVideoAd, error: Error) {
        vfAdLog("reward show failed error=\(describeAdError(error))")
        vfAdLog("reward waterfall info=\(describeAdLoadInfos(rewardedVideoAd.mediation?.getAdLoadInfoList()))")
    }

    func nativeExpressRewardedVideoAdDidClose(_ rewardedVideoAd: BUNativeExpressRewardedVideoAd) {
        vfAdLog("reward did close didEarnReward=\(didEarnReward)")
        finish(didEarnReward ? .granted : .failed)
    }

    private func finish(_ result: AdRewardResult) {
        guard !didFinish else { return }
        didFinish = true
        ad = nil
        completion(result)
    }
}

@MainActor
extension UIApplication {
    static var vfTopViewController: UIViewController? {
        let rootViewController = shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController

        return rootViewController?.vfTopMostViewController()
    }
}

extension UIViewController {
    func vfTopMostViewController() -> UIViewController {
        if let presentedViewController {
            return presentedViewController.vfTopMostViewController()
        }
        if let navigationController = self as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return visibleViewController.vfTopMostViewController()
        }
        if let tabBarController = self as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return selectedViewController.vfTopMostViewController()
        }
        return self
    }
}

private func vfAdLog(_ message: String) {
    #if DEBUG
    print("vf_ad_debug: \(message)")
    #endif
}

private func describeAdError(_ error: Any?) -> String {
    guard let error else { return "nil" }
    if let nsError = error as? NSError {
        return "\(nsError.domain)(\(nsError.code)): \(nsError.localizedDescription) userInfo=\(nsError.userInfo)"
    }
    return String(describing: error)
}

private func describeAdLoadInfos(_ infos: [BUMAdLoadInfo]?) -> String {
    guard let infos, !infos.isEmpty else { return "[]" }
    return infos.map { info in
        let userInfo = info.errUserInfo.map { String(describing: $0) } ?? "nil"
        return "{adn=\(info.adnName), custom=\(info.customAdnName ?? "nil"), rit=\(info.mediationRit), code=\(info.errCode), msg=\(info.errMsg), userInfo=\(userInfo)}"
    }.joined(separator: " | ")
}
#endif
