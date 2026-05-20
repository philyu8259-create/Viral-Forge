import Foundation

#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
import UIKit

enum TrackingAuthorizationService {
    @MainActor
    static func requestForAdsIfNeeded() async -> TrackingAuthorizationOutcome {
        let currentStatus = ATTrackingManager.trackingAuthorizationStatus
        guard currentStatus == .notDetermined else {
            return .alreadyDetermined(currentStatus.vfDebugName)
        }

        await waitUntilAppIsActive()
        try? await Task.sleep(nanoseconds: 600_000_000)

        let updatedStatus = await ATTrackingManager.requestTrackingAuthorization()
        return .requested(updatedStatus.vfDebugName)
    }

    @MainActor
    private static func waitUntilAppIsActive() async {
        for _ in 0..<10 {
            if UIApplication.shared.applicationState == .active {
                return
            }
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
    }
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
#else
enum TrackingAuthorizationService {
    @MainActor
    static func requestForAdsIfNeeded() async -> TrackingAuthorizationOutcome {
        .unavailable
    }
}
#endif

enum TrackingAuthorizationOutcome: Equatable {
    case requested(String)
    case alreadyDetermined(String)
    case unavailable
}
