import SwiftUI

/// A single onboarding page with a large icon, title, and description.
struct OnboardingPageView: View {
    let icon: String
    let title: String
    let description: String

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Large SF Symbol with accent gradient
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.appAccent, .appAccentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .appAccent.opacity(0.3), radius: 20, y: 4)
                .scaleEffect(appeared ? 1.0 : 0.6)
                .opacity(appeared ? 1.0 : 0.0)

            VStack(spacing: 12) {
                Text(title)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.body)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                    .lineSpacing(4)
            }
            .offset(y: appeared ? 0 : 20)
            .opacity(appeared ? 1.0 : 0.0)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        OnboardingPageView(
            icon: "cube.transparent",
            title: "Scan Your Room",
            description: "Use your camera to create a 3D map of your space. We'll help you find the perfect layout."
        )
    }
    .preferredColorScheme(.dark)
}
