import Foundation

// MARK: - Measurement Unit

enum MeasurementUnit: String, Codable, CaseIterable, Identifiable {
    case metric
    case imperial

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .metric: return "Metric (m, kg)"
        case .imperial: return "Imperial (ft, lbs)"
        }
    }
}

// MARK: - User Preferences

struct UserPreferences: Codable, Equatable {
    var measurementUnit: MeasurementUnit
    var notificationsEnabled: Bool

    init(measurementUnit: MeasurementUnit = .metric, notificationsEnabled: Bool = true) {
        self.measurementUnit = measurementUnit
        self.notificationsEnabled = notificationsEnabled
    }

    enum CodingKeys: String, CodingKey {
        case measurementUnit = "measurement_unit"
        case notificationsEnabled = "notifications_enabled"
    }
}

// MARK: - User

struct User: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    var displayName: String
    var photoURL: String?
    let createdAt: Date
    var lastActiveAt: Date
    var savedDesignIDs: [String]
    var favoriteEquipmentIDs: [String]
    var preferences: UserPreferences

    init(
        id: String,
        email: String,
        displayName: String,
        photoURL: String? = nil,
        createdAt: Date = Date(),
        lastActiveAt: Date = Date(),
        savedDesignIDs: [String] = [],
        favoriteEquipmentIDs: [String] = [],
        preferences: UserPreferences = UserPreferences()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.savedDesignIDs = savedDesignIDs
        self.favoriteEquipmentIDs = favoriteEquipmentIDs
        self.preferences = preferences
    }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case photoURL = "photo_url"
        case createdAt = "created_at"
        case lastActiveAt = "last_active_at"
        case savedDesignIDs = "saved_design_ids"
        case favoriteEquipmentIDs = "favorite_equipment_ids"
        case preferences
    }
}

// MARK: - Firestore Helpers

extension User {
    /// Converts the user to a dictionary suitable for Firestore storage.
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "email": email,
            "display_name": displayName,
            "created_at": createdAt,
            "last_active_at": lastActiveAt,
            "saved_design_ids": savedDesignIDs,
            "favorite_equipment_ids": favoriteEquipmentIDs,
            "preferences": [
                "measurement_unit": preferences.measurementUnit.rawValue,
                "notifications_enabled": preferences.notificationsEnabled
            ]
        ]
        if let photoURL {
            data["photo_url"] = photoURL
        }
        return data
    }
}
