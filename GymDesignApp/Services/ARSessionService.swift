import Foundation
import Combine
import ARKit
import RealityKit

// MARK: - AR Session State

enum ARSessionState: Equatable {
    case notStarted
    case initializing
    case scanning
    case ready
    case failed(String)

    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .initializing: return "Initializing"
        case .scanning: return "Scanning"
        case .ready: return "Ready"
        case .failed(let reason): return "Failed: \(reason)"
        }
    }

    var isActive: Bool {
        switch self {
        case .scanning, .ready: return true
        default: return false
        }
    }
}

// MARK: - AR Session Service

final class ARSessionService: NSObject, ObservableObject {

    // MARK: Published Properties

    @Published private(set) var sessionState: ARSessionState = .notStarted
    @Published private(set) var detectedPlanes: [ARPlaneAnchor] = []
    @Published private(set) var worldMappingStatus: ARFrame.WorldMappingStatus = .notAvailable
    @Published private(set) var trackingStateDescription: String = ""

    // MARK: Internal Properties

    let session = ARSession()

    // MARK: Private Properties

    private var cancellables = Set<AnyCancellable>()
    private var planeAnchors: [UUID: ARPlaneAnchor] = [:]

    // MARK: Initialization

    override init() {
        super.init()
        session.delegate = self
    }

    // MARK: - Configuration

    private func makeConfiguration() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()

        // Plane detection
        configuration.planeDetection = [.horizontal, .vertical]

        // Scene reconstruction (mesh) — requires LiDAR
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }

        // Scene depth semantics — requires LiDAR
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }

        // Environment texturing for realistic lighting
        configuration.environmentTexturing = .automatic

        // Enable light estimation
        configuration.isLightEstimationEnabled = true

        return configuration
    }

    // MARK: - Session Control

    func run() {
        guard sessionState != .scanning && sessionState != .ready else { return }

        DispatchQueue.main.async { [weak self] in
            self?.sessionState = .initializing
        }

        let configuration = makeConfiguration()
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func pause() {
        session.pause()
    }

    func reset() {
        planeAnchors.removeAll()

        DispatchQueue.main.async { [weak self] in
            self?.detectedPlanes = []
            self?.sessionState = .notStarted
            self?.worldMappingStatus = .notAvailable
            self?.trackingStateDescription = ""
        }

        let configuration = makeConfiguration()
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    // MARK: - Plane Tracking

    private func updateDetectedPlanes() {
        let planes = Array(planeAnchors.values)
        DispatchQueue.main.async { [weak self] in
            self?.detectedPlanes = planes
        }
    }

    // MARK: - Queries

    /// Returns true if the device supports LiDAR-based scene reconstruction.
    var supportsSceneReconstruction: Bool {
        ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }

    /// Returns the number of horizontal planes detected.
    var horizontalPlaneCount: Int {
        planeAnchors.values.filter { $0.alignment == .horizontal }.count
    }

    /// Returns the number of vertical planes detected.
    var verticalPlaneCount: Int {
        planeAnchors.values.filter { $0.alignment == .vertical }.count
    }
}

// MARK: - ARSessionDelegate

extension ARSessionService: ARSessionDelegate {

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let mappingStatus = frame.worldMappingStatus
        DispatchQueue.main.async { [weak self] in
            self?.worldMappingStatus = mappingStatus
        }
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let newState: ARSessionState
        let description: String

        switch camera.trackingState {
        case .notAvailable:
            newState = .failed("AR tracking is not available on this device.")
            description = "Tracking not available"

        case .limited(let reason):
            description = trackingLimitedReasonDescription(reason)
            switch reason {
            case .initializing:
                newState = .initializing
            default:
                // Remain in scanning state but surface the limitation
                newState = .scanning
            }

        case .normal:
            newState = .scanning
            description = "Tracking normal"
        }

        DispatchQueue.main.async { [weak self] in
            self?.sessionState = newState
            self?.trackingStateDescription = description
        }
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        var updated = false
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                planeAnchors[planeAnchor.identifier] = planeAnchor
                updated = true
            }
        }
        if updated {
            updateDetectedPlanes()
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        var updated = false
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                planeAnchors[planeAnchor.identifier] = planeAnchor
                updated = true
            }
        }
        if updated {
            updateDetectedPlanes()
        }
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        var updated = false
        for anchor in anchors {
            if planeAnchors.removeValue(forKey: anchor.identifier) != nil {
                updated = true
            }
        }
        if updated {
            updateDetectedPlanes()
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        let message = error.localizedDescription
        DispatchQueue.main.async { [weak self] in
            self?.sessionState = .failed(message)
        }
    }

    func sessionWasInterrupted(_ session: ARSession) {
        DispatchQueue.main.async { [weak self] in
            self?.trackingStateDescription = "Session interrupted"
        }
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        DispatchQueue.main.async { [weak self] in
            self?.trackingStateDescription = "Resuming session..."
        }
    }

    // MARK: - Helpers

    private func trackingLimitedReasonDescription(_ reason: ARCamera.TrackingState.Reason) -> String {
        switch reason {
        case .initializing:
            return "Initializing AR session..."
        case .excessiveMotion:
            return "Slow down — too much motion"
        case .insufficientFeatures:
            return "Point at an area with more detail"
        case .relocalizing:
            return "Relocalizing..."
        @unknown default:
            return "Limited tracking"
        }
    }
}
