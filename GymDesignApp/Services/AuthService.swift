import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

// MARK: - Auth Service Errors

enum AuthServiceError: LocalizedError {
    case userNotFound
    case firestoreReadFailed(underlying: Error)
    case firestoreWriteFailed(underlying: Error)
    case signOutFailed(underlying: Error)
    case unknown(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "No authenticated user found."
        case .firestoreReadFailed(let error):
            return "Failed to read user data: \(error.localizedDescription)"
        case .firestoreWriteFailed(let error):
            return "Failed to save user data: \(error.localizedDescription)"
        case .signOutFailed(let error):
            return "Failed to sign out: \(error.localizedDescription)"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Auth Service Protocol

protocol AuthServiceProtocol: ObservableObject {
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    var isLoading: Bool { get }

    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String, displayName: String) async throws
    func signOut() throws
    func resetPassword(email: String) async throws
}

// MARK: - Auth Service

final class AuthService: ObservableObject, AuthServiceProtocol {

    // MARK: Published Properties

    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var isLoading: Bool = true

    // MARK: Private Properties

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()

    private var usersCollection: CollectionReference {
        db.collection("users")
    }

    // MARK: Initialization

    init() {
        listenToAuthState()
    }

    deinit {
        if let handle = authStateHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }

    // MARK: Auth State Listener

    private func listenToAuthState() {
        authStateHandle = auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self else { return }

            Task { @MainActor in
                if let firebaseUser {
                    do {
                        let user = try await self.fetchOrCreateUserDocument(for: firebaseUser)
                        self.currentUser = user
                        self.isAuthenticated = true
                    } catch {
                        // User exists in Auth but Firestore doc is unreachable.
                        // Map the basic Firebase Auth data so the session is not lost.
                        self.currentUser = self.mapFirebaseUser(firebaseUser)
                        self.isAuthenticated = true
                    }
                } else {
                    self.currentUser = nil
                    self.isAuthenticated = false
                }
                self.isLoading = false
            }
        }
    }

    // MARK: Sign In

    func signIn(email: String, password: String) async throws {
        await setLoading(true)
        defer { Task { @MainActor in self.isLoading = false } }

        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            let user = try await fetchOrCreateUserDocument(for: result.user)
            try await updateLastActive(for: user.id)
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch {
            throw mapAuthError(error)
        }
    }

    // MARK: Sign Up

    func signUp(email: String, password: String, displayName: String) async throws {
        await setLoading(true)
        defer { Task { @MainActor in self.isLoading = false } }

        do {
            let result = try await auth.createUser(withEmail: email, password: password)

            // Update the Firebase Auth display name.
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()

            let newUser = User(
                id: result.user.uid,
                email: email,
                displayName: displayName,
                photoURL: result.user.photoURL?.absoluteString
            )

            try await storeUserDocument(newUser)

            await MainActor.run {
                self.currentUser = newUser
                self.isAuthenticated = true
            }
        } catch {
            throw mapAuthError(error)
        }
    }

    // MARK: Sign Out

    func signOut() throws {
        do {
            try auth.signOut()
            Task { @MainActor in
                self.currentUser = nil
                self.isAuthenticated = false
            }
        } catch {
            throw AuthServiceError.signOutFailed(underlying: error)
        }
    }

    // MARK: Reset Password

    func resetPassword(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            throw mapAuthError(error)
        }
    }

    // MARK: Firestore Helpers

    private func fetchOrCreateUserDocument(for firebaseUser: FirebaseAuth.User) async throws -> User {
        let docRef = usersCollection.document(firebaseUser.uid)

        do {
            let snapshot = try await docRef.getDocument()

            if snapshot.exists, let data = snapshot.data() {
                return try decodeUser(from: data)
            } else {
                // First sign-in or missing doc — create from Auth profile.
                let user = mapFirebaseUser(firebaseUser)
                try await storeUserDocument(user)
                return user
            }
        } catch let error as AuthServiceError {
            throw error
        } catch {
            throw AuthServiceError.firestoreReadFailed(underlying: error)
        }
    }

    private func storeUserDocument(_ user: User) async throws {
        do {
            try await usersCollection.document(user.id).setData(user.firestoreData, merge: true)
        } catch {
            throw AuthServiceError.firestoreWriteFailed(underlying: error)
        }
    }

    private func updateLastActive(for userID: String) async throws {
        do {
            try await usersCollection.document(userID).updateData([
                "last_active_at": FieldValue.serverTimestamp()
            ])
        } catch {
            // Non-critical — log but do not throw.
            print("[AuthService] Failed to update last_active_at: \(error.localizedDescription)")
        }
    }

    // MARK: Mapping

    private func mapFirebaseUser(_ firebaseUser: FirebaseAuth.User) -> User {
        User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName ?? "User",
            photoURL: firebaseUser.photoURL?.absoluteString
        )
    }

    private func decodeUser(from data: [String: Any]) throws -> User {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            // Handle Firestore Timestamp serialized as a Double (seconds since epoch).
            if let timestamp = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: timestamp)
            }
            // Fallback to ISO-8601 string.
            if let dateString = try? container.decode(String.self),
               let date = ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            return Date()
        }
        return try decoder.decode(User.self, from: jsonData)
    }

    // MARK: Error Mapping

    private func mapAuthError(_ error: Error) -> Error {
        if let authError = error as? AuthServiceError {
            return authError
        }
        return AuthServiceError.unknown(underlying: error)
    }

    // MARK: Utilities

    @MainActor
    private func setLoading(_ value: Bool) {
        isLoading = value
    }
}
