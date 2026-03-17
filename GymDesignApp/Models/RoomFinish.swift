import Foundation
import SwiftUI

// MARK: - Flooring Type

enum FlooringType: String, Codable, CaseIterable, Identifiable {
    case rubberTile = "rubber_tile"
    case foam
    case hardwood
    case turf
    case concrete
    case vinyl

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rubberTile: return "Rubber Tile"
        case .foam:       return "Foam"
        case .hardwood:   return "Hardwood"
        case .turf:       return "Turf"
        case .concrete:   return "Concrete"
        case .vinyl:      return "Vinyl"
        }
    }

    var icon: String {
        switch self {
        case .rubberTile: return "square.grid.2x2.fill"
        case .foam:       return "rectangle.split.3x3.fill"
        case .hardwood:   return "rectangle.pattern.checkered"
        case .turf:       return "leaf.fill"
        case .concrete:   return "square.fill"
        case .vinyl:      return "rectangle.fill"
        }
    }

    /// Approximate cost per square foot (USD).
    var pricePerSqFt: Double {
        switch self {
        case .rubberTile: return 4.50
        case .foam:       return 2.00
        case .hardwood:   return 8.00
        case .turf:       return 5.50
        case .concrete:   return 3.00
        case .vinyl:      return 3.50
        }
    }

    var defaultColorHex: String {
        switch self {
        case .rubberTile: return "#2C2C2C"
        case .foam:       return "#3A3A5C"
        case .hardwood:   return "#8B6914"
        case .turf:       return "#2E7D32"
        case .concrete:   return "#9E9E9E"
        case .vinyl:      return "#5D4037"
        }
    }
}

// MARK: - Ceiling Type

enum CeilingType: String, Codable, CaseIterable, Identifiable {
    case standard
    case exposed
    case acoustic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .exposed:  return "Exposed"
        case .acoustic: return "Acoustic"
        }
    }

    var icon: String {
        switch self {
        case .standard: return "rectangle.fill"
        case .exposed:  return "line.3.horizontal"
        case .acoustic: return "circle.grid.3x3.fill"
        }
    }

    /// Approximate cost per square foot (USD).
    var pricePerSqFt: Double {
        switch self {
        case .standard: return 2.00
        case .exposed:  return 1.50
        case .acoustic: return 6.00
        }
    }
}

// MARK: - Lighting Type

enum LightingType: String, Codable, CaseIterable, Identifiable {
    case fluorescent
    case led
    case recessed
    case track
    case natural

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fluorescent: return "Fluorescent"
        case .led:         return "LED"
        case .recessed:    return "Recessed"
        case .track:       return "Track"
        case .natural:     return "Natural"
        }
    }

    var icon: String {
        switch self {
        case .led:         return "lightbulb.led.fill"
        case .fluorescent: return "light.strip.2.fill"
        case .recessed:    return "light.recessed.fill"
        case .track:       return "light.cylindrical.ceiling.fill"
        case .natural:     return "sun.max.fill"
        }
    }

    /// Approximate cost per square foot (USD).
    var pricePerSqFt: Double {
        switch self {
        case .fluorescent: return 1.50
        case .led:         return 3.00
        case .recessed:    return 5.00
        case .track:       return 4.50
        case .natural:     return 0.00
        }
    }
}

// MARK: - Room Finish

struct RoomFinish: Codable, Equatable {

    // MARK: Walls

    /// Wall color as hex string (e.g. "#FFFFFF").
    var wallColor: String
    /// Optional wall texture identifier.
    var wallTexture: String?

    // MARK: Flooring

    var flooringType: FlooringType
    /// Flooring color as hex string.
    var flooringColor: String

    // MARK: Ceiling

    /// Ceiling color as hex string.
    var ceilingColor: String
    var ceilingType: CeilingType

    // MARK: Lighting

    var lightingType: LightingType
    /// Brightness from 0.0 (off) to 1.0 (maximum).
    var lightingIntensity: Float
    /// Color temperature in Kelvin (2700 warm to 6500 daylight).
    var lightingColorTemp: Float

    // MARK: Initialization

    init(
        wallColor: String = "#FFFFFF",
        wallTexture: String? = nil,
        flooringType: FlooringType = .rubberTile,
        flooringColor: String = "#2C2C2C",
        ceilingColor: String = "#F5F5F5",
        ceilingType: CeilingType = .standard,
        lightingType: LightingType = .led,
        lightingIntensity: Float = 0.8,
        lightingColorTemp: Float = 4000
    ) {
        self.wallColor = wallColor
        self.wallTexture = wallTexture
        self.flooringType = flooringType
        self.flooringColor = flooringColor
        self.ceilingColor = ceilingColor
        self.ceilingType = ceilingType
        self.lightingType = lightingType
        self.lightingIntensity = min(max(lightingIntensity, 0), 1)
        self.lightingColorTemp = min(max(lightingColorTemp, 2700), 6500)
    }

    // MARK: Coding Keys

    enum CodingKeys: String, CodingKey {
        case wallColor = "wall_color"
        case wallTexture = "wall_texture"
        case flooringType = "flooring_type"
        case flooringColor = "flooring_color"
        case ceilingColor = "ceiling_color"
        case ceilingType = "ceiling_type"
        case lightingType = "lighting_type"
        case lightingIntensity = "lighting_intensity"
        case lightingColorTemp = "lighting_color_temp"
    }

    // MARK: Cost Estimates

    /// Estimated flooring cost for a given area in square feet.
    func estimatedFlooringCost(areaSqFt: Double) -> Double {
        flooringType.pricePerSqFt * areaSqFt
    }

    /// Estimated ceiling cost for a given area in square feet.
    func estimatedCeilingCost(areaSqFt: Double) -> Double {
        ceilingType.pricePerSqFt * areaSqFt
    }

    /// Estimated lighting cost for a given area in square feet.
    func estimatedLightingCost(areaSqFt: Double) -> Double {
        lightingType.pricePerSqFt * areaSqFt
    }

    /// Approximate color for the current color temperature.
    var temperatureColor: Color {
        let t = (lightingColorTemp - 2700) / (6500 - 2700)
        let r = 1.0 - Double(t) * 0.3
        let g = 0.7 + Double(t) * 0.3
        let b = 0.4 + Double(t) * 0.6
        return Color(red: r, green: g, blue: b)
    }
}
