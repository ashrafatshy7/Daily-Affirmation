import Foundation
import UserNotifications
import SwiftUI

class QuoteHistory {
    private var history: [String] = []
    private var currentIndex: Int = 0
    private let quotes: [String]
    
    init(initialQuote: String, availableQuotes: [String]) {
        self.quotes = availableQuotes
        self.history = [initialQuote]
        self.currentIndex = 0
    }
    
    var currentQuote: String {
        guard currentIndex < history.count else { return "Stay inspired!" }
        return history[currentIndex]
    }
    
    func getPreviewQuote(offset: Int) -> String {
        if offset == 0 {
            // Current quote
            return currentQuote
        } else if offset == -1 {
            // Previous quote
            guard currentIndex > 0 else { return currentQuote }
            return history[currentIndex - 1]
        } else if offset == 1 {
            // Next quote
            if currentIndex + 1 < history.count {
                // Use existing next quote from history
                return history[currentIndex + 1]
            } else {
                // Generate preview of what next quote would be
                return generateRandomQuote()
            }
        } else {
            return currentQuote
        }
    }
    
    func moveNext() -> String {
        if currentIndex + 1 < history.count {
            // Move to existing next quote
            currentIndex += 1
            return history[currentIndex]
        } else {
            // Generate new quote and add to history
            let newQuote = generateRandomQuote()
            history.append(newQuote)
            currentIndex = history.count - 1
            return newQuote
        }
    }
    
    func movePrevious() -> String? {
        guard currentIndex > 0 else { return nil }
        currentIndex -= 1
        return history[currentIndex]
    }
    
    private func generateRandomQuote() -> String {
        guard !quotes.isEmpty else { return "Stay inspired!" }
        
        // Ensure we don't return the same quote as current
        let currentQuote = history[currentIndex]
        let availableQuotes = quotes.filter { $0 != currentQuote }
        if availableQuotes.isEmpty {
            return quotes.randomElement() ?? "Stay inspired!"
        }
        
        return availableQuotes.randomElement() ?? "Stay inspired!"
    }
}

class QuoteManager: ObservableObject {
    @Published var quotes: [String] = []
    @Published var currentIndex: Int = 0
    @Published private var currentQuoteText: String = ""
    private var isInitializing = true
    private var quoteHistory: QuoteHistory?
    
    @Published var dailyNotifications: Bool = false {
        didSet {
            if !isInitializing {
                saveSettings()
                if dailyNotifications {
                    requestNotificationPermission()
                } else {
                    cancelNotifications()
                }
            }
        }
    }
    
    enum NotificationMode: String, CaseIterable {
        case single = "single"
        case range = "range"
        
        func displayName(using quoteManager: QuoteManager) -> String {
            switch self {
            case .single: return quoteManager.localizedString("single_daily")
            case .range: return quoteManager.localizedString("time_range")
            }
        }
    }
    
    @Published var notificationMode: NotificationMode = .range {
        didSet {
            if !isInitializing {
                saveSettings()
                if dailyNotifications {
                    scheduleNotification()
                }
            }
        }
    }
    @Published var singleNotificationTime: Date = {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
    }() {
        didSet {
            if !isInitializing {
                saveSettings()
                if dailyNotifications && notificationMode == .single {
                    scheduleNotification()
                }
            }
        }
    }
    @Published var startTime: Date = {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
    }() {
        didSet {
            if !isInitializing {
                adjustEndTimeIfNeeded()
                adjustNotificationCountIfNeeded()
                saveSettings()
                if dailyNotifications {
                    scheduleNotification()
                }
            }
        }
    }
    @Published var endTime: Date = {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now) ?? now
    }() {
        didSet {
            if !isInitializing {
                adjustNotificationCountIfNeeded()
                saveSettings()
                if dailyNotifications {
                    scheduleNotification()
                }
            }
        }
    }
    @Published var notificationCount: Int = 1 {
        didSet {
            if !isInitializing {
                saveSettings()
                if dailyNotifications {
                    scheduleNotification()
                }
            }
        }
    }
    @Published var fontSize: FontSize = .medium {
        didSet {
            if !isInitializing {
                saveSettings()
            }
        }
    }
    
    
    enum FontSize: String, CaseIterable {
        case small = "small"
        case medium = "medium"
        case large = "large"
        
        func displayName(using quoteManager: QuoteManager) -> String {
            switch self {
            case .small: return quoteManager.localizedString("font_small")
            case .medium: return quoteManager.localizedString("font_medium")
            case .large: return quoteManager.localizedString("font_large")
            }
        }
        
        var multiplier: CGFloat {
            switch self {
            case .small: return 0.9
            case .medium: return 1.0
            case .large: return 1.2
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func safeCurrentIndex() -> Int {
        guard !quotes.isEmpty else { return 0 }
        return max(0, min(currentIndex, quotes.count - 1))
    }
    
    // MARK: - Static Helper Methods
    
    init() {
        isInitializing = true
        // Set default notification times: 9:00 AM to 10:00 AM
        let calendar = Calendar.current
        let now = Date()
        startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
        endTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now) ?? now
        singleNotificationTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
        notificationCount = 1
        notificationMode = .range
        
        setupNotificationCategories()
        loadSettings()
        loadQuotes()
        setDailyQuote()
        isInitializing = false
    }
    
    private func setupNotificationCategories() {
        let category = UNNotificationCategory(
            identifier: "DAILY_AFFIRMATION",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    private func loadQuotes() {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let quotesArray = try? JSONDecoder().decode([String].self, from: data) else {
            print("Failed to load quotes")
            return
        }
        
        self.quotes = quotesArray
    }
    
    private func setDailyQuote() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        
        if !quotes.isEmpty {
            // Ensure safe calculation to prevent overflow
            let safeDayOfYear = max(1, dayOfYear)
            currentIndex = (safeDayOfYear - 1) % quotes.count
            
            // Initialize quote history with daily quote
            let dailyQuote = quotes[currentIndex]
            quoteHistory = QuoteHistory(initialQuote: dailyQuote, availableQuotes: quotes)
            currentQuoteText = dailyQuote
        } else {
            currentIndex = 0
            quoteHistory = nil
            currentQuoteText = NSLocalizedString("loading", comment: "")
        }
    }
    
    func nextQuote() {
        guard let history = quoteHistory else { return }
        let newQuote = history.moveNext()
        DispatchQueue.main.async {
            self.currentQuoteText = newQuote
        }
    }
    
    func previousQuote() {
        guard let history = quoteHistory else { return }
        if let previousQuote = history.movePrevious() {
            DispatchQueue.main.async {
                self.currentQuoteText = previousQuote
            }
        }
    }
    
    var currentQuote: String {
        return currentQuoteText
    }
    
    func getPreviewQuote(offset: Int) -> String {
        guard let history = quoteHistory else { return currentQuoteText }
        return history.getPreviewQuote(offset: offset)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
    
    // MARK: - Notification Time Calculation
    func calculateNotificationTimes() -> [Date] {
        let calendar = Calendar.current
        
        // Get minutes since midnight for both times
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        var endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        // Handle cross-midnight scenarios (e.g., 10 PM to 6 AM)
        if endMinutes <= startMinutes {
            endMinutes += 24 * 60 // Add 24 hours
        }
        
        let totalMinutes = endMinutes - startMinutes
        
        // Validation: ensure there's at least a 1-minute difference
        if totalMinutes < 1 {
            // Return start time as single notification if times are equal
            return [startTime]
        }
        
        // Limit notification count to maximum possible unique times
        // Since iOS only supports minute precision, max notifications = total minutes + 1
        let maxPossibleNotifications = totalMinutes + 1
        let count = min(max(1, notificationCount), maxPossibleNotifications)
        
        var notificationTimes: [Date] = []
        
        if count == 1 {
            // Single notification at center of range
            let centerMinutes = startMinutes + totalMinutes / 2
            if let notificationTime = createDateFromMinutes(centerMinutes, using: calendar) {
                notificationTimes.append(notificationTime)
            }
        } else {
            // Multiple notifications distributed evenly (space-between)
            // Calculate the exact interval for space-between distribution
            let interval = Double(totalMinutes) / Double(count - 1)
            
            // Generate notifications with proper space-between distribution
            for i in 0..<count {
                let exactMinutes = Double(startMinutes) + (Double(i) * interval)
                let minutes = Int(round(exactMinutes))
                let adjustedMinutes = min(minutes, endMinutes) // Don't exceed end time
                
                if let notificationTime = createDateFromMinutes(adjustedMinutes, using: calendar) {
                    notificationTimes.append(notificationTime)
                }
            }
        }
        
        // Sort by time and remove duplicates
        return Array(Set(notificationTimes)).sorted()
    }
    
    private func createDateFromMinutes(_ minutes: Int, using calendar: Calendar) -> Date? {
        let adjustedMinutes = minutes % (24 * 60) // Handle overflow past midnight
        let hours = adjustedMinutes / 60
        let mins = adjustedMinutes % 60
        
        let now = Date()
        return calendar.date(bySettingHour: hours, minute: mins, second: 0, of: now)
    }
    
    // MARK: - Settings Persistence
    private func saveSettings() {
        UserDefaults.standard.set(dailyNotifications, forKey: "dailyNotifications")
        UserDefaults.standard.set(startTime, forKey: "startTime")
        UserDefaults.standard.set(endTime, forKey: "endTime")
        UserDefaults.standard.set(singleNotificationTime, forKey: "singleNotificationTime")
        UserDefaults.standard.set(notificationCount, forKey: "notificationCount")
        UserDefaults.standard.set(notificationMode.rawValue, forKey: "notificationMode")
        UserDefaults.standard.set(fontSize.rawValue, forKey: "fontSize")
    }
    
    private func loadSettings() {
        dailyNotifications = UserDefaults.standard.bool(forKey: "dailyNotifications")
        
        if let savedFontSize = FontSize(rawValue: UserDefaults.standard.string(forKey: "fontSize") ?? "") {
            fontSize = savedFontSize
        }
        
        // Load notification times if available
        if let savedStartTime = UserDefaults.standard.object(forKey: "startTime") as? Date {
            startTime = savedStartTime
        }
        
        if let savedEndTime = UserDefaults.standard.object(forKey: "endTime") as? Date {
            endTime = savedEndTime
        }
        
        // Load single notification time if available
        if let savedSingleTime = UserDefaults.standard.object(forKey: "singleNotificationTime") as? Date {
            singleNotificationTime = savedSingleTime
        }
        
        // Load notification count if available
        if UserDefaults.standard.object(forKey: "notificationCount") != nil {
            notificationCount = UserDefaults.standard.integer(forKey: "notificationCount")
            // Ensure count is at least 1
            if notificationCount < 1 {
                notificationCount = 1
            }
        }
        
        // Load notification mode if available
        if let savedMode = NotificationMode(rawValue: UserDefaults.standard.string(forKey: "notificationMode") ?? "") {
            notificationMode = savedMode
        }
        
        // If notifications were enabled, check permission and schedule
        if dailyNotifications {
            checkNotificationPermissionAndSchedule()
        }
    }
    
    // MARK: - Notification Methods
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission error: \(error)")
                    self?.dailyNotifications = false
                } else if granted {
                    print("Notification permission granted")
                    self?.scheduleNotification()
                } else {
                    print("Notification permission denied")
                    self?.dailyNotifications = false
                }
            }
        }
    }
    
    private func checkNotificationPermissionAndSchedule() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    self?.scheduleNotification()
                case .denied:
                    self?.dailyNotifications = false
                case .notDetermined:
                    self?.requestNotificationPermission()
                default:
                    self?.dailyNotifications = false
                }
            }
        }
    }
    
    private func scheduleNotification() {
        cancelNotifications()
        
        guard dailyNotifications, !quotes.isEmpty else {
            print("Cannot schedule: notifications disabled or no quotes")
            return
        }
        
        let calendar = Calendar.current
        
        if notificationMode == .single {
            // Schedule single daily notification
            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("daily_inspiration", comment: "")
            content.body = getRandomQuote()
            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "DAILY_AFFIRMATION"
            
            let components = calendar.dateComponents([.hour, .minute], from: singleNotificationTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let identifier = "dailyInspiration_single_\(components.hour ?? 0)_\(components.minute ?? 0)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling single notification \(identifier): \(error)")
                }
            }
        } else {
            // Schedule range-based notifications
            let notificationTimes = calculateNotificationTimes()
            
            for (index, notificationTime) in notificationTimes.enumerated() {
                let content = UNMutableNotificationContent()
                content.title = NSLocalizedString("daily_inspiration", comment: "")
                content.body = getRandomQuote() // Use random quote for each notification
                content.sound = .default
                content.badge = 1
                
                // Add category for better notification handling
                content.categoryIdentifier = "DAILY_AFFIRMATION"
                
                let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                
                // Create more unique identifiers to avoid conflicts
                let identifier = "dailyInspiration_range_\(components.hour ?? 0)_\(components.minute ?? 0)_\(index)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling range notification \(identifier): \(error)")
                    }
                }
            }
        }
    }
    
    
    private func cancelNotifications() {
        // Cancel all existing daily inspiration notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToCancel = requests
                .filter { $0.identifier.hasPrefix("dailyInspiration") }
                .map { $0.identifier }
            
            if !identifiersToCancel.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
                // Also remove delivered notifications
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiersToCancel)
            }
        }
    }
    
    private func getDailyQuote() -> String {
        guard !quotes.isEmpty else { return NSLocalizedString("stay_inspired", comment: "") }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        
        let dailyIndex = (dayOfYear - 1) % quotes.count
        return quotes[dailyIndex]
    }
    
    private func getRandomQuote() -> String {
        guard !quotes.isEmpty else { return NSLocalizedString("stay_inspired", comment: "") }
        return quotes.randomElement() ?? NSLocalizedString("stay_inspired", comment: "")
    }
    
    var formattedNotificationTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let startTimeStr = formatter.string(from: startTime)
        let endTimeStr = formatter.string(from: endTime)
        return "\(startTimeStr) - \(endTimeStr)"
    }
    
    var formattedNotificationCount: String {
        return "\(notificationCount)"
    }
    
    var isValidTimeRange: Bool {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        // Consider it valid if there's a difference (handles cross-midnight)
        return startMinutes != endMinutes
    }
    
    var maxNotificationsAllowed: Int {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        var endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        // Handle cross-midnight scenarios
        if endMinutes <= startMinutes {
            endMinutes += 24 * 60
        }
        
        let totalMinutes = endMinutes - startMinutes
        
        // Maximum notifications based on time range (total minutes + 1 to include both start and end)
        let timeBasedMax = max(1, totalMinutes + 1)
        
        // Apply both time-based limitation and hard cap of 10
        return min(10, timeBasedMax)
    }
    
    // MARK: - Time Adjustment
    private func adjustEndTimeIfNeeded() {
        // Only adjust if we're in range mode
        guard notificationMode == .range else { return }
        
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        // If start time is >= end time, set end time to start time + 1 minute
        if startMinutes >= endMinutes {
            let newEndMinutes = startMinutes + 1
            let newEndHour = newEndMinutes / 60
            let newEndMinute = newEndMinutes % 60
            
            // Handle the case where adding 1 minute goes to next day (24:00 -> 00:00)
            if newEndHour >= 24 {
                // Set to 00:00 next day
                endTime = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: endTime) ?? endTime
            } else {
                // Set to calculated time same day
                endTime = calendar.date(bySettingHour: newEndHour, minute: newEndMinute, second: 0, of: endTime) ?? endTime
            }
        }
    }
    
    // MARK: - Notification Count Adjustment
    private func adjustNotificationCountIfNeeded() {
        // Only adjust if we're in range mode
        guard notificationMode == .range else { return }
        
        let maxAllowed = maxNotificationsAllowed
        
        // If current count exceeds the new maximum, reduce it to the maximum
        if notificationCount > maxAllowed {
            notificationCount = maxAllowed
        }
        // If current count is less than or equal to maximum, don't change it
    }
    
    // MARK: - Localization
    func localizedString(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
}
