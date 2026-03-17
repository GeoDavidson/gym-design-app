import Foundation
import RealityKit
import UIKit

// MARK: - Entity Helpers

extension ModelEntity {

    // MARK: - Factory Methods

    /// Creates a box `ModelEntity` with the given dimensions and color.
    static func createBox(
        width: Float,
        height: Float,
        depth: Float,
        color: UIColor
    ) -> ModelEntity {
        let mesh = MeshResource.generateBox(
            width: width,
            height: height,
            depth: depth,
            cornerRadius: 0.005
        )
        var material = SimpleMaterial()
        material.color = .init(tint: color)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.generateCollisionShapes(recursive: false)
        return entity
    }

    /// Attempts to load a USDZ model by name from the app bundle.
    /// Falls back to a gray box with the specified dimensions if loading fails.
    static func loadEquipmentModel(
        named name: String,
        fallbackDimensions: SIMD3<Float> = SIMD3<Float>(0.5, 0.5, 0.5)
    ) -> ModelEntity {
        do {
            let entity = try Entity.load(named: name)
            // Wrap in ModelEntity if needed
            if let modelEntity = entity as? ModelEntity {
                modelEntity.generateCollisionShapes(recursive: true)
                return modelEntity
            }
            // If the loaded entity is not a ModelEntity, find one in children
            if let childModel = entity.children.compactMap({ $0 as? ModelEntity }).first {
                childModel.generateCollisionShapes(recursive: true)
                return childModel
            }
            // Fallback: wrap the entity's bounds into a box placeholder
            return createBox(
                width: fallbackDimensions.x,
                height: fallbackDimensions.y,
                depth: fallbackDimensions.z,
                color: .systemGray
            )
        } catch {
            #if DEBUG
            print("[Entity+Helpers] Failed to load model '\(name)': \(error.localizedDescription). Using fallback box.")
            #endif
            return createBox(
                width: fallbackDimensions.x,
                height: fallbackDimensions.y,
                depth: fallbackDimensions.z,
                color: .systemGray
            )
        }
    }

    // MARK: - Visual Feedback

    /// Highlights or un-highlights the entity to indicate selection state.
    /// When selected, the material color is tinted with the accent color (#00D4FF).
    func highlight(isSelected: Bool) {
        guard var model = self.model else { return }

        if isSelected {
            // Apply accent-tinted emissive material
            var highlightMaterial = SimpleMaterial()
            highlightMaterial.color = .init(tint: UIColor(red: 0, green: 0.83, blue: 1.0, alpha: 1.0))
            highlightMaterial.metallic = .float(0.3)
            highlightMaterial.roughness = .float(0.4)
            model.materials = model.materials.map { _ in highlightMaterial }
        } else {
            // Restore default gray material
            var defaultMaterial = SimpleMaterial()
            defaultMaterial.color = .init(tint: .systemGray)
            model.materials = model.materials.map { _ in defaultMaterial }
        }

        self.model = model
    }

    /// Placeholder for gesture installation.
    /// - Parameter arView: The ARView instance to install gestures on.
    /// - Note: Call `arView.installGestures([.translation, .rotation, .scale], for: entity)` to enable gestures.
    func enableGestures(in arView: Any) {
        // Gesture installation requires an ARView reference.
        // Usage:
        //   if let view = arView as? ARView {
        //       view.installGestures([.translation, .rotation, .scale], for: self)
        //   }
    }

    /// Updates all materials on this entity to use the specified color.
    func applyMaterial(color: UIColor) {
        guard var model = self.model else { return }

        var material = SimpleMaterial()
        material.color = .init(tint: color)

        model.materials = model.materials.map { _ in material }
        self.model = model
    }
}
