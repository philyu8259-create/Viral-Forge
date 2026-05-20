import Foundation

struct AppAdConfiguration: Equatable {
    var isEnabled: Bool
    var appOpenEnabled: Bool
    var rewardedTextGenerationEnabled: Bool
    var textGenerationRewardDebugGrantEnabled: Bool
    var nativeFeedEnabled: Bool
    var showDebugFallbackAds: Bool

    var appId: String
    var appOpenPlacementID: String
    var rewardedTextGenerationPlacementID: String
    var templatesFeedPlacementID: String
    var projectsFeedPlacementID: String
    var historyFeedPlacementID: String

    static let placeholderAppId = "TODO_PANGLE_APP_ID"
    static let placeholderPlacementID = "TODO_PANGLE_PLACEMENT_ID"

    static let todoMessage = "TODO: Replace placeholders with real Pangle IDs before production release"

    static let unavailable: AppAdConfiguration = AppAdConfiguration(
        isEnabled: false,
        appOpenEnabled: false,
        rewardedTextGenerationEnabled: false,
        textGenerationRewardDebugGrantEnabled: false,
        nativeFeedEnabled: false,
        showDebugFallbackAds: false,
        appId: placeholderAppId,
        appOpenPlacementID: placeholderPlacementID,
        rewardedTextGenerationPlacementID: placeholderPlacementID,
        templatesFeedPlacementID: placeholderPlacementID,
        projectsFeedPlacementID: placeholderPlacementID,
        historyFeedPlacementID: placeholderPlacementID
    )

    var hasConfiguredAppId: Bool {
        appId != Self.placeholderAppId
    }

    var hasConfiguredAppOpenPlacement: Bool {
        appOpenPlacementID != Self.placeholderPlacementID
    }

    var hasConfiguredRewardPlacement: Bool {
        rewardedTextGenerationPlacementID != Self.placeholderPlacementID
    }

    var hasConfiguredFeedPlacements: Bool {
        templatesFeedPlacementID != Self.placeholderPlacementID
            || projectsFeedPlacementID != Self.placeholderPlacementID
            || historyFeedPlacementID != Self.placeholderPlacementID
    }
}
