import Foundation
import Combine

// MARK: - Profile View Model

@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: Published Properties

    @Published var user: User?
    @Published var designCount: Int = 0
    @Published var submissionCount: Int = 0
    @Published var favoritesCount: Int = 0
    @Published var isLoading: Bool = false

    // MARK: Dependencies

    private let authService: AuthService

    // MARK: Computed Properties

    var displayInitials: String {
        guard let name = user?.displayName, !name.isEmpty else { return "?" }
        let components = name.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }
        return initials.map(String.init).joined().uppercased()
    }

    var displayName: String {
        user?.displayName ?? "User"
    }

    var email: String {
        user?.email ?? ""
    }

    // MARK: Initialization

    init(authService: AuthService = AuthService()) {
        self.authService = authService
    }

    // MARK: Data Loading

    func fetchProfile() async {
        isLoading = true
        defer { isLoading = false }

        // Simulate network delay
        try? await Task.sleep(for: .milliseconds(400))

        // Pull current user from auth service
        user = authService.currentUser ?? Self.mockUser

        // Mock stats — replace with Firestore queries
        designCount = 12
        submissionCount = 3
        favoritesCount = 8
    }

    // MARK: Sign Out

    func signOut() {
        do {
            try authService.signOut()
            user = nil
        } catch {
            print("[ProfileViewModel] Sign out failed: \(error.localizedDescription)")
        }
    }

    // MARK: Mock Data

    private static let mockUser = User(
        id: "mock-user-1",
        email: "designer@gymdesign.app",
        displayName: "Alex Johnson",
        savedDesignIDs: ["d-1", "d-2", "d-3"],
        favoriteEquipmentIDs: ["eq-1", "eq-2"]
    )
}
