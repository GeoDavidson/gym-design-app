import SwiftUI

// MARK: - Chat Bubble View

struct ChatBubbleView: View {

    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                // Content bubble
                bubbleContent
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(bubbleBackground, in: bubbleShape)

                // Timestamp
                Text(message.formattedTimestamp)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.appTextTertiary)
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }

    // MARK: - Bubble Content

    @ViewBuilder
    private var bubbleContent: some View {
        if message.isStreaming && message.content.isEmpty {
            streamingIndicator
        } else if isUser {
            Text(message.content)
                .font(.system(size: 15))
                .foregroundStyle(.white)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                markdownText(message.content)
                if message.isStreaming {
                    streamingIndicator
                }
            }
        }
    }

    // MARK: - Bubble Background

    @ViewBuilder
    private var bubbleBackground: some ShapeStyle {
        if isUser {
            LinearGradient(
                colors: [Color.appAccent, Color.appAccentSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            Color.appSurface
        }
    }

    // MARK: - Bubble Shape

    private var bubbleShape: UnevenRoundedRectangle {
        if isUser {
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 16,
                bottomTrailingRadius: 4,
                topTrailingRadius: 16
            )
        } else {
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 4,
                bottomTrailingRadius: 16,
                topTrailingRadius: 16
            )
        }
    }

    // MARK: - Streaming Indicator (3-dot animation)

    private var streamingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                StreamingDot(delay: Double(index) * 0.2)
            }
        }
        .frame(height: 20)
    }

    // MARK: - Basic Markdown Rendering

    /// Supports **bold**, *italic*, and bullet lists (lines starting with "- ").
    @ViewBuilder
    private func markdownText(_ text: String) -> some View {
        if #available(iOS 17, *) {
            Text(LocalizedStringKey(sanitizedMarkdown(text)))
                .font(.system(size: 15))
                .foregroundStyle(Color.appTextPrimary)
                .tint(Color.appAccent)
        }
    }

    /// Cleans the raw text so SwiftUI's LocalizedStringKey markdown can handle it.
    private func sanitizedMarkdown(_ text: String) -> String {
        // Ensure list items render on new lines
        text.replacingOccurrences(of: "\n- ", with: "\n\u{2022} ")
            .replacingOccurrences(of: "\n* ", with: "\n\u{2022} ")
    }
}

// MARK: - Streaming Dot

private struct StreamingDot: View {
    let delay: Double
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(Color.appTextSecondary)
            .frame(width: 6, height: 6)
            .offset(y: isAnimating ? -4 : 2)
            .animation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
                .delay(delay),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack(spacing: 16) {
            ChatBubbleView(
                message: ChatMessage(role: .user, content: "What equipment fits a 4x5m room?")
            )
            ChatBubbleView(
                message: ChatMessage(
                    role: .assistant,
                    content: "A 4x5m room (20 m\u{00B2}) gives you plenty of options! Here are my top picks:\n\n- **Power rack** — the centerpiece, place against the back wall\n- **Adjustable bench** — slides under the rack when not in use\n- **Cable machine** — compact functional trainer in the corner\n- *Rubber flooring* throughout for noise and impact protection"
                )
            )
            ChatBubbleView(
                message: ChatMessage(role: .assistant, content: "", isStreaming: true)
            )
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
