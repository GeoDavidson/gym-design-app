import SwiftUI

// MARK: - Themed Text Field

/// A styled text field with dark surface background, left SF Symbol icon, and accent-colored icon.
/// Designed for the dark futuristic theme of the app.
struct ThemedTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String = "envelope.fill"
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var submitLabel: SubmitLabel = .next

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.appAccent)
                .frame(width: 20, alignment: .center)

            TextField("", text: $text, prompt: promptText)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.appTextPrimary)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .submitLabel(submitLabel)
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.appSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }

    private var promptText: Text {
        Text(placeholder)
            .foregroundColor(.appTextTertiary)
    }
}

// MARK: - Themed Secure Field

/// A styled secure field matching `ThemedTextField` design, for password entry.
struct ThemedSecureField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String = "lock.fill"
    var textContentType: UITextContentType? = nil
    var submitLabel: SubmitLabel = .go

    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.appAccent)
                .frame(width: 20, alignment: .center)

            Group {
                if isRevealed {
                    TextField("", text: $text, prompt: promptText)
                        .textContentType(textContentType)
                        .submitLabel(submitLabel)
                } else {
                    SecureField("", text: $text, prompt: promptText)
                        .textContentType(textContentType)
                        .submitLabel(submitLabel)
                }
            }
            .font(.system(size: 15, weight: .regular))
            .foregroundColor(.appTextPrimary)

            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appTextSecondary)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.appSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }

    private var promptText: Text {
        Text(placeholder)
            .foregroundColor(.appTextTertiary)
    }
}

// MARK: - Previews

#Preview("ThemedTextField") {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack(spacing: 12) {
            ThemedTextField(placeholder: "Email", text: .constant(""), icon: "envelope.fill")
            ThemedSecureField(placeholder: "Password", text: .constant(""), icon: "lock.fill")
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
