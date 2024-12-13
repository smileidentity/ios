import UIKit

class HapticManager {
    static let shared = HapticManager()

    private init() {}

    // MARK: Notification Feedback

    /// Triggers a notification haptic feedback
    /// - Parameter type: The notification type (success, warning, error)
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    // MARK: Impact Feedback

    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
