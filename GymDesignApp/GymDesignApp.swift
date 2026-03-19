import SwiftUI
import FirebaseCore

@main
struct GymDesignApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            rootView
                .preferredColorScheme(.dark)
                .environmentObject(authViewModel)
        }
    }

    @ViewBuilder
    private var rootView: some View {
        switch authViewModel.authState {
        case .splash:
            SplashView(onFinished: { authViewModel.checkOnboardingStatus() })

        case .onboarding:
            OnboardingContainerView(onComplete: { authViewModel.completeOnboarding() })

        case .login:
            LoginView()

        case .authenticated:
            TabBarView()
        }
    }
}
