import SwiftUI
import RealityKit
import Combine

// MARK: - Virtual Room View (Non-AR RealityKit)

/// UIViewRepresentable wrapping ARView in `.nonAR` camera mode.
/// Programmatically builds room geometry (floor, walls, ceiling) and places equipment.
struct VirtualRoomView: UIViewRepresentable {

    @ObservedObject var viewModel: RoomDesignViewModel

    // MARK: - Coordinator

    class Coordinator {
        var arView: ARView?
        var roomAnchor: AnchorEntity?
        var cancellables = Set<AnyCancellable>()

        /// Track which placement IDs have entities so we can diff.
        var placedEquipmentIDs = Set<String>()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Make UIView

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.environment.background = .color(.black)
        arView.cameraMode = .nonAR

        // Disable unnecessary AR features
        arView.renderOptions = [.disableMotionBlur, .disableDepthOfField]

        context.coordinator.arView = arView

        // Root anchor
        let anchor = AnchorEntity(world: .zero)
        arView.scene.addAnchor(anchor)
        context.coordinator.roomAnchor = anchor

        // Build initial room
        buildRoom(in: anchor, context: context)
        configureLighting(in: anchor, context: context)
        positionCamera(arView: arView)

        return arView
    }

    // MARK: - Update UIView

    func updateUIView(_ arView: ARView, context: Context) {
        guard let anchor = context.coordinator.roomAnchor else { return }

        // Rebuild room geometry on every SwiftUI state change.
        // In production you would diff and only update changed parts.
        rebuildRoom(anchor: anchor, context: context)
        updateEquipmentPlacements(anchor: anchor, context: context)
        updateLighting(anchor: anchor, context: context)
    }

    // MARK: - Room Construction

    private func buildRoom(in anchor: AnchorEntity, context: Context) {
        let room = viewModel.room
        let finish = viewModel.roomFinish

        let w = room.width
        let l = room.length
        let h = room.height
        let wallThickness: Float = 0.05

        // Materials
        let wallColor = uiColor(from: finish.wallColor)
        let floorColor = uiColor(from: finish.flooringColor)
        let ceilingColor = uiColor(from: finish.ceilingColor)

        var wallMaterial = SimpleMaterial()
        wallMaterial.color = .init(tint: wallColor)
        wallMaterial.roughness = .float(0.8)

        var floorMaterial = SimpleMaterial()
        floorMaterial.color = .init(tint: floorColor)
        floorMaterial.roughness = .float(0.6)

        var ceilingMaterial = SimpleMaterial()
        ceilingMaterial.color = .init(tint: ceilingColor)
        ceilingMaterial.roughness = .float(0.9)

        // Floor
        let floor = ModelEntity(
            mesh: .generatePlane(width: w, depth: l),
            materials: [floorMaterial]
        )
        floor.name = "room_floor"
        floor.position = SIMD3<Float>(0, 0, 0)
        anchor.addChild(floor)

        // Ceiling
        let ceiling = ModelEntity(
            mesh: .generatePlane(width: w, depth: l),
            materials: [ceilingMaterial]
        )
        ceiling.name = "room_ceiling"
        ceiling.position = SIMD3<Float>(0, h, 0)
        ceiling.orientation = simd_quatf(angle: .pi, axis: SIMD3<Float>(1, 0, 0))
        anchor.addChild(ceiling)

        // Back wall (along X axis, at -Z)
        let backWall = ModelEntity(
            mesh: .generateBox(width: w, height: h, depth: wallThickness),
            materials: [wallMaterial]
        )
        backWall.name = "room_wall_back"
        backWall.position = SIMD3<Float>(0, h / 2, -l / 2)
        anchor.addChild(backWall)

        // Front wall (along X axis, at +Z)
        let frontWall = ModelEntity(
            mesh: .generateBox(width: w, height: h, depth: wallThickness),
            materials: [wallMaterial]
        )
        frontWall.name = "room_wall_front"
        frontWall.position = SIMD3<Float>(0, h / 2, l / 2)
        anchor.addChild(frontWall)

        // Left wall (along Z axis, at -X)
        let leftWall = ModelEntity(
            mesh: .generateBox(width: wallThickness, height: h, depth: l),
            materials: [wallMaterial]
        )
        leftWall.name = "room_wall_left"
        leftWall.position = SIMD3<Float>(-w / 2, h / 2, 0)
        anchor.addChild(leftWall)

        // Right wall (along Z axis, at +X)
        let rightWall = ModelEntity(
            mesh: .generateBox(width: wallThickness, height: h, depth: l),
            materials: [wallMaterial]
        )
        rightWall.name = "room_wall_right"
        rightWall.position = SIMD3<Float>(w / 2, h / 2, 0)
        anchor.addChild(rightWall)
    }

    private func rebuildRoom(anchor: AnchorEntity, context: Context) {
        // Remove old room geometry
        let roomNames: Set<String> = [
            "room_floor", "room_ceiling",
            "room_wall_back", "room_wall_front",
            "room_wall_left", "room_wall_right"
        ]
        for child in anchor.children where roomNames.contains(child.name) {
            child.removeFromParent()
        }
        buildRoom(in: anchor, context: context)
    }

    // MARK: - Equipment Placement

    private func updateEquipmentPlacements(anchor: AnchorEntity, context: Context) {
        let currentIDs = Set(viewModel.placements.map { $0.id })
        let existingIDs = context.coordinator.placedEquipmentIDs

        // Remove deleted placements
        let toRemove = existingIDs.subtracting(currentIDs)
        for id in toRemove {
            if let entity = anchor.children.first(where: { $0.name == "equip_\(id)" }) {
                entity.removeFromParent()
            }
        }

        // Add or update placements
        for placement in viewModel.placements {
            let entityName = "equip_\(placement.id)"

            if let existingEntity = anchor.children.first(where: { $0.name == entityName }) {
                // Update position/rotation
                existingEntity.position = placement.position
                existingEntity.orientation = simd_quatf(angle: placement.rotationY, axis: SIMD3<Float>(0, 1, 0))
            } else {
                // Create placeholder box for equipment
                let equipment = viewModel.equipment(for: placement)
                let dims = equipment?.dimensions ?? EquipmentDimensions(width: 0.5, length: 0.5, height: 1.0)

                var material = SimpleMaterial()
                let categoryColor = equipment?.category.color ?? .gray
                material.color = .init(tint: UIColor(categoryColor))
                material.roughness = .float(0.4)
                material.metallic = .float(0.3)

                let entity = ModelEntity(
                    mesh: .generateBox(
                        width: Float(dims.width),
                        height: Float(dims.height),
                        depth: Float(dims.length)
                    ),
                    materials: [material]
                )
                entity.name = entityName
                entity.position = placement.position
                entity.position.y = Float(dims.height) / 2 // Sit on floor
                entity.orientation = simd_quatf(angle: placement.rotationY, axis: SIMD3<Float>(0, 1, 0))

                // Enable tap gesture (collision shape)
                entity.generateCollisionShapes(recursive: false)

                anchor.addChild(entity)
            }
        }

        context.coordinator.placedEquipmentIDs = currentIDs
    }

    // MARK: - Lighting

    private func configureLighting(in anchor: AnchorEntity, context: Context) {
        let finish = viewModel.roomFinish

        // Ambient approximation via a dim directional fill
        let ambientLight = DirectionalLight()
        ambientLight.name = "room_ambient"
        ambientLight.light.color = .white
        ambientLight.light.intensity = 400 * finish.lightingIntensity
        ambientLight.light.isRealWorldProxy = false
        ambientLight.look(at: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(0, 5, 0), relativeTo: nil)
        anchor.addChild(ambientLight)

        // Primary directional light
        let mainLight = DirectionalLight()
        mainLight.name = "room_main_light"
        let tempColor = temperatureToUIColor(kelvin: finish.lightingColorTemp)
        mainLight.light.color = tempColor
        mainLight.light.intensity = 1200 * finish.lightingIntensity
        mainLight.light.isRealWorldProxy = false
        mainLight.look(
            at: SIMD3<Float>(0, 0, 0),
            from: SIMD3<Float>(2, viewModel.room.height, 2),
            relativeTo: nil
        )
        anchor.addChild(mainLight)
    }

    private func updateLighting(anchor: AnchorEntity, context: Context) {
        // Remove old lights
        for child in anchor.children where child.name == "room_ambient" || child.name == "room_main_light" {
            child.removeFromParent()
        }
        configureLighting(in: anchor, context: context)
    }

    // MARK: - Camera

    private func positionCamera(arView: ARView) {
        let room = viewModel.room
        let distance = max(room.width, room.length) * 1.2
        let cameraHeight = room.height * 0.8

        let cameraEntity = PerspectiveCamera()
        cameraEntity.camera.fieldOfViewInDegrees = 60
        let cameraAnchor = AnchorEntity(world: .zero)
        cameraAnchor.addChild(cameraEntity)
        cameraEntity.position = SIMD3<Float>(distance * 0.7, cameraHeight, distance * 0.7)
        cameraEntity.look(
            at: SIMD3<Float>(0, room.height * 0.3, 0),
            from: cameraEntity.position,
            relativeTo: nil
        )
        arView.scene.addAnchor(cameraAnchor)
    }

    // MARK: - Helpers

    private func uiColor(from hex: String) -> UIColor {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255
        let g = CGFloat((int >> 8) & 0xFF) / 255
        let b = CGFloat(int & 0xFF) / 255
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }

    private func temperatureToUIColor(kelvin: Float) -> UIColor {
        // Attempt a rough warm → cool gradient
        let t = (kelvin - 2700) / (6500 - 2700)
        let r = 1.0 - Double(t) * 0.3
        let g = 0.85 + Double(t) * 0.15
        let b = 0.5 + Double(t) * 0.5
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - Preview

#Preview {
    VirtualRoomView(viewModel: RoomDesignViewModel())
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
}
