import Foundation
import Combine

// MARK: - Room Design ViewModel

/// Central view model that owns the room, equipment placements, and room finishes
/// for a single design session (AR or Virtual).
@MainActor
final class RoomDesignViewModel: ObservableObject {

    // MARK: - Published State

    @Published var room: Room
    @Published var roomFinish: RoomFinish
    @Published var placements: [EquipmentPlacement]
    @Published var equipmentCatalog: [Equipment]
    @Published var selectedPlacementID: String?
    @Published var designName: String
    @Published var isSaving: Bool = false

    // MARK: - Initialization

    init(
        room: Room = Room(
            width: Float(AppConstants.DefaultRoom.width),
            length: Float(AppConstants.DefaultRoom.length),
            height: Float(AppConstants.DefaultRoom.height)
        ),
        roomFinish: RoomFinish = RoomFinish(),
        placements: [EquipmentPlacement] = [],
        equipmentCatalog: [Equipment] = [],
        designName: String = "My Gym Design"
    ) {
        self.room = room
        self.roomFinish = roomFinish
        self.placements = placements
        self.equipmentCatalog = equipmentCatalog
        self.designName = designName
    }

    // MARK: - Equipment Placement

    func addEquipment(_ equipment: Equipment, at position: SIMD3<Float> = .zero) {
        let placement = EquipmentPlacement(
            equipmentID: equipment.id,
            positionX: position.x,
            positionY: position.y,
            positionZ: position.z
        )
        placements.append(placement)
        selectedPlacementID = placement.id
    }

    func removePlacement(_ placementID: String) {
        placements.removeAll { $0.id == placementID }
        if selectedPlacementID == placementID {
            selectedPlacementID = nil
        }
    }

    func updatePlacementPosition(_ placementID: String, position: SIMD3<Float>) {
        guard let index = placements.firstIndex(where: { $0.id == placementID }) else { return }
        placements[index].position = position
    }

    func updatePlacementRotation(_ placementID: String, rotationY: Float) {
        guard let index = placements.firstIndex(where: { $0.id == placementID }) else { return }
        placements[index].rotationY = rotationY
    }

    func equipment(for placement: EquipmentPlacement) -> Equipment? {
        equipmentCatalog.first { $0.id == placement.equipmentID }
    }

    // MARK: - Room Dimensions

    func updateRoomDimensions(width: Float, length: Float, height: Float) {
        room.width = width
        room.length = length
        room.height = height
    }

    // MARK: - Cost Calculations

    var totalEquipmentCost: Double {
        placements.compactMap { placement in
            equipment(for: placement)?.price
        }.reduce(0, +)
    }

    var flooringCost: Double {
        let areaSqFt = Double(room.area) * 10.7639 // m² to ft²
        return areaSqFt * roomFinish.flooringType.pricePerSqFt
    }

    var estimatedTotalCost: Double {
        let subtotal = totalEquipmentCost + flooringCost
        let installation = subtotal * AppConstants.Business.installationMarkup
        let tax = subtotal * AppConstants.Business.taxRate
        return subtotal + installation + tax
    }

    // MARK: - Save (Stub)

    func saveDesign() async {
        isSaving = true
        defer { isSaving = false }
        // TODO: Integrate with FirestoreService to persist design
        try? await Task.sleep(for: .seconds(1))
    }
}
