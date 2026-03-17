import SwiftUI

// MARK: - AR Toolbar

/// A bottom toolbar for the AR design view. Contains action buttons for adding
/// equipment, design tools, undo/redo, and delete. Displays a selected
/// equipment info bar when an item is selected.
struct ARToolbar: View {

    @ObservedObject var viewModel: RoomDesignViewModel

    /// Action triggered when the user taps the Add Equipment button.
    var onAddEquipment: () -> Void
    /// Action triggered when the user taps the Design Tools button.
    var onDesignTools: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            // Selected equipment info bar
            if let selectedID = viewModel.selectedPlacementID,
               let placement = viewModel.placements.first(where: { $0.id == selectedID }),
               let equipment = viewModel.equipment(for: placement) {
                selectedInfoBar(equipment: equipment)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Toolbar
            toolbarContent
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.selectedPlacementID)
    }

    // MARK: - Selected Equipment Info Bar

    private func selectedInfoBar(equipment: Equipment) -> some View {
        HStack(spacing: 12) {
            // Category color indicator
            Circle()
                .fill(equipment.category.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(equipment.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("Tap to deselect")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            // Deselect button
            Button {
                viewModel.selectedPlacementID = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "#00D4FF").opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            viewModel.selectedPlacementID = nil
        }
    }

    // MARK: - Toolbar Content

    private var toolbarContent: some View {
        HStack(spacing: 0) {
            toolbarButton(
                icon: "plus.circle.fill",
                label: "Add",
                action: onAddEquipment
            )

            toolbarButton(
                icon: "paintbrush.fill",
                label: "Design",
                action: onDesignTools
            )

            toolbarButton(
                icon: "arrow.uturn.backward",
                label: "Undo",
                action: { /* TODO: Undo action */ }
            )

            toolbarButton(
                icon: "arrow.uturn.forward",
                label: "Redo",
                action: { /* TODO: Redo action */ }
            )

            // Delete — only visible when equipment is selected
            if viewModel.selectedPlacementID != nil {
                toolbarButton(
                    icon: "trash.fill",
                    label: "Delete",
                    tint: Color.appError,
                    action: {
                        if let selectedID = viewModel.selectedPlacementID {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.removePlacement(selectedID)
                            }
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Toolbar Button

    private func toolbarButton(
        icon: String,
        label: String,
        tint: Color = Color(hex: "#00D4FF"),
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 44, height: 44)
                    .background(tint.opacity(0.12), in: Circle())

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()

        VStack {
            Spacer()
            ARToolbar(
                viewModel: {
                    let vm = RoomDesignViewModel()
                    vm.equipmentCatalog = [
                        Equipment(
                            name: "Treadmill",
                            description: "Commercial treadmill",
                            category: .cardio,
                            dimensions: EquipmentDimensions(width: 0.8, length: 2.0, height: 1.5),
                            price: 2999,
                            brand: "NordicTrack",
                            usdzModelName: "treadmill",
                            requiredClearance: EquipmentDimensions(width: 0.5, length: 1.0, height: 0.5)
                        ),
                    ]
                    vm.addEquipment(vm.equipmentCatalog[0])
                    return vm
                }(),
                onAddEquipment: {},
                onDesignTools: {}
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    .preferredColorScheme(.dark)
}
