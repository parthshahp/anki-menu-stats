import Foundation

struct EmptyParams: Encodable {}

struct AnkiRequest<Params: Encodable>: Encodable {
    let action: String
    let version: Int
    let params: Params
}

struct AnkiResponse<Result: Decodable>: Decodable {
    let result: Result?
    let error: String?
}

enum AnkiClientError: LocalizedError {
    case invalidStatusCode(Int)
    case apiError(String)
    case missingResult

    var errorDescription: String? {
        switch self {
        case .invalidStatusCode(let code):
            return "AnkiConnect returned HTTP \(code)."
        case .apiError(let message):
            return "AnkiConnect error: \(message)"
        case .missingResult:
            return "AnkiConnect response did not include a result."
        }
    }
}

struct AnkiClient: Sendable {
    private let endpoint: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(endpoint: URL = URL(string: "http://127.0.0.1:8765")!, session: URLSession = .shared) {
        self.endpoint = endpoint
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func request<Result: Decodable>(action: String) async throws -> Result {
        try await request(action: action, params: EmptyParams())
    }

    func request<Result: Decodable, Params: Encodable>(action: String, params: Params) async throws -> Result {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 6
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(AnkiRequest(action: action, version: 6, params: params))

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200...299).contains(http.statusCode) else {
            throw AnkiClientError.invalidStatusCode(http.statusCode)
        }

        let decoded = try decoder.decode(AnkiResponse<Result>.self, from: data)

        if let error = decoded.error {
            throw AnkiClientError.apiError(error)
        }
        guard let result = decoded.result else {
            throw AnkiClientError.missingResult
        }

        return result
    }
}
