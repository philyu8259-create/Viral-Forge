import Foundation

struct BackendDataService {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func health() async throws -> HealthResponse {
        try await apiClient.get("/health")
    }

    func quota() async throws -> QuotaState {
        let response: QuotaResponse = try await apiClient.get("/api/quota")
        return response.state
    }

    func updateProStatus(isPro: Bool) async throws -> QuotaState {
        let response: QuotaResponse = try await apiClient.post("/api/quota/pro", body: QuotaProUpdateRequest(isPro: isPro))
        return response.state
    }

    func syncSubscription(_ request: SubscriptionSyncRequest) async throws -> QuotaState {
        let response: QuotaResponse = try await apiClient.post("/api/subscription/sync", body: request)
        return response.state
    }

    func templates() async throws -> [CreativeTemplate] {
        let response: TemplateListResponse = try await apiClient.get("/api/templates")
        return response.templates.map(\.template)
    }

    func brandProfile() async throws -> BrandProfile {
        let response: BrandProfileEnvelope = try await apiClient.get("/api/brand")
        return response.brandProfile
    }

    func saveBrandProfile(_ profile: BrandProfile) async throws -> BrandProfile {
        let response: BrandProfileEnvelope = try await apiClient.post("/api/brand", body: BrandProfileRequest(profile: profile))
        return response.brandProfile
    }

    func projects() async throws -> [ContentProject] {
        let response: ProjectListResponse = try await apiClient.get("/api/projects")
        return response.projects.compactMap { $0.project() }
    }

    func saveProject(_ project: ContentProject) async throws -> ContentProject? {
        let response: SaveProjectResponse = try await apiClient.post("/api/project/save", body: ProjectSaveRequest(project: project))
        return response.project.project()
    }

    func deleteProject(id: UUID) async throws -> Bool {
        let response: DeleteProjectResponse = try await apiClient.delete("/api/projects/\(id.uuidString)")
        return response.deleted
    }
}
