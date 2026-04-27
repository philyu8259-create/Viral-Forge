import Foundation

struct BackendContentService: ContentGenerating {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func generateContent(from draft: GenerationDraft) async throws -> ContentProject {
        let request = GenerateContentRequest(draft: draft)
        let response: GenerateContentResponse = try await apiClient.post("/api/content/generate", body: request)
        let projectId = response.projectId.flatMap(UUID.init(uuidString:)) ?? UUID()

        return ContentProject(
            id: projectId,
            createdAt: .now,
            draft: draft,
            result: ContentResult(
                titles: response.titles.map(\.line),
                hooks: response.hooks.map(\.line),
                caption: response.caption,
                sellingPoints: response.sellingPoints,
                hashtags: response.hashtags
            ),
            poster: response.poster.draft(fallbackStyle: draft.templateStyle),
            isFavorite: false,
            hasPosterExport: false
        )
    }
}
