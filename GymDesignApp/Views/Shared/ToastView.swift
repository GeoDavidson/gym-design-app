import SwiftUI

// MARK: - Toast Type

enum ToastType {
    case success
    case error
    case warning
    case info

    var color: Color {
        switch self {
        case .success: return AppTheme.success
        case .error:   return AppTheme.error
        case .warning: return AppTheme.warning
        case .info:    return AppTheme.accent
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error:   return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info:    return "info.circle.fill"
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let type: ToastType
    let message: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: type.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(type.color)

            Text(message)
                .font(AppTheme.body)
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(2)

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm + 4)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(type.color.opacity(0.4), lineWidth: 1)
                )
        )
        .shadow(color: type.color.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, AppTheme.Spacing.md)
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let type: ToastType
    let message: String

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if isPresented {
                    ToastView(type: type, message: message)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(999)
                        .padding(.top, AppTheme.Spacing.xl)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isPresented = false
                                }
                            }
                        }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
    }
}

// MARK: - View Extension

extension View {
    /// Displays a toast notification that slides in from the top and auto-dismisses after 3 seconds.
    func toast(isPresented: Binding<Bool>, type: ToastType, message: String) -> some View {
        modifier(ToastModifier(isPresented: isPresented, type: type, message: message))
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()

        VStack(spacing: 16) {
            ToastView(type: .success, message: "Design saved successfully!")
            ToastView(type: .error, message: "Failed to load equipment model.")
            ToastView(type: .warning, message: "Equipment overlaps detected.")
            ToastView(type: .info, message: "Tap and drag to place equipment.")
        }
    }
    .preferredColorScheme(.dark)
}
#endif
