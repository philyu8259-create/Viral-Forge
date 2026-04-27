import Foundation

struct AppConfiguration {
    var backendBaseURL: URL?

    static var current: AppConfiguration {
        let rawBaseURL = Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String
        let trimmedBaseURL = rawBaseURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let configuredURL = URL(string: trimmedBaseURL).flatMap { trimmedBaseURL.isEmpty ? nil : $0 }

        #if DEBUG
        let fallbackURL = URL(string: "http://localhost:8787")
        #else
        let fallbackURL: URL? = nil
        #endif

        return AppConfiguration(backendBaseURL: configuredURL ?? fallbackURL)
    }
}
