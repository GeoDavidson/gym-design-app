import Foundation

// MARK: - API Error

enum ClaudeAPIError: LocalizedError {
    case unauthorized
    case rateLimited
    case serverError(statusCode: Int, message: String)
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse
    case streamingError(String)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Invalid API key. Please check your configuration."
        case .rateLimited:
            return "Rate limit reached. Please try again in a moment."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .streamingError(let message):
            return "Streaming error: \(message)"
        }
    }
}

// MARK: - Claude AI Service

final class ClaudeAIService: Sendable {

    // MARK: - Singleton

    static let shared = ClaudeAIService()

    // MARK: - Configuration

    /// Replace with your actual API key or load from a secure source.
    private let apiKey: String = "YOUR_CLAUDE_API_KEY"
    private let endpoint = AppConstants.API.claudeAPIEndpoint
    private let model = AppConstants.API.claudeModel
    private let anthropicVersion = "2023-06-01"

    private let session: URLSession

    // MARK: - Default System Prompt

    static let defaultSystemPrompt = """
        You are a gym design advisor for the GymDesign AR app. \
        Help users choose equipment, plan layouts, and optimize their home gym setup. \
        Provide practical recommendations considering room dimensions, budget constraints, \
        flooring requirements, ventilation, and safety clearances. \
        When discussing equipment placement, consider standard clearance zones and traffic flow. \
        Keep responses concise and actionable.
        """

    // MARK: - Init

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConstants.API.requestTimeoutInterval
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }

    // MARK: - Send Message (Non-Streaming)

    /// Sends messages to the Claude Messages API and returns the full response text.
    func sendMessage(
        messages: [ChatMessage],
        systemPrompt: String = ClaudeAIService.defaultSystemPrompt
    ) async throws -> String {
        let request = try buildRequest(messages: messages, systemPrompt: systemPrompt, stream: false)

        let (data, response) = try await session.data(for: request)
        try validateHTTPResponse(response)

        return try parseResponseText(from: data)
    }

    // MARK: - Send Message (Streaming)

    /// Streams response text from the Claude Messages API as an AsyncThrowingStream of string deltas.
    func sendMessageStream(
        messages: [ChatMessage],
        systemPrompt: String = ClaudeAIService.defaultSystemPrompt
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = try buildRequest(messages: messages, systemPrompt: systemPrompt, stream: true)
                    let (bytes, response) = try await session.bytes(for: request)
                    try validateHTTPResponse(response)

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = String(line.dropFirst(6))

                        if jsonString == "[DONE]" { break }

                        guard let jsonData = jsonString.data(using: .utf8),
                              let event = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
                        else { continue }

                        let eventType = event["type"] as? String ?? ""

                        if eventType == "content_block_delta",
                           let delta = event["delta"] as? [String: Any],
                           let text = delta["text"] as? String {
                            continuation.yield(text)
                        }

                        if eventType == "message_stop" {
                            break
                        }

                        if eventType == "error",
                           let error = event["error"] as? [String: Any],
                           let message = error["message"] as? String {
                            throw ClaudeAPIError.streamingError(message)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private Helpers

    private func buildRequest(
        messages: [ChatMessage],
        systemPrompt: String,
        stream: Bool
    ) throws -> URLRequest {
        guard let url = URL(string: endpoint) else {
            throw ClaudeAPIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 2048,
            "system": systemPrompt,
            "stream": stream,
            "messages": messages.map { $0.apiRepresentation }
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func validateHTTPResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw ClaudeAPIError.invalidResponse
        }

        switch http.statusCode {
        case 200...299:
            return
        case 401:
            throw ClaudeAPIError.unauthorized
        case 429:
            throw ClaudeAPIError.rateLimited
        default:
            throw ClaudeAPIError.serverError(
                statusCode: http.statusCode,
                message: HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            )
        }
    }

    private func parseResponseText(from data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String
        else {
            throw ClaudeAPIError.invalidResponse
        }
        return text
    }
}
