import SwiftUI

// MARK: - Share Service

/// Provides utilities for sharing gym designs via the system share sheet.
struct ShareService {

    // MARK: - Share Item Generation

    /// Generates an array of share items (text summary) for a gym design.
    static func generateShareItems(
        designName: String,
        dimensions: String,
        equipmentCount: Int
    ) -> [Any] {
        let summary = """
        Check out my gym design: "\(designName)"
        Room Dimensions: \(dimensions)
        Equipment Pieces: \(equipmentCount)

        Designed with GymDesign AR
        """
        return [summary]
    }

    /// Generates share items from a `RoomDesign` object, including a text summary.
    static func shareDesign(design: RoomDesign) -> [Any] {
        let dimensions = design.room.displayDimensions
        let equipmentCount = design.equipmentCount
        let floorType = design.roomFinish.flooringType.displayName
        let area = design.room.displayArea

        let summary = """
        Check out my gym design: "\(design.name)"

        Room: \(dimensions) (\(area))
        Floor: \(floorType)
        Equipment: \(equipmentCount) piece\(equipmentCount == 1 ? "" : "s")

        Designed with GymDesign AR
        """

        var items: [Any] = [summary]
        return items
    }

    // MARK: - View Snapshot

    /// Renders a SwiftUI view as a `UIImage` using `ImageRenderer` (iOS 16+).
    @MainActor
    static func renderViewAsImage<V: View>(_ view: V, size: CGSize) -> UIImage? {
        let renderer = ImageRenderer(content:
            view
                .frame(width: size.width, height: size.height)
                .background(Color(hex: "#0D0D0D"))
                .environment(\.colorScheme, .dark)
        )
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}
