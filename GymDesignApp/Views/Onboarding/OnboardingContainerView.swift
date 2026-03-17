import SwiftUI

/// Three-page onboarding flow with skip / next controls and page indicator dots.
struct OnboardingContainerView: View {
    var onComplete: () -> Void

    @State private var currentPage: Int = 0

    private let pages: [(icon: String, title: String, description: String)] = [
        (
            icon: "cube.transparent",
            title: "Scan Your Room",
            description: "Point your camera at the space and let the app build a 3D map automatically."
        ),
        (
            icon: "dumbbell.fill",
            title: "Design Your Gym",
            description: "Browse equipment, drag it into your room, and see exactly how it fits in augmented reality."
        ),
        (
            icon: "hammer.fill",
            title: "Build It For Real",
            description: "Export your layout, get equipment recommendations, and share with the community."
        )
    ]

    private var isLastPage: Bool { currentPage == pages.count - 1 }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Skip Button
                HStack {
                    Spacer()
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Skip")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.appTextSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.top, 8)
                .padding(.trailing, 8)

                // MARK: - Page Content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(
                            icon: page.icon,
                            title: page.title,
                            description: page.description
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // MARK: - Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.appAccent : Color.appTextTertiary)
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // MARK: - Next / Get Started Button
                AccentButton(
                    title: isLastPage ? "Get Started" : "Next",
                    icon: isLastPage ? "arrow.right" : nil
                ) {
                    if isLastPage {
                        completeOnboarding()
                    } else {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Helpers

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        onComplete()
    }
}

#Preview {
    OnboardingContainerView(onComplete: {})
        .preferredColorScheme(.dark)
}
