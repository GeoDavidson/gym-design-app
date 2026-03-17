import Foundation
import Combine
import SwiftUI

// MARK: - Auth State

enum AuthState: Equatable {
    case splash
    case onboarding
    case login
    case authenticated
}

// MARK: - Auth Validation Error

private enum ValidationError: LocalizedError {
    case invalidEmail
    case passwordTooShort
    case passwordsDoNotMatch
    case displayNameEmpty

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .passwordTooShort:
            return "Password must be at least 8 characters."
        case .passwordsDoNotMatch:
            return "Passwords do not match."
        case .displayNameEmpty:
            return "Please enter your name."
        }
    }
}

// MARK: - Auth View Model

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: Form Fields

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var displayName: String = ""

    // MARK: State

    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var authState: AuthState = .splash

    // MARK: Derived Validation (reactive)

    @Published private(set) var isEmailValid: Bool = false
    @Published private(set) var isPasswordValid: Bool = false
    @Published private(set) var doPasswordsMatch: Bool = true

    // MARK: Dependencies

    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()

    // MARK: Constants

    private static let onboardingCompletedKey = "hasCompletedOnboarding"
    private static let minimumPasswordLength = 8

    // MARK: Initialization

    init(authService: AuthService) {
        self.authService = authService
        setupBindings()
        setupValidation()
    }

    // MARK: Bindings

    private func setupBindings() {
        // React to auth service state changes.
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                guard let self else { return }
                if isAuthenticated {
                    self.authState = .authenticated
                } else if self.authState == .authenticated {
                    // User was authenticated but signed out.
                    self.authState = .login
                }
            }
            .store(in: &cancellables)

        authService.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                guard let self else { return }
                // When AuthService finishes its initial load and user is not authenticated,
                // determine whether to show onboarding or login.
                if !isLoading && !self.authService.isAuthenticated && self.authState == .splash {
                    self.checkOnboardingStatus()
                }
            }
            .store(in: &cancellables)
    }

    private func setupValidation() {
        $email
            .map { Self.isValidEmail($0) }
            .assign(to: &$isEmailValid)

        $password
            .map { $0.count >= Self.minimumPasswordLength }
            .assign(to: &$isPasswordValid)

        Publishers.CombineLatest($password, $confirmPassword)
            .map { password, confirm in
                confirm.isEmpty || password == confirm
            }
            .assign(to: &$doPasswordsMatch)
    }

    // MARK: Onboarding

    func checkOnboardingStatus() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingCompletedKey)
        authState = hasCompletedOnboarding ? .login : .onboarding
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Self.onboardingCompletedKey)
        authState = .login
    }

    // MARK: Login

    func login() async {
        do {
            try validateLoginFields()
            isLoading = true
            try await authService.signIn(email: email.trimmingCharacters(in: .whitespaces), password: password)
            clearForm()
        } catch {
            presentError(error)
        }
        isLoading = false
    }

    // MARK: Sign Up

    func signUp() async {
        do {
            try validateSignUpFields()
            isLoading = true
            try await authService.signUp(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password,
                displayName: displayName.trimmingCharacters(in: .whitespaces)
            )
            clearForm()
        } catch {
            presentError(error)
        }
        isLoading = false
    }

    // MARK: Forgot Password

    func forgotPassword() async {
        guard Self.isValidEmail(email) else {
            presentError(ValidationError.invalidEmail)
            return
        }

        do {
            isLoading = true
            try await authService.resetPassword(email: email.trimmingCharacters(in: .whitespaces))
            isLoading = false
            errorMessage = "A password reset link has been sent to \(email)."
            showError = true
        } catch {
            isLoading = false
            presentError(error)
        }
    }

    // MARK: Sign Out

    func signOut() {
        do {
            try authService.signOut()
            clearForm()
            authState = .login
        } catch {
            presentError(error)
        }
    }

    // MARK: Validation

    private func validateLoginFields() throws {
        guard Self.isValidEmail(email) else {
            throw ValidationError.invalidEmail
        }
        guard password.count >= Self.minimumPasswordLength else {
            throw ValidationError.passwordTooShort
        }
    }

    private func validateSignUpFields() throws {
        let trimmedName = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            throw ValidationError.displayNameEmpty
        }
        guard Self.isValidEmail(email) else {
            throw ValidationError.invalidEmail
        }
        guard password.count >= Self.minimumPasswordLength else {
            throw ValidationError.passwordTooShort
        }
        guard password == confirmPassword else {
            throw ValidationError.passwordsDoNotMatch
        }
    }

    private static func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        // Lightweight regex covering the vast majority of valid addresses.
        let pattern = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: Helpers

    private func presentError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }

    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
    }
}
