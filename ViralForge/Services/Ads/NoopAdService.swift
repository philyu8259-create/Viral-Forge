import Foundation

final class NoopAdService: AdService {
    private let configuration: AppAdConfiguration

    init(configuration: AppAdConfiguration) {
        self.configuration = configuration
    }

    var isEnabled: Bool {
        configuration.isEnabled
    }

    var isRewardedTextGenerationEnabled: Bool {
        configuration.isEnabled && configuration.rewardedTextGenerationEnabled
    }

    var isDebugFallbackEnabled: Bool {
        configuration.showDebugFallbackAds
    }

    func bootstrap() async {
        // No-op implementation for builds without Pangle SDK.
    }

    func requestAppOpenAd() async -> AdPresentationResult {
        guard isEnabled, configuration.appOpenEnabled else {
            return .unavailable
        }

        guard isDebugFallbackEnabled else {
            return .suppressed
        }
        return .shown
    }

    func requestRewardedTextGeneration() async -> AdRewardResult {
        guard isRewardedTextGenerationEnabled else {
            return .unavailable
        }
        guard isDebugFallbackEnabled else {
            return .unavailable
        }

        // In debug/no-SDK mode, reward is currently disabled by default unless this
        // explicit feature toggle is enabled in AppConfiguration.
        guard configuration.textGenerationRewardDebugGrantEnabled else {
            return .unavailable
        }

        return .granted
    }

    func feedPlacement(for surface: AdSurface) -> AdFeedPlacement? {
        guard isEnabled, configuration.nativeFeedEnabled else {
            return nil
        }
        guard surface != .appOpen && surface != .rewardedTextGeneration else {
            return nil
        }

        let isPlaceholder = !configuration.hasConfiguredFeedPlacements
        guard isPlaceholder || isDebugFallbackEnabled else {
            return nil
        }

        switch surface {
        case .templatesList:
            return AdFeedPlacement(
                surface: surface,
                title: "Sponsored Templates",
                subtitle: "Ad placement from template feed (placeholder configuration active)",
                actionLabel: isPlaceholder ? "Configure Pangle placement" : "View sponsored content"
            )
        case .projectsList:
            return AdFeedPlacement(
                surface: surface,
                title: "Sponsored Projects",
                subtitle: "Ad placement from project list (placeholder configuration active)",
                actionLabel: isPlaceholder ? "Configure Pangle placement" : "View sponsored content"
            )
        case .historyList:
            return AdFeedPlacement(
                surface: surface,
                title: "Sponsored History",
                subtitle: "Ad placement from history list (placeholder configuration active)",
                actionLabel: isPlaceholder ? "Configure Pangle placement" : "View sponsored content"
            )
        case .appOpen, .rewardedTextGeneration:
            return nil
        }
    }
}
