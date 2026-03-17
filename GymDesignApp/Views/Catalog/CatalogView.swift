import SwiftUI

// MARK: - Catalog View

/// Main catalog screen displaying filterable, searchable equipment in a grid layout.
struct CatalogView: View {

    @StateObject private var viewModel = EquipmentCatalogViewModel()
    @State private var showSortSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar

                    // Category chips
                    CategoryListView(
                        selectedCategory: $viewModel.selectedCategory,
                        onSelect: { viewModel.selectCategory($0) }
                    )
                    .padding(.top, AppTheme.Spacing.sm)

                    // Content
                    if viewModel.isLoading {
                        LoadingView(message: "Loading equipment catalog...")
                    } else if let error = viewModel.errorMessage {
                        errorState(error)
                    } else if viewModel.filteredEquipment.isEmpty {
                        emptyState
                    } else {
                        EquipmentGridView(equipment: viewModel.filteredEquipment)
                    }
                }
            }
            .navigationTitle("Equipment")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    sortButton
                }
            }
            .sheet(isPresented: $showSortSheet) {
                sortSheet
            }
            .task {
                await viewModel.loadCatalog()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundStyle(Color.appTextSecondary)

            TextField("Search equipment...", text: $viewModel.searchText)
                .font(AppTheme.body)
                .foregroundStyle(Color.appTextPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .fill(Color.appSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.sm)
    }

    // MARK: - Sort Button

    private var sortButton: some View {
        Button {
            showSortSheet = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.appAccent)

                if viewModel.sortOption != .nameAsc {
                    Circle()
                        .fill(Color.appAccent)
                        .frame(width: 8, height: 8)
                        .offset(x: 4, y: -4)
                }
            }
        }
    }

    // MARK: - Sort Sheet

    private var sortSheet: some View {
        NavigationStack {
            List {
                ForEach(EquipmentCatalogService.SortOption.allCases) { option in
                    Button {
                        viewModel.sortOption = option
                        showSortSheet = false
                    } label: {
                        HStack {
                            Text(option.rawValue)
                                .font(AppTheme.body)
                                .foregroundStyle(Color.appTextPrimary)

                            Spacer()

                            if viewModel.sortOption == option {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.appAccent)
                            }
                        }
                    }
                    .listRowBackground(Color.appSurface)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showSortSheet = false
                    }
                    .foregroundStyle(Color.appAccent)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Equipment Found",
            message: "Try adjusting your search or filters to find what you're looking for.",
            buttonTitle: "Clear Filters",
            buttonIcon: "xmark.circle"
        ) {
            viewModel.clearFilters()
        }
    }

    // MARK: - Error State

    private func errorState(_ message: String) -> some View {
        EmptyStateView(
            icon: "exclamationmark.triangle.fill",
            title: "Something Went Wrong",
            message: message,
            buttonTitle: "Try Again",
            buttonIcon: "arrow.clockwise"
        ) {
            Task {
                await viewModel.loadCatalog()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CatalogView()
}
