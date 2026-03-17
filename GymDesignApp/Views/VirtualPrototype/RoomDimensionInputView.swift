import SwiftUI

// MARK: - Room Dimension Input View

struct RoomDimensionInputView: View {

    // MARK: - State

    @State private var widthValue: Double = AppConstants.DefaultRoom.width
    @State private var lengthValue: Double = AppConstants.DefaultRoom.length
    @State private var heightValue: Double = AppConstants.DefaultRoom.height
    @State private var unit: MeasurementUnit = .metric
    @State private var showValidationError = false
    @State private var validationMessage = ""

    var onCreateRoom: ((Float, Float, Float) -> Void)?

    @Environment(\.dismiss) private var dismiss

    // MARK: - Constants

    private let minDimension = AppConstants.DefaultRoom.minDimension
    private let maxDimension = AppConstants.DefaultRoom.maxDimension
    private let step: Double = 0.5
    private let feetPerMeter: Double = 3.28084

    // MARK: - Computed

    /// Displayed values in the user's chosen unit.
    private var displayWidth: Double {
        unit == .metric ? widthValue : widthValue * feetPerMeter
    }

    private var displayLength: Double {
        unit == .metric ? lengthValue : lengthValue * feetPerMeter
    }

    private var displayHeight: Double {
        unit == .metric ? heightValue : heightValue * feetPerMeter
    }

    private var displayMin: Double {
        unit == .metric ? minDimension : minDimension * feetPerMeter
    }

    private var displayMax: Double {
        unit == .metric ? maxDimension : maxDimension * feetPerMeter
    }

    private var displayStep: Double {
        unit == .metric ? step : step * feetPerMeter
    }

    private var unitLabel: String {
        unit == .metric ? "m" : "ft"
    }

    private var areaDisplay: String {
        let area = widthValue * lengthValue
        if unit == .metric {
            return String(format: "%.1f m\u{00B2}", area)
        } else {
            let areaFt = area * feetPerMeter * feetPerMeter
            return String(format: "%.1f ft\u{00B2}", areaFt)
        }
    }

    private var isValid: Bool {
        widthValue >= minDimension && widthValue <= maxDimension
            && lengthValue >= minDimension && lengthValue <= maxDimension
            && heightValue >= minDimension && heightValue <= maxDimension
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    headerSection
                    unitToggleSection
                    roomPreview
                    dimensionInputs
                    areaInfoSection
                    createButton
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.lg)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Invalid Dimensions", isPresented: $showValidationError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationMessage)
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "square.resize")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.accentGradient)

            Text("Room Dimensions")
                .font(AppTheme.title)
                .foregroundColor(AppTheme.textPrimary)

            Text("Enter your room measurements to create a virtual prototype.")
                .font(AppTheme.body)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, AppTheme.Spacing.sm)
    }

    private var unitToggleSection: some View {
        GlassCard(cornerRadius: AppTheme.CornerRadius.medium, padding: AppTheme.Spacing.sm) {
            Picker("Unit", selection: $unit) {
                Text("Metric (m)").tag(MeasurementUnit.metric)
                Text("Imperial (ft)").tag(MeasurementUnit.imperial)
            }
            .pickerStyle(.segmented)
        }
    }

    private var roomPreview: some View {
        GlassCard {
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Top-Down Preview")
                    .font(AppTheme.caption)
                    .foregroundColor(AppTheme.textSecondary)

                GeometryReader { geometry in
                    let maxSide = max(widthValue, lengthValue)
                    let scale = min(geometry.size.width, geometry.size.height) / CGFloat(maxSide + 1)
                    let rectW = CGFloat(widthValue) * scale
                    let rectL = CGFloat(lengthValue) * scale

                    ZStack {
                        // Grid lines
                        GridPattern(
                            width: geometry.size.width,
                            height: geometry.size.height,
                            cellSize: scale * CGFloat(step)
                        )
                        .stroke(Color.white.opacity(0.05), lineWidth: 0.5)

                        // Room rectangle
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppTheme.accent.opacity(0.1))
                            .frame(width: rectW, height: rectL)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(AppTheme.accent, lineWidth: 2)
                            )

                        // Width label
                        Text(String(format: "%.1f%@", displayWidth, unitLabel))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(AppTheme.accent)
                            .offset(y: -rectL / 2 - 12)

                        // Length label
                        Text(String(format: "%.1f%@", displayLength, unitLabel))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(AppTheme.accent)
                            .rotationEffect(.degrees(-90))
                            .offset(x: -rectW / 2 - 18)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(height: 200)
            }
        }
    }

    private var dimensionInputs: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            DimensionRow(
                label: "Width",
                icon: "arrow.left.and.right",
                value: $widthValue,
                displayValue: displayWidth,
                unit: unitLabel,
                range: minDimension...maxDimension,
                step: step,
                conversionFactor: unit == .metric ? 1.0 : feetPerMeter
            )

            DimensionRow(
                label: "Length",
                icon: "arrow.up.and.down",
                value: $lengthValue,
                displayValue: displayLength,
                unit: unitLabel,
                range: minDimension...maxDimension,
                step: step,
                conversionFactor: unit == .metric ? 1.0 : feetPerMeter
            )

            DimensionRow(
                label: "Height",
                icon: "arrow.up.to.line",
                value: $heightValue,
                displayValue: displayHeight,
                unit: unitLabel,
                range: minDimension...maxDimension,
                step: step,
                conversionFactor: unit == .metric ? 1.0 : feetPerMeter
            )
        }
    }

    private var areaInfoSection: some View {
        GlassCard(cornerRadius: AppTheme.CornerRadius.medium) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Floor Area")
                        .font(AppTheme.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    Text(areaDisplay)
                        .font(AppTheme.headline)
                        .foregroundColor(AppTheme.textPrimary)
                }
                Spacer()
                Image(systemName: "square.dashed")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.accent)
            }
        }
    }

    private var createButton: some View {
        AccentButton(
            title: "Create Room",
            icon: "plus.rectangle.on.rectangle",
            isDisabled: !isValid
        ) {
            guard isValid else {
                validationMessage = "Each dimension must be between \(String(format: "%.1f", displayMin))\(unitLabel) and \(String(format: "%.1f", displayMax))\(unitLabel)."
                showValidationError = true
                return
            }
            onCreateRoom?(Float(widthValue), Float(lengthValue), Float(heightValue))
        }
        .padding(.top, AppTheme.Spacing.sm)
    }
}

// MARK: - Dimension Row

private struct DimensionRow: View {
    let label: String
    let icon: String
    @Binding var value: Double
    let displayValue: Double
    let unit: String
    let range: ClosedRange<Double>
    let step: Double
    let conversionFactor: Double

    var body: some View {
        GlassCard(cornerRadius: AppTheme.CornerRadius.medium) {
            VStack(spacing: AppTheme.Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(AppTheme.accent)
                    Text(label)
                        .font(AppTheme.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()
                    Text(String(format: "%.1f %@", displayValue, unit))
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundColor(AppTheme.accent)
                }

                HStack(spacing: AppTheme.Spacing.md) {
                    Button {
                        let newValue = value - step
                        if newValue >= range.lowerBound {
                            value = newValue
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(value <= range.lowerBound ? AppTheme.textSecondary.opacity(0.3) : AppTheme.accent)
                    }
                    .disabled(value <= range.lowerBound)

                    Slider(
                        value: $value,
                        in: range,
                        step: step
                    )
                    .tint(AppTheme.accent)

                    Button {
                        let newValue = value + step
                        if newValue <= range.upperBound {
                            value = newValue
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(value >= range.upperBound ? AppTheme.textSecondary.opacity(0.3) : AppTheme.accent)
                    }
                    .disabled(value >= range.upperBound)
                }
            }
        }
    }
}

// MARK: - Grid Pattern Shape

private struct GridPattern: Shape {
    let width: CGFloat
    let height: CGFloat
    let cellSize: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard cellSize > 2 else { return path }

        let cols = Int(width / cellSize) + 1
        let rows = Int(height / cellSize) + 1

        for col in 0...cols {
            let x = CGFloat(col) * cellSize
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: height))
        }
        for row in 0...rows {
            let y = CGFloat(row) * cellSize
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: width, y: y))
        }
        return path
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RoomDimensionInputView { w, l, h in
            print("Room created: \(w) x \(l) x \(h)")
        }
    }
    .preferredColorScheme(.dark)
}
