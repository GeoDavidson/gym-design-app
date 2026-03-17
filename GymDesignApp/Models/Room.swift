import Foundation
import simd

// MARK: - Room

struct Room: Codable, Identifiable, Equatable {
    let id: String
    var width: Float
    var length: Float
    var height: Float
    var scannedMeshData: Data?
    var origin: SIMD3<Float>

    // MARK: Computed Properties

    /// Floor area in square meters.
    var area: Float {
        width * length
    }

    /// Room volume in cubic meters.
    var volume: Float {
        width * length * height
    }

    /// Human-readable dimensions string (e.g. "4.0m x 5.0m x 2.5m").
    var displayDimensions: String {
        String(format: "%.1fm x %.1fm x %.1fm", width, length, height)
    }

    /// Human-readable area string.
    var displayArea: String {
        String(format: "%.1f m\u{00B2}", area)
    }

    // MARK: Initialization

    init(
        id: String = UUID().uuidString,
        width: Float,
        length: Float,
        height: Float,
        scannedMeshData: Data? = nil,
        origin: SIMD3<Float> = .zero
    ) {
        self.id = id
        self.width = width
        self.length = length
        self.height = height
        self.scannedMeshData = scannedMeshData
        self.origin = origin
    }

    // MARK: Codable — Custom SIMD3<Float> Coding

    enum CodingKeys: String, CodingKey {
        case id
        case width
        case length
        case height
        case scannedMeshData = "scanned_mesh_data"
        case originX = "origin_x"
        case originY = "origin_y"
        case originZ = "origin_z"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        width = try container.decode(Float.self, forKey: .width)
        length = try container.decode(Float.self, forKey: .length)
        height = try container.decode(Float.self, forKey: .height)
        scannedMeshData = try container.decodeIfPresent(Data.self, forKey: .scannedMeshData)

        let x = try container.decode(Float.self, forKey: .originX)
        let y = try container.decode(Float.self, forKey: .originY)
        let z = try container.decode(Float.self, forKey: .originZ)
        origin = SIMD3<Float>(x, y, z)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(width, forKey: .width)
        try container.encode(length, forKey: .length)
        try container.encode(height, forKey: .height)
        try container.encodeIfPresent(scannedMeshData, forKey: .scannedMeshData)
        try container.encode(origin.x, forKey: .originX)
        try container.encode(origin.y, forKey: .originY)
        try container.encode(origin.z, forKey: .originZ)
    }

    // MARK: Equatable

    static func == (lhs: Room, rhs: Room) -> Bool {
        lhs.id == rhs.id
            && lhs.width == rhs.width
            && lhs.length == rhs.length
            && lhs.height == rhs.height
            && lhs.scannedMeshData == rhs.scannedMeshData
            && lhs.origin == rhs.origin
    }
}
