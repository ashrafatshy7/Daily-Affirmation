import Foundation

// MARK: - Safe Math Utilities
extension Double {
    /// Returns true if the value is a valid finite number (not NaN or infinite)
    var isValidNumber: Bool {
        return !isNaN && !isInfinite
    }
    
    /// Safely converts to Int, returning a fallback value if invalid
    func safeInt(fallback: Int = 0) -> Int {
        guard isValidNumber else { return fallback }
        let rounded = self.rounded()
        guard rounded.isValidNumber else { return fallback }
        return Int(rounded)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let notificationPermissionDenied = Notification.Name("notificationPermissionDenied")
    static let resetOnboarding = Notification.Name("resetOnboarding")
}