import SwiftUI

/// A centered empty-state placeholder with icon, text, and optional action button.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var buttonTitle: String? = nil
    var buttonIcon: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.appAccent, .appAccentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.bottom, 4)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }

            if let buttonTitle, let action {
                AccentButton(
                    title: buttonTitle,
                    icon: buttonIcon,
                    action: action
                )
                .frame(maxWidth: 240)
                .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        EmptyStateView(
            icon: "dumbbell.fill",
            title: "No Equipment Yet",
            message: "Start designing your dream gym by adding equipment from the catalog.",
            buttonTitle: "Browse Catalog",
            buttonIcon: "square.grid.2x2.fill"
        ) {}
    }
    .preferredColorScheme(.dark)
}
