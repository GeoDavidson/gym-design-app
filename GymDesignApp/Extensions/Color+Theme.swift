import SwiftUI

// MARK: - Theme Colors

extension Color {

    // MARK: Backgrounds

    /// Primary app background — deep dark tone.
    static let appBackground = Color(hex: "0D0D0F")

    /// Slightly elevated surface for cards and sheets.
    static let appSurface = Color(hex: "1A1A1F")

    /// Elevated surface for modals and popovers.
    static let appSurfaceElevated = Color(hex: "252530")

    /// Light surface variant.
    static let appSurfaceLight = Color(hex: "2A2A2A")

    // MARK: Accent / Brand

    /// Primary accent — vibrant blue-purple.
    static let appAccent = Color(hex: "6C63FF")

    /// Secondary accent — energetic orange.
    static let appAccentSecondary = Color(hex: "FF6B35")

    /// Tertiary accent — teal / cyan.
    static let appAccentTertiary = Color(hex: "00D4AA")

    // MARK: Text

    /// Primary text on dark backgrounds.
    static let appTextPrimary = Color(hex: "F5F5F7")

    /// Secondary / muted text.
    static let appTextSecondary = Color(hex: "8E8E93")

    /// Tertiary / placeholder text.
    static let appTextTertiary = Color(hex: "48484A")

    // MARK: Semantic

    /// Success indicators.
    static let appSuccess = Color(hex: "34C759")

    /// Warning indicators.
    static let appWarning = Color(hex: "FFD60A")

    /// Error / destructive indicators.
    static let appError = Color(hex: "FF3B30")

    // MARK: Borders & Dividers

    /// Subtle border for glass-style elements.
    static let appBorder = Color.white.opacity(0.12)

    /// Divider line color.
    static let appDivider = Color.white.opacity(0.06)

    // MARK: Gradients

    /// Primary accent gradient.
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "6C63FF"), Color(hex: "A855F7")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Warm accent gradient.
    static let warmGradient = LinearGradient(
        colors: [Color(hex: "FF6B35"), Color(hex: "FF3B30")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Hex Initializer

extension Color {

    /// Creates a `Color` from a hexadecimal string.
    ///
    /// Supports formats: `"#RRGGBB"`, `"RRGGBB"`, `"#RRGGBBAA"`, `"RRGGBBAA"`,
    /// `"#RGB"`, and `"RGB"` (shorthand).
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var hexValue: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&hexValue)

        let r, g, b, a: Double

        switch sanitized.count {
        case 3: // RGB shorthand
            r = Double((hexValue & 0xF00) >> 8) / 15.0
            g = Double((hexValue & 0x0F0) >> 4) / 15.0
            b = Double(hexValue & 0x00F) / 15.0
            a = 1.0
        case 6: // RRGGBB
            r = Double((hexValue & 0xFF0000) >> 16) / 255.0
            g = Double((hexValue & 0x00FF00) >> 8) / 255.0
            b = Double(hexValue & 0x0000FF) / 255.0
            a = 1.0
        case 8: // RRGGBBAA
            r = Double((hexValue & 0xFF000000) >> 24) / 255.0
            g = Double((hexValue & 0x00FF0000) >> 16) / 255.0
            b = Double((hexValue & 0x0000FF00) >> 8) / 255.0
            a = Double(hexValue & 0x000000FF) / 255.0
        default:
            r = 0; g = 0; b = 0; a = 1.0
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
