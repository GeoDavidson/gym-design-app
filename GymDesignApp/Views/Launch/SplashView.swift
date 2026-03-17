import SwiftUI

/// Animated splash screen shown on app launch. Auto-transitions after 2 seconds.
struct SplashView: View {
    var onFinished: () -> Void

    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0.0
    @State private var subtitleOpacity: Double = 0.0
    @State private var ringRotation: Double = 0

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            // Subtle radial glow behind logo
            RadialGradient(
                colors: [
                    Color.appAccent.opacity(0.12),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 220
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // Spinning accent ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.appAccent, .appAccentSecondary, .appAccent],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(ringRotation))

                // App title with accent gradient
                Text("GymDesign AR")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appAccent, .appAccentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Design your dream gym in AR")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .opacity(subtitleOpacity)
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
        }
        .onAppear {
            // Ring rotation
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }

            // Scale + fade in
            withAnimation(.easeOut(duration: 0.8)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // Subtitle delayed fade
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                subtitleOpacity = 1.0
            }

            // Auto-transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onFinished()
            }
        }
    }
}

#Preview {
    SplashView(onFinished: {})
        .preferredColorScheme(.dark)
}
