import SwiftUI

// MARK: - Equipment Category

enum EquipmentCategory: String, Codable, CaseIterable, Identifiable {
    case cardio
    case strength
    case freeWeights = "free_weights"
    case stretching
    case flooring
    case storage
    case accessories

    var id: String { rawValue }

    // MARK: Display Name

    var displayName: String {
        switch self {
        case .cardio:       return "Cardio"
        case .strength:     return "Strength"
        case .freeWeights:  return "Free Weights"
        case .stretching:   return "Stretching"
        case .flooring:     return "Flooring"
        case .storage:      return "Storage"
        case .accessories:  return "Accessories"
        }
    }

    // MARK: SF Symbol Icon

    var iconName: String {
        switch self {
        case .cardio:       return "heart.fill"
        case .strength:     return "dumbbell.fill"
        case .freeWeights:  return "scalemass.fill"
        case .stretching:   return "figure.flexibility"
        case .flooring:     return "square.grid.3x3.fill"
        case .storage:      return "archivebox.fill"
        case .accessories:  return "wrench.and.screwdriver.fill"
        }
    }

    // MARK: Category Color

    var color: Color {
        switch self {
        case .cardio:       return Color(hex: "#FF3B5C")  // Red
        case .strength:     return Color(hex: "#00D4FF")  // Cyan
        case .freeWeights:  return Color(hex: "#FFB800")  // Amber
        case .stretching:   return Color(hex: "#00FF88")  // Green
        case .flooring:     return Color(hex: "#7B2FFF")  // Purple
        case .storage:      return Color(hex: "#FF8A00")  // Orange
        case .accessories:  return Color(hex: "#00B4D8")  // Teal
        }
    }
}
