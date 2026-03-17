import Foundation

// MARK: - Community Post

struct CommunityPost: Codable, Identifiable, Equatable {
    let id: String
    let userID: String
    let userName: String
    let userPhotoURL: String?
    let designID: String
    let designName: String
    let imageURLs: [String]
    let thumbnailURL: String
    let description: String
    let equipmentTags: [String]
    let roomDimensions: String
    let totalCost: Double?
    var likeCount: Int
    let commentCount: Int
    let createdAt: Date
    var isLiked: Bool

    init(
        id: String = UUID().uuidString,
        userID: String,
        userName: String,
        userPhotoURL: String? = nil,
        designID: String,
        designName: String,
        imageURLs: [String] = [],
        thumbnailURL: String = "",
        description: String = "",
        equipmentTags: [String] = [],
        roomDimensions: String = "",
        totalCost: Double? = nil,
        likeCount: Int = 0,
        commentCount: Int = 0,
        createdAt: Date = Date(),
        isLiked: Bool = false
    ) {
        self.id = id
        self.userID = userID
        self.userName = userName
        self.userPhotoURL = userPhotoURL
        self.designID = designID
        self.designName = designName
        self.imageURLs = imageURLs
        self.thumbnailURL = thumbnailURL
        self.description = description
        self.equipmentTags = equipmentTags
        self.roomDimensions = roomDimensions
        self.totalCost = totalCost
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.createdAt = createdAt
        self.isLiked = isLiked
    }

    // MARK: Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case userName = "user_name"
        case userPhotoURL = "user_photo_url"
        case designID = "design_id"
        case designName = "design_name"
        case imageURLs = "image_urls"
        case thumbnailURL = "thumbnail_url"
        case description
        case equipmentTags = "equipment_tags"
        case roomDimensions = "room_dimensions"
        case totalCost = "total_cost"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case createdAt = "created_at"
        case isLiked = "is_liked"
    }

    // MARK: Helpers

    var formattedCost: String? {
        guard let cost = totalCost else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: cost))
    }

    var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    // MARK: Equatable

    static func == (lhs: CommunityPost, rhs: CommunityPost) -> Bool {
        lhs.id == rhs.id
            && lhs.likeCount == rhs.likeCount
            && lhs.isLiked == rhs.isLiked
    }
}
