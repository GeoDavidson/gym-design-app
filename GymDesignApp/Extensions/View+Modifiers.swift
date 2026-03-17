import SwiftUI

// MARK: - Glass Background

extension View {

    /// Applies an ultra-thin material background with a subtle white border overlay,
    /// producing a frosted-glass effect.
    func glassBackground(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
    }
}

// MARK: - Accent Gradient Background

extension View {

    /// Fills the background with the app's primary accent gradient.
    func accentGradientBackground(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(
                LinearGradient(
                    colors: [Color(hex: "6C63FF"), Color(hex: "A855F7")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
    }
}

// MARK: - Card Style

extension View {

    /// Applies a standard card appearance: surface background, rounded corners, and a soft shadow.
    func cardStyle(cornerRadius: CGFloat = 16, shadowRadius: CGFloat = 8) -> some View {
        self
            .background(Color.appSurface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: shadowRadius, x: 0, y: 4)
    }
}

// MARK: - Shimmer

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    var duration: Double
    var bounce: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.25),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(20))
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                    .repeatForever(autoreverses: bounce)
                ) {
                    phase = 300
                }
            }
    }
}

extension View {

    /// Adds an animated shimmer effect, useful for skeleton loading placeholders.
    func shimmer(duration: Double = 1.5, bounce: Bool = false) -> some View {
        modifier(ShimmerModifier(duration: duration, bounce: bounce))
    }
}

// MARK: - Accent Button Style

struct AccentButtonStyle: ButtonStyle {

    var cornerRadius: CGFloat
    var horizontalPadding: CGFloat
    var verticalPadding: CGFloat

    init(
        cornerRadius: CGFloat = 14,
        horizontalPadding: CGFloat = 24,
        verticalPadding: CGFloat = 14
    ) {
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color(hex: "6C63FF"), Color(hex: "A855F7")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Convenience Button Style Extension

extension ButtonStyle where Self == AccentButtonStyle {
    /// The app's primary call-to-action button style with a gradient background.
    static var accent: AccentButtonStyle { AccentButtonStyle() }
}
