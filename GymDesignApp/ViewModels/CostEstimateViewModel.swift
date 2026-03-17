import Foundation
import Combine
import SwiftUI

// MARK: - Cost Estimate View Model

@MainActor
final class CostEstimateViewModel: ObservableObject {

    // MARK: - Published State

    @Published var costEstimate: CostEstimate?
    @Published var isCalculating: Bool = false

    // MARK: - Input References

    var currentRoom: Room?
    var placedEquipment: [Equipment] = []

    // MARK: - Private

    private let estimationService = CostEstimationService.shared

    // MARK: - Calculate

    /// Pulls current room + equipment data and builds a cost estimate.
    func calculateEstimate() {
        guard let room = currentRoom else { return }

        isCalculating = true

        // Run on a background-friendly delay to allow UI to show loading state.
        Task {
            // Simulate brief calculation time for polish
            try? await Task.sleep(for: .milliseconds(400))

            let estimate = estimationService.estimateCost(
                room: room,
                equipment: placedEquipment
            )

            costEstimate = estimate
            isCalculating = false
        }
    }

    // MARK: - Formatted Totals

    var formattedGrandTotal: String {
        costEstimate?.formattedGrandTotal ?? "$0.00"
    }

    var formattedEquipmentTotal: String {
        CostEstimationService.formatCurrency(costEstimate?.equipmentTotal ?? 0)
    }

    var formattedFinishesTotal: String {
        CostEstimationService.formatCurrency(costEstimate?.finishesTotal ?? 0)
    }

    var formattedInstallation: String {
        costEstimate?.formattedInstallationFee ?? "$0.00"
    }

    var formattedTax: String {
        costEstimate?.formattedTaxAmount ?? "$0.00"
    }

    // MARK: - Category Breakdown

    var categoryBreakdown: [(category: CostCategory, items: [CostLineItem])] {
        costEstimate?.groupedByCategory ?? []
    }
}
