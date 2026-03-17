import SwiftUI

// MARK: - Sign Up View

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var displayNameError: String?
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var confirmPasswordError: String?

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case displayName
        case email
        case password
        case confirmPassword
    }

    // MARK: - Validation Helpers

    private var isFormValid: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && isValidEmail(email)
        && password.count >= 8
        && password == confirmPassword
    }

    private func isValidEmail(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                        .padding(.top, 32)

                    fieldsSection

                    signUpButton
                        .padding(.top, 8)

                    Spacer()
                        .frame(height: 48)

                    logInLink
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appAccent)
                }
            }
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

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: 8) {
            Text("Create Account")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.appTextPrimary)

            Text("Join the GymDesign AR community")
                .font(.system(size: 15))
                .foregroundColor(.appTextSecondary)
        }
    }

    private var fieldsSection: some View {
        VStack(spacing: 16) {
            // Display Name
            fieldWithError(error: displayNameError) {
                ThemedTextField(
                    placeholder: "Display Name",
                    text: $displayName,
                    icon: "person.fill",
                    textContentType: .name,
                    submitLabel: .next
                )
                .focused($focusedField, equals: .displayName)
                .onSubmit { focusedField = .email }
                .onChange(of: displayName) { _, newValue in
                    if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !newValue.isEmpty {
                        displayNameError = "Display name is required"
                    } else {
                        displayNameError = nil
                    }
                }
            }

            // Email
            fieldWithError(error: emailError) {
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
                .onChange(of: email) { _, newValue in
                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty {
                        emailError = nil
                    } else if !isValidEmail(trimmed) {
                        emailError = "Enter a valid email address"
                    } else {
                        emailError = nil
                    }
                }
            }

            // Password
            fieldWithError(error: passwordError) {
                ThemedSecureField(
                    placeholder: "Password (min 8 characters)",
                    text: $password,
                    icon: "lock.fill",
                    textContentType: .newPassword,
                    submitLabel: .next
                )
                .focused($focusedField, equals: .password)
                .onSubmit { focusedField = .confirmPassword }
                .onChange(of: password) { _, newValue in
                    if !newValue.isEmpty && newValue.count < 8 {
                        passwordError = "Password must be at least 8 characters"
                    } else {
                        passwordError = nil
                    }
                    // Re-validate confirm when password changes
                    if !confirmPassword.isEmpty && newValue != confirmPassword {
                        confirmPasswordError = "Passwords do not match"
                    } else if !confirmPassword.isEmpty {
                        confirmPasswordError = nil
                    }
                }
            }

            // Confirm Password
            fieldWithError(error: confirmPasswordError) {
                ThemedSecureField(
                    placeholder: "Confirm Password",
                    text: $confirmPassword,
                    icon: "lock.shield.fill",
                    textContentType: .newPassword,
                    submitLabel: .go
                )
                .focused($focusedField, equals: .confirmPassword)
                .onSubmit { attemptSignUp() }
                .onChange(of: confirmPassword) { _, newValue in
                    if !newValue.isEmpty && newValue != password {
                        confirmPasswordError = "Passwords do not match"
                    } else {
                        confirmPasswordError = nil
                    }
                }
            }
        }
    }

    private var signUpButton: some View {
        AccentButton(
            title: "Sign Up",
            isLoading: authViewModel.isLoading,
            isDisabled: !isFormValid
        ) {
            attemptSignUp()
        }
    }

    private var logInLink: some View {
        HStack(spacing: 4) {
            Text("Already have an account?")
                .font(.system(size: 15))
                .foregroundColor(.appTextSecondary)

            Button { dismiss() } label: {
                Text("Log In")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.appAccent)
            }
        }
    }

    // MARK: - Helpers

    private func fieldWithError<Content: View>(
        error: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content()

            if let error {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(error)
                        .font(.system(size: 12))
                }
                .foregroundColor(.red)
                .padding(.leading, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: error)
    }

    // MARK: - Actions

    private func validateAll() -> Bool {
        var valid = true

        if displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            displayNameError = "Display name is required"
            valid = false
        }
        if !isValidEmail(email) {
            emailError = "Enter a valid email address"
            valid = false
        }
        if password.count < 8 {
            passwordError = "Password must be at least 8 characters"
            valid = false
        }
        if password != confirmPassword {
            confirmPasswordError = "Passwords do not match"
            valid = false
        }

        return valid
    }

    private func attemptSignUp() {
        guard validateAll() else { return }
        focusedField = nil

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            await authViewModel.signUp(
                email: trimmedEmail,
                password: password,
                displayName: trimmedName
            )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
