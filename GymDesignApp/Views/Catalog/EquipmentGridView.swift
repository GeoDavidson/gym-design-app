import SwiftUI

// MARK: - Equipment Grid View

/// A responsive 2-column grid of equipment cards with staggered appear animations.
struct EquipmentGridView: View {

    let equipment: [Equipment]

    private let columns = [
        GridItem(.flexible(), spacing: AppTheme.Spacing.md),
        GridItem(.flexible(), spacing: AppTheme.Spacing.md)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppTheme.Spacing.md) {
                ForEach(Array(equipment.enumerated()), id: \.element.id) { index, item in
                    NavigationLink(value: item) {
                        EquipmentCardCell(equipment: item, index: index)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.top, AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.xxl)
        }
        .navigationDestination(for: Equipment.self) { item in
            EquipmentDetailView(equipment: item)
        }
    }
}

// MARK: - Equipment Card Cell

private struct EquipmentCardCell: View {

    let equipment: Equipment
    let index: Int

    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Thumbnail placeholder
            thumbnailView

            // Info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(equipment.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(equipment.brand)
                    .font(AppTheme.caption)
                    .foregroundStyle(Color.appTextSecondary)

                HStack {
                    Text(equipment.displayPrice)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.appAccent)

                    Spacer()
                }

                // Dimensions badge
                dimensionsBadge
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.bottom, AppTheme.Spacing.sm)
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous))
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            let delay = Double(index % 10) * 0.05
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
        }
    }

    // MARK: - Thumbnail

    private var thumbnailView: some View {
        ZStack {
            // Gradient background using category color
            LinearGradient(
                colors: [
                    equipment.category.color.opacity(0.3),
                    equipment.category.color.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: equipment.category.iconName)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(equipment.category.color.opacity(0.6))

            // Category pill overlay
            VStack {
                HStack {
                    Spacer()
                    Text(equipment.category.displayName)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule(style: .continuous)
                                .fill(equipment.category.color.opacity(0.8))
                        )
                        .padding(8)
                }
                Spacer()
            }
        }
        .frame(height: 120)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: AppTheme.CornerRadius.large,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: AppTheme.CornerRadius.large,
                style: .continuous
            )
        )
    }

    // MARK: - Dimensions Badge

    private var dimensionsBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "ruler")
                .font(.system(size: 9))
            Text(equipment.dimensions.displayString)
                .font(.system(size: 9, weight: .medium))
        }
        .foregroundStyle(Color.appTextTertiary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(Color.appSurface)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            EquipmentGridView(equipment: [
                Equipment(
                    id: "1",
                    name: "Pro Treadmill X9000",
                    description: "A commercial treadmill.",
                    category: .cardio,
                    dimensions: EquipmentDimensions(width: 0.84, length: 2.03, height: 1.63),
                    price: 3499.99,
                    brand: "LifeFitness",
                    usdzModelName: "treadmill.usdz",
                    requiredClearance: EquipmentDimensions(width: 0.3, length: 1.2, height: 0),
                    powerRequired: true
                ),
                Equipment(
                    id: "2",
                    name: "Power Rack Pro",
                    description: "Heavy-duty power rack.",
                    category: .strength,
                    dimensions: EquipmentDimensions(width: 1.32, length: 1.47, height: 2.29),
                    price: 1695.00,
                    brand: "Rogue",
                    usdzModelName: "rack.usdz",
                    requiredClearance: EquipmentDimensions(width: 0.3, length: 1.05, height: 0)
                )
            ])
        }
    }
    .preferredColorScheme(.dark)
}
