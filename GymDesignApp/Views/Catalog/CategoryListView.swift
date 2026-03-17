import SwiftUI

// MARK: - Category List View

/// Horizontal scrollable row of category filter chips with an "All" option.
struct CategoryListView: View {

    @Binding var selectedCategory: EquipmentCategory?
    var onSelect: (EquipmentCategory?) -> Void

    @Namespace private var chipNamespace

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                // "All" chip
                CategoryChip(
                    title: "All",
                    iconName: "square.grid.2x2.fill",
                    color: .appAccent,
                    isSelected: selectedCategory == nil,
                    namespace: chipNamespace
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        onSelect(nil)
                    }
                }

                // Category chips
                ForEach(EquipmentCategory.allCases) { category in
                    CategoryChip(
                        title: category.displayName,
                        iconName: category.iconName,
                        color: category.color,
                        isSelected: selectedCategory == category,
                        namespace: chipNamespace
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            onSelect(category)
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.xs)
        }
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {

    let title: String
    let iconName: String
    let color: Color
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.caption.weight(.semibold))

                Text(title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : Color.appTextSecondary)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .matchedGeometryEffect(id: "chipBackground", in: namespace)
                } else {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                }
            }
            .overlay {
                if isSelected {
                    Capsule(style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [color, color.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                } else {
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack {
            CategoryListView(
                selectedCategory: .constant(nil),
                onSelect: { _ in }
            )

            CategoryListView(
                selectedCategory: .constant(.cardio),
                onSelect: { _ in }
            )
        }
    }
    .preferredColorScheme(.dark)
}
