import Foundation
import Combine

// MARK: - Sort Option

enum SortOption: String, CaseIterable, Identifiable {
    case recent = "Most Recent"
    case name = "Name"
    case roomSize = "Room Size"

    var id: String { rawValue }
}

// MARK: - Saved Designs View Model

@MainActor
final class SavedDesignsViewModel: ObservableObject {

    // MARK: Published Properties

    @Published var designs: [RoomDesign] = []
    @Published var isLoading: Bool = false
    @Published var sortOption: SortOption = .recent

    // MARK: Computed Properties

    var sortedDesigns: [RoomDesign] {
        switch sortOption {
        case .recent:
            return designs.sorted { $0.createdAt > $1.createdAt }
        case .name:
            return designs.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .roomSize:
            return designs.sorted { $0.room.area > $1.room.area }
        }
    }

    // MARK: Data Loading

    func fetchDesigns() async {
        isLoading = true
        defer { isLoading = false }

        // Simulate network delay
        try? await Task.sleep(for: .milliseconds(500))

        designs = Self.mockDesigns
    }

    // MARK: Actions

    func deleteDesign(id: String) async {
        designs.removeAll { $0.id == id }

        // TODO: Delete from Firestore
    }

    func duplicateDesign(id: String) async {
        guard let original = designs.first(where: { $0.id == id }) else { return }

        let duplicate = RoomDesign(
            userID: original.userID,
            name: "\(original.name) (Copy)",
            room: original.room,
            roomFinish: original.roomFinish,
            placements: original.placements,
            isFavorite: false
        )

        designs.insert(duplicate, at: 0)

        // TODO: Save duplicate to Firestore
    }

    // MARK: Mock Data

    private static let mockDesigns: [RoomDesign] = [
        RoomDesign(
            userID: "mock-user-1",
            name: "Home Gym",
            room: Room(width: 5.0, length: 6.0, height: 2.8),
            placements: [
                EquipmentPlacement(equipmentID: "eq-1", positionX: 1, positionY: 0, positionZ: 1),
                EquipmentPlacement(equipmentID: "eq-2", positionX: 2, positionY: 0, positionZ: 3),
                EquipmentPlacement(equipmentID: "eq-3", positionX: 3, positionY: 0, positionZ: 1)
            ],
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        ),
        RoomDesign(
            userID: "mock-user-1",
            name: "Garage Gym",
            room: Room(width: 7.0, length: 4.5, height: 3.0),
            placements: [
                EquipmentPlacement(equipmentID: "eq-4", positionX: 1, positionY: 0, positionZ: 2),
                EquipmentPlacement(equipmentID: "eq-5", positionX: 3, positionY: 0, positionZ: 2)
            ],
            createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        ),
        RoomDesign(
            userID: "mock-user-1",
            name: "Basement Setup",
            room: Room(width: 8.0, length: 10.0, height: 2.5),
            placements: [
                EquipmentPlacement(equipmentID: "eq-1", positionX: 2, positionY: 0, positionZ: 4),
                EquipmentPlacement(equipmentID: "eq-2", positionX: 4, positionY: 0, positionZ: 4),
                EquipmentPlacement(equipmentID: "eq-3", positionX: 6, positionY: 0, positionZ: 4),
                EquipmentPlacement(equipmentID: "eq-6", positionX: 2, positionY: 0, positionZ: 8),
                EquipmentPlacement(equipmentID: "eq-7", positionX: 5, positionY: 0, positionZ: 8)
            ],
            createdAt: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        ),
        RoomDesign(
            userID: "mock-user-1",
            name: "Office Gym Corner",
            room: Room(width: 3.0, length: 3.5, height: 2.7),
            placements: [
                EquipmentPlacement(equipmentID: "eq-8", positionX: 1, positionY: 0, positionZ: 1)
            ],
            createdAt: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        )
    ]
}
