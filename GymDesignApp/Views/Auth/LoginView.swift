import SwiftUI

// MARK: - Login View

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showForgotPassword = false

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case email
        case password
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !password.isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        appTitle
                            .padding(.top, 72)

                        Spacer()
                            .frame(height: 32)

                        fieldsSection

                        forgotPasswordLink

                        loginButton
                            .padding(.top, 8)

                        Spacer()
                            .frame(height: 48)

                        signUpLink
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
                    .environmentObject(authViewModel)
            }
            .navigationDestination(isPresented: $showForgotPassword) {
                ForgotPasswordView()
                    .environmentObject(authViewModel)
            }
            .alert("Error", isPresented: $authViewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(authViewModel.errorMessage)
            }
            .onTapGesture {
                focusedField = nil
            }
        }
    }

    // MARK: - Subviews

    private var appTitle: some View {
        VStack(spacing: 8) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentGradient)

            Text(AppConstants.App.name)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Color.accentGradient)

            Text("Design your perfect gym in AR")
                .font(.system(size: 15))
                .foregroundColor(.appTextSecondary)
        }
    }

    private var fieldsSection: some View {
        VStack(spacing: 16) {
            ThemedTextField(
                placeholder: "Email",
                text: $email,
                icon: "envelope.fill",
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                submitLabel: .next
            )
            .focused($focusedField, equals: .email)
            .onSubmit { focusedField = .password }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            ThemedSecureField(
                placeholder: "Password",
                text: $password,
                icon: "lock.fill",
                textContentType: .password,
                submitLabel: .go
            )
            .focused($focusedField, equals: .password)
            .onSubmit { attemptLogin() }
        }
    }

    private var forgotPasswordLink: some View {
        HStack {
            Spacer()
            Button {
                showForgotPassword = true
            } label: {
                Text("Forgot Password?")
                    .font(.system(size: 13))
                    .foregroundColor(.appAccent)
            }
        }
    }

    private var loginButton: some View {
        AccentButton(
            title: "Log In",
            isLoading: authViewModel.isLoading,
            isDisabled: !isFormValid
        ) {
            attemptLogin()
        }
    }

    private var signUpLink: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .font(.system(size: 15))
                .foregroundColor(.appTextSecondary)

            Button {
                showSignUp = true
            } label: {
                Text("Sign Up")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appAccent)
            }
        }
    }

    // MARK: - Actions

    private func attemptLogin() {
        guard isFormValid else { return }
        focusedField = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            await authViewModel.signIn(email: trimmedEmail, password: password)
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
