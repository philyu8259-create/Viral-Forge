import Foundation

protocol AdService: AnyObject {
    var isEnabled: Bool { get }
    var isRewardedTextGenerationEnabled: Bool { get }

    func bootstrap() async
    func requestAppOpenAd() async -> AdPresentationResult
    func requestRewardedTextGeneration() async -> AdRewardResult
    func feedPlacement(for surface: AdSurface) -> AdFeedPlacement?
}

