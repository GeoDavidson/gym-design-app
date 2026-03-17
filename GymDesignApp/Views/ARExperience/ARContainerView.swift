import SwiftUI
import ARKit
import RealityKit
import Combine

// MARK: - AR Container View

/// A `UIViewRepresentable` that wraps a RealityKit `ARView` for placing and
/// manipulating gym equipment in augmented reality.
struct ARContainerView: UIViewRepresentable {

    @ObservedObject var viewModel: RoomDesignViewModel

    // MARK: - Make / Update

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false

        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        configuration.environmentTexturing = .automatic
        configuration.isLightEstimationEnabled = true

        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        // Enable coaching overlay for initial guidance
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)

        // Install gesture recognizers
        context.coordinator.setupGestures(on: arView)
        context.coordinator.arView = arView

        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        let coordinator = context.coordinator
        coordinator.syncEntities(with: viewModel.placements, in: arView)
        coordinator.updateSelection(selectedID: viewModel.selectedPlacementID, in: arView)
        coordinator.applyRoomFinishes(viewModel.roomFinish, in: arView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject {

        weak var arView: ARView?
        private var viewModel: RoomDesignViewModel

        /// Maps placement IDs to their RealityKit entities.
        private var entityMap: [String: ModelEntity] = [:]

        /// Tracks the entity currently being dragged.
        private var draggedEntity: ModelEntity?
        private var dragStartPosition: SIMD3<Float> = .zero

        /// Anchor for all placed equipment.
        private let rootAnchor = AnchorEntity(plane: .horizontal)

        /// Materials cache for room finishes applied to detected planes.
        private var planeMaterialAnchor: AnchorEntity?

        // MARK: Init

        init(viewModel: RoomDesignViewModel) {
            self.viewModel = viewModel
            super.init()
        }

        // MARK: - Gesture Setup

        func setupGestures(on arView: ARView) {
            arView.scene.addAnchor(rootAnchor)

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            arView.addGestureRecognizer(tap)

            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            arView.addGestureRecognizer(pan)

            let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
            rotation.delegate = self
            arView.addGestureRecognizer(rotation)

            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            pinch.delegate = self
            arView.addGestureRecognizer(pinch)
        }

        // MARK: - Tap — Raycast & Place / Select

        @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView else { return }
            let location = gesture.location(in: arView)

            // Check if tapping on an existing entity
            if let hitEntity = arView.entity(at: location) as? ModelEntity,
               let placementID = entityMap.first(where: { $0.value === hitEntity })?.key {
                Task { @MainActor in
                    self.viewModel.selectedPlacementID = placementID
                }
                return
            }

            // Raycast to place new equipment at the tapped location
            let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
            guard let firstResult = results.first else { return }

            let worldPosition = SIMD3<Float>(
                firstResult.worldTransform.columns.3.x,
                firstResult.worldTransform.columns.3.y,
                firstResult.worldTransform.columns.3.z
            )

            Task { @MainActor in
                // If equipment is pending placement (selected in picker), place it
                if let selectedID = self.viewModel.selectedPlacementID,
                   let index = self.viewModel.placements.firstIndex(where: { $0.id == selectedID }) {
                    self.viewModel.placements[index].position = worldPosition
                } else {
                    // Deselect
                    self.viewModel.selectedPlacementID = nil
                }
            }
        }

        // MARK: - Pan — Move Equipment

        @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let arView else { return }

            switch gesture.state {
            case .began:
                let location = gesture.location(in: arView)
                if let hitEntity = arView.entity(at: location) as? ModelEntity {
                    draggedEntity = hitEntity
                    dragStartPosition = hitEntity.position(relativeTo: rootAnchor)

                    if let placementID = entityMap.first(where: { $0.value === hitEntity })?.key {
                        Task { @MainActor in
                            self.viewModel.selectedPlacementID = placementID
                        }
                    }
                }

            case .changed:
                guard let entity = draggedEntity else { return }
                let location = gesture.location(in: arView)
                let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
                if let result = results.first {
                    let newPosition = SIMD3<Float>(
                        result.worldTransform.columns.3.x,
                        result.worldTransform.columns.3.y,
                        result.worldTransform.columns.3.z
                    )
                    entity.setPosition(newPosition, relativeTo: nil)
                }

            case .ended, .cancelled:
                if let entity = draggedEntity,
                   let placementID = entityMap.first(where: { $0.value === entity })?.key {
                    let finalPosition = entity.position(relativeTo: nil)
                    Task { @MainActor in
                        self.viewModel.updatePlacementPosition(placementID, position: finalPosition)
                    }
                }
                draggedEntity = nil

            default:
                break
            }
        }

        // MARK: - Rotation — Rotate Equipment

        @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            guard let arView else { return }

            switch gesture.state {
            case .began, .changed:
                let location = gesture.location(in: arView)
                if let hitEntity = arView.entity(at: location) as? ModelEntity {
                    let angle = Float(gesture.rotation)
                    let currentOrientation = hitEntity.orientation
                    let rotationDelta = simd_quatf(angle: -angle, axis: SIMD3<Float>(0, 1, 0))
                    hitEntity.orientation = rotationDelta * currentOrientation
                    gesture.rotation = 0
                }

            case .ended:
                let location = gesture.location(in: arView)
                if let hitEntity = arView.entity(at: location) as? ModelEntity,
                   let placementID = entityMap.first(where: { $0.value === hitEntity })?.key {
                    let yAngle = hitEntity.orientation.angle
                    Task { @MainActor in
                        self.viewModel.updatePlacementRotation(placementID, rotationY: yAngle)
                    }
                }

            default:
                break
            }
        }

        // MARK: - Pinch — Scale Equipment

        @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let arView else { return }

            switch gesture.state {
            case .began, .changed:
                let location = gesture.location(in: arView)
                if let hitEntity = arView.entity(at: location) as? ModelEntity {
                    let scaleFactor = Float(gesture.scale)
                    hitEntity.scale *= SIMD3<Float>(repeating: scaleFactor)
                    gesture.scale = 1
                }

            case .ended:
                let location = gesture.location(in: arView)
                if let hitEntity = arView.entity(at: location) as? ModelEntity,
                   let placementID = entityMap.first(where: { $0.value === hitEntity })?.key,
                   let index = viewModel.placements.firstIndex(where: { $0.id == placementID }) {
                    let finalScale = hitEntity.scale.x
                    Task { @MainActor in
                        self.viewModel.placements[index].scale = finalScale
                    }
                }

            default:
                break
            }
        }

        // MARK: - Entity Synchronization

        /// Ensures RealityKit entities match the current placements array.
        func syncEntities(with placements: [EquipmentPlacement], in arView: ARView) {
            let currentIDs = Set(placements.map(\.id))
            let existingIDs = Set(entityMap.keys)

            // Remove entities no longer in placements
            for removedID in existingIDs.subtracting(currentIDs) {
                if let entity = entityMap.removeValue(forKey: removedID) {
                    entity.removeFromParent()
                }
            }

            // Add or update entities
            for placement in placements {
                if let existingEntity = entityMap[placement.id] {
                    // Update transform
                    existingEntity.setPosition(placement.position, relativeTo: nil)
                    existingEntity.orientation = placement.rotation
                    existingEntity.scale = SIMD3<Float>(repeating: placement.scale)
                } else {
                    // Create new entity
                    let equipment = viewModel.equipment(for: placement)
                    let entity = loadEquipmentEntity(
                        modelName: equipment?.usdzModelName,
                        dimensions: equipment?.dimensions
                    )
                    entity.name = placement.id
                    entity.setPosition(placement.position, relativeTo: nil)
                    entity.orientation = placement.rotation
                    entity.scale = SIMD3<Float>(repeating: placement.scale)

                    // Enable gestures
                    entity.generateCollisionShapes(recursive: true)

                    rootAnchor.addChild(entity)
                    entityMap[placement.id] = entity
                }
            }
        }

        // MARK: - Model Loading

        /// Attempts to load a USDZ model by name. Falls back to a colored box primitive
        /// matching the equipment dimensions.
        private func loadEquipmentEntity(
            modelName: String?,
            dimensions: EquipmentDimensions?
        ) -> ModelEntity {
            // Attempt to load USDZ model from bundle
            if let name = modelName {
                do {
                    let entity = try ModelEntity.loadModel(named: name)
                    entity.generateCollisionShapes(recursive: true)
                    return entity
                } catch {
                    // Fall through to box fallback
                    print("[ARContainerView] Failed to load USDZ '\(name)': \(error.localizedDescription)")
                }
            }

            // Fallback: colored box matching equipment dimensions
            let dims = dimensions ?? EquipmentDimensions(width: 0.5, length: 0.5, height: 0.5)
            let mesh = MeshResource.generateBox(
                width: dims.width,
                height: dims.height,
                depth: dims.length,
                cornerRadius: 0.01
            )

            var material = SimpleMaterial()
            material.color = .init(
                tint: UIColor(Color(hex: "#00D4FF")).withAlphaComponent(0.85),
                texture: nil
            )
            material.roughness = .float(0.4)
            material.metallic = .float(0.2)

            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.generateCollisionShapes(recursive: true)
            return entity
        }

        // MARK: - Selection Highlight

        /// Applies or removes emission highlight on the selected entity.
        func updateSelection(selectedID: String?, in arView: ARView) {
            for (id, entity) in entityMap {
                if id == selectedID {
                    applySelectionHighlight(to: entity)
                } else {
                    removeSelectionHighlight(from: entity)
                }
            }
        }

        private func applySelectionHighlight(to entity: ModelEntity) {
            guard var material = entity.model?.materials.first as? SimpleMaterial else { return }
            material.color = .init(
                tint: UIColor(Color(hex: "#00D4FF")),
                texture: material.color.texture
            )
            entity.model?.materials = [material]
        }

        private func removeSelectionHighlight(from entity: ModelEntity) {
            guard var material = entity.model?.materials.first as? SimpleMaterial else { return }
            material.color = .init(
                tint: UIColor(Color(hex: "#00D4FF")).withAlphaComponent(0.85),
                texture: material.color.texture
            )
            entity.model?.materials = [material]
        }

        // MARK: - Room Finish Materials on Detected Planes

        /// Applies room finish colors to detected horizontal (floor) and vertical (wall) planes
        /// using an occlusion-style material tint.
        func applyRoomFinishes(_ finish: RoomFinish, in arView: ARView) {
            // Remove previous plane material anchor
            if let existing = planeMaterialAnchor {
                arView.scene.removeAnchor(existing)
            }

            guard let frame = arView.session.currentFrame else { return }

            let anchor = AnchorEntity(world: .zero)

            for arAnchor in frame.anchors {
                guard let planeAnchor = arAnchor as? ARPlaneAnchor else { continue }

                let extent = planeAnchor.planeExtent
                let mesh = MeshResource.generatePlane(
                    width: extent.width,
                    depth: extent.height
                )

                let colorHex: String
                switch planeAnchor.alignment {
                case .horizontal:
                    colorHex = finish.flooringColor
                case .vertical:
                    colorHex = finish.wallColor
                @unknown default:
                    colorHex = finish.wallColor
                }

                var material = SimpleMaterial()
                material.color = .init(
                    tint: UIColor(Color(hex: colorHex)).withAlphaComponent(0.3),
                    texture: nil
                )
                material.roughness = .float(0.8)
                material.metallic = .float(0.0)

                let planeEntity = ModelEntity(mesh: mesh, materials: [material])

                let transform = Transform(matrix: planeAnchor.transform)
                planeEntity.transform = transform

                anchor.addChild(planeEntity)
            }

            arView.scene.addAnchor(anchor)
            planeMaterialAnchor = anchor
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ARContainerView.Coordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Allow rotation and pinch to work simultaneously
        let isPinchOrRotation = gestureRecognizer is UIPinchGestureRecognizer
            || gestureRecognizer is UIRotationGestureRecognizer
        let otherIsPinchOrRotation = otherGestureRecognizer is UIPinchGestureRecognizer
            || otherGestureRecognizer is UIRotationGestureRecognizer
        return isPinchOrRotation && otherIsPinchOrRotation
    }
}
