import SwiftUI

// MARK: - Ceiling Picker

/// Allows selection of ceiling type, color, and displays room height and pricing.
struct CeilingPicker: View {

    @ObservedObject var viewModel: RoomFinishViewModel

    /// Room height in meters, passed from the parent.
    let roomHeight: Float

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            // Ceiling type selector
            ceilingTypeSection

            // Color presets
            ceilingColorSection

            // Room height display
            roomHeightSection

            // Price info
            priceInfoSection
        }
    }

    // MARK: - Ceiling Type Section

    private var ceilingTypeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Ceiling Type")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.textPrimary)

            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(CeilingType.allCases) { type in
                    ceilingTypeCard(type: type)
                }
            }
        }
    }

    private func ceilingTypeCard(type: CeilingType) -> some View {
        let isSelected = viewModel.roomFinish.ceilingType == type

        return Button {
            viewModel.updateCeilingType(type)
        } label: {
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: type.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(isSelected ? AppTheme.accent : AppTheme.textSecondary)

                Text(type.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)

                Text(String(format: "$%.2f/ft\u{00B2}", type.pricePerSqFt))
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .fill(isSelected ? AppTheme.accent.opacity(0.12) : AppTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                    .stroke(
                        isSelected ? AppTheme.accent : Color.white.opacity(0.1),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Ceiling Color Section

    private var ceilingColorSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Ceiling Color")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.textPrimary)

            HStack(spacing: AppTheme.Spacing.lg) {
                ForEach(RoomFinishViewModel.ceilingColorPresets, id: \.self) { hex in
                    colorCircle(hex: hex, isSelected: viewModel.roomFinish.ceilingColor == hex) {
                        viewModel.updateCeilingColor(hex)
                    }
                }
            }
        }
    }

    // MARK: - Room Height Section

    private var roomHeightSection: some View {
        GlassCard(cornerRadius: AppTheme.CornerRadius.medium) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Room Height")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.textSecondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", roomHeight))
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("m")
                            .font(AppTheme.body)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Imperial")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text(String(format: "%.1f ft", roomHeight * 3.28084))
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }

    // MARK: - Price Info Section

    private var priceInfoSection: some View {
        GlassCard(cornerRadius: AppTheme.CornerRadius.medium) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Price Per Sq Ft")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.textSecondary)

                    Text(String(format: "$%.2f / ft\u{00B2}", viewModel.roomFinish.ceilingType.pricePerSqFt))
                        .font(AppTheme.headline)
                        .foregroundColor(AppTheme.accent)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Type")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.textSecondary)

                    Text(viewModel.roomFinish.ceilingType.displayName)
                        .font(AppTheme.headline)
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
    }

    // MARK: - Subviews

    private func colorCircle(hex: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: hex))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? AppTheme.accent : Color.white.opacity(0.15),
                                lineWidth: isSelected ? 3 : 1
                            )
                    )

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(contrastColor(for: hex))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func contrastColor(for hex: String) -> Color {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.5 ? .black : .white
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        CeilingPicker(viewModel: RoomFinishViewModel(), roomHeight: 2.5)
            .padding()
    }
    .background(AppTheme.background)
    .preferredColorScheme(.dark)
}
