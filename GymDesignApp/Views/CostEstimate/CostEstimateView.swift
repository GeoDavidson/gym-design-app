import SwiftUI

// MARK: - Cost Estimate View

struct CostEstimateView: View {

    @StateObject private var viewModel = CostEstimateViewModel()

    /// Inject room and equipment from the parent context.
    var room: Room?
    var equipment: [Equipment] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if viewModel.isCalculating {
                    loadingState
                } else if let estimate = viewModel.costEstimate {
                    estimateContent(estimate)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Cost Estimate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if viewModel.costEstimate != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(
                            item: shareText,
                            subject: Text("GymDesign AR Cost Estimate"),
                            message: Text("Check out my gym cost estimate!")
                        ) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(Color.appTextSecondary)
                        }
                    }
                }
            }
            .onAppear {
                viewModel.currentRoom = room
                viewModel.placedEquipment = equipment
                viewModel.calculateEstimate()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Estimate Content

    private func estimateContent(_ estimate: CostEstimate) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary card
                CostSummaryCard(
                    grandTotal: viewModel.formattedGrandTotal,
                    equipmentTotal: viewModel.formattedEquipmentTotal,
                    finishesTotal: viewModel.formattedFinishesTotal,
                    installationTotal: viewModel.formattedInstallation
                )

                // Category sections
                ForEach(viewModel.categoryBreakdown, id: \.category) { group in
                    categorySection(group.category, items: group.items)
                }

                // Request quote button
                AccentButton(title: "Request Quote", icon: "envelope.fill") {
                    // Future: open quote request flow
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
    }

    // MARK: - Category Section

    private func categorySection(_ category: CostCategory, items: [CostLineItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appAccent)
                Text(category.displayName)
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
            }
            .padding(.bottom, 4)

            // Items
            ForEach(items) { item in
                CostLineItemRow(item: item)
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(Color.appAccent)
            Text("Calculating estimate...")
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 48))
                .foregroundStyle(Color.appTextTertiary)
            Text("No design data available")
                .font(.headline)
                .foregroundStyle(Color.appTextSecondary)
            Text("Add a room and equipment to see an estimate.")
                .font(.subheadline)
                .foregroundStyle(Color.appTextTertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Share Text

    private var shareText: String {
        guard let estimate = viewModel.costEstimate else { return "" }
        var text = "GymDesign AR - Cost Estimate\n"
        text += "================================\n"
        for group in estimate.groupedByCategory {
            text += "\n\(group.category.displayName):\n"
            for item in group.items {
                text += "  \(item.name) x\(item.quantity) — \(item.formattedTotalPrice)\n"
            }
        }
        text += "\n================================\n"
        text += "Grand Total: \(estimate.formattedGrandTotal)\n"
        return text
    }
}

// MARK: - Preview

#Preview {
    CostEstimateView(
        room: Room(width: 4.0, length: 5.0, height: 2.5),
        equipment: []
    )
}
