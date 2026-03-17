import Foundation

// MARK: - Equipment Catalog Service

/// Singleton service responsible for loading, caching, filtering, and sorting
/// the equipment catalog from local mock data.
final class EquipmentCatalogService: ObservableObject, @unchecked Sendable {

    // MARK: - Singleton

    static let shared = EquipmentCatalogService()

    // MARK: - Sort Option

    enum SortOption: String, CaseIterable, Identifiable {
        case nameAsc = "Name (A-Z)"
        case priceAsc = "Price (Low-High)"
        case priceDesc = "Price (High-Low)"
        case category = "Category"

        var id: String { rawValue }
    }

    // MARK: - Private State

    private var cachedEquipment: [Equipment]?
    private let lock = NSLock()

    // MARK: - Init

    private init() {}

    // MARK: - Public API

    /// Loads and returns all equipment, caching the result in memory.
    func fetchEquipment() async throws -> [Equipment] {
        if let cached = cachedEquipment {
            return cached
        }

        let equipment = try await loadFromBundle()

        lock.lock()
        cachedEquipment = equipment
        lock.unlock()

        return equipment
    }

    /// Returns equipment filtered by a specific category.
    func fetchByCategory(_ category: EquipmentCategory) async throws -> [Equipment] {
        let all = try await fetchEquipment()
        return all.filter { $0.category == category }
    }

    /// Searches equipment by name or description (case-insensitive).
    func search(query: String) async throws -> [Equipment] {
        let all = try await fetchEquipment()

        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return all
        }

        let lowered = query.lowercased()
        return all.filter { equipment in
            equipment.name.lowercased().contains(lowered)
            || equipment.description.lowercased().contains(lowered)
            || equipment.brand.lowercased().contains(lowered)
            || equipment.category.displayName.lowercased().contains(lowered)
        }
    }

    /// Filters and sorts equipment based on search query, category, and sort option.
    func filteredEquipment(
        searchQuery: String,
        category: EquipmentCategory?,
        sortOption: SortOption
    ) async throws -> [Equipment] {
        var results = try await fetchEquipment()

        // Apply category filter
        if let category {
            results = results.filter { $0.category == category }
        }

        // Apply search filter
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let lowered = trimmed.lowercased()
            results = results.filter { equipment in
                equipment.name.lowercased().contains(lowered)
                || equipment.description.lowercased().contains(lowered)
                || equipment.brand.lowercased().contains(lowered)
            }
        }

        // Apply sort
        results = sorted(results, by: sortOption)

        return results
    }

    /// Sorts equipment by the given option.
    func sorted(_ equipment: [Equipment], by option: SortOption) -> [Equipment] {
        switch option {
        case .nameAsc:
            return equipment.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .priceAsc:
            return equipment.sorted { $0.price < $1.price }
        case .priceDesc:
            return equipment.sorted { $0.price > $1.price }
        case .category:
            return equipment.sorted {
                if $0.category.displayName == $1.category.displayName {
                    return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
                return $0.category.displayName < $1.category.displayName
            }
        }
    }

    /// Clears the in-memory cache, forcing a reload on next fetch.
    func clearCache() {
        lock.lock()
        cachedEquipment = nil
        lock.unlock()
    }

    // MARK: - Private Helpers

    private func loadFromBundle() async throws -> [Equipment] {
        guard let url = Bundle.main.url(forResource: "MockEquipment", withExtension: "json") else {
            throw CatalogError.fileNotFound
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([Equipment].self, from: data)
    }
}

// MARK: - Catalog Error

extension EquipmentCatalogService {
    enum CatalogError: LocalizedError {
        case fileNotFound
        case decodingFailed

        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "Equipment catalog data file not found."
            case .decodingFailed:
                return "Failed to decode equipment catalog data."
            }
        }
    }
}
