import SwiftUI

// MARK: - Chat Input Bar

struct ChatInputBar: View {

    @Binding var text: String
    var isLoading: Bool
    var onSend: () -> Void

    @FocusState private var isFocused: Bool

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.appDivider)

            HStack(alignment: .bottom, spacing: 10) {
                // Text field
                TextField("Ask about gym design...", text: $text, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1...5)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                    .focused($isFocused)
                    .submitLabel(.send)
                    .onSubmit {
                        if canSend { onSend() }
                    }

                // Send button
                Button {
                    onSend()
                } label: {
                    ZStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 36, height: 36)
                    .background(
                        canSend
                            ? AnyShapeStyle(
                                LinearGradient(
                                    colors: [Color.appAccent, Color.appAccentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                              )
                            : AnyShapeStyle(Color.appSurfaceLight),
                        in: Circle()
                    )
                }
                .disabled(!canSend)
                .animation(.easeInOut(duration: 0.2), value: canSend)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.appBackground)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack {
            Spacer()
            ChatInputBar(text: .constant(""), isLoading: false, onSend: {})
            ChatInputBar(text: .constant("Hello!"), isLoading: false, onSend: {})
            ChatInputBar(text: .constant("Waiting..."), isLoading: true, onSend: {})
        }
    }
    .preferredColorScheme(.dark)
}
