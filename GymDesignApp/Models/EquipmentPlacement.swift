import Foundation
import simd

// MARK: - Equipment Placement

struct EquipmentPlacement: Codable, Identifiable, Equatable {
    let id: String
    let equipmentID: String
    var position: SIMD3<Float>
    var rotation: simd_quatf
    var scale: Float
    var isLocked: Bool

    // MARK: Initialization

    init(
        id: String = UUID().uuidString,
        equipmentID: String,
        position: SIMD3<Float> = .zero,
        rotation: simd_quatf = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
        scale: Float = 1.0,
        isLocked: Bool = false
    ) {
        self.id = id
        self.equipmentID = equipmentID
        self.position = position
        self.rotation = rotation
        self.scale = scale
        self.isLocked = isLocked
    }

    /// Convenience initializer from Y-axis rotation angle in radians.
    init(
        id: String = UUID().uuidString,
        equipmentID: String,
        positionX: Float,
        positionY: Float,
        positionZ: Float,
        rotationY: Float = 0
    ) {
        self.id = id
        self.equipmentID = equipmentID
        self.position = SIMD3<Float>(positionX, positionY, positionZ)
        self.rotation = simd_quatf(angle: rotationY, axis: SIMD3<Float>(0, 1, 0))
        self.scale = 1.0
        self.isLocked = false
    }

    // MARK: Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case equipmentID = "equipment_id"
        case posX = "pos_x"
        case posY = "pos_y"
        case posZ = "pos_z"
        case rotIX = "rot_ix"
        case rotIY = "rot_iy"
        case rotIZ = "rot_iz"
        case rotR = "rot_r"
        case scale
        case isLocked = "is_locked"
    }

    // MARK: Custom Codable — SIMD3<Float> & simd_quatf

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        equipmentID = try container.decode(String.self, forKey: .equipmentID)

        let px = try container.decode(Float.self, forKey: .posX)
        let py = try container.decode(Float.self, forKey: .posY)
        let pz = try container.decode(Float.self, forKey: .posZ)
        position = SIMD3<Float>(px, py, pz)

        let ix = try container.decode(Float.self, forKey: .rotIX)
        let iy = try container.decode(Float.self, forKey: .rotIY)
        let iz = try container.decode(Float.self, forKey: .rotIZ)
        let r = try container.decode(Float.self, forKey: .rotR)
        rotation = simd_quatf(ix: ix, iy: iy, iz: iz, r: r)

        scale = try container.decode(Float.self, forKey: .scale)
        isLocked = try container.decode(Bool.self, forKey: .isLocked)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(equipmentID, forKey: .equipmentID)

        try container.encode(position.x, forKey: .posX)
        try container.encode(position.y, forKey: .posY)
        try container.encode(position.z, forKey: .posZ)

        try container.encode(rotation.imag.x, forKey: .rotIX)
        try container.encode(rotation.imag.y, forKey: .rotIY)
        try container.encode(rotation.imag.z, forKey: .rotIZ)
        try container.encode(rotation.real, forKey: .rotR)

        try container.encode(scale, forKey: .scale)
        try container.encode(isLocked, forKey: .isLocked)
    }

    // MARK: Computed Helpers

    /// Extracts the Y-axis rotation angle in radians from the quaternion.
    var rotationY: Float {
        get {
            let siny = 2.0 * (rotation.real * rotation.imag.y + rotation.imag.x * rotation.imag.z)
            let cosy = 1.0 - 2.0 * (rotation.imag.y * rotation.imag.y + rotation.imag.z * rotation.imag.z)
            return atan2(siny, cosy)
        }
        set {
            rotation = simd_quatf(angle: newValue, axis: SIMD3<Float>(0, 1, 0))
        }
    }

    // MARK: Equatable

    static func == (lhs: EquipmentPlacement, rhs: EquipmentPlacement) -> Bool {
        lhs.id == rhs.id
            && lhs.equipmentID == rhs.equipmentID
            && lhs.position == rhs.position
            && lhs.rotation == rhs.rotation
            && lhs.scale == rhs.scale
            && lhs.isLocked == rhs.isLocked
    }
}
