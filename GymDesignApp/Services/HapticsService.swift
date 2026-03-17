import UIKit

// MARK: - Haptics Service

/// Centralized haptic feedback manager providing impact, notification, and selection feedback.
final class HapticsService {

    // MARK: - Singleton

    static let shared = HapticsService()

    // MARK: - Generators

    private var impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    // MARK: - Initialization

    private init() {
        // Pre-create impact generators for each style
        let styles: [UIImpactFeedbackGenerator.FeedbackStyle] = [.light, .medium, .heavy, .soft, .rigid]
        for style in styles {
            impactGenerators[style] = UIImpactFeedbackGenerator(style: style)
        }
    }

    // MARK: - Feedback Methods

    /// Triggers an impact haptic with the specified style.
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        impactGenerators[style]?.impactOccurred()
    }

    /// Triggers a notification haptic with the specified type.
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.notificationOccurred(type)
    }

    /// Triggers a selection change haptic.
    func selection() {
        selectionGenerator.selectionChanged()
    }

    // MARK: - Preparation

    /// Prepares all generators so that haptics fire with minimal latency.
    func prepare() {
        for generator in impactGenerators.values {
            generator.prepare()
        }
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
}
