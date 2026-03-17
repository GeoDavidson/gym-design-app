import Foundation
import Combine
import SwiftUI

// MARK: - AI Chat View Model

@MainActor
final class AIChatViewModel: ObservableObject {

    // MARK: - Published State

    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?

    // MARK: - Room Context (optional)

    /// Set this to provide room/equipment context to the AI advisor.
    var currentRoom: Room?
    var placedEquipment: [Equipment] = []

    // MARK: - Suggested Prompts

    let suggestedPrompts: [String] = [
        "What equipment fits a 4x5m room?",
        "Best flooring for weightlifting?",
        "Budget home gym under $5000?",
        "Power rack placement tips"
    ]

    // MARK: - Private

    private let aiService = ClaudeAIService.shared
    private var streamTask: Task<Void, Never>?

    // MARK: - Send Message

    /// Appends the user message, calls Claude streaming, and progressively builds the assistant reply.
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Clear input immediately
        inputText = ""
        error = nil

        // Append user message
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)

        // Create placeholder assistant message
        let assistantID = UUID().uuidString
        var assistantMessage = ChatMessage(
            id: assistantID,
            role: .assistant,
            content: "",
            isStreaming: true
        )
        messages.append(assistantMessage)
        isLoading = true

        // Streaming task
        streamTask = Task { [weak self] in
            guard let self else { return }

            do {
                let systemPrompt = buildSystemPrompt()
                let apiMessages = messages
                    .filter { !$0.isStreaming }  // exclude the empty assistant placeholder
                    .map { $0 }

                let stream = aiService.sendMessageStream(
                    messages: apiMessages,
                    systemPrompt: systemPrompt
                )

                for try await delta in stream {
                    guard !Task.isCancelled else { break }
                    assistantMessage.content += delta
                    // Update the last message in place
                    if let index = messages.lastIndex(where: { $0.id == assistantID }) {
                        messages[index].content = assistantMessage.content
                    }
                }

                // Mark streaming complete
                if let index = messages.lastIndex(where: { $0.id == assistantID }) {
                    messages[index].isStreaming = false
                }
            } catch {
                // On error, remove the empty assistant placeholder and show error
                if let index = messages.lastIndex(where: { $0.id == assistantID }) {
                    if messages[index].content.isEmpty {
                        messages.remove(at: index)
                    } else {
                        messages[index].isStreaming = false
                    }
                }
                self.error = (error as? ClaudeAPIError)?.errorDescription ?? error.localizedDescription
            }

            isLoading = false
        }
    }

    /// Sends a suggested prompt directly.
    func sendSuggestedPrompt(_ prompt: String) {
        inputText = prompt
        sendMessage()
    }

    // MARK: - Clear Chat

    func clearChat() {
        streamTask?.cancel()
        streamTask = nil
        messages.removeAll()
        error = nil
        isLoading = false
    }

    // MARK: - System Prompt Builder

    /// Constructs the system prompt, injecting room context when a design is active.
    func buildSystemPrompt() -> String {
        var prompt = ClaudeAIService.defaultSystemPrompt

        if let room = currentRoom {
            prompt += "\n\nCurrent room context:"
            prompt += "\n- Dimensions: \(room.displayDimensions)"
            prompt += "\n- Floor area: \(room.displayArea)"
            prompt += "\n- Volume: \(String(format: "%.1f m³", room.volume))"
        }

        if !placedEquipment.isEmpty {
            prompt += "\n\nCurrently placed equipment:"
            let grouped = Dictionary(grouping: placedEquipment, by: { $0.name })
            for (name, items) in grouped.sorted(by: { $0.key < $1.key }) {
                prompt += "\n- \(name) x\(items.count)"
            }
        }

        return prompt
    }
}
