import SwiftUI

// MARK: - Forgot Password View

struct ForgotPasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var emailError: String?
    @State private var isResetSent = false

    @FocusState private var isEmailFocused: Bool

    // MARK: - Validation

    private var isFormValid: Bool {
        isValidEmail(email)
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
                    if isResetSent {
                        successContent
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        formContent
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 72)
                .animation(.easeInOut(duration: 0.4), value: isResetSent)
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
            isEmailFocused = false
        }
    }

    // MARK: - Form Content

    private var formContent: some View {
        VStack(spacing: 24) {
            headerIcon

            VStack(spacing: 8) {
                Text("Reset Password")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text("Enter the email associated with your account and we'll send a link to reset your password.")
                    .font(.system(size: 15))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()
                .frame(height: 16)

            VStack(alignment: .leading, spacing: 4) {
                ThemedTextField(
                    placeholder: "Email",
                    text: $email,
                    icon: "envelope.fill",
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    submitLabel: .go
                )
                .focused($isEmailFocused)
                .onSubmit { attemptReset() }
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

                if let error = emailError {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 12))
                        Text(error)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.red)
                    .padding(.leading, 4)
                }
            }

            AccentButton(
                title: "Send Reset Link",
                isLoading: authViewModel.isLoading,
                isDisabled: !isFormValid
            ) {
                attemptReset()
            }
            .padding(.top, 8)

            backToLoginLink
        }
    }

    // MARK: - Success Content

    private var successContent: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 96, height: 96)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.green)
            }

            VStack(spacing: 8) {
                Text("Check Your Email")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text("We've sent a password reset link to **\(email.trimmingCharacters(in: .whitespacesAndNewlines))**. Check your inbox and follow the instructions.")
                    .font(.system(size: 15))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer()
                .frame(height: 16)

            AccentButton(title: "Back to Login") {
                dismiss()
            }

            Button {
                withAnimation {
                    isResetSent = false
                    email = ""
                }
            } label: {
                Text("Try a different email")
                    .font(.system(size: 15))
                    .foregroundColor(.appAccent)
            }
        }
    }

    // MARK: - Subviews

    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(Color.appAccent.opacity(0.12))
                .frame(width: 88, height: 88)

            Image(systemName: "lock.rotation")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(Color.accentGradient)
        }
    }

    private var backToLoginLink: some View {
        Button { dismiss() } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 14, weight: .semibold))
                Text("Back to Login")
                    .font(.system(size: 15))
            }
            .foregroundColor(.appTextSecondary)
        }
    }

    // MARK: - Actions

    private func attemptReset() {
        guard isFormValid else {
            emailError = "Enter a valid email address"
            return
        }
        isEmailFocused = false

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            await authViewModel.resetPassword(email: trimmedEmail)
            if !authViewModel.showError {
                withAnimation {
                    isResetSent = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ForgotPasswordView()
            .environmentObject(AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
