import Foundation
import Combine
import SwiftUI

// MARK: - Equipment Catalog ViewModel

@MainActor
final class EquipmentCatalogViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var equipment: [Equipment] = []
    @Published var filteredEquipment: [Equipment] = []
    @Published var selectedCategory: EquipmentCategory?
    @Published var searchText: String = ""
    @Published var sortOption: SortOption = .nameAsc
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Sort Option

    typealias SortOption = EquipmentCatalogService.SortOption

    // MARK: - Dependencies

    private let service: EquipmentCatalogService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(service: EquipmentCatalogService = .shared) {
        self.service = service
        setupFilterPipeline()
    }

    // MARK: - Combine Pipeline

    /// Sets up a reactive pipeline that debounces search input and
    /// reacts to category/sort changes to update filteredEquipment.
    private func setupFilterPipeline() {
        let searchPublisher = $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()

        let categoryPublisher = $selectedCategory
            .removeDuplicates()

        let sortPublisher = $sortOption
            .removeDuplicates()

        let equipmentPublisher = $equipment
            .removeDuplicates()

        Publishers.CombineLatest4(
            searchPublisher,
            categoryPublisher,
            sortPublisher,
            equipmentPublisher
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] searchText, category, sort, allEquipment in
            self?.applyFilters(
                searchText: searchText,
                category: category,
                sort: sort,
                source: allEquipment
            )
        }
        .store(in: &cancellables)
    }

    // MARK: - Filter Logic

    private func applyFilters(
        searchText: String,
        category: EquipmentCategory?,
        sort: SortOption,
        source: [Equipment]
    ) {
        var results = source

        // Category filter
        if let category {
            results = results.filter { $0.category == category }
        }

        // Search filter
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let lowered = trimmed.lowercased()
            results = results.filter { equipment in
                equipment.name.lowercased().contains(lowered)
                || equipment.description.lowercased().contains(lowered)
                || equipment.brand.lowercased().contains(lowered)
                || equipment.category.displayName.lowercased().contains(lowered)
            }
        }

        // Sort
        results = service.sorted(results, by: sort)

        withAnimation(.easeInOut(duration: 0.25)) {
            filteredEquipment = results
        }
    }

    // MARK: - Public Actions

    /// Loads the full equipment catalog from the service.
    func loadCatalog() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let loaded = try await service.fetchEquipment()
            equipment = loaded
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Selects a category filter or clears it if the same category is tapped again.
    func selectCategory(_ category: EquipmentCategory?) {
        if selectedCategory == category {
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
    }

    /// Clears all filters and resets to the default state.
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        sortOption = .nameAsc
    }

    /// Returns the count of active filters for UI badge display.
    var activeFilterCount: Int {
        var count = 0
        if selectedCategory != nil { count += 1 }
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { count += 1 }
        if sortOption != .nameAsc { count += 1 }
        return count
    }
}
