import SwiftUI

// MARK: - Equipment Detail View

/// Full detail screen for a single piece of equipment, with hero image,
/// specs, dimensions diagram, and action buttons.
struct EquipmentDetailView: View {

    let equipment: Equipment

    @State private var isFavorite = false
    @State private var showAddConfirmation = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroSection
                    infoSection
                    dimensionsSection
                    clearanceSection
                    specsSection
                    descriptionSection
                }
                // Bottom padding for sticky button
                .padding(.bottom, 100)
            }

            // Sticky bottom button
            stickyBottomBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                favoriteButton
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack {
            LinearGradient(
                colors: [
                    equipment.category.color.opacity(0.35),
                    equipment.category.color.opacity(0.08),
                    Color.appBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: equipment.category.iconName)
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [equipment.category.color, equipment.category.color.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Category badge
                Text(equipment.category.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(equipment.category.color.opacity(0.7))
                    )
            }
            .padding(.vertical, AppTheme.Spacing.xxl)
        }
        .frame(height: 260)
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(equipment.name)
                .font(.title.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)

            HStack(spacing: AppTheme.Spacing.sm) {
                Text(equipment.brand)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.appTextSecondary)

                if let modelNumber = equipment.modelNumber {
                    Text("·")
                        .foregroundStyle(Color.appTextTertiary)
                    Text(modelNumber)
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextTertiary)
                }
            }

            Text(equipment.displayPrice)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.appAccent)
                .padding(.top, AppTheme.Spacing.xs)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.md)
    }

    // MARK: - Dimensions Section

    private var dimensionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader("Dimensions", icon: "ruler")

            GlassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.md) {
                VStack(spacing: AppTheme.Spacing.md) {
                    // Visual dimension diagram
                    dimensionDiagram

                    Divider()
                        .overlay(Color.appBorder)

                    // Dimension values
                    HStack(spacing: 0) {
                        dimensionValue("Width", value: equipment.dimensions.width)
                        Spacer()
                        dimensionValue("Length", value: equipment.dimensions.length)
                        Spacer()
                        dimensionValue("Height", value: equipment.dimensions.height)
                    }
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.lg)
    }

    private var dimensionDiagram: some View {
        let maxDim = max(equipment.dimensions.width, equipment.dimensions.length, 0.01)
        let diagramWidth: CGFloat = 200
        let scale = diagramWidth / CGFloat(maxDim)
        let w = CGFloat(equipment.dimensions.width) * scale
        let l = CGFloat(equipment.dimensions.length) * scale
        let clampedW = min(max(w, 40), diagramWidth)
        let clampedL = min(max(l, 40), diagramWidth * 0.8)

        return ZStack {
            // Equipment footprint
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(equipment.category.color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(equipment.category.color.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                )
                .frame(width: clampedW, height: clampedL)

            // Width label
            VStack {
                Spacer()
                HStack(spacing: 2) {
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 8))
                    Text(String(format: "W: %.2fm", equipment.dimensions.width))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(Color.appAccent)
                .offset(y: 14)
            }
            .frame(width: clampedW, height: clampedL)

            // Length label
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    Image(systemName: "arrow.up.and.down")
                        .font(.system(size: 8))
                    Text(String(format: "L: %.2fm", equipment.dimensions.length))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
                .foregroundStyle(Color.appAccentSecondary)
                .offset(x: 40)
            }
            .frame(width: clampedW, height: clampedL)
        }
        .frame(height: clampedL + 30)
        .frame(maxWidth: .infinity)
    }

    private func dimensionValue(_ label: String, value: Float) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.appTextTertiary)
            Text(String(format: "%.2fm", value))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(Color.appTextPrimary)
        }
    }

    // MARK: - Clearance Section

    private var clearanceSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader("Required Clearance", icon: "arrow.up.left.and.arrow.down.right")

            GlassCard(cornerRadius: AppTheme.CornerRadius.large, padding: AppTheme.Spacing.md) {
                HStack(spacing: 0) {
                    clearanceValue("Side (each)", value: equipment.requiredClearance.width)
                    Spacer()
                    clearanceValue("Front/Back (each)", value: equipment.requiredClearance.length)
                }
            }

            // Total footprint
            HStack {
                Image(systemName: "square.dashed")
                    .font(.caption)
                    .foregroundStyle(Color.appTextTertiary)

                let totalW = equipment.dimensions.width + equipment.requiredClearance.width * 2
                let totalL = equipment.dimensions.length + equipment.requiredClearance.length * 2
                Text(String(format: "Total floor space: %.2fm x %.2fm (%.1f sq ft)",
                            totalW, totalL, Double(totalW * totalL) * 10.764))
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.horizontal, AppTheme.Spacing.xs)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.lg)
    }

    private func clearanceValue(_ label: String, value: Float) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.appTextTertiary)
            Text(String(format: "%.2fm", value))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(Color.appTextPrimary)
        }
    }

    // MARK: - Specs Section

    private var specsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader("Specifications", icon: "list.bullet.rectangle")

            GlassCard(cornerRadius: AppTheme.CornerRadius.large, padding: 0) {
                VStack(spacing: 0) {
                    if let weight = equipment.weightKg {
                        specRow(icon: "scalemass", label: "Weight", value: String(format: "%.0f kg (%.0f lbs)", weight, weight * 2.20462))
                    }

                    specRow(
                        icon: equipment.powerRequired ? "bolt.fill" : "bolt.slash",
                        label: "Power Required",
                        value: equipment.powerRequired ? "Yes" : "No",
                        valueColor: equipment.powerRequired ? Color(hex: "FFB800") : Color.appTextSecondary
                    )

                    specRow(icon: "tag", label: "Category", value: equipment.category.displayName, isLast: true)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.lg)
    }

    private func specRow(
        icon: String,
        label: String,
        value: String,
        valueColor: Color = .appTextPrimary,
        isLast: Bool = false
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 24)

                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)

                Spacer()

                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(valueColor)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm + 2)

            if !isLast {
                Divider()
                    .overlay(Color.appBorder)
                    .padding(.leading, 52)
            }
        }
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader("Description", icon: "text.alignleft")

            Text(equipment.description)
                .font(AppTheme.body)
                .foregroundStyle(Color.appTextSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.lg)
    }

    // MARK: - Sticky Bottom Bar

    private var stickyBottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(Color.appBorder)

            AccentButton(
                title: "Add to Design",
                icon: "plus.square.on.square"
            ) {
                showAddConfirmation = true
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.top, AppTheme.Spacing.sm)
            .padding(.bottom, AppTheme.Spacing.md)
        }
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .alert("Added to Design", isPresented: $showAddConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(equipment.name) has been added to your current design.")
        }
    }

    // MARK: - Favorite Button

    private var favoriteButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isFavorite.toggle()
            }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.body.weight(.medium))
                .foregroundStyle(isFavorite ? Color(hex: "FF3B5C") : Color.appTextSecondary)
                .symbolEffect(.bounce, value: isFavorite)
        }
    }

    // MARK: - Section Header Helper

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.appAccent)

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EquipmentDetailView(
            equipment: Equipment(
                id: "preview_001",
                name: "Pro Treadmill X9000",
                description: "Commercial-grade treadmill with a 22-inch HD touchscreen, speeds up to 15 mph, incline range of -3% to 15%, and Bluetooth connectivity. Built-in heart rate monitoring and over 40 preset workout programs. Perfect for both commercial gyms and dedicated home fitness enthusiasts.",
                category: .cardio,
                dimensions: EquipmentDimensions(width: 0.84, length: 2.03, height: 1.63),
                price: 3499.99,
                brand: "LifeFitness",
                modelNumber: "LF-X9000",
                usdzModelName: "treadmill_x9000.usdz",
                requiredClearance: EquipmentDimensions(width: 0.3, length: 1.2, height: 0),
                weightKg: 136,
                powerRequired: true
            )
        )
    }
    .preferredColorScheme(.dark)
}
