import Foundation

// MARK: - Equipment Dimensions

struct EquipmentDimensions: Codable, Hashable {
    /// Width in meters.
    let width: Float
    /// Length in meters.
    let length: Float
    /// Height in meters.
    let height: Float

    /// Floor footprint area in square meters.
    var footprint: Float {
        width * length
    }

    /// Human-readable metric dimensions string.
    var displayString: String {
        String(format: "%.2fm x %.2fm x %.2fm", width, length, height)
    }

    /// Human-readable imperial dimensions string.
    var displayStringImperial: String {
        let wFt = width * 3.28084
        let lFt = length * 3.28084
        let hFt = height * 3.28084
        return String(format: "%.1fft x %.1fft x %.1fft", wFt, lFt, hFt)
    }
}

// MARK: - Equipment

struct Equipment: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let category: EquipmentCategory
    let dimensions: EquipmentDimensions
    let price: Double
    let brand: String
    let modelNumber: String?
    let usdzModelName: String
    let thumbnailURL: String?
    let requiredClearance: EquipmentDimensions
    let weightKg: Double?
    let powerRequired: Bool

    // MARK: Computed Properties

    /// Total floor space needed including clearance on each side (square meters).
    var totalFootprint: Float {
        let totalWidth = dimensions.width + requiredClearance.width * 2
        let totalLength = dimensions.length + requiredClearance.length * 2
        return totalWidth * totalLength
    }

    /// Formatted price string in USD.
    var displayPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
    }

    // MARK: Initialization

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        category: EquipmentCategory,
        dimensions: EquipmentDimensions,
        price: Double,
        brand: String,
        modelNumber: String? = nil,
        usdzModelName: String,
        thumbnailURL: String? = nil,
        requiredClearance: EquipmentDimensions,
        weightKg: Double? = nil,
        powerRequired: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.dimensions = dimensions
        self.price = price
        self.brand = brand
        self.modelNumber = modelNumber
        self.usdzModelName = usdzModelName
        self.thumbnailURL = thumbnailURL
        self.requiredClearance = requiredClearance
        self.weightKg = weightKg
        self.powerRequired = powerRequired
    }

    // MARK: Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case category
        case dimensions
        case price
        case brand
        case modelNumber = "model_number"
        case usdzModelName = "usdz_model_name"
        case thumbnailURL = "thumbnail_url"
        case requiredClearance = "required_clearance"
        case weightKg = "weight_kg"
        case powerRequired = "power_required"
    }

    // MARK: Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Equipment, rhs: Equipment) -> Bool {
        lhs.id == rhs.id
    }
}
