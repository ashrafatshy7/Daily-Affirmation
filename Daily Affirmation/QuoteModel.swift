import Foundation
import UserNotifications
import SwiftUI
import Combine

class QuoteHistory {
    private var history: [String] = []
    private var currentIndex: Int = 0
    private let quotes: [String]
    private var cachedNextQuote: String?
    
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
                // Generate and cache preview of what next quote would be
                if cachedNextQuote == nil {
                    cachedNextQuote = generateRandomQuote()
                }
                return cachedNextQuote!
            }
        } else {
            return currentQuote
        }
    }
    
    func moveNext() -> String {
        if currentIndex + 1 < history.count {
            // Move to existing next quote
            currentIndex += 1
            // Clear cache since we're moving to existing quote
            cachedNextQuote = nil
            return history[currentIndex]
        } else {
            // Use cached quote if available, otherwise generate new one
            let newQuote = cachedNextQuote ?? generateRandomQuote()
            history.append(newQuote)
            currentIndex = history.count - 1
            // Clear cache since we've used it
            cachedNextQuote = nil
            return newQuote
        }
    }
    
    func movePrevious() -> String? {
        guard currentIndex > 0 else { return nil }
        currentIndex -= 1
        // Clear cache when moving backwards since next quote might be different
        cachedNextQuote = nil
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
    
    private var _dailyNotifications: Bool = false
    private let _dailyNotificationsSubject = PassthroughSubject<Bool, Never>()
    
    var dailyNotifications: Bool {
        get { 
            if Thread.isMainThread {
                return _dailyNotifications
            } else {
                return DispatchQueue.main.sync { _dailyNotifications }
            }
        }
        set {
            if Thread.isMainThread {
                _setDailyNotifications(newValue)
            } else {
                DispatchQueue.main.sync {
                    self._setDailyNotifications(newValue)
                }
            }
        }
    }
    
    private func _setDailyNotifications(_ newValue: Bool) {
        if !isInitializing && newValue {
            // Check permission before enabling notifications
            checkNotificationPermissionBeforeEnabling { [weak self] canEnable in
                DispatchQueue.main.async {
                    if canEnable {
                        self?._updateDailyNotifications(newValue)
                    } else {
                        // Permission denied, keep notifications off and notify delegates
                        NotificationCenter.default.post(name: .notificationPermissionDenied, object: nil)
                    }
                }
            }
        } else {
            _updateDailyNotifications(newValue)
        }
    }
    
    private func _updateDailyNotifications(_ newValue: Bool) {
        _dailyNotifications = newValue
        _dailyNotificationsSubject.send(newValue) // Send on main thread
        objectWillChange.send() // Manually trigger @Published-like behavior on main thread
        
        if !isInitializing {
            saveSettings()
            if _dailyNotifications {
                requestNotificationPermission()
            } else {
                cancelNotifications()
            }
        }
    }
    
    // Provide publisher access like @Published
    var dailyNotificationsPublisher: AnyPublisher<Bool, Never> {
        return _dailyNotificationsSubject.eraseToAnyPublisher()
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
            // Validate and clamp notification count to acceptable bounds
            let clampedValue = max(1, min(notificationCount, maxNotificationsAllowed))
            if clampedValue != notificationCount {
                // Avoid infinite recursion by temporarily setting isInitializing
                let wasInitializing = isInitializing
                isInitializing = true
                notificationCount = clampedValue
                isInitializing = wasInitializing
            }
            
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
    
    @Published var lovedQuotes: Set<String> = [] {
        didSet {
            if !isInitializing {
                saveLovedQuotes()
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
    
    private var userDefaults: UserDefaults
    
    init(loadFromDefaults: Bool = true, userDefaults: UserDefaults? = nil) {
        // Auto-detect test environment and use shared test storage
        if userDefaults == nil && ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            // In test environment: use thread-local shared UserDefaults for the test
            self.userDefaults = QuoteManager.getTestUserDefaults()
        } else {
            // Use provided UserDefaults or standard
            self.userDefaults = userDefaults ?? UserDefaults.standard
        }
        
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
        
        if loadFromDefaults {
            loadSettings()
            loadLovedQuotes()
        } else {
            // For tests: start with clean state
            lovedQuotes = Set<String>()
        }
        
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
            currentQuoteText = "Loading..."
        }
    }
    
    func nextQuote() {
        guard let history = quoteHistory else { return }
        let newQuote = history.moveNext()
        
        if Thread.isMainThread {
            currentQuoteText = newQuote
        } else {
            DispatchQueue.main.sync {
                self.currentQuoteText = newQuote
            }
        }
    }
    
    func previousQuote() {
        guard let history = quoteHistory else { return }
        if let previousQuote = history.movePrevious() {
            if Thread.isMainThread {
                currentQuoteText = previousQuote
            } else {
                DispatchQueue.main.sync {
                    self.currentQuoteText = previousQuote
                }
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
        if endMinutes < startMinutes {
            endMinutes += 24 * 60 // Add 24 hours
        }
        
        let totalMinutes = endMinutes - startMinutes
        
        // Validation: ensure there's at least a 1-minute difference
        if totalMinutes < 1 {
            // Return start time as single notification if times are equal
            return [startTime]
        }
        
        // Limit notification count to maximum allowed by the app
        let count = min(max(1, notificationCount), maxNotificationsAllowed)
        
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
        userDefaults.set(dailyNotifications, forKey: "dailyNotifications")
        userDefaults.set(startTime, forKey: "startTime")
        userDefaults.set(endTime, forKey: "endTime")
        userDefaults.set(singleNotificationTime, forKey: "singleNotificationTime")
        userDefaults.set(notificationCount, forKey: "notificationCount")
        userDefaults.set(notificationMode.rawValue, forKey: "notificationMode")
        userDefaults.set(fontSize.rawValue, forKey: "fontSize")
    }
    
    private func loadSettings() {
        dailyNotifications = userDefaults.bool(forKey: "dailyNotifications")
        
        if let savedFontSize = FontSize(rawValue: userDefaults.string(forKey: "fontSize") ?? "") {
            fontSize = savedFontSize
        }
        
        // Load notification times if available
        if let savedStartTime = userDefaults.object(forKey: "startTime") as? Date {
            startTime = savedStartTime
        }
        
        if let savedEndTime = userDefaults.object(forKey: "endTime") as? Date {
            endTime = savedEndTime
        }
        
        // Load single notification time if available
        if let savedSingleTime = userDefaults.object(forKey: "singleNotificationTime") as? Date {
            singleNotificationTime = savedSingleTime
        }
        
        // Load notification count if available
        if userDefaults.object(forKey: "notificationCount") != nil {
            notificationCount = userDefaults.integer(forKey: "notificationCount")
            // Ensure count is at least 1
            if notificationCount < 1 {
                notificationCount = 1
            }
        }
        
        // Load notification mode if available
        if let savedMode = NotificationMode(rawValue: userDefaults.string(forKey: "notificationMode") ?? "") {
            notificationMode = savedMode
        }
        
        // If notifications were enabled, check permission and schedule
        if dailyNotifications {
            checkNotificationPermissionAndSchedule()
        }
    }
    
    // MARK: - Notification Methods
    private func checkNotificationPermissionBeforeEnabling(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                completion(true)
            case .denied:
                completion(false)
            case .notDetermined:
                // Request permission
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    completion(granted)
                }
            default:
                completion(false)
            }
        }
    }
    
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
            content.title = "ThinkUp"
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
                content.title = "ThinkUp"
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
        guard !quotes.isEmpty else { return "Stay inspired!" }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        
        let dailyIndex = (dayOfYear - 1) % quotes.count
        return quotes[dailyIndex]
    }
    
    private func getRandomQuote() -> String {
        guard !quotes.isEmpty else { return "Stay inspired!" }
        return quotes.randomElement() ?? "Stay inspired!"
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
        if endMinutes < startMinutes {
            endMinutes += 24 * 60
        }
        
        let totalMinutes = endMinutes - startMinutes
        
        // Maximum notifications based on time range (total minutes + 1 to include both start and end)
        let timeBasedMax = max(1, totalMinutes + 1)
        
        // Apply hard cap only for very long ranges (more than 12 hours = 720 minutes)
        if totalMinutes > 720 {
            return 10
        }
        
        return timeBasedMax
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
    
    // MARK: - Loved Quotes Management
    func toggleLoveQuote(_ quote: String) {
        if Thread.isMainThread {
            var newLovedQuotes = self.lovedQuotes
            if newLovedQuotes.contains(quote) {
                newLovedQuotes.remove(quote)
            } else {
                newLovedQuotes.insert(quote)
            }
            self.lovedQuotes = newLovedQuotes
        } else {
            DispatchQueue.main.sync {
                var newLovedQuotes = self.lovedQuotes
                if newLovedQuotes.contains(quote) {
                    newLovedQuotes.remove(quote)
                } else {
                    newLovedQuotes.insert(quote)
                }
                self.lovedQuotes = newLovedQuotes
            }
        }
    }
    
    func isQuoteLoved(_ quote: String) -> Bool {
        return lovedQuotes.contains(quote)
    }
    
    var lovedQuotesArray: [String] {
        return Array(lovedQuotes).sorted()
    }
    
    private func saveLovedQuotes() {
        let lovedQuotesArray = Array(lovedQuotes)
        
        // Encode each quote using Base64 to preserve special characters
        let encodedQuotes = lovedQuotesArray.map { encodeQuoteForStorage($0) }
        
        // Save the encoded array to UserDefaults (this replaces existing data)
        userDefaults.set(encodedQuotes, forKey: "lovedQuotes")
        userDefaults.synchronize() // Force immediate synchronization
        
        print("Debug: Saved \(lovedQuotesArray.count) quotes: \(lovedQuotesArray)")
        
        // Validation: verify the data was saved correctly
        if let savedData = userDefaults.array(forKey: "lovedQuotes") as? [String] {
            let expectedCount = lovedQuotesArray.count
            let actualCount = savedData.count
            if expectedCount != actualCount {
                print("Warning: Expected to save \(expectedCount) quotes but saved \(actualCount)")
                print("Debug: Actual saved data: \(savedData)")
            }
        }
    }
    
    private func loadLovedQuotes() {
        guard let savedArray = userDefaults.array(forKey: "lovedQuotes") as? [String] else {
            // No saved data, start with empty set
            let wasInitializing = isInitializing
            isInitializing = true
            lovedQuotes = Set<String>()
            isInitializing = wasInitializing
            return
        }
        
        var decodedQuotes: [String] = []
        var needsMigration = false
        var failedDecodingCount = 0
        
        for savedQuote in savedArray {
            if isBase64Encoded(savedQuote) {
                // This is an encoded quote, decode it
                let decodedQuote = decodeQuoteFromStorage(savedQuote)
                if decodedQuote != savedQuote { // Successfully decoded (different from input)
                    decodedQuotes.append(decodedQuote)
                } else {
                    // Decoding failed, treat as raw quote
                    decodedQuotes.append(savedQuote)
                    needsMigration = true
                    failedDecodingCount += 1
                }
            } else {
                // This is a raw quote (old format), keep as-is but mark for migration
                decodedQuotes.append(savedQuote)
                needsMigration = true
            }
        }
        
        // Validation: log any issues for debugging
        if failedDecodingCount > 0 {
            print("Warning: Failed to decode \(failedDecodingCount) Base64 quotes")
        }
        
        // Set the loaded quotes
        let wasInitializing = isInitializing
        isInitializing = true
        lovedQuotes = Set(decodedQuotes)
        isInitializing = wasInitializing
        
        print("Debug: Loaded \(decodedQuotes.count) quotes: \(decodedQuotes)")
        
        // If we found old format data, migrate it to new format
        if needsMigration {
            print("Debug: Migrating \(decodedQuotes.count) quotes to new format")
            saveLovedQuotes()
        }
    }
    
    // MARK: - Encoding Utilities for Special Characters
    private func encodeQuoteForStorage(_ quote: String) -> String {
        guard let data = quote.data(using: .utf8) else { return quote }
        return data.base64EncodedString()
    }
    
    private func decodeQuoteFromStorage(_ encodedQuote: String) -> String {
        guard let data = Data(base64Encoded: encodedQuote),
              let decodedString = String(data: data, encoding: .utf8) else {
            // If Base64 decoding fails, return the original string (backward compatibility)
            return encodedQuote
        }
        return decodedString
    }
    
    private func isBase64Encoded(_ string: String) -> Bool {
        // More strict Base64 detection to avoid false positives
        guard string.count > 8, // Minimum reasonable length for Base64 encoded text
              string.count % 4 == 0 else { // Base64 must be multiple of 4
            return false
        }
        
        // Check for Base64 character set
        let base64CharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")
        guard string.rangeOfCharacter(from: base64CharacterSet.inverted) == nil else {
            return false
        }
        
        // Verify it's actually valid Base64 by trying to decode it
        guard let data = Data(base64Encoded: string),
              let decodedString = String(data: data, encoding: .utf8),
              !decodedString.isEmpty else {
            return false
        }
        
        // Additional check: the decoded string should look like a quote (reasonable length and characters)
        return decodedString.count > 3 && decodedString.count < 10000
    }
    
    // MARK: - Testing Support
    func clearLovedQuotes() {
        // Clear in-memory data
        if Thread.isMainThread {
            lovedQuotes = Set<String>()
        } else {
            DispatchQueue.main.sync {
                self.lovedQuotes = Set<String>()
            }
        }
        
        // Completely clear UserDefaults data
        userDefaults.removeObject(forKey: "lovedQuotes")
        userDefaults.synchronize()
        
        // Double-check that the data is really gone
        if userDefaults.array(forKey: "lovedQuotes") != nil {
            print("Warning: UserDefaults still contains loved quotes data after clearing")
        }
        
        print("Debug: Cleared all loved quotes from memory and UserDefaults")
    }
    
    // Check if we're running in a test environment
    private var isRunningTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
               NSClassFromString("XCTestCase") != nil
    }
    
    // MARK: - Test Support
    private static var currentTestUserDefaults: UserDefaults?
    private static var currentTestIdentifier: String?
    
    private static func getTestUserDefaults() -> UserDefaults {
        // Use call stack to identify the current test method
        let stackTrace = Thread.callStackSymbols
        var testMethodName = "unknown"
        
        // Look for test method in call stack
        for frame in stackTrace {
            if frame.contains("test") && frame.contains("[") && frame.contains("]") {
                // Extract test method name from stack frame
                if let range = frame.range(of: "test"),
                   let endRange = frame.range(of: "]", range: range.upperBound..<frame.endIndex) {
                    testMethodName = String(frame[range.lowerBound..<endRange.lowerBound])
                    break
                }
            }
        }
        
        // Always create fresh UserDefaults for each test method
        if currentTestIdentifier != testMethodName {
            currentTestIdentifier = testMethodName
            // Add timestamp to ensure unique storage even if test methods have same name
            let testSuiteName = "QuoteManagerTest_\(testMethodName)_\(Date().timeIntervalSince1970)"
            currentTestUserDefaults = UserDefaults(suiteName: testSuiteName)
            
            // Clear any existing data to ensure clean slate
            currentTestUserDefaults?.removePersistentDomain(forName: testSuiteName)
            currentTestUserDefaults = UserDefaults(suiteName: testSuiteName)
        }
        
        return currentTestUserDefaults!
    }
    
    static func createTestInstance() -> QuoteManager {
        // Create a unique UserDefaults suite for this test instance
        let testSuiteName = "QuoteManagerTest_\(UUID().uuidString)"
        let testUserDefaults = UserDefaults(suiteName: testSuiteName)!
        return QuoteManager(loadFromDefaults: false, userDefaults: testUserDefaults)
    }
    
    // MARK: - Localization
    func localizedString(_ key: String) -> String {
        // Return direct English strings based on key
        switch key {
        case "settings": return "Settings"
        case "dark_mode": return "Dark Mode"
        case "daily_notifications": return "Daily Notifications"
        case "notification_time": return "Notification Time"
        case "notification_mode": return "Notification Mode"
        case "single_daily": return "Single Daily"
        case "time_range": return "Time Range"
        case "start_time": return "Start Time"
        case "end_time": return "End Time"
        case "notification_count": return "Notification Count"
        case "font_size": return "Font Size"
        case "language": return "Language"
        case "loved_quotes": return "Loved Quotes"
        case "privacy_policy": return "Privacy Policy"
        case "font_small": return "Small"
        case "font_medium": return "Medium"
        case "font_large": return "Large"
        case "english": return "English"
        case "hebrew": return "Hebrew"
        case "arabic": return "Arabic"
        case "prev": return "PREV"
        case "next": return "NEXT"
        case "share": return "SHARE"
        case "done": return "Done"
        case "swipe_up_next": return "Swipe up for next"
        case "daily_inspiration": return "ThinkUp"
        case "share_suffix": return "- Daily Inspiration"
        case "loading": return "Loading..."
        case "stay_inspired": return "Stay inspired!"
        case "enable_notifications_title": return "Stay Inspired Daily"
        case "enable_notifications_description": return "Get daily motivational quotes delivered to your device. You can customize the timing in settings."
        case "allow_notifications": return "Allow Notifications"
        case "not_now": return "Not Now"
        default: return key
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let notificationPermissionDenied = Notification.Name("notificationPermissionDenied")
}
