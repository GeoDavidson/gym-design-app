import Foundation

// MARK: - Room Design

/// A complete gym design combining room geometry, equipment placements, finishes, and metadata.
struct RoomDesign: Codable, Identifiable, Equatable {
    let id: String
    let userID: String
    var name: String
    var room: Room
    var roomFinish: RoomFinish
    var placements: [EquipmentPlacement]
    var thumbnailURL: String?
    var isFavorite: Bool
    let createdAt: Date
    var updatedAt: Date

    // MARK: Computed Properties

    /// Total number of placed equipment items.
    var equipmentCount: Int { placements.count }

    /// Human-readable creation date.
    var displayDate: String {
        Self.dateFormatter.string(from: createdAt)
    }

    /// Human-readable update date.
    var displayUpdatedDate: String {
        Self.dateFormatter.string(from: updatedAt)
    }

    // MARK: Initialization

    init(
        id: String = UUID().uuidString,
        userID: String,
        name: String = "My Gym Design",
        room: Room = Room(
            width: Float(AppConstants.DefaultRoom.width),
            length: Float(AppConstants.DefaultRoom.length),
            height: Float(AppConstants.DefaultRoom.height)
        ),
        roomFinish: RoomFinish = RoomFinish(),
        placements: [EquipmentPlacement] = [],
        thumbnailURL: String? = nil,
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userID = userID
        self.name = name
        self.room = room
        self.roomFinish = roomFinish
        self.placements = placements
        self.thumbnailURL = thumbnailURL
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case name
        case room
        case roomFinish = "room_finish"
        case placements
        case thumbnailURL = "thumbnail_url"
        case isFavorite = "is_favorite"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: Equatable

    static func == (lhs: RoomDesign, rhs: RoomDesign) -> Bool {
        lhs.id == rhs.id
            && lhs.userID == rhs.userID
            && lhs.name == rhs.name
            && lhs.room == rhs.room
            && lhs.roomFinish == rhs.roomFinish
            && lhs.placements == rhs.placements
            && lhs.isFavorite == rhs.isFavorite
    }

    // MARK: Private

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
