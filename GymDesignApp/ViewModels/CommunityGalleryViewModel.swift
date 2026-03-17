import Foundation
import Combine
import SwiftUI

// MARK: - Gallery Filter

enum GalleryFilter: String, CaseIterable, Identifiable {
    case trending
    case recent
    case topRated

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .trending: return "Trending"
        case .recent:   return "Recent"
        case .topRated: return "Top Rated"
        }
    }

    var icon: String {
        switch self {
        case .trending: return "flame.fill"
        case .recent:   return "clock.fill"
        case .topRated: return "star.fill"
        }
    }
}

// MARK: - Community Gallery View Model

@MainActor
final class CommunityGalleryViewModel: ObservableObject {

    // MARK: - Published State

    @Published var posts: [CommunityPost] = []
    @Published var isLoading: Bool = false
    @Published var selectedFilter: GalleryFilter = .trending

    // MARK: - Fetch Posts

    /// Loads posts — currently uses mock data; swap with Firestore in production.
    func fetchPosts() async {
        isLoading = true

        // Simulate network latency
        try? await Task.sleep(for: .milliseconds(600))

        // Try loading from bundle JSON first, fall back to hardcoded mock data.
        if let bundlePosts = loadMockPostsFromBundle() {
            posts = bundlePosts
        } else {
            posts = Self.hardcodedMockPosts
        }

        applySortOrder()
        isLoading = false
    }

    // MARK: - Toggle Like

    func toggleLike(postID: String) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index].isLiked.toggle()
        posts[index].likeCount += posts[index].isLiked ? 1 : -1
    }

    // MARK: - Filter

    func applyFilter(_ filter: GalleryFilter) {
        selectedFilter = filter
        applySortOrder()
    }

    // MARK: - Private

    private func applySortOrder() {
        switch selectedFilter {
        case .trending:
            posts.sort { $0.likeCount > $1.likeCount }
        case .recent:
            posts.sort { $0.createdAt > $1.createdAt }
        case .topRated:
            posts.sort { $0.likeCount + $0.commentCount > $1.likeCount + $1.commentCount }
        }
    }

    private func loadMockPostsFromBundle() -> [CommunityPost]? {
        guard let url = Bundle.main.url(forResource: "MockCommunityPosts", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode([CommunityPost].self, from: data)
    }

    // MARK: - Hardcoded Mock Data

    static let hardcodedMockPosts: [CommunityPost] = [
        CommunityPost(
            id: "post_001",
            userID: "user_101",
            userName: "Mike Chen",
            userPhotoURL: nil,
            designID: "design_001",
            designName: "Compact Power Studio",
            imageURLs: ["gym_1a", "gym_1b"],
            thumbnailURL: "gym_1_thumb",
            description: "Maximized every inch of my 3x4m spare bedroom. Power rack against the back wall with pull-up bar, folding bench, and a compact cable machine. Rubber flooring throughout.",
            equipmentTags: ["Power Rack", "Adjustable Bench", "Cable Machine"],
            roomDimensions: "3.0m x 4.0m x 2.5m",
            totalCost: 4250.00,
            likeCount: 142,
            commentCount: 23,
            createdAt: Calendar.current.date(byAdding: .hour, value: -6, to: Date())!,
            isLiked: false
        ),
        CommunityPost(
            id: "post_002",
            userID: "user_102",
            userName: "Sarah Johnson",
            userPhotoURL: nil,
            designID: "design_002",
            designName: "Garage Gym Paradise",
            imageURLs: ["gym_2a", "gym_2b", "gym_2c"],
            thumbnailURL: "gym_2_thumb",
            description: "Two-car garage conversion with dedicated zones: lifting platform, cardio corner, and stretching area. Insulated walls and LED panel lighting.",
            equipmentTags: ["Olympic Platform", "Treadmill", "Dumbbells", "Rower"],
            roomDimensions: "6.0m x 7.0m x 2.8m",
            totalCost: 12800.00,
            likeCount: 287,
            commentCount: 45,
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            isLiked: true
        ),
        CommunityPost(
            id: "post_003",
            userID: "user_103",
            userName: "Alex Rivera",
            userPhotoURL: nil,
            designID: "design_003",
            designName: "Minimalist Home Gym",
            imageURLs: ["gym_3a"],
            thumbnailURL: "gym_3_thumb",
            description: "Less is more. Adjustable dumbbells, a flat bench, pull-up bar, and kettlebells. Perfect for a small apartment corner.",
            equipmentTags: ["Adjustable Dumbbells", "Flat Bench", "Kettlebells"],
            roomDimensions: "2.5m x 3.0m x 2.4m",
            totalCost: 1850.00,
            likeCount: 98,
            commentCount: 12,
            createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            isLiked: false
        ),
        CommunityPost(
            id: "post_004",
            userID: "user_104",
            userName: "Jordan Lee",
            userPhotoURL: nil,
            designID: "design_004",
            designName: "CrossFit Box",
            imageURLs: ["gym_4a", "gym_4b"],
            thumbnailURL: "gym_4_thumb",
            description: "Full CrossFit setup in a basement. Wall-mounted rig, rower, assault bike, and a dedicated area for Olympic lifts with bumper plates.",
            equipmentTags: ["Wall Rig", "Rower", "Assault Bike", "Bumper Plates"],
            roomDimensions: "5.0m x 8.0m x 3.0m",
            totalCost: 9500.00,
            likeCount: 215,
            commentCount: 34,
            createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            isLiked: false
        ),
        CommunityPost(
            id: "post_005",
            userID: "user_105",
            userName: "Emma Patel",
            userPhotoURL: nil,
            designID: "design_005",
            designName: "Yoga & Recovery Room",
            imageURLs: ["gym_5a", "gym_5b"],
            thumbnailURL: "gym_5_thumb",
            description: "A serene recovery space with cork flooring, wall mirrors, resistance bands, foam rollers, and a Pilates reformer. Warm lighting throughout.",
            equipmentTags: ["Pilates Reformer", "Yoga Mat", "Foam Rollers", "TRX"],
            roomDimensions: "4.0m x 5.0m x 2.6m",
            totalCost: 3200.00,
            likeCount: 176,
            commentCount: 28,
            createdAt: Calendar.current.date(byAdding: .hour, value: -18, to: Date())!,
            isLiked: true
        )
    ]
}
