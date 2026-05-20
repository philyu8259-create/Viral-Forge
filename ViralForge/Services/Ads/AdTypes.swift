import Foundation

enum AdSurface: String, CaseIterable {
    case appOpen
    case rewardedTextGeneration
    case templatesList
    case projectsList
    case historyList
}

enum AdPresentationResult {
    case unavailable
    case shown
    case presentedBySDK
    case suppressed
}

enum AdRewardResult {
    case unavailable
    case granted
    case failed
}

struct AdFeedPlacement: Equatable, Identifiable {
    let id: String
    let surface: AdSurface
    let placementID: String
    let isSDKBacked: Bool
    let title: String
    let subtitle: String
    let actionLabel: String

    init(
        surface: AdSurface,
        placementID: String = AppAdConfiguration.placeholderPlacementID,
        isSDKBacked: Bool = false,
        title: String,
        subtitle: String,
        actionLabel: String
    ) {
        self.id = surface.rawValue
        self.surface = surface
        self.placementID = placementID
        self.isSDKBacked = isSDKBacked
        self.title = title
        self.subtitle = subtitle
        self.actionLabel = actionLabel
    }
}
