import SwiftUI

// MARK: - AR Scan Overlay View

/// A semi-transparent overlay displayed during room scanning. Shows a pulsing
/// ring animation, instruction text, progress bar, and actions to complete or
/// skip the scan.
struct ARScanOverlayView: View {

    @ObservedObject var viewModel: ARScanViewModel

    /// Called when the user completes the scan.
    var onComplete: () -> Void
    /// Called when the user elects to skip scanning and enter dimensions manually.
    var onSkip: () -> Void

    @State private var ringScale: CGFloat = 1.0
    @State private var ringOpacity: Double = 0.8

    // MARK: - Body

    var body: some View {
        ZStack {
            // Semi-transparent dark backdrop
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Cancel button — top-left
                HStack {
                    Button {
                        viewModel.resetScan()
                        onSkip()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Center content
                VStack(spacing: 32) {
                    pulsingRing
                    instructionSection
                    progressSection
                    actionButtons
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .onAppear {
            startRingAnimation()
        }
    }

    // MARK: - Pulsing Ring

    private var pulsingRing: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(
                    Color(hex: "#00D4FF").opacity(ringOpacity * 0.3),
                    lineWidth: 2
                )
                .frame(width: 160, height: 160)
                .scaleEffect(ringScale)

            // Middle ring
            Circle()
                .stroke(
                    Color(hex: "#00D4FF").opacity(0.5),
                    lineWidth: 3
                )
                .frame(width: 120, height: 120)

            // Inner filled circle with icon
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#00D4FF").opacity(0.25),
                            Color(hex: "#7B2FFF").opacity(0.10),
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 50
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: scanStateIcon)
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(Color(hex: "#00D4FF"))
                )
        }
    }

    private var scanStateIcon: String {
        switch viewModel.scanState {
        case .instructions: return "viewfinder"
        case .scanning:     return "camera.viewfinder"
        case .processing:   return "gearshape.2"
        case .complete:     return "checkmark.circle"
        }
    }

    // MARK: - Ring Animation

    private func startRingAnimation() {
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            ringScale = 1.15
            ringOpacity = 0.4
        }
    }

    // MARK: - Instructions

    private var instructionSection: some View {
        VStack(spacing: 8) {
            Text("Room Scanning")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            Text(viewModel.instructionText)
                .font(.system(size: 15))
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .animation(.easeInOut(duration: 0.3), value: viewModel.instructionText)
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 8) {
            // Progress label
            HStack {
                Text("Scan Progress")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.appTextSecondary)
                Spacer()
                Text("\(Int(viewModel.scanProgress * 100))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "#00D4FF"))
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    // Fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#00D4FF"), Color(hex: "#7B2FFF")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: max(0, geometry.size.width * CGFloat(viewModel.scanProgress)),
                            height: 8
                        )
                        .animation(.easeInOut(duration: 0.4), value: viewModel.scanProgress)
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Complete Scan
            AccentButton(
                title: "Complete Scan",
                icon: "checkmark.circle.fill",
                isDisabled: !viewModel.canCompleteScan
            ) {
                viewModel.completeScan()
                onComplete()
            }

            // Skip & Enter Dimensions
            Button {
                onSkip()
            } label: {
                Text("Skip & Enter Dimensions")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.appTextSecondary)
                    .underline()
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ARScanOverlayView(
            viewModel: ARScanViewModel(
                arSessionService: ARSessionService()
            ),
            onComplete: {},
            onSkip: {}
        )
    }
}
