import Foundation

protocol ContentGenerating {
    func generateContent(from draft: GenerationDraft) async throws -> ContentProject
}
