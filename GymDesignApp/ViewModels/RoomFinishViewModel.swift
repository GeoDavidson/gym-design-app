import Foundation
import Combine
import SwiftUI

// MARK: - Room Finish ViewModel

/// Manages room finish selections (walls, floor, ceiling, lighting)
/// and propagates changes back to the parent `RoomDesignViewModel`.
@MainActor
final class RoomFinishViewModel: ObservableObject {

    // MARK: - Published State

    @Published var roomFinish: RoomFinish

    // MARK: - Color Presets

    /// Wall color presets (hex strings).
    static let wallColorPresets: [String] = [
        "#FFFFFF", "#E0E0E0", "#666666", "#1B2838",
        "#2D4A2D", "#4A1B2D", "#333333", "#F5F0E8"
    ]

    /// Flooring color presets grouped by flooring type.
    static let flooringColorPresets: [FlooringType: [String]] = [
        .rubberTile: ["#2C2C2C", "#1A1A1A", "#3D3D3D", "#4A4A4A", "#1C3A5F", "#5C1A1A"],
        .foam:       ["#3A3A5C", "#2B2B4E", "#4D4D6D", "#1A1A3A", "#3D5C3A", "#5C3A5C"],
        .hardwood:   ["#8B6914", "#A0522D", "#D2B48C", "#6B4226", "#DEB887", "#8B4513"],
        .turf:       ["#2E7D32", "#1B5E20", "#4CAF50", "#388E3C", "#66BB6A", "#2C5F2D"],
        .concrete:   ["#9E9E9E", "#757575", "#BDBDBD", "#616161", "#E0E0E0", "#424242"],
        .vinyl:      ["#5D4037", "#795548", "#8D6E63", "#4E342E", "#3E2723", "#6D4C41"]
    ]

    /// Ceiling color presets (hex strings).
    static let ceilingColorPresets: [String] = [
        "#FFFFFF", "#E0E0E0", "#333333", "#000000"
    ]

    // MARK: - Change Callback

    /// Called whenever the room finish changes. Typically bound to the parent view model.
    var onFinishChanged: ((RoomFinish) -> Void)?

    // MARK: - Initialization

    init(roomFinish: RoomFinish = RoomFinish(), onFinishChanged: ((RoomFinish) -> Void)? = nil) {
        self.roomFinish = roomFinish
        self.onFinishChanged = onFinishChanged
    }

    // MARK: - Wall Updates

    func updateWallColor(_ hex: String) {
        roomFinish.wallColor = hex
        propagateChanges()
    }

    func updateWallTexture(_ texture: String?) {
        roomFinish.wallTexture = texture
        propagateChanges()
    }

    // MARK: - Flooring Updates

    func updateFlooring(type: FlooringType, color: String) {
        roomFinish.flooringType = type
        roomFinish.flooringColor = color
        propagateChanges()
    }

    func updateFlooringType(_ type: FlooringType) {
        roomFinish.flooringType = type
        roomFinish.flooringColor = type.defaultColorHex
        propagateChanges()
    }

    func updateFlooringColor(_ color: String) {
        roomFinish.flooringColor = color
        propagateChanges()
    }

    // MARK: - Ceiling Updates

    func updateCeiling(type: CeilingType, color: String) {
        roomFinish.ceilingType = type
        roomFinish.ceilingColor = color
        propagateChanges()
    }

    func updateCeilingType(_ type: CeilingType) {
        roomFinish.ceilingType = type
        propagateChanges()
    }

    func updateCeilingColor(_ color: String) {
        roomFinish.ceilingColor = color
        propagateChanges()
    }

    // MARK: - Lighting Updates

    func updateLighting(type: LightingType, intensity: Float, colorTemp: Float) {
        roomFinish.lightingType = type
        roomFinish.lightingIntensity = min(max(intensity, 0), 1)
        roomFinish.lightingColorTemp = min(max(colorTemp, 2700), 6500)
        propagateChanges()
    }

    func updateLightingType(_ type: LightingType) {
        roomFinish.lightingType = type
        propagateChanges()
    }

    func updateLightingIntensity(_ intensity: Float) {
        roomFinish.lightingIntensity = min(max(intensity, 0), 1)
        propagateChanges()
    }

    func updateLightingColorTemp(_ colorTemp: Float) {
        roomFinish.lightingColorTemp = min(max(colorTemp, 2700), 6500)
        propagateChanges()
    }

    // MARK: - Helpers

    /// Color presets for the currently selected flooring type.
    var currentFlooringColorPresets: [String] {
        Self.flooringColorPresets[roomFinish.flooringType] ?? [roomFinish.flooringType.defaultColorHex]
    }

    /// Descriptive label for the current color temperature.
    var colorTemperatureLabel: String {
        let temp = roomFinish.lightingColorTemp
        if temp < 3500 {
            return "Warm"
        } else if temp < 5000 {
            return "Neutral"
        } else {
            return "Cool"
        }
    }

    /// Intensity as a percentage integer (0-100).
    var intensityPercent: Int {
        Int(roomFinish.lightingIntensity * 100)
    }

    /// Color temperature display string.
    var colorTempDisplay: String {
        String(format: "%.0fK", roomFinish.lightingColorTemp)
    }

    // MARK: - Private

    private func propagateChanges() {
        onFinishChanged?(roomFinish)
    }
}
