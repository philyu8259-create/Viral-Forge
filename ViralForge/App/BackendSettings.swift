import Foundation

enum BackendMode: String, CaseIterable, Codable, Identifiable {
    case mock = "Mock"
    case backend = "Backend"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mock: AppText.localized("Mock", "模拟")
        case .backend: AppText.localized("Backend", "后端")
        }
    }
}

struct BackendSettings: Codable, Equatable {
    var mode: BackendMode = .mock
    var baseURLString = ""
    var userId = "demo-user"

    var baseURL: URL? {
        URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

enum BackendSettingsStore {
    private static let storageKey = "viralforge.backend.settings"
    private static let anonymousUserIdKey = "viralforge.backend.anonymousUserId"

    static func load(configuration: AppConfiguration = .current) -> BackendSettings {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let settings = try? JSONDecoder().decode(BackendSettings.self, from: data) {
            if settings.mode == .backend,
               let configuredURL = configuration.backendBaseURL,
               isLocalhost(settings.baseURL),
               !isLocalhost(configuredURL) {
                let migratedSettings = BackendSettings(
                    mode: .backend,
                    baseURLString: configuredURL.absoluteString,
                    userId: settings.userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? anonymousUserId() : settings.userId
                )
                save(migratedSettings)
                return migratedSettings
            }
            return settings
        }

        if let configuredURL = configuration.backendBaseURL {
            return BackendSettings(mode: .backend, baseURLString: configuredURL.absoluteString, userId: anonymousUserId())
        }

        return BackendSettings()
    }

    static func save(_ settings: BackendSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private static func anonymousUserId() -> String {
        if let stored = UserDefaults.standard.string(forKey: anonymousUserIdKey),
           !stored.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return stored
        }

        let userId = "vf-\(UUID().uuidString.lowercased())"
        UserDefaults.standard.set(userId, forKey: anonymousUserIdKey)
        return userId
    }

    private static func isLocalhost(_ url: URL?) -> Bool {
        guard let host = url?.host()?.lowercased() else { return false }
        return host == "localhost" || host == "127.0.0.1" || host == "::1"
    }
}
