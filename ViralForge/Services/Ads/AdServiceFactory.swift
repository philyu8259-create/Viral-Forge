import Foundation

enum AdServiceFactory {
    static func make(with configuration: AppAdConfiguration) -> AdService {
        guard configuration.isEnabled else {
            return NoopAdService(configuration: configuration)
        }

        if configuration.showDebugFallbackAds {
            return NoopAdService(configuration: configuration)
        }

        #if canImport(BUAdSDK)
        return PangleAdService(configuration: configuration)
        #else
        return NoopAdService(configuration: configuration)
        #endif
    }
}
