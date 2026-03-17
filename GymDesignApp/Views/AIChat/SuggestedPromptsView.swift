import SwiftUI

// MARK: - Suggested Prompts View

struct SuggestedPromptsView: View {

    var onPromptSelected: (String) -> Void

    private let prompts = [
        "What equipment fits a 4x5m room?",
        "Best flooring for weightlifting?",
        "Budget home gym under $5000?",
        "Power rack placement tips"
    ]

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.appAccent.opacity(0.2), Color.appAccentSecondary.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appAccent, Color.appAccentSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Header
            VStack(spacing: 6) {
                Text("Ask me anything")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                Text("about gym design")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
            }

            // Prompt chips
            VStack(spacing: 10) {
                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        onPromptSelected(prompt)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.appAccent)
                            Text(prompt)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.appTextPrimary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.appTextTertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        SuggestedPromptsView { prompt in
            print(prompt)
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
