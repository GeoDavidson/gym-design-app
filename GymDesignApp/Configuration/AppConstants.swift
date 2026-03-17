import Foundation

enum AppConstants {

    // MARK: - App Info

    enum App {
        static let name = "GymDesign AR"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.gymdesign.ar"
    }

    // MARK: - Firebase Collection Names

    enum Collections {
        static let users = "users"
        static let designs = "designs"
        static let equipment = "equipment"
        static let communityPosts = "communityPosts"
        static let submissions = "submissions"
    }

    // MARK: - API Configuration

    enum API {
        static let claudeAPIEndpoint = "https://api.anthropic.com/v1/messages"
        static let claudeModel = "claude-sonnet-4-20250514"
        static let requestTimeoutInterval: TimeInterval = 30
        static let maxRetryAttempts = 3
    }

    // MARK: - Default Room Dimensions (meters)

    enum DefaultRoom {
        static let width: Double = 4.0
        static let length: Double = 5.0
        static let height: Double = 2.5
        static let minDimension: Double = 2.0
        static let maxDimension: Double = 20.0
    }

    // MARK: - Storage Paths

    enum Storage {
        static let userAvatars = "user_avatars"
        static let designThumbnails = "design_thumbnails"
        static let designModels = "design_models"
        static let equipmentImages = "equipment_images"
        static let communityImages = "community_images"
    }

    // MARK: - Business Constants

    enum Business {
        static let installationMarkup: Double = 0.15
        static let taxRate: Double = 0.08
    }

    // MARK: - AR Configuration

    enum AR {
        static let defaultPlaneDetectionDistance: Float = 5.0
        static let equipmentSnapThreshold: Float = 0.1
        static let gridCellSize: Float = 0.25
    }

    // MARK: - Pagination

    enum Pagination {
        static let defaultPageSize = 20
        static let communityFeedPageSize = 15
        static let equipmentPageSize = 30
    }

    // MARK: - Cache

    enum Cache {
        static let maxMemoryCostMB = 50
        static let maxDiskCacheMB = 200
        static let defaultExpirationSeconds: TimeInterval = 3600
    }

    // MARK: - Animation

    enum Animation {
        static let defaultDuration: Double = 0.3
        static let springDamping: Double = 0.75
        static let springResponse: Double = 0.5
    }
}
