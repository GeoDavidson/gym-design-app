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
            SplashView()

        case .onboarding:
            OnboardingContainerView()

        case .unauthenticated:
            LoginView()

        case .authenticated:
            TabBarView()
        }
    }
}
