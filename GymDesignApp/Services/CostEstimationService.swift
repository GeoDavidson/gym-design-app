import Foundation

// MARK: - Cost Estimation Service

/// Pure calculation service — no network calls. Produces a `CostEstimate` from room + equipment data.
final class CostEstimationService {

    // MARK: - Singleton

    static let shared = CostEstimationService()
    private init() {}

    // MARK: - Rate Constants (USD)

    private enum Rates {
        static let rubberFlooringPerSqFt: Double = 6.50
        static let wallFinishPerSqFt: Double = 3.25
        static let ceilingFinishPerSqFt: Double = 2.75
        static let ledFixtureUnit: Double = 85.00
        static let fixturesPerSqM: Double = 0.3  // roughly 1 fixture per ~3.3 m²
    }

    // MARK: - Estimate

    /// Builds a full cost estimate from room dimensions and placed equipment.
    ///
    /// - Parameters:
    ///   - room: The room whose dimensions drive finish calculations.
    ///   - equipment: Equipment items placed in the design (duplicates counted).
    ///   - designID: Identifier for the design this estimate belongs to.
    /// - Returns: A complete `CostEstimate`.
    func estimateCost(
        room: Room,
        equipment: [Equipment],
        designID: String = UUID().uuidString
    ) -> CostEstimate {
        var lineItems: [CostLineItem] = []

        // --- Equipment ---
        let grouped = Dictionary(grouping: equipment, by: { $0.id })
        for (_, items) in grouped.sorted(by: { $0.value.first?.name ?? "" < $1.value.first?.name ?? "" }) {
            guard let item = items.first else { continue }
            lineItems.append(
                CostLineItem(
                    category: .equipment,
                    name: "\(item.brand) \(item.name)",
                    quantity: items.count,
                    unitPrice: item.price
                )
            )
        }

        // --- Flooring ---
        let floorAreaSqFt = Double(room.area) * 10.7639  // m² -> ft²
        lineItems.append(
            CostLineItem(
                category: .flooring,
                name: "Rubber Gym Flooring",
                quantity: Int(ceil(floorAreaSqFt)),
                unitPrice: Rates.rubberFlooringPerSqFt
            )
        )

        // --- Wall Finish ---
        let perimeterFt = Double(2 * (room.width + room.length)) * 3.28084
        let wallHeightFt = Double(room.height) * 3.28084
        let wallAreaSqFt = perimeterFt * wallHeightFt
        lineItems.append(
            CostLineItem(
                category: .walls,
                name: "Impact-Resistant Wall Panels",
                quantity: Int(ceil(wallAreaSqFt)),
                unitPrice: Rates.wallFinishPerSqFt
            )
        )

        // --- Ceiling ---
        lineItems.append(
            CostLineItem(
                category: .ceiling,
                name: "Acoustic Ceiling Tiles",
                quantity: Int(ceil(floorAreaSqFt)),
                unitPrice: Rates.ceilingFinishPerSqFt
            )
        )

        // --- Lighting ---
        let fixtureCount = max(1, Int(ceil(Double(room.area) * Rates.fixturesPerSqM)))
        lineItems.append(
            CostLineItem(
                category: .lighting,
                name: "LED Panel Light Fixture",
                quantity: fixtureCount,
                unitPrice: Rates.ledFixtureUnit
            )
        )

        // Build estimate (installation and tax are computed properties on CostEstimate).
        let estimate = CostEstimate(
            designID: designID,
            lineItems: lineItems
        )

        // Append installation and tax as explicit line items for display purposes.
        let installationItem = CostLineItem(
            category: .installation,
            name: "Professional Installation (15%)",
            quantity: 1,
            unitPrice: estimate.installationFee
        )
        let taxItem = CostLineItem(
            category: .tax,
            name: "Sales Tax (8%)",
            quantity: 1,
            unitPrice: estimate.taxAmount
        )

        return CostEstimate(
            designID: designID,
            lineItems: lineItems + [installationItem, taxItem]
        )
    }

    // MARK: - Currency Formatting

    static func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
    }
}
