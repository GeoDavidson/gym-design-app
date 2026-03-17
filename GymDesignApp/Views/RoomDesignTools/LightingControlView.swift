import SwiftUI

// MARK: - Lighting Control View

/// Controls for selecting lighting type, intensity, and color temperature
/// with a live visual preview.
struct LightingControlView: View {

    @ObservedObject var viewModel: RoomFinishViewModel

    // Local slider state to avoid excessive view model updates
    @State private var intensityValue: Float = 0.8
    @State private var colorTempValue: Float = 4000

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            // Lighting type selector
            lightingTypeSection

            // Intensity slider
            intensitySection

            // Color temperature slider
            colorTemperatureSection

            // Visual preview
            lightPreviewSection
        }
        .onAppear {
            intensityValue = viewModel.roomFinish.lightingIntensity
            colorTempValue = viewModel.roomFinish.lightingColorTemp
        }
    }

    // MARK: - Lighting Type Section

    private var lightingTypeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Lighting Type")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(LightingType.allCases) { type in
                        lightingTypeCard(type: type)
                    }
                }
            }
        }
    }

    private func lightingTypeCard(type: LightingType) -> some View {
        let isSelected = viewModel.roomFinish.lightingType == type

        return Button {
            viewModel.updateLightingType(type)
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

    // MARK: - Intensity Section

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("Intensity")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Text("\(Int(intensityValue * 100))%")
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundColor(AppTheme.accent)
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "sun.min")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)

                Slider(value: $intensityValue, in: 0...1, step: 0.01)
                    .tint(AppTheme.accent)
                    .onChange(of: intensityValue) { _, newValue in
                        viewModel.updateLightingIntensity(newValue)
                    }

                Image(systemName: "sun.max.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.accent)
            }
        }
    }

    // MARK: - Color Temperature Section

    private var colorTemperatureSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("Color Temperature")
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Text(String(format: "%.0fK", colorTempValue))
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundColor(AppTheme.accent)
            }

            // Gradient track background
            ZStack(alignment: .leading) {
                // Temperature gradient track
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#FF9329"),  // Warm (2700K)
                                Color(hex: "#FFD4A0"),  // Warm-neutral
                                Color(hex: "#FFFFFF"),  // Neutral (4600K)
                                Color(hex: "#C4D4FF"),  // Cool-neutral
                                Color(hex: "#9BB8FF")   // Cool (6500K)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 8)
                    .padding(.horizontal, AppTheme.Spacing.xs)

                // Slider overlaid on top
                Slider(value: $colorTempValue, in: 2700...6500, step: 100)
                    .tint(.clear)
                    .onChange(of: colorTempValue) { _, newValue in
                        viewModel.updateLightingColorTemp(newValue)
                    }
            }

            // Temperature labels
            HStack {
                Text("2700K")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#FF9329"))

                Spacer()

                Text(viewModel.colorTemperatureLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Text("6500K")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#9BB8FF"))
            }
        }
    }

    // MARK: - Light Preview Section

    private var lightPreviewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Preview")
                .font(AppTheme.caption)
                .foregroundColor(AppTheme.textSecondary)

            HStack(spacing: AppTheme.Spacing.lg) {
                // Light preview circle
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    temperatureColor.opacity(Double(intensityValue) * 0.5),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)

                    // Inner light circle
                    Circle()
                        .fill(temperatureColor)
                        .frame(width: 60, height: 60)
                        .opacity(Double(intensityValue))
                        .shadow(
                            color: temperatureColor.opacity(Double(intensityValue) * 0.8),
                            radius: 20
                        )

                    // Bulb icon
                    Image(systemName: viewModel.roomFinish.lightingType.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(
                            intensityValue > 0.3
                                ? contrastColorForLight
                                : AppTheme.textSecondary
                        )
                }
                .frame(width: 120, height: 120)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                        .fill(AppTheme.surface)
                )

                // Info labels
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    infoRow(label: "Type", value: viewModel.roomFinish.lightingType.displayName)
                    infoRow(label: "Intensity", value: "\(Int(intensityValue * 100))%")
                    infoRow(label: "Temperature", value: String(format: "%.0fK", colorTempValue))
                    infoRow(label: "Tone", value: viewModel.colorTemperatureLabel)

                    if viewModel.roomFinish.lightingType.pricePerSqFt > 0 {
                        infoRow(
                            label: "Cost",
                            value: String(format: "$%.2f/ft\u{00B2}", viewModel.roomFinish.lightingType.pricePerSqFt)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private func infoRow(label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(AppTheme.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
        }
    }

    // MARK: - Computed Properties

    /// Approximate color for the current color temperature.
    private var temperatureColor: Color {
        let t = (colorTempValue - 2700) / (6500 - 2700)
        let r = 1.0 - Double(t) * 0.3
        let g = 0.7 + Double(t) * 0.3
        let b = 0.4 + Double(t) * 0.6
        return Color(red: r, green: g, blue: b)
    }

    /// Determines icon color to contrast against the preview light.
    private var contrastColorForLight: Color {
        let t = (colorTempValue - 2700) / (6500 - 2700)
        // Warmer/brighter lights get a dark icon, cooler/dimmer get a light icon
        return (t < 0.5 && intensityValue > 0.5) ? Color.black.opacity(0.6) : Color.white.opacity(0.8)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        LightingControlView(viewModel: RoomFinishViewModel())
            .padding()
    }
    .background(AppTheme.background)
    .preferredColorScheme(.dark)
}
