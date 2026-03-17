import SwiftUI

// MARK: - Submit Design View

struct SubmitDesignView: View {
    let designID: String
    let designName: String
    let roomDimensions: String
    let equipmentCount: Int
    let estimatedCost: Double?

    @StateObject private var viewModel = DesignSubmissionViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            if viewModel.showSuccess {
                successOverlay
                    .transition(.opacity.combined(with: .scale))
            } else {
                formContent
            }
        }
        .navigationTitle("Submit Design")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Form Content

    private var formContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                designSummaryCard
                contactInfoSection
                notesSection
                costSummaryCard
                termsSection
                submitButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
    }

    // MARK: - Design Summary Card

    private var designSummaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Design Summary", systemImage: "square.and.pencil")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)

                Divider()
                    .overlay(Color.appDivider)

                summaryRow(label: "Design Name", value: designName)
                summaryRow(label: "Room Dimensions", value: roomDimensions)
                summaryRow(label: "Equipment Items", value: "\(equipmentCount)")
            }
        }
    }

    // MARK: - Contact Info Section

    private var contactInfoSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Label("Contact Information", systemImage: "person.crop.circle")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)

                Divider()
                    .overlay(Color.appDivider)

                // Contact method picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preferred Contact Method")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)

                    Picker("Contact Method", selection: $viewModel.preferredContact) {
                        ForEach(ContactMethod.allCases) { method in
                            Label(method.displayName, systemImage: method.iconName)
                                .tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Phone number field (shown when phone is selected)
                if viewModel.preferredContact == .phone {
                    ThemedTextField(
                        placeholder: "Phone Number",
                        text: $viewModel.contactPhone,
                        icon: "phone.fill",
                        keyboardType: .phonePad,
                        textContentType: .telephoneNumber
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.preferredContact)
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Additional Notes", systemImage: "note.text")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)

                Divider()
                    .overlay(Color.appDivider)

                TextEditor(text: $viewModel.notes)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(minHeight: 100, maxHeight: 200)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.appSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if viewModel.notes.isEmpty {
                            Text("Any special requirements, preferences, or details...")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.appTextTertiary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
    }

    // MARK: - Cost Summary Card

    private var costSummaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Cost Estimate", systemImage: "dollarsign.circle.fill")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)

                Divider()
                    .overlay(Color.appDivider)

                if let cost = estimatedCost {
                    HStack {
                        Text("Estimated Total")
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextSecondary)
                        Spacer()
                        Text(formatCurrency(cost))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.appAccent)
                    }

                    Text("Final cost may vary based on site assessment and material availability.")
                        .font(.caption)
                        .foregroundStyle(Color.appTextTertiary)
                } else {
                    Text("Cost estimate will be provided after review.")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
    }

    // MARK: - Terms Section

    private var termsSection: some View {
        Button {
            viewModel.agreedToTerms.toggle()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: viewModel.agreedToTerms ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(viewModel.agreedToTerms ? Color.appAccent : Color.appTextSecondary)

                Text("I agree to the terms of service and understand that this submission is a request for a professional consultation. Estimated costs are subject to change.")
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        AccentButton(
            title: "Submit for Build",
            icon: "paperplane.fill",
            isLoading: viewModel.isSubmitting,
            isDisabled: !viewModel.isFormValid
        ) {
            Task {
                await viewModel.submitDesign(
                    designID: designID,
                    estimatedCost: estimatedCost
                )
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                // Particle circles
                ForEach(0..<12, id: \.self) { index in
                    Circle()
                        .fill(particleColor(for: index))
                        .frame(width: CGFloat.random(in: 6...14),
                               height: CGFloat.random(in: 6...14))
                        .offset(particleOffset(for: index))
                        .opacity(0.8)
                }

                // Main checkmark circle
                Circle()
                    .fill(Color.appSuccess.opacity(0.15))
                    .frame(width: 120, height: 120)

                Circle()
                    .stroke(Color.appSuccess, lineWidth: 3)
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Color.appSuccess)
            }

            VStack(spacing: 12) {
                Text("Design Submitted!")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)

                Text("We'll review your design and get back to you within 2-3 business days.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }

            AccentButton(title: "Done", icon: "checkmark") {
                dismiss()
            }
            .frame(maxWidth: 200)

            Spacer()
        }
        .padding()
    }

    // MARK: - Helpers

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.appTextPrimary)
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }

    private func particleColor(for index: Int) -> Color {
        let colors: [Color] = [.appAccent, .appAccentSecondary, .appSuccess, .appWarning]
        return colors[index % colors.count]
    }

    private func particleOffset(for index: Int) -> CGSize {
        let angle = Double(index) * (360.0 / 12.0) * .pi / 180.0
        let radius: Double = Double.random(in: 70...110)
        return CGSize(
            width: cos(angle) * radius,
            height: sin(angle) * radius
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SubmitDesignView(
            designID: "preview-design",
            designName: "Home Gym v1",
            roomDimensions: "4.0m x 5.0m x 2.5m",
            equipmentCount: 8,
            estimatedCost: 12500.00
        )
    }
    .preferredColorScheme(.dark)
}
