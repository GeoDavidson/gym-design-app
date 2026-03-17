import SwiftUI

// MARK: - Design Tools Panel

/// Bottom sheet that lets the user adjust room finishes: walls, floor, ceiling, and lighting.
struct DesignToolsPanel: View {

    // MARK: - Tab

    enum DesignTab: String, CaseIterable, Identifiable {
        case walls = "Walls"
        case floor = "Floor"
        case ceiling = "Ceiling"
        case lighting = "Lighting"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .walls:    return "rectangle.portrait.fill"
            case .floor:    return "square.grid.2x2.fill"
            case .ceiling:  return "rectangle.fill"
            case .lighting: return "lightbulb.fill"
            }
        }
    }

    // MARK: - State

    @ObservedObject var viewModel: RoomDesignViewModel
    @StateObject private var finishViewModel: RoomFinishViewModel
    @State private var selectedTab: DesignTab = .walls

    @Environment(\.dismiss) private var dismiss

    // MARK: - Initialization

    init(viewModel: RoomDesignViewModel) {
        self.viewModel = viewModel
        _finishViewModel = StateObject(wrappedValue: RoomFinishViewModel(
            roomFinish: viewModel.roomFinish
        ))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                tabSelector

                Divider()
                    .background(Color.white.opacity(0.1))

                // Tab content
                ScrollView {
                    tabContent
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.md)
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Design Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
        .onAppear {
            finishViewModel.onFinishChanged = { [weak viewModel] finish in
                viewModel?.roomFinish = finish
            }
        }
        .onChange(of: finishViewModel.roomFinish) { _, newValue in
            viewModel.roomFinish = newValue
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(DesignTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: AppTheme.Spacing.xs) {
                        HStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14))
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(selectedTab == tab ? AppTheme.accent : AppTheme.textSecondary)
                        .padding(.vertical, AppTheme.Spacing.sm)

                        // Accent underline
                        Rectangle()
                            .fill(selectedTab == tab ? AppTheme.accent : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .background(AppTheme.surface)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .walls:
            WallColorPicker(viewModel: finishViewModel)
        case .floor:
            FlooringPicker(viewModel: finishViewModel)
        case .ceiling:
            CeilingPicker(viewModel: finishViewModel, roomHeight: viewModel.room.height)
        case .lighting:
            LightingControlView(viewModel: finishViewModel)
        }
    }
}

// MARK: - Preview

#Preview {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            DesignToolsPanel(viewModel: RoomDesignViewModel())
        }
        .preferredColorScheme(.dark)
}
