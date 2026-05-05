import UIKit

enum AppHaptics {
    static func lightTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func mediumImpact() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func successNotice() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func achievementUnlocked() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warningNotice() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}
