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

    static func load(configuration: AppConfiguration = .current) -> BackendSettings {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let settings = try? JSONDecoder().decode(BackendSettings.self, from: data) {
            return settings
        }

        if let configuredURL = configuration.backendBaseURL {
            return BackendSettings(mode: .backend, baseURLString: configuredURL.absoluteString, userId: "demo-user")
        }

        return BackendSettings()
    }

    static func save(_ settings: BackendSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
