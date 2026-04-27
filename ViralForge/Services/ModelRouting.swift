import Foundation

struct ModelRoute: Hashable, Codable {
    var textProvider: String
    var textModel: String
    var imageProvider: String
    var imageModel: String

    static func route(for language: ContentLanguage) -> ModelRoute {
        switch language {
        case .chinese:
            ModelRoute(
                textProvider: "qwen",
                textModel: "qwen-plus",
                imageProvider: "seedream",
                imageModel: "doubao-seedream-4-5-251128"
            )
        case .english:
            ModelRoute(
                textProvider: "openai",
                textModel: "gpt-5.4",
                imageProvider: "openai",
                imageModel: "gpt-image-1.5"
            )
        }
    }
}
