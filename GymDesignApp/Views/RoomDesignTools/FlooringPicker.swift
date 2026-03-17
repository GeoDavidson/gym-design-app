import SwiftUI

// MARK: - Flooring Picker

/// Allows selection of flooring type, color, and displays pricing info.
struct FlooringPicker: View {

    @ObservedObject var viewModel: RoomFinishViewModel

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            // Flooring type selector
            flooringTypeSection

            // Color grid for selected type
            colorGridSection

            // Preview swatch
            previewSwatchSection

            // Price info
            priceInfoSection
        }
    }

    // MARK: - Flooring Type Section

    private var flooringTypeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Flooring Type")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(FlooringType.allCases) { type in
                        flooringTypeCard(type: type)
                    }
                }
            }
        }
    }

    private func flooringTypeCard(type: FlooringType) -> some View {
        let isSelected = viewModel.roomFinish.flooringType == type

        return Button {
            viewModel.updateFlooringType(type)
        } label: {
            VStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: type.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? AppTheme.accent : AppTheme.textSecondary)
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(isSelected ? AppTheme.accent.opacity(0.15) : AppTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(
                                isSelected ? AppTheme.accent : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )

                Text(type.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? AppTheme.accent : AppTheme.textSecondary)
                    .lineLimit(1)
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Color Grid Section

    private var colorGridSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Color Options")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.textPrimary)

            let presets = viewModel.currentFlooringColorPresets

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.md), count: 4), spacing: AppTheme.Spacing.md) {
                ForEach(presets, id: \.self) { hex in
                    colorCircle(hex: hex, isSelected: viewModel.roomFinish.flooringColor == hex) {
                        viewModel.updateFlooringColor(hex)
                    }
                }
            }
        }
    }

    // MARK: - Preview Swatch Section

    private var previewSwatchSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Preview")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.textSecondary)

            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(Color(hex: viewModel.roomFinish.flooringColor))
                .frame(height: 64)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .overlay(
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.roomFinish.flooringType.displayName)
                                .font(.system(size: 13, weight: .semibold))
                            Text(viewModel.roomFinish.flooringColor.uppercased())
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                        }
                        .foregroundColor(contrastColor(for: viewModel.roomFinish.flooringColor))
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                )
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

                    Text(String(format: "$%.2f / ft\u{00B2}", viewModel.roomFinish.flooringType.pricePerSqFt))
                        .font(AppTheme.headline)
                        .foregroundColor(AppTheme.accent)
                }

                Spacer()

                Image(systemName: viewModel.roomFinish.flooringType.icon)
                    .font(.system(size: 28))
                    .foregroundColor(AppTheme.accent.opacity(0.6))
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
        FlooringPicker(viewModel: RoomFinishViewModel())
            .padding()
    }
    .background(AppTheme.background)
    .preferredColorScheme(.dark)
}
