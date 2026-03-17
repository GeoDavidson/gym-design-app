import SwiftUI
import RealityKit

// MARK: - Virtual Design View

/// Full virtual design screen for building a gym layout without AR.
/// Mirrors the AR design flow but uses `VirtualRoomView` for 3D rendering.
struct VirtualDesignView: View {

    // MARK: - State

    @StateObject private var roomDesignViewModel = RoomDesignViewModel()

    @State private var showEquipmentPicker = false
    @State private var showDesignTools = false
    @State private var showRoomDimensionInput = true
    @State private var isEditingName = false

    @FocusState private var nameFieldFocused: Bool

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.background.ignoresSafeArea()

                if showRoomDimensionInput {
                    roomDimensionInputLayer
                } else {
                    designLayer
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEquipmentPicker) {
                equipmentPickerSheet
            }
            .sheet(isPresented: $showDesignTools) {
                DesignToolsPanel(viewModel: roomDesignViewModel)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Room Dimension Input Layer

    private var roomDimensionInputLayer: some View {
        RoomDimensionInputView { width, length, height in
            roomDesignViewModel.updateRoomDimensions(
                width: width,
                length: length,
                height: height
            )
            withAnimation(.easeInOut(duration: 0.4)) {
                showRoomDimensionInput = false
            }
        }
    }

    // MARK: - Design Layer

    private var designLayer: some View {
        ZStack {
            // Full-screen virtual room
            VirtualRoomView(viewModel: roomDesignViewModel)
                .ignoresSafeArea()

            // Camera controls overlay
            VirtualCameraControls(viewModel: roomDesignViewModel)
                .ignoresSafeArea()

            // Top bar overlay
            VStack {
                topBar
                Spacer()
            }

            // Bottom toolbar overlay
            VStack {
                Spacer()
                bottomToolbar
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Back button
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }

            // Room name (editable)
            if isEditingName {
                TextField("Room Name", text: $roomDesignViewModel.designName)
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(AppTheme.surface.opacity(0.8), in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))
                    .focused($nameFieldFocused)
                    .onSubmit {
                        isEditingName = false
                    }
                    .onAppear {
                        nameFieldFocused = true
                    }
            } else {
                Button {
                    isEditingName = true
                } label: {
                    HStack(spacing: 4) {
                        Text(roomDesignViewModel.designName)
                            .font(AppTheme.headline)
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(1)

                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }

            Spacer()

            // Save button
            Button {
                Task {
                    await roomDesignViewModel.saveDesign()
                }
            } label: {
                Group {
                    if roomDesignViewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
            .disabled(roomDesignViewModel.isSaving)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.6), Color.black.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            toolbarButton(icon: "cube.fill", label: "Equipment") {
                showEquipmentPicker = true
            }

            toolbarButton(icon: "paintbrush.fill", label: "Finishes") {
                showDesignTools = true
            }

            toolbarButton(icon: "arrow.counterclockwise", label: "Undo") {
                undoLastPlacement()
            }

            toolbarButton(icon: "trash", label: "Delete") {
                deleteSelectedPlacement()
            }
            .opacity(roomDesignViewModel.selectedPlacementID != nil ? 1.0 : 0.4)
            .disabled(roomDesignViewModel.selectedPlacementID == nil)

            toolbarButton(icon: "square.resize", label: "Resize") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showRoomDimensionInput = true
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.bottom, AppTheme.Spacing.sm)
    }

    // MARK: - Equipment Picker Sheet

    private var equipmentPickerSheet: some View {
        NavigationStack {
            equipmentPickerContent
                .navigationTitle("Equipment")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            showEquipmentPicker = false
                        }
                        .foregroundColor(AppTheme.accent)
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
    }

    private var equipmentPickerContent: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.sm) {
                if roomDesignViewModel.equipmentCatalog.isEmpty {
                    emptyEquipmentState
                } else {
                    ForEach(EquipmentCategory.allCases) { category in
                        let items = roomDesignViewModel.equipmentCatalog.filter { $0.category == category }
                        if !items.isEmpty {
                            equipmentSection(category: category, items: items)
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private var emptyEquipmentState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.textSecondary)

            Text("No Equipment Available")
                .font(AppTheme.headline)
                .foregroundColor(AppTheme.textPrimary)

            Text("Equipment catalog is loading or empty.")
                .font(AppTheme.body)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.xxl)
    }

    private func equipmentSection(category: EquipmentCategory, items: [Equipment]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: category.iconName)
                    .foregroundColor(category.color)
                Text(category.displayName)
                    .font(AppTheme.headline)
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.top, AppTheme.Spacing.sm)

            ForEach(items) { equipment in
                Button {
                    roomDesignViewModel.addEquipment(equipment)
                    showEquipmentPicker = false
                } label: {
                    HStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: category.iconName)
                            .font(.system(size: 20))
                            .foregroundColor(category.color)
                            .frame(width: 44, height: 44)
                            .background(category.color.opacity(0.15), in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(equipment.name)
                                .font(AppTheme.body)
                                .foregroundColor(AppTheme.textPrimary)
                            Text(equipment.displayPrice)
                                .font(AppTheme.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppTheme.accent)
                    }
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Toolbar Button

    private func toolbarButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Actions

    private func undoLastPlacement() {
        guard let lastPlacement = roomDesignViewModel.placements.last else { return }
        roomDesignViewModel.removePlacement(lastPlacement.id)
    }

    private func deleteSelectedPlacement() {
        guard let selectedID = roomDesignViewModel.selectedPlacementID else { return }
        roomDesignViewModel.removePlacement(selectedID)
    }
}

// MARK: - Preview

#Preview {
    VirtualDesignView()
        .preferredColorScheme(.dark)
}
