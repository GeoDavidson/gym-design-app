import SwiftUI
import ARKit
import RealityKit

// MARK: - Design Mode

enum DesignMode: String, CaseIterable, Identifiable {
    case ar = "AR"
    case virtual = "Virtual"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .ar:      return "arkit"
        case .virtual: return "cube.transparent"
        }
    }
}

// MARK: - AR Design View

/// The main AR design screen. Presents the AR camera feed overlaid with
/// toolbar controls, equipment picker, and design tools.
struct ARDesignView: View {

    // MARK: - State

    @StateObject private var roomDesignViewModel = RoomDesignViewModel()
    @StateObject private var arScanViewModel: ARScanViewModel

    @State private var designMode: DesignMode = .ar
    @State private var showEquipmentPicker = false
    @State private var showDesignTools = false
    @State private var isScanning = true

    @Environment(\.dismiss) private var dismiss

    // MARK: - Init

    init(arSessionService: ARSessionService = ARSessionService()) {
        _arScanViewModel = StateObject(
            wrappedValue: ARScanViewModel(arSessionService: arSessionService)
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Full-screen AR view
                ARContainerView(viewModel: roomDesignViewModel)
                    .ignoresSafeArea()

                // Overlay UI
                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    bottomSection
                }

                // Scanning overlay
                if isScanning {
                    ARScanOverlayView(
                        viewModel: arScanViewModel,
                        onComplete: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                isScanning = false
                            }
                            if let room = arScanViewModel.estimatedRoom {
                                roomDesignViewModel.updateRoomDimensions(
                                    width: room.width,
                                    length: room.length,
                                    height: room.height
                                )
                            }
                        },
                        onSkip: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                isScanning = false
                            }
                        }
                    )
                    .transition(.opacity)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showEquipmentPicker) {
                AREquipmentPickerSheet(
                    equipment: roomDesignViewModel.equipmentCatalog,
                    onSelect: { equipment in
                        roomDesignViewModel.addEquipment(equipment)
                        showEquipmentPicker = false
                    }
                )
            }
            .sheet(isPresented: $showDesignTools) {
                designToolsSheet
            }
            .onAppear {
                arScanViewModel.startScan()
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Back button
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
            }

            Spacer()

            // Mode toggle
            modeToggle

            Spacer()

            // Save button
            Button {
                Task {
                    await roomDesignViewModel.saveDesign()
                }
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
            .disabled(roomDesignViewModel.isSaving)
            .opacity(roomDesignViewModel.isSaving ? 0.5 : 1.0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        HStack(spacing: 4) {
            ForEach(DesignMode.allCases) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        designMode = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 13, weight: .semibold))
                        Text(mode.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(designMode == mode ? .white : Color.appTextSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        designMode == mode
                            ? AnyShapeStyle(Color(hex: "#00D4FF").opacity(0.25))
                            : AnyShapeStyle(Color.clear)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        ARToolbar(
            viewModel: roomDesignViewModel,
            onAddEquipment: { showEquipmentPicker = true },
            onDesignTools: { showDesignTools = true }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Design Tools Sheet

    private var designToolsSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Design Tools")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)

                Text("Room finishes, lighting, and flooring controls coming soon.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showDesignTools = false
                    }
                    .foregroundStyle(Color(hex: "#00D4FF"))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.appBackground)
    }
}

// MARK: - Preview

#Preview {
    ARDesignView()
}
