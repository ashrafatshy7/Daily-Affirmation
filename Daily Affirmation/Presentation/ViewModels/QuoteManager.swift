import Foundation
import UserNotifications
import SwiftUI
import Combine

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
    
    
    @Published var notificationMode: NotificationMode = .single {
        didSet {
            if !isInitializing {
                // Check if user has access to time range mode
                if notificationMode == .range && !hasTimeRangeAccess {
                    // Revert to single mode if no access
                    notificationMode = .single
                    return
                }
                saveSettings()
                if dailyNotifications {
                    scheduleNotification()
                }
            }
        }
    }
    
    // MARK: - Subscription Access
    var hasTimeRangeAccess: Bool {
        // Use UserDefaults for immediate access to avoid actor issues
        return UserDefaults.standard.bool(forKey: "hasTimeRangeAccess")
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
    
    @Published var personalQuotes: [PersonalQuote] = [] {
        didSet {
            if !isInitializing {
                savePersonalQuotes()
                rebuildQuoteBag()
            }
        }
    }
    
    @Published var includePersonalQuotes: Bool = true {
        didSet {
            if !isInitializing {
                saveSettings()
                rebuildQuoteBag()
            }
        }
    }
    
    @Published var personalQuoteFrequencyMultiplier: Double = 2.0 {
        didSet {
            if !isInitializing {
                saveSettings()
                quoteBag.updatePersonalQuoteFrequency(multiplier: personalQuoteFrequencyMultiplier)
            }
        }
    }
    
    internal var quoteBag = QuoteBag()
    
    
    
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
        notificationMode = .single
        
        setupNotificationCategories()
        
        if loadFromDefaults {
            loadSettings()
            loadLovedQuotes()
            loadPersonalQuotes()
        } else {
            // For tests: start with clean state
            lovedQuotes = Set<String>()
            personalQuotes = []
        }
        
        loadQuotes()
        setDailyQuote()
        
        // Load offline subscription status immediately - this will be handled by SubscriptionManager on app launch
        
        isInitializing = false
        
        // Build initial quote bag after everything is loaded
        rebuildQuoteBag()
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
            quoteHistory = QuoteHistory(initialQuote: dailyQuote, availableQuotes: quotes, quoteManager: self)
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
        userDefaults.set(includePersonalQuotes, forKey: "includePersonalQuotes")
        userDefaults.set(personalQuoteFrequencyMultiplier, forKey: "personalQuoteFrequencyMultiplier")
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
        
        // Load include personal quotes setting (defaults to true if not set)
        if userDefaults.object(forKey: "includePersonalQuotes") != nil {
            includePersonalQuotes = userDefaults.bool(forKey: "includePersonalQuotes")
        } else {
            includePersonalQuotes = true
        }
        
        // Load personal quote frequency multiplier (defaults to 2.0 if not set)
        if userDefaults.object(forKey: "personalQuoteFrequencyMultiplier") != nil {
            personalQuoteFrequencyMultiplier = userDefaults.double(forKey: "personalQuoteFrequencyMultiplier")
            // Ensure the value is within valid range (1.0 - 5.0)
            personalQuoteFrequencyMultiplier = max(1.0, min(5.0, personalQuoteFrequencyMultiplier))
        } else {
            personalQuoteFrequencyMultiplier = 2.0
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
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                if granted {
                    self?.scheduleNotification()
                } else {
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
        
        // Check if user has access to time range mode
        if notificationMode == .range && !hasTimeRangeAccess {
            print("Time range mode requires subscription, switching to single mode")
            notificationMode = .single
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
        ensureQuoteBagInitialized()
        
        if let selectedQuote = quoteBag.selectRandomQuote() {
            return selectedQuote.text
        }
        
        // Fallback to old method if quote bag fails
        var allAvailableQuotes: [String] = []
        
        // Add regular quotes
        if !quotes.isEmpty {
            allAvailableQuotes.append(contentsOf: quotes)
        }
        
        // Add personal quotes if enabled and available
        if includePersonalQuotes {
            let activePersonal = activePersonalQuotes.map { $0.displayText }
            allAvailableQuotes.append(contentsOf: activePersonal)
        }
        
        guard !allAvailableQuotes.isEmpty else { return "Stay inspired!" }
        return allAvailableQuotes.randomElement() ?? "Stay inspired!"
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
        
        // Apply hard cap of 10 notifications maximum regardless of time range
        return min(timeBasedMax, 10)
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
        
        // Set the loaded quotes
        let wasInitializing = isInitializing
        isInitializing = true
        lovedQuotes = Set(decodedQuotes)
        isInitializing = wasInitializing
        
        // If we found old format data, migrate it to new format
        if needsMigration {
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
    
    // MARK: - Quote Bag Management
    private func rebuildQuoteBag() {
        quoteBag = QuoteBag()
        
        // Add built-in quotes
        for quote in quotes {
            let weightedQuote = WeightedQuote(text: quote, type: .builtin)
            quoteBag.addQuote(weightedQuote)
        }
        
        // Add personal quotes if enabled
        if includePersonalQuotes {
            for personalQuote in activePersonalQuotes {
                let weightedQuote = WeightedQuote(
                    text: personalQuote.displayText,
                    type: .personal,
                    baseWeight: 1.0,
                    personalQuoteId: personalQuote.id
                )
                quoteBag.addQuote(weightedQuote)
            }
        }
        
        // Apply frequency multiplier to personal quotes
        quoteBag.updatePersonalQuoteFrequency(multiplier: personalQuoteFrequencyMultiplier)
    }
    
    internal func ensureQuoteBagInitialized() {
        if quoteBag.isEmpty && (!quotes.isEmpty || !personalQuotes.isEmpty) {
            rebuildQuoteBag()
        }
    }
    
    func getQuoteBagStatistics() -> (total: Int, used: Int, personal: Int, builtin: Int) {
        return quoteBag.getQuoteStatistics()
    }
    
    // MARK: - Personal Quotes Management
    func addPersonalQuote(_ text: String) -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty && trimmedText.count >= 4 && trimmedText.count <= 50 else {
            return false
        }
        
        let newQuote = PersonalQuote(text: trimmedText)
        
        if Thread.isMainThread {
            personalQuotes.append(newQuote)
        } else {
            DispatchQueue.main.sync {
                self.personalQuotes.append(newQuote)
            }
        }
        return true
    }
    
    func deletePersonalQuote(withId id: UUID) {
        if Thread.isMainThread {
            personalQuotes.removeAll { $0.id == id }
        } else {
            DispatchQueue.main.sync {
                self.personalQuotes.removeAll { $0.id == id }
            }
        }
    }
    
    func updatePersonalQuote(withId id: UUID, newText: String) -> Bool {
        let trimmedText = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty && trimmedText.count >= 4 && trimmedText.count <= 50 else {
            return false
        }
        
        if Thread.isMainThread {
            if let index = personalQuotes.firstIndex(where: { $0.id == id }) {
                personalQuotes[index].text = trimmedText
                // Update quote bag directly for immediate consistency
                quoteBag.updateQuote(withId: id, newText: trimmedText)
                return true
            }
        } else {
            return DispatchQueue.main.sync {
                if let index = self.personalQuotes.firstIndex(where: { $0.id == id }) {
                    self.personalQuotes[index].text = trimmedText
                    // Update quote bag directly for immediate consistency
                    self.quoteBag.updateQuote(withId: id, newText: trimmedText)
                    return true
                }
                return false
            }
        }
        return false
    }
    
    func togglePersonalQuoteActive(withId id: UUID) {
        if Thread.isMainThread {
            if let index = personalQuotes.firstIndex(where: { $0.id == id }) {
                personalQuotes[index].isActive.toggle()
            }
        } else {
            DispatchQueue.main.sync {
                if let index = self.personalQuotes.firstIndex(where: { $0.id == id }) {
                    self.personalQuotes[index].isActive.toggle()
                }
            }
        }
    }
    
    var activePersonalQuotes: [PersonalQuote] {
        return personalQuotes.filter { $0.isActive }
    }
    
    var sortedPersonalQuotes: [PersonalQuote] {
        return personalQuotes.sorted { $0.createdDate > $1.createdDate }
    }
    
    private func savePersonalQuotes() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(personalQuotes)
            
            // Encode the data using Base64 to preserve special characters
            let encodedData = data.base64EncodedString()
            
            userDefaults.set(encodedData, forKey: "personalQuotes")
            userDefaults.synchronize()
        } catch {
            print("Failed to save personal quotes: \(error)")
        }
    }
    
    private func loadPersonalQuotes() {
        guard let encodedData = userDefaults.string(forKey: "personalQuotes") else {
            // No saved data, start with empty array
            let wasInitializing = isInitializing
            isInitializing = true
            personalQuotes = []
            isInitializing = wasInitializing
            return
        }
        
        do {
            // Decode the Base64 data
            guard let data = Data(base64Encoded: encodedData) else {
                print("Failed to decode personal quotes data")
                personalQuotes = []
                return
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let loadedQuotes = try decoder.decode([PersonalQuote].self, from: data)
            
            let wasInitializing = isInitializing
            isInitializing = true
            personalQuotes = loadedQuotes
            isInitializing = wasInitializing
        } catch {
            print("Failed to load personal quotes: \(error)")
            // If loading fails, start with empty array
            let wasInitializing = isInitializing
            isInitializing = true
            personalQuotes = []
            isInitializing = wasInitializing
        }
    }
    
    func clearPersonalQuotes() {
        if Thread.isMainThread {
            personalQuotes = []
        } else {
            DispatchQueue.main.sync {
                self.personalQuotes = []
            }
        }
        
        userDefaults.removeObject(forKey: "personalQuotes")
        userDefaults.synchronize()
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
            // Data persists, which could be expected in some testing scenarios
        }
        
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
    static let resetOnboarding = Notification.Name("resetOnboarding")
}
