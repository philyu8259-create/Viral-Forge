import Foundation

struct AppConfiguration {
    var backendBaseURL: URL?
    var adConfiguration: AppAdConfiguration

    static var current: AppConfiguration {
        let rawBaseURL = Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String
        let trimmedBaseURL = rawBaseURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let configuredURL = URL(string: trimmedBaseURL).flatMap { trimmedBaseURL.isEmpty ? nil : $0 }

        #if DEBUG
        let fallbackURL = URL(string: "https://viralfo-backend-ipiunjbsno.cn-hangzhou.fcapp.run")
        #else
        let fallbackURL: URL? = nil
        #endif

        return AppConfiguration(
            backendBaseURL: configuredURL ?? fallbackURL,
            adConfiguration: AppAdConfiguration(
                isEnabled: readBool(for: "VIRALFORGE_ADS_ENABLED", default: false),
                appOpenEnabled: readBool(for: "VIRALFORGE_ADS_APP_OPEN_ENABLED", default: false),
                rewardedTextGenerationEnabled: readBool(for: "VIRALFORGE_ADS_REWARDED_TEXT_GENERATION_ENABLED", default: false),
                textGenerationRewardDebugGrantEnabled: readBool(
                    for: "VIRALFORGE_ADS_TEXT_GENERATION_REWARD_DEBUG_GRANT_ENABLED",
                    default: false
                ),
                nativeFeedEnabled: readBool(for: "VIRALFORGE_ADS_NATIVE_FEED_ENABLED", default: false),
                showDebugFallbackAds: readBool(for: "VIRALFORGE_ADS_SHOW_DEBUG_FALLBACK_ADS", default: false),
                appId: readString(for: "VIRALFORGE_ADS_APP_ID", default: AppAdConfiguration.placeholderAppId),
                appOpenPlacementID: readString(
                    for: "VIRALFORGE_ADS_APP_OPEN_PLACEMENT_ID",
                    default: AppAdConfiguration.placeholderPlacementID
                ),
                rewardedTextGenerationPlacementID: readString(
                    for: "VIRALFORGE_ADS_REWARDED_TEXT_GENERATION_PLACEMENT_ID",
                    default: AppAdConfiguration.placeholderPlacementID
                ),
                templatesFeedPlacementID: readString(
                    for: "VIRALFORGE_ADS_TEMPLATES_FEED_PLACEMENT_ID",
                    default: AppAdConfiguration.placeholderPlacementID
                ),
                projectsFeedPlacementID: readString(
                    for: "VIRALFORGE_ADS_PROJECTS_FEED_PLACEMENT_ID",
                    default: AppAdConfiguration.placeholderPlacementID
                ),
                historyFeedPlacementID: readString(
                    for: "VIRALFORGE_ADS_HISTORY_FEED_PLACEMENT_ID",
                    default: AppAdConfiguration.placeholderPlacementID
                )
            )
        )
    }

    private static func readString(for key: String, default defaultValue: String) -> String {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return defaultValue
        }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultValue : trimmed
    }

    private static func readBool(for key: String, default defaultValue: Bool) -> Bool {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) else {
            return defaultValue
        }

        if let boolValue = value as? Bool {
            return boolValue
        }

        let normalized = String(describing: value)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch normalized {
        case "1", "true", "yes", "y", "on":
            return true
        case "0", "false", "no", "off", "n":
            return false
        default:
            return defaultValue
        }
    }
}
