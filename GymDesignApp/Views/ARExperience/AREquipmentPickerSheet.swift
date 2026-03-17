import SwiftUI

// MARK: - AR Equipment Picker Sheet

/// A bottom sheet that lets the user browse and select equipment to place in the
/// AR scene. Supports search, category filtering, and displays a grid of
/// equipment cards.
struct AREquipmentPickerSheet: View {

    // MARK: - Properties

    /// Full equipment catalog. Pass this from the parent or use an environment object.
    let equipment: [Equipment]
    /// Called when the user selects a piece of equipment.
    let onSelect: (Equipment) -> Void

    @State private var searchText = ""
    @State private var selectedCategory: EquipmentCategory?
    @Environment(\.dismiss) private var dismiss

    // MARK: - Filtered Results

    private var filteredEquipment: [Equipment] {
        var results = equipment

        // Category filter
        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }

        // Search filter
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmed.isEmpty {
            results = results.filter { item in
                item.name.lowercased().contains(trimmed)
                    || item.brand.lowercased().contains(trimmed)
                    || item.category.displayName.lowercased().contains(trimmed)
            }
        }

        return results
    }

    // MARK: - Grid Layout

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                categoryTabs
                equipmentGrid
            }
            .background(Color.appBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Add Equipment")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.appBackground)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)

            TextField("Search equipment...", text: $searchText)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .tint(Color(hex: "#00D4FF"))

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Category Tabs

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // "All" tab
                categoryTab(label: "All", icon: "square.grid.2x2", isSelected: selectedCategory == nil) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = nil
                    }
                }

                // Category tabs
                ForEach(EquipmentCategory.allCases) { category in
                    categoryTab(
                        label: category.displayName,
                        icon: category.iconName,
                        color: category.color,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
    }

    private func categoryTab(
        label: String,
        icon: String,
        color: Color = Color(hex: "#00D4FF"),
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : Color.appTextSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? AnyShapeStyle(color.opacity(0.2))
                    : AnyShapeStyle(Color.appSurface)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? color.opacity(0.5) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Equipment Grid

    private var equipmentGrid: some View {
        ScrollView {
            if filteredEquipment.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredEquipment) { item in
                        equipmentCard(item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Equipment Card

    private func equipmentCard(_ item: Equipment) -> some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            onSelect(item)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                // Thumbnail / icon area
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    item.category.color.opacity(0.15),
                                    item.category.color.opacity(0.05),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Image(systemName: item.category.iconName)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(item.category.color)
                }
                .frame(height: 90)

                // Info section
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(item.displayPrice)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: "#00D4FF"))

                    Text(item.dimensions.displayString)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Color.appTextSecondary)

            Text("No equipment found")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

            Text("Try adjusting your search or category filter.")
                .font(.system(size: 14))
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - Preview

#Preview {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            AREquipmentPickerSheet(
                equipment: [
                    Equipment(
                        name: "Commercial Treadmill",
                        description: "High-end commercial treadmill",
                        category: .cardio,
                        dimensions: EquipmentDimensions(width: 0.85, length: 2.1, height: 1.5),
                        price: 3499,
                        brand: "NordicTrack",
                        usdzModelName: "treadmill",
                        requiredClearance: EquipmentDimensions(width: 0.5, length: 1.0, height: 0.5)
                    ),
                    Equipment(
                        name: "Power Rack",
                        description: "Heavy-duty power rack",
                        category: .strength,
                        dimensions: EquipmentDimensions(width: 1.2, length: 1.5, height: 2.3),
                        price: 1899,
                        brand: "Rogue",
                        usdzModelName: "power_rack",
                        requiredClearance: EquipmentDimensions(width: 0.8, length: 1.2, height: 0.3)
                    ),
                    Equipment(
                        name: "Adjustable Dumbbells",
                        description: "5-52.5 lb adjustable set",
                        category: .freeWeights,
                        dimensions: EquipmentDimensions(width: 0.4, length: 0.2, height: 0.2),
                        price: 449,
                        brand: "Bowflex",
                        usdzModelName: "dumbbells",
                        requiredClearance: EquipmentDimensions(width: 0.5, length: 0.5, height: 0.3)
                    ),
                    Equipment(
                        name: "Yoga Mat",
                        description: "Premium exercise mat",
                        category: .stretching,
                        dimensions: EquipmentDimensions(width: 0.6, length: 1.8, height: 0.01),
                        price: 79,
                        brand: "Manduka",
                        usdzModelName: "yoga_mat",
                        requiredClearance: EquipmentDimensions(width: 0.3, length: 0.3, height: 0.0)
                    ),
                ],
                onSelect: { _ in }
            )
        }
        .preferredColorScheme(.dark)
}
