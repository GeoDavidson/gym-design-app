import SwiftUI

// MARK: - Saved Designs Grid View

struct SavedDesignsGridView: View {

    @StateObject private var viewModel = SavedDesignsViewModel()
    @State private var designToDelete: RoomDesign?
    @State private var showDeleteConfirmation = false

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // MARK: Body

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                loadingGrid
            } else if viewModel.sortedDesigns.isEmpty {
                emptyState
            } else {
                designGrid
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("My Designs")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                sortMenu
            }
        }
        .onAppear {
            if viewModel.designs.isEmpty {
                Task {
                    await viewModel.fetchDesigns()
                }
            }
        }
        .alert("Delete Design", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                designToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let design = designToDelete {
                    Task {
                        await viewModel.deleteDesign(id: design.id)
                    }
                }
                designToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete \"\(designToDelete?.name ?? "this design")\"? This action cannot be undone.")
        }
    }

    // MARK: Sort Menu

    private var sortMenu: some View {
        Menu {
            ForEach(SortOption.allCases) { option in
                Button {
                    viewModel.sortOption = option
                } label: {
                    HStack {
                        Text(option.rawValue)
                        if viewModel.sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.accent)
        }
    }

    // MARK: Design Grid

    private var designGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(viewModel.sortedDesigns) { design in
                SavedDesignCard(design: design)
                    .contextMenu {
                        contextMenuItems(for: design)
                    }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.bottom, AppTheme.Spacing.xxl)
    }

    // MARK: Context Menu

    @ViewBuilder
    private func contextMenuItems(for design: RoomDesign) -> some View {
        Button {
            Task {
                await viewModel.duplicateDesign(id: design.id)
            }
        } label: {
            Label("Duplicate", systemImage: "doc.on.doc")
        }

        Button {
            // Share action placeholder
        } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }

        Divider()

        Button(role: .destructive) {
            designToDelete = design
            showDeleteConfirmation = true
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: Loading Grid

    private var loadingGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(AppTheme.surface)
                    .frame(height: 200)
                    .shimmer()
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.textSecondary)

            Text("No Saved Designs")
                .font(AppTheme.title)
                .foregroundStyle(AppTheme.textPrimary)

            Text("Your saved gym designs will appear here.\nStart by creating a new design.")
                .font(AppTheme.body)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Saved Design Card

private struct SavedDesignCard: View {

    let design: RoomDesign

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Thumbnail gradient
            ZStack {
                LinearGradient(
                    colors: [
                        AppTheme.accent.opacity(0.25),
                        AppTheme.accentSecondary.opacity(0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: "cube.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.5))
            }
            .frame(height: 100)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: AppTheme.CornerRadius.large,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: AppTheme.CornerRadius.large
                )
            )

            // Info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(design.name)
                    .font(AppTheme.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)

                Text(design.displayDate)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)

                HStack {
                    Text(design.room.displayArea)
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textSecondary)

                    Spacer()

                    Text("\(design.equipmentCount) items")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(AppTheme.accent, in: Capsule())
                }
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.bottom, AppTheme.Spacing.sm)
        }
        .glassMaterial(cornerRadius: AppTheme.CornerRadius.large)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SavedDesignsGridView()
    }
    .preferredColorScheme(.dark)
}
