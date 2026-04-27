import Foundation

final class APIClient: Sendable {
    private let baseURL: URL
    private let userId: String
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(baseURL: URL, userId: String = "demo-user", session: URLSession = .shared) {
        self.baseURL = baseURL
        self.userId = userId
        self.session = session
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder.dateEncodingStrategy = .iso8601
    }

    func get<Response: Decodable>(_ path: String) async throws -> Response {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(userId, forHTTPHeaderField: "x-user-id")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIClientError.httpStatus(httpResponse.statusCode, serverMessage(from: data))
        }
        return try decoder.decode(Response.self, from: data)
    }

    func post<Request: Encodable, Response: Decodable>(_ path: String, body: Request) async throws -> Response {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIClientError.httpStatus(httpResponse.statusCode, serverMessage(from: data))
        }
        return try decoder.decode(Response.self, from: data)
    }

    func delete<Response: Decodable>(_ path: String) async throws -> Response {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(userId, forHTTPHeaderField: "x-user-id")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIClientError.httpStatus(httpResponse.statusCode, serverMessage(from: data))
        }
        return try decoder.decode(Response.self, from: data)
    }

    private func serverMessage(from data: Data) -> String? {
        guard let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data) else { return nil }
        return envelope.error.message
    }
}

enum APIClientError: LocalizedError {
    case invalidResponse
    case httpStatus(Int, String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Invalid server response."
        case .httpStatus(let statusCode, let message):
            if let message, !message.isEmpty {
                "Server returned HTTP \(statusCode): \(message)"
            } else {
                "Server returned HTTP \(statusCode)."
            }
        }
    }
}

private struct APIErrorEnvelope: Decodable {
    var error: APIErrorBody
}

private struct APIErrorBody: Decodable {
    var message: String
}
