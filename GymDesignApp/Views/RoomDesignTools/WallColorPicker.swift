import SwiftUI

// MARK: - Wall Color Picker

/// Allows users to select a wall color from presets or a custom picker,
/// and choose a wall texture.
struct WallColorPicker: View {

    @ObservedObject var viewModel: RoomFinishViewModel

    @State private var customColor: Color = .white
    @State private var selectedTexture: WallTexture = .smooth

    // MARK: - Wall Textures

    enum WallTexture: String, CaseIterable, Identifiable {
        case smooth
        case brick
        case concrete
        case woodPanel = "wood_panel"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .smooth:    return "Smooth"
            case .brick:     return "Brick"
            case .concrete:  return "Concrete"
            case .woodPanel: return "Wood Panel"
            }
        }

        var icon: String {
            switch self {
            case .smooth:    return "rectangle.fill"
            case .brick:     return "rectangle.split.3x3"
            case .concrete:  return "square.fill"
            case .woodPanel: return "rectangle.pattern.checkered"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            // Wall color section
            wallColorSection

            // Custom color picker
            customColorSection

            // Wall texture section
            wallTextureSection
        }
        .onAppear {
            if let texture = viewModel.roomFinish.wallTexture {
                selectedTexture = WallTexture(rawValue: texture) ?? .smooth
            }
            customColor = Color(hex: viewModel.roomFinish.wallColor)
        }
    }

    // MARK: - Wall Color Section

    private var wallColorSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Wall Color")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.textPrimary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.md), count: 4), spacing: AppTheme.Spacing.md) {
                ForEach(RoomFinishViewModel.wallColorPresets, id: \.self) { hex in
                    colorCircle(hex: hex, isSelected: viewModel.roomFinish.wallColor == hex) {
                        viewModel.updateWallColor(hex)
                        customColor = Color(hex: hex)
                    }
                }
            }
        }
    }

    // MARK: - Custom Color Section

    private var customColorSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Custom Color")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.textSecondary)

            HStack(spacing: AppTheme.Spacing.md) {
                ColorPicker("", selection: $customColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 44, height: 44)
                    .scaleEffect(1.2)

                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(customColor)
                    .frame(height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
            .onChange(of: customColor) { _, newColor in
                let hex = hexString(from: newColor)
                viewModel.updateWallColor(hex)
            }
        }
    }

    // MARK: - Wall Texture Section

    private var wallTextureSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Wall Texture")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(WallTexture.allCases) { texture in
                        textureCard(texture: texture)
                    }
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

    private func textureCard(texture: WallTexture) -> some View {
        let isSelected = selectedTexture == texture

        return Button {
            selectedTexture = texture
            viewModel.updateWallTexture(texture.rawValue)
        } label: {
            VStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: texture.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(isSelected ? AppTheme.accent : AppTheme.textSecondary)
                    .frame(width: 64, height: 64)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .fill(isSelected ? AppTheme.accent.opacity(0.15) : AppTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(isSelected ? AppTheme.accent : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )

                Text(texture.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? AppTheme.accent : AppTheme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    /// Returns black or white based on perceived brightness of the hex color.
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

    /// Converts a SwiftUI Color to a hex string.
    private func hexString(from color: Color) -> String {
        let components = UIColor(color).cgColor.components ?? [0, 0, 0, 1]
        let r = components.count > 0 ? components[0] : 0
        let g = components.count > 1 ? components[1] : 0
        let b = components.count > 2 ? components[2] : 0
        return String(
            format: "#%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        WallColorPicker(viewModel: RoomFinishViewModel())
            .padding()
    }
    .background(AppTheme.background)
    .preferredColorScheme(.dark)
}
