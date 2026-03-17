import SwiftUI
import RealityKit

// MARK: - Virtual Camera Controls

/// Overlay that adds orbit, pan, and zoom gestures to the virtual room view.
/// Manages its own camera state and repositions the ARView camera accordingly.
struct VirtualCameraControls: View {

    @ObservedObject var viewModel: RoomDesignViewModel

    /// Reference to the ARView — set after VirtualRoomView creates it.
    var arView: ARView?

    // MARK: - Camera State

    @State private var orbitAngle: Float = .pi / 4       // Horizontal angle (radians)
    @State private var orbitPitch: Float = .pi / 6        // Vertical angle (radians)
    @State private var orbitDistance: Float = 8.0          // Distance from center
    @State private var panOffset: SIMD2<Float> = .zero    // XZ pan offset

    // Gesture tracking
    @State private var lastOrbitAngle: Float = .pi / 4
    @State private var lastOrbitPitch: Float = .pi / 6
    @State private var lastOrbitDistance: Float = 8.0
    @State private var lastPanOffset: SIMD2<Float> = .zero

    private let minDistance: Float = 2.0
    private let maxDistance: Float = 25.0
    private let minPitch: Float = 0.05
    private let maxPitch: Float = .pi / 2 - 0.05

    // MARK: - Body

    var body: some View {
        ZStack {
            // Transparent gesture capture layer
            Color.clear
                .contentShape(Rectangle())
                .gesture(orbitGesture)
                .gesture(panGesture)
                .gesture(zoomGesture)

            // Floating controls
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: AppTheme.Spacing.sm) {
                        cameraButton(icon: "arrow.counterclockwise", label: "Reset") {
                            resetCamera(animated: true)
                        }
                        cameraButton(icon: "square.tophalf.filled", label: "Top") {
                            topDownView(animated: true)
                        }
                    }
                    .padding(.trailing, AppTheme.Spacing.md)
                    .padding(.bottom, 100) // Above bottom toolbar
                }
            }
        }
        .onAppear {
            resetCameraState()
            applyCameraTransform()
        }
    }

    // MARK: - Gestures

    /// One-finger drag: orbit camera around room center.
    private var orbitGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                let sensitivity: Float = 0.005
                orbitAngle = lastOrbitAngle + Float(value.translation.width) * sensitivity
                orbitPitch = clamp(
                    lastOrbitPitch - Float(value.translation.height) * sensitivity,
                    min: minPitch,
                    max: maxPitch
                )
                applyCameraTransform()
            }
            .onEnded { _ in
                lastOrbitAngle = orbitAngle
                lastOrbitPitch = orbitPitch
            }
    }

    /// Two-finger drag: pan camera.
    private var panGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .simultaneously(with: DragGesture(minimumDistance: 5))
            .onChanged { value in
                guard let primary = value.first?.translation else { return }
                let sensitivity: Float = 0.005
                panOffset = SIMD2<Float>(
                    lastPanOffset.x + Float(primary.width) * sensitivity,
                    lastPanOffset.y + Float(primary.height) * sensitivity
                )
                applyCameraTransform()
            }
            .onEnded { _ in
                lastPanOffset = panOffset
            }
    }

    /// Pinch: zoom in/out.
    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let scale = Float(value.magnification)
                orbitDistance = clamp(
                    lastOrbitDistance / scale,
                    min: minDistance,
                    max: maxDistance
                )
                applyCameraTransform()
            }
            .onEnded { _ in
                lastOrbitDistance = orbitDistance
            }
    }

    // MARK: - Camera Transform

    private func applyCameraTransform() {
        guard let arView else { return }

        let room = viewModel.room
        let centerY = room.height * 0.3

        // Spherical coordinates → Cartesian
        let x = orbitDistance * cos(orbitPitch) * sin(orbitAngle) + panOffset.x
        let y = orbitDistance * sin(orbitPitch) + centerY
        let z = orbitDistance * cos(orbitPitch) * cos(orbitAngle) + panOffset.y

        let cameraPosition = SIMD3<Float>(x, y, z)
        let lookTarget = SIMD3<Float>(panOffset.x, centerY, panOffset.y)

        // Find camera entity in scene
        if let cameraAnchor = arView.scene.anchors.first(where: { anchor in
            anchor.children.contains(where: { $0 is PerspectiveCamera })
        }),
           let camera = cameraAnchor.children.first(where: { $0 is PerspectiveCamera }) {
            camera.position = cameraPosition
            camera.look(at: lookTarget, from: cameraPosition, relativeTo: nil)
        }
    }

    // MARK: - Presets

    private func resetCamera(animated: Bool) {
        resetCameraState()
        if animated {
            withAnimation(.easeInOut(duration: 0.4)) {
                applyCameraTransform()
            }
        } else {
            applyCameraTransform()
        }
    }

    private func resetCameraState() {
        let room = viewModel.room
        orbitDistance = max(room.width, room.length) * 1.2
        orbitAngle = .pi / 4
        orbitPitch = .pi / 6
        panOffset = .zero
        lastOrbitAngle = orbitAngle
        lastOrbitPitch = orbitPitch
        lastOrbitDistance = orbitDistance
        lastPanOffset = panOffset
    }

    private func topDownView(animated: Bool) {
        orbitPitch = .pi / 2 - 0.05
        orbitAngle = 0
        orbitDistance = max(viewModel.room.width, viewModel.room.length) * 1.0
        panOffset = .zero
        lastOrbitAngle = orbitAngle
        lastOrbitPitch = orbitPitch
        lastOrbitDistance = orbitDistance
        lastPanOffset = panOffset
        applyCameraTransform()
    }

    // MARK: - Helpers

    private func clamp(_ value: Float, min minVal: Float, max maxVal: Float) -> Float {
        Swift.min(Swift.max(value, minVal), maxVal)
    }

    private func cameraButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(width: 48, height: 48)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VirtualCameraControls(viewModel: RoomDesignViewModel())
    }
    .preferredColorScheme(.dark)
}
