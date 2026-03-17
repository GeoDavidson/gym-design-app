import SwiftUI

/// A full-screen loading overlay with a pulsating accent ring animation.
struct LoadingView: View {
    var message: String? = nil

    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0.6

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    // Pulsating outer ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.appAccent, .appAccentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 72, height: 72)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    // Inner progress spinner
                    ProgressView()
                        .controlSize(.large)
                        .tint(.appAccent)
                }

                if let message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
            ) {
                ringScale = 1.15
                ringOpacity = 0.2
            }
        }
    }
}

#Preview {
    LoadingView(message: "Scanning your room...")
        .preferredColorScheme(.dark)
}
