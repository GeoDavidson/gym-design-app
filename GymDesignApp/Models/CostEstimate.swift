import Foundation

// MARK: - Cost Line Item Category

enum CostCategory: String, Codable, CaseIterable, Identifiable {
    case equipment
    case flooring
    case walls
    case ceiling
    case lighting
    case installation
    case tax

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .equipment:    return "Equipment"
        case .flooring:     return "Flooring"
        case .walls:        return "Wall Finish"
        case .ceiling:      return "Ceiling"
        case .lighting:     return "Lighting"
        case .installation: return "Installation"
        case .tax:          return "Tax"
        }
    }

    var icon: String {
        switch self {
        case .equipment:    return "dumbbell.fill"
        case .flooring:     return "square.grid.3x3.fill"
        case .walls:        return "rectangle.portrait.fill"
        case .ceiling:      return "rectangle.topthird.inset.filled"
        case .lighting:     return "lightbulb.fill"
        case .installation: return "wrench.and.screwdriver.fill"
        case .tax:          return "percent"
        }
    }
}

// MARK: - Cost Line Item

struct CostLineItem: Codable, Identifiable, Equatable {
    let id: String
    let category: CostCategory
    let name: String
    let quantity: Int
    let unitPrice: Double
    let totalPrice: Double

    init(
        id: String = UUID().uuidString,
        category: CostCategory,
        name: String,
        quantity: Int,
        unitPrice: Double
    ) {
        self.id = id
        self.category = category
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.totalPrice = Double(quantity) * unitPrice
    }

    var formattedUnitPrice: String {
        Self.currencyFormatter.string(from: NSNumber(value: unitPrice)) ?? "$\(unitPrice)"
    }

    var formattedTotalPrice: String {
        Self.currencyFormatter.string(from: NSNumber(value: totalPrice)) ?? "$\(totalPrice)"
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
}

// MARK: - Cost Estimate

struct CostEstimate: Codable, Identifiable, Equatable {
    let id: String
    let designID: String
    let lineItems: [CostLineItem]
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        designID: String,
        lineItems: [CostLineItem],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.designID = designID
        self.lineItems = lineItems
        self.createdAt = createdAt
    }

    // MARK: Computed Totals

    /// Sum of all line items excluding installation and tax.
    var subtotal: Double {
        lineItems
            .filter { $0.category != .installation && $0.category != .tax }
            .reduce(0) { $0 + $1.totalPrice }
    }

    /// Installation fee — 15% of subtotal.
    var installationFee: Double {
        subtotal * AppConstants.Business.installationMarkup
    }

    /// Tax — 8% of (subtotal + installation).
    var taxAmount: Double {
        (subtotal + installationFee) * AppConstants.Business.taxRate
    }

    /// Grand total including installation and tax.
    var grandTotal: Double {
        subtotal + installationFee + taxAmount
    }

    /// Equipment-only total.
    var equipmentTotal: Double {
        lineItems.filter { $0.category == .equipment }.reduce(0) { $0 + $1.totalPrice }
    }

    /// Room finishes total (flooring + walls + ceiling + lighting).
    var finishesTotal: Double {
        lineItems
            .filter { [.flooring, .walls, .ceiling, .lighting].contains($0.category) }
            .reduce(0) { $0 + $1.totalPrice }
    }

    // MARK: Grouped Items

    /// Line items grouped by category, preserving category order.
    var groupedByCategory: [(category: CostCategory, items: [CostLineItem])] {
        let order: [CostCategory] = [.equipment, .flooring, .walls, .ceiling, .lighting, .installation, .tax]
        return order.compactMap { cat in
            let items = lineItems.filter { $0.category == cat }
            return items.isEmpty ? nil : (category: cat, items: items)
        }
    }

    // MARK: Formatting

    var formattedGrandTotal: String {
        Self.currencyFormatter.string(from: NSNumber(value: grandTotal)) ?? "$\(grandTotal)"
    }

    var formattedSubtotal: String {
        Self.currencyFormatter.string(from: NSNumber(value: subtotal)) ?? "$\(subtotal)"
    }

    var formattedInstallationFee: String {
        Self.currencyFormatter.string(from: NSNumber(value: installationFee)) ?? "$\(installationFee)"
    }

    var formattedTaxAmount: String {
        Self.currencyFormatter.string(from: NSNumber(value: taxAmount)) ?? "$\(taxAmount)"
    }

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
}
