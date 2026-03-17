import Foundation
import Combine
import ARKit

// MARK: - Scan State

enum ScanState: Equatable {
    case instructions
    case scanning
    case processing
    case complete
}

// MARK: - AR Scan ViewModel

@MainActor
final class ARScanViewModel: ObservableObject {

    // MARK: Published Properties

    @Published private(set) var scanState: ScanState = .instructions
    @Published private(set) var scanProgress: Float = 0
    @Published private(set) var estimatedRoom: Room?
    @Published private(set) var instructionText: String = "Point your camera at the floor to begin."
    @Published private(set) var canCompleteScan: Bool = false

    // MARK: Dependencies

    private let arSessionService: ARSessionService
    private let reconstructionService: RoomReconstructionService

    // MARK: Private Properties

    private var cancellables = Set<AnyCancellable>()
    private static let completionThreshold: Float = 0.6

    // MARK: Initialization

    init(
        arSessionService: ARSessionService,
        reconstructionService: RoomReconstructionService = RoomReconstructionService()
    ) {
        self.arSessionService = arSessionService
        self.reconstructionService = reconstructionService
        bindToARSession()
    }

    // MARK: - Bindings

    private func bindToARSession() {
        // React to session state changes
        arSessionService.$sessionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleSessionStateChange(state)
            }
            .store(in: &cancellables)

        // React to detected planes for progress and room estimation
        arSessionService.$detectedPlanes
            .receive(on: DispatchQueue.main)
            .throttle(for: .milliseconds(500), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] planes in
                self?.handlePlanesUpdate(planes)
            }
            .store(in: &cancellables)

        // React to world mapping status for instruction refinement
        arSessionService.$worldMappingStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, self.scanState == .scanning else { return }
                self.updateInstructionForScanProgress()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Actions

    func startScan() {
        scanState = .scanning
        scanProgress = 0
        estimatedRoom = nil
        canCompleteScan = false
        instructionText = "Point your camera at the floor."
        arSessionService.run()
    }

    func completeScan() {
        guard canCompleteScan else { return }

        scanState = .processing
        instructionText = "Processing room data..."

        // Final room estimation
        let planes = arSessionService.detectedPlanes
        if let room = reconstructionService.estimateRoom(from: planes) {
            estimatedRoom = room
            scanState = .complete
            instructionText = "Room detected! \(room.displayDimensions)"
        } else {
            // Fallback to default room
            let fallback = makeFallbackRoom()
            estimatedRoom = fallback
            scanState = .complete
            instructionText = "Room estimated with available data."
        }
    }

    func resetScan() {
        scanState = .instructions
        scanProgress = 0
        estimatedRoom = nil
        canCompleteScan = false
        instructionText = "Point your camera at the floor to begin."
        arSessionService.reset()
    }

    // MARK: - Private Handlers

    private func handleSessionStateChange(_ state: ARSessionState) {
        guard scanState == .scanning else { return }

        switch state {
        case .initializing:
            instructionText = "Initializing AR... Hold your device steady."

        case .scanning:
            updateInstructionForScanProgress()

        case .failed(let reason):
            instructionText = "AR issue: \(reason)"

        default:
            break
        }
    }

    private func handlePlanesUpdate(_ planes: [ARPlaneAnchor]) {
        guard scanState == .scanning else { return }

        // Update progress based on scan completeness
        let completeness = reconstructionService.estimateScanCompleteness(planes: planes)
        scanProgress = completeness

        // Attempt room estimation
        if let room = reconstructionService.estimateRoom(from: planes) {
            estimatedRoom = room
        }

        // Enable completion when threshold is met
        canCompleteScan = completeness >= Self.completionThreshold

        updateInstructionForScanProgress()
    }

    // MARK: - Instruction Logic

    private func updateInstructionForScanProgress() {
        let horizontalCount = arSessionService.horizontalPlaneCount
        let verticalCount = arSessionService.verticalPlaneCount

        if horizontalCount == 0 {
            instructionText = "Point your camera at the floor."
        } else if verticalCount == 0 {
            instructionText = "Floor detected! Now slowly pan toward the walls."
        } else if verticalCount < 2 {
            instructionText = "Wall detected. Continue scanning the remaining walls."
        } else if verticalCount < 4 {
            instructionText = "Good progress! Scan more walls for better accuracy."
        } else if canCompleteScan {
            instructionText = "Room detected! Tap \"Complete Scan\" when ready."
        } else {
            instructionText = "Keep scanning for improved room detection."
        }
    }

    // MARK: - Helpers

    private func makeFallbackRoom() -> Room {
        Room(
            width: Float(AppConstants.DefaultRoom.width),
            length: Float(AppConstants.DefaultRoom.length),
            height: Float(AppConstants.DefaultRoom.height)
        )
    }
}
