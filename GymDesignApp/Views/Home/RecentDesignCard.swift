import SwiftUI

// MARK: - Recent Design Card

struct RecentDesignCard: View {

    let design: RoomDesign

    // MARK: Body

    var body: some View {
        NavigationLink {
            // Placeholder destination — will be replaced with the full design editor
            Text(design.name)
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.background.ignoresSafeArea())
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
    }

    // MARK: Card Content

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            thumbnailPlaceholder
            designInfo
        }
        .frame(width: 200, height: 240)
        .glassMaterial(cornerRadius: AppTheme.CornerRadius.large)
    }

    // MARK: Thumbnail

    private var thumbnailPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.accent.opacity(0.3),
                    AppTheme.accentSecondary.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "cube.fill")
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
        }
        .frame(height: 120)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: AppTheme.CornerRadius.large,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: AppTheme.CornerRadius.large
            )
        )
    }

    // MARK: Design Info

    private var designInfo: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(design.name)
                .font(AppTheme.headline)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)

            Text(design.room.displayDimensions)
                .font(AppTheme.caption)
                .foregroundStyle(AppTheme.textSecondary)

            HStack {
                equipmentBadge

                Spacer()

                Text(design.displayDate)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.bottom, AppTheme.Spacing.sm)
    }

    // MARK: Equipment Badge

    private var equipmentBadge: some View {
        Text("\(design.equipmentCount) items")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(AppTheme.accent, in: Capsule())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RecentDesignCard(
            design: RoomDesign(
                userID: "preview",
                name: "Home Gym",
                room: Room(width: 5.0, length: 6.0, height: 2.8),
                placements: [
                    EquipmentPlacement(equipmentID: "eq-1", positionX: 1, positionY: 0, positionZ: 1),
                    EquipmentPlacement(equipmentID: "eq-2", positionX: 2, positionY: 0, positionZ: 3)
                ]
            )
        )
        .padding()
        .background(AppTheme.background)
    }
    .preferredColorScheme(.dark)
}
