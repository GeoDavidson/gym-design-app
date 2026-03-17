import Foundation
import SwiftUI

// MARK: - Contact Method

enum ContactMethod: String, Codable, CaseIterable, Identifiable {
    case email
    case phone
    case inApp = "in_app"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .email:  return "Email"
        case .phone:  return "Phone"
        case .inApp:  return "In-App"
        }
    }

    var iconName: String {
        switch self {
        case .email:  return "envelope.fill"
        case .phone:  return "phone.fill"
        case .inApp:  return "message.fill"
        }
    }
}

// MARK: - Submission Status

enum SubmissionStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case submitted
    case underReview = "under_review"
    case approved
    case inProgress = "in_progress"
    case completed
    case cancelled

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .draft:       return "Draft"
        case .submitted:   return "Submitted"
        case .underReview: return "Under Review"
        case .approved:    return "Approved"
        case .inProgress:  return "In Progress"
        case .completed:   return "Completed"
        case .cancelled:   return "Cancelled"
        }
    }

    var color: Color {
        switch self {
        case .draft:       return .appTextSecondary
        case .submitted:   return .appAccent
        case .underReview: return .appWarning
        case .approved:    return .appSuccess
        case .inProgress:  return .appAccentSecondary
        case .completed:   return .appSuccess
        case .cancelled:   return .appError
        }
    }

    var iconName: String {
        switch self {
        case .draft:       return "doc.text"
        case .submitted:   return "paperplane.fill"
        case .underReview: return "eye.fill"
        case .approved:    return "checkmark.seal.fill"
        case .inProgress:  return "hammer.fill"
        case .completed:   return "flag.checkered"
        case .cancelled:   return "xmark.circle.fill"
        }
    }

    /// The ordinal position in the timeline (excluding cancelled).
    var stepIndex: Int {
        switch self {
        case .draft:       return 0
        case .submitted:   return 1
        case .underReview: return 2
        case .approved:    return 3
        case .inProgress:  return 4
        case .completed:   return 5
        case .cancelled:   return -1
        }
    }

    /// All statuses in timeline order (excluding cancelled).
    static var timelineSteps: [SubmissionStatus] {
        [.draft, .submitted, .underReview, .approved, .inProgress, .completed]
    }
}

// MARK: - Design Submission

struct DesignSubmission: Codable, Identifiable, Equatable {
    let id: String
    let designID: String
    let userID: String
    var status: SubmissionStatus
    var submittedAt: Date?
    var reviewedAt: Date?
    var estimatedCompletionDate: Date?
    var notes: String?
    var reviewerNotes: String?
    var estimatedCost: Double?
    var finalCost: Double?
    var contactPhone: String?
    var preferredContactMethod: ContactMethod
    let createdAt: Date

    // MARK: Initialization

    init(
        id: String = UUID().uuidString,
        designID: String,
        userID: String,
        status: SubmissionStatus = .draft,
        submittedAt: Date? = nil,
        reviewedAt: Date? = nil,
        estimatedCompletionDate: Date? = nil,
        notes: String? = nil,
        reviewerNotes: String? = nil,
        estimatedCost: Double? = nil,
        finalCost: Double? = nil,
        contactPhone: String? = nil,
        preferredContactMethod: ContactMethod = .email,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.designID = designID
        self.userID = userID
        self.status = status
        self.submittedAt = submittedAt
        self.reviewedAt = reviewedAt
        self.estimatedCompletionDate = estimatedCompletionDate
        self.notes = notes
        self.reviewerNotes = reviewerNotes
        self.estimatedCost = estimatedCost
        self.finalCost = finalCost
        self.contactPhone = contactPhone
        self.preferredContactMethod = preferredContactMethod
        self.createdAt = createdAt
    }

    // MARK: Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case designID = "design_id"
        case userID = "user_id"
        case status
        case submittedAt = "submitted_at"
        case reviewedAt = "reviewed_at"
        case estimatedCompletionDate = "estimated_completion_date"
        case notes
        case reviewerNotes = "reviewer_notes"
        case estimatedCost = "estimated_cost"
        case finalCost = "final_cost"
        case contactPhone = "contact_phone"
        case preferredContactMethod = "preferred_contact_method"
        case createdAt = "created_at"
    }

    // MARK: Formatting

    var formattedEstimatedCost: String? {
        guard let estimatedCost else { return nil }
        return Self.currencyFormatter.string(from: NSNumber(value: estimatedCost))
    }

    var formattedFinalCost: String? {
        guard let finalCost else { return nil }
        return Self.currencyFormatter.string(from: NSNumber(value: finalCost))
    }

    var formattedSubmittedDate: String? {
        guard let submittedAt else { return nil }
        return Self.dateFormatter.string(from: submittedAt)
    }

    var formattedReviewedDate: String? {
        guard let reviewedAt else { return nil }
        return Self.dateFormatter.string(from: reviewedAt)
    }

    var formattedCompletionDate: String? {
        guard let estimatedCompletionDate else { return nil }
        return Self.dateFormatter.string(from: estimatedCompletionDate)
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
