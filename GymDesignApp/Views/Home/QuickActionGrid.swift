import SwiftUI

// MARK: - Quick Action Grid

struct QuickActionGrid: View {

    let actions: [QuickAction]
    var onActionTapped: ((QuickAction) -> Void)?

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // MARK: Body

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(actions) { action in
                QuickActionCard(action: action)
                    .onTapGesture {
                        onActionTapped?(action)
                    }
            }
        }
    }
}

// MARK: - Quick Action Card

private struct QuickActionCard: View {

    let action: QuickAction
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Image(systemName: action.icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(action.color)
                .frame(width: 48, height: 48)
                .background(action.color.opacity(0.15), in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))

            VStack(alignment: .leading, spacing: 2) {
                Text(action.title)
                    .font(AppTheme.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Text(action.subtitle)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .glassMaterial(cornerRadius: AppTheme.CornerRadius.large)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Preview

#Preview {
    QuickActionGrid(
        actions: [
            QuickAction(icon: "camera.fill", title: "AR Scan", subtitle: "Scan your room", color: .blue),
            QuickAction(icon: "cube.fill", title: "Virtual Design", subtitle: "Build from scratch", color: .purple),
            QuickAction(icon: "square.grid.2x2.fill", title: "Catalog", subtitle: "Browse equipment", color: .green),
            QuickAction(icon: "brain.head.profile", title: "AI Advisor", subtitle: "Get recommendations", color: .orange)
        ]
    )
    .padding()
    .background(AppTheme.background)
    .preferredColorScheme(.dark)
}
