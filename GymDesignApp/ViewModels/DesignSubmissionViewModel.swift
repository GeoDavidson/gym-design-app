import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

// MARK: - Design Submission ViewModel

@MainActor
final class DesignSubmissionViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var submission: DesignSubmission?
    @Published var contactPhone: String = ""
    @Published var notes: String = ""
    @Published var preferredContact: ContactMethod = .email
    @Published var isSubmitting: Bool = false
    @Published var showSuccess: Bool = false
    @Published var errorMessage: String?
    @Published var agreedToTerms: Bool = false

    // MARK: - Private Properties

    private let firestoreService: FirestoreService
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(firestoreService: FirestoreService = .shared) {
        self.firestoreService = firestoreService
    }

    // MARK: - Submit Design

    /// Submits a design for professional build review.
    /// Creates a new `DesignSubmission` document in Firestore.
    func submitDesign(designID: String, estimatedCost: Double? = nil) async {
        guard let userID = Auth.auth().currentUser?.uid else {
            errorMessage = "You must be signed in to submit a design."
            return
        }

        guard agreedToTerms else {
            errorMessage = "Please agree to the terms and conditions."
            return
        }

        isSubmitting = true
        errorMessage = nil

        let newSubmission = DesignSubmission(
            designID: designID,
            userID: userID,
            status: .submitted,
            submittedAt: Date(),
            notes: notes.isEmpty ? nil : notes,
            estimatedCost: estimatedCost,
            contactPhone: contactPhone.isEmpty ? nil : contactPhone,
            preferredContactMethod: preferredContact
        )

        do {
            try await firestoreService.save(
                newSubmission,
                collection: AppConstants.Collections.submissions,
                id: newSubmission.id
            )

            submission = newSubmission
            showSuccess = true
        } catch {
            errorMessage = "Failed to submit design: \(error.localizedDescription)"
        }

        isSubmitting = false
    }

    // MARK: - Fetch Existing Submission

    /// Fetches an existing submission for a given design.
    func fetchSubmission(for designID: String) async {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        do {
            let submissions: [DesignSubmission] = try await firestoreService.fetchAll(
                collection: AppConstants.Collections.submissions,
                filters: [
                    QueryFilter(field: "design_id", op: .isEqualTo, value: designID),
                    QueryFilter(field: "user_id", op: .isEqualTo, value: userID)
                ],
                limit: 1
            )
            submission = submissions.first
        } catch {
            print("[DesignSubmissionViewModel] Failed to fetch submission: \(error.localizedDescription)")
        }
    }

    // MARK: - Cancel Submission

    /// Cancels an existing submission.
    func cancelSubmission() async {
        guard var current = submission else { return }

        current.status = .cancelled
        isSubmitting = true

        do {
            try await firestoreService.save(
                current,
                collection: AppConstants.Collections.submissions,
                id: current.id
            )
            submission = current
        } catch {
            errorMessage = "Failed to cancel submission: \(error.localizedDescription)"
        }

        isSubmitting = false
    }

    // MARK: - Listen for Status Updates

    /// Starts a real-time listener for submission status changes.
    func listenForUpdates(submissionID: String) {
        let stream: AsyncStream<DesignSubmission?> = firestoreService.listen(
            collection: AppConstants.Collections.submissions,
            id: submissionID
        )

        Task {
            for await updatedSubmission in stream {
                self.submission = updatedSubmission
            }
        }
    }

    // MARK: - Validation

    var isFormValid: Bool {
        agreedToTerms && (preferredContact != .phone || !contactPhone.isEmpty)
    }
}
