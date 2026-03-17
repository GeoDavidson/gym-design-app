import Foundation

// MARK: - Chat Message

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: String
    let role: Role
    var content: String
    let timestamp: Date
    var isStreaming: Bool

    // MARK: Role

    enum Role: String, Codable {
        case user
        case assistant
    }

    // MARK: Initialization

    init(
        id: String = UUID().uuidString,
        role: Role,
        content: String,
        timestamp: Date = Date(),
        isStreaming: Bool = false
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }

    // MARK: Equatable

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
            && lhs.role == rhs.role
            && lhs.content == rhs.content
            && lhs.isStreaming == rhs.isStreaming
    }

    // MARK: Helpers

    /// Returns an API-compatible dictionary for the Claude Messages API.
    var apiRepresentation: [String: String] {
        ["role": role.rawValue, "content": content]
    }

    /// Formatted timestamp for display (e.g. "2:34 PM").
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: timestamp)
    }
}
