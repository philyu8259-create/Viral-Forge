import Foundation

enum ContentServiceFactory {
    static func makeDefault(configuration: AppConfiguration = .current, userId: String = "demo-user") -> ContentGenerating {
        guard let backendBaseURL = configuration.backendBaseURL else {
            return MockContentService()
        }

        return BackendContentService(apiClient: APIClient(baseURL: backendBaseURL, userId: userId))
    }
}
