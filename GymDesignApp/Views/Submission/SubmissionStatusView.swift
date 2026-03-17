import SwiftUI

// MARK: - Submission Status View

struct SubmissionStatusView: View {
    @StateObject private var viewModel = DesignSubmissionViewModel()
    let submissionID: String

    @State private var showCancelAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            if let submission = viewModel.submission {
                ScrollView {
                    VStack(spacing: 24) {
                        statusHeader(submission)
                        statusTimeline(submission)
                        statusDetailsCard(submission)
                        actionButtons(submission)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            } else {
                LoadingView(message: "Loading submission...")
            }
        }
        .navigationTitle("Submission Status")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.listenForUpdates(submissionID: submissionID)
        }
        .alert("Cancel Submission", isPresented: $showCancelAlert) {
            Button("Keep Submission", role: .cancel) {}
            Button("Cancel Submission", role: .destructive) {
                Task { await viewModel.cancelSubmission() }
            }
        } message: {
            Text("Are you sure you want to cancel this submission? This action cannot be undone.")
        }
    }

    // MARK: - Status Header

    private func statusHeader(_ submission: DesignSubmission) -> some View {
        GlassCard {
            VStack(spacing: 12) {
                Image(systemName: submission.status.iconName)
                    .font(.system(size: 40))
                    .foregroundStyle(submission.status.color)

                Text(submission.status.displayName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)

                if submission.status == .cancelled {
                    Text("This submission has been cancelled.")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Status Timeline

    private func statusTimeline(_ submission: DesignSubmission) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("Progress")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                    .padding(.bottom, 16)

                ForEach(Array(SubmissionStatus.timelineSteps.enumerated()), id: \.element.id) { index, step in
                    timelineStep(
                        step: step,
                        currentStatus: submission.status,
                        isLast: index == SubmissionStatus.timelineSteps.count - 1
                    )
                }
            }
        }
    }

    private func timelineStep(step: SubmissionStatus, currentStatus: SubmissionStatus, isLast: Bool) -> some View {
        let isCompleted = step.stepIndex < currentStatus.stepIndex
        let isCurrent = step.stepIndex == currentStatus.stepIndex
        let isPending = step.stepIndex > currentStatus.stepIndex
        let isCancelled = currentStatus == .cancelled

        return HStack(alignment: .top, spacing: 16) {
            // Indicator column
            VStack(spacing: 0) {
                // Circle indicator
                ZStack {
                    Circle()
                        .fill(circleColor(isCompleted: isCompleted, isCurrent: isCurrent, isCancelled: isCancelled))
                        .frame(width: 32, height: 32)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    } else if isCurrent && !isCancelled {
                        Circle()
                            .fill(.white)
                            .frame(width: 10, height: 10)
                    } else {
                        Circle()
                            .stroke(Color.appTextTertiary, lineWidth: 1.5)
                            .frame(width: 12, height: 12)
                    }
                }

                // Connecting line
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? Color.appAccent : Color.appTextTertiary.opacity(0.3))
                        .frame(width: 2, height: 36)
                }
            }

            // Label column
            VStack(alignment: .leading, spacing: 4) {
                Text(step.displayName)
                    .font(.subheadline.weight(isCurrent ? .semibold : .regular))
                    .foregroundStyle(
                        isPending && !isCancelled
                            ? Color.appTextTertiary
                            : Color.appTextPrimary
                    )

                if isCurrent && !isCancelled {
                    Text("Current step")
                        .font(.caption)
                        .foregroundStyle(Color.appAccent)
                }
            }
            .padding(.top, 4)

            Spacer()
        }
    }

    private func circleColor(isCompleted: Bool, isCurrent: Bool, isCancelled: Bool) -> Color {
        if isCancelled { return .appTextTertiary.opacity(0.3) }
        if isCompleted { return .appAccent }
        if isCurrent { return .appAccent }
        return Color.appTextTertiary.opacity(0.15)
    }

    // MARK: - Status Details Card

    private func statusDetailsCard(_ submission: DesignSubmission) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Details", systemImage: "info.circle.fill")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)

                Divider()
                    .overlay(Color.appDivider)

                if let date = submission.formattedSubmittedDate {
                    detailRow(label: "Submitted", value: date)
                }

                if let date = submission.formattedReviewedDate {
                    detailRow(label: "Reviewed", value: date)
                }

                if let date = submission.formattedCompletionDate {
                    detailRow(label: "Est. Completion", value: date)
                }

                if let cost = submission.formattedEstimatedCost {
                    detailRow(label: "Estimated Cost", value: cost, valueColor: .appAccent)
                }

                if let cost = submission.formattedFinalCost {
                    detailRow(label: "Final Cost", value: cost, valueColor: .appSuccess)
                }

                if let reviewerNotes = submission.reviewerNotes, !reviewerNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Reviewer Notes")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.appTextSecondary)

                        Text(reviewerNotes)
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextPrimary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.appSurface)
                            )
                    }
                }

                if let notes = submission.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your Notes")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.appTextSecondary)

                        Text(notes)
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextPrimary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.appSurface)
                            )
                    }
                }
            }
        }
    }

    private func detailRow(label: String, value: String, valueColor: Color = .appTextPrimary) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(valueColor)
        }
    }

    // MARK: - Action Buttons

    private func actionButtons(_ submission: DesignSubmission) -> some View {
        VStack(spacing: 12) {
            // Contact Support
            Button {
                // Opens system mail or in-app support flow
                if let url = URL(string: "mailto:support@gymdesign.app") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Contact Support", systemImage: "envelope.fill")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .foregroundStyle(Color.appAccent)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.appAccent, lineWidth: 1.5)
                    )
            }

            // Cancel Submission (only when cancellable)
            if submission.status != .cancelled
                && submission.status != .completed
                && submission.status != .inProgress {
                Button {
                    showCancelAlert = true
                } label: {
                    Label("Cancel Submission", systemImage: "xmark.circle")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .foregroundStyle(Color.appError)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.appError.opacity(0.5), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.bottom, 16)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SubmissionStatusView(submissionID: "preview-submission")
    }
    .preferredColorScheme(.dark)
}
