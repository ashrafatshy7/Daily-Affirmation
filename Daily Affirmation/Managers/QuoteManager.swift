import Foundation
import UserNotifications
import SwiftUI
import Combine
import WidgetKit

class QuoteManager: ObservableObject {
    @Published var quotes: [String] = []
    @Published var currentIndex: Int = 0
    @Published private var currentQuoteText: String = ""
    internal var isInitializing = true
    private var quoteHistory: QuoteHistory?
    
    // Category support
    private var quoteCategories: QuoteCategories?
    @Published var selectedCategory: QuoteCategory = .general {
        didSet {
            if !isInitializing {
                updateQuotesForSelectedCategory()
                saveSettings()
            }
        }
    }
    @Published var availableCategories: [QuoteCategory] = QuoteCategory.allCases
    
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
    
    @Published var textColor: TextColor = .white {
        didSet {
            if !isInitializing {
                saveSettings()
            }
        }
    }
    
    @Published var selectedBackgroundImage: String = "background" {
        didSet {
            if !isInitializing {
                // Auto-set text color based on background default
                textColor = getDefaultTextColor(for: selectedBackgroundImage)
                saveSettings()
                // Sync background to SharedQuoteManager for widgets
                SharedQuoteManager.shared.setCurrentBackground(selectedBackgroundImage)
                WidgetCenter.shared.reloadTimelines(ofKind: "Daily_Affirmation_Widgets")
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
    
    // MARK: - User Behavior Tracking & Personalization
    @Published var userType: UserType = .new
    @Published var totalAppOpens: Int = 0
    @Published var consecutiveDays: Int = 0
    @Published var lastOpenDate: Date = Date()
    @Published var totalQuotesViewed: Int = 0
    @Published var totalLovesGiven: Int = 0
    @Published var hasCompletedOnboarding: Bool = false
    
    enum UserType: String, CaseIterable {
        case new = "new"           // 0-3 days, < 10 quotes viewed
        case returning = "returning" // 4-29 days, or 10-100 quotes viewed
        case superUser = "superUser" // 30+ days, or 100+ quotes viewed, or 10+ loves
        
        var personalizedGreeting: String {
            switch self {
            case .new:
                return "Welcome! Let's find your daily inspiration ✨"
            case .returning:
                return "Welcome back! Here's today's inspiration 🌟"
            case .superUser:
                return "Your daily dose of motivation is ready 🚀"
            }
        }
        
        var shouldShowSwipeIndicator: Bool {
            return self == .new
        }
        
        var shouldShowAdvancedFeatures: Bool {
            return self == .superUser
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
    
    enum TextColor: String, CaseIterable {
        case white = "white"
        case black = "black"
        
        func displayName(using quoteManager: QuoteManager) -> String {
            switch self {
            case .white: return "White Text"
            case .black: return "Black Text"
            }
        }
    }
    
    // MARK: - Background to Text Color Mapping
    private static let backgroundTextColorMap: [String: TextColor] = [
        "background": .white,
        "background1": .white,
        "background2": .black,
        "background3": .white,
        "background4": .black,
        "background5": .white,
        "background6": .white,
        "background7": .white,
        "background8": .white,
        "background9": .white,
        "background10": .white,
        "background11": .white,
        "background12": .white,
        "background13": .white,
        "background14": .white,
        "background15": .white,
        "background16": .white,
        "background17": .white,
        "background18": .white,
        "background19": .white,
        "background20": .white,
        "background21": .white,
        "background22": .white,
        "background23": .white,
        "background24": .black,
        "background25": .white,
        "background26": .white
    ]
    
    func getDefaultTextColor(for backgroundName: String) -> TextColor {
        return Self.backgroundTextColorMap[backgroundName] ?? .white
    }
    
    // MARK: - Helper Methods
    
    private func safeCurrentIndex() -> Int {
        guard !quotes.isEmpty else { return 0 }
        return max(0, min(currentIndex, quotes.count - 1))
    }
    
    // MARK: - Static Helper Methods
    
    internal var userDefaults: UserDefaults
    private let ratingManager = AppStoreRatingManager.shared
    
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
        
        isInitializing = false
        
        // Build initial quote bag after everything is loaded
        rebuildQuoteBag()
        
        // Sync initial background and quote to SharedQuoteManager for widgets
        SharedQuoteManager.shared.setCurrentBackground(selectedBackgroundImage)
        SharedQuoteManager.shared.setCurrentQuote(currentQuoteText)
        
        // Listen for premium settings reset notification
        NotificationCenter.default.addObserver(
            forName: .premiumSettingsReset,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handlePremiumSettingsReset()
        }
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
    
    // MARK: - Premium Settings Reset Handler
    private func handlePremiumSettingsReset() {
        // Reset background to default
        selectedBackgroundImage = "background"
        
        // Reset category to General
        selectedCategory = .general
        
        // Reset personal quotes toggle to off
        includePersonalQuotes = false
        
        // Rebuild quote bag without personal quotes
        rebuildQuoteBag()
        
        // Update the current quote to reflect changes
        setDailyQuote()
    }
    
    // MARK: - Quote Management
    
    private func loadQuotes() {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load quotes file")
            return
        }
        
        // Try to decode new categorized structure first
        if let categorizedQuotes = try? JSONDecoder().decode(QuoteCategories.self, from: data) {
            self.quoteCategories = categorizedQuotes
            
            // Update available categories based on what exists in the file
            let fileCategories = categorizedQuotes.categories.keys.compactMap { QuoteCategory(rawValue: $0) }
            if !fileCategories.isEmpty {
                availableCategories = fileCategories.sorted { $0.rawValue < $1.rawValue }
            }
            
            // Load quotes for the selected category
            updateQuotesForSelectedCategory()
        } else if let quotesArray = try? JSONDecoder().decode([String].self, from: data) {
            // Fallback to old array format
            self.quotes = quotesArray
            print("Loaded quotes using legacy array format")
        } else {
            print("Failed to decode quotes in any format")
            return
        }
    }
    
    private func updateQuotesForSelectedCategory() {
        guard let categories = quoteCategories else {
            return
        }
        
        if let categoryQuotes = categories.categories[selectedCategory.rawValue] {
            self.quotes = categoryQuotes
        } else {
            // Fallback to default category if selected one doesn't exist
            if let defaultQuotes = categories.categories[categories.defaultCategory] {
                self.quotes = defaultQuotes
            } else {
                self.quotes = []
            }
        }
        
        // Reset quote history and rebuild quote bag when category changes
        setDailyQuote()
        rebuildQuoteBag()
        
        // Sync the new current quote after category change
        SharedQuoteManager.shared.setCurrentQuote(currentQuoteText)
        WidgetCenter.shared.reloadTimelines(ofKind: "Daily_Affirmation_Widgets")
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
            
            // Sync initial quote to shared storage
            SharedQuoteManager.shared.setCurrentQuote(dailyQuote)
            
            // Only reload widgets on initial load, not during initialization
            if !isInitializing {
                WidgetCenter.shared.reloadTimelines(ofKind: "Daily_Affirmation_Widgets")
            }
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
            SharedQuoteManager.shared.setCurrentQuote(newQuote)
            trackQuoteViewed()
        } else {
            DispatchQueue.main.sync {
                self.currentQuoteText = newQuote
                SharedQuoteManager.shared.setCurrentQuote(newQuote)
                self.trackQuoteViewed()
            }
        }
    }
    
    func previousQuote() {
        guard let history = quoteHistory else { return }
        if let previousQuote = history.movePrevious() {
            if Thread.isMainThread {
                currentQuoteText = previousQuote
                SharedQuoteManager.shared.setCurrentQuote(previousQuote)
                trackQuoteViewed()
            } else {
                DispatchQueue.main.sync {
                    self.currentQuoteText = previousQuote
                    SharedQuoteManager.shared.setCurrentQuote(previousQuote)
                    self.trackQuoteViewed()
                }
            }
        }
    }
    
    var currentQuote: String {
        return currentQuoteText
    }
    
    // MARK: - Deep Link Support
    func setSpecificQuote(_ quote: String) {
        // First, try to navigate to the quote if it already exists in history
        if let history = quoteHistory, history.navigateToQuote(quote) {
            // Quote found in history, navigation successful
            if Thread.isMainThread {
                currentQuoteText = quote
                SharedQuoteManager.shared.setCurrentQuote(quote)
            } else {
                DispatchQueue.main.sync {
                    self.currentQuoteText = quote
                    SharedQuoteManager.shared.setCurrentQuote(quote)
                }
            }
            return
        }
        
        // Quote not in history yet, proceed with adding it
        // Find the quote in our current quotes array
        if let index = quotes.firstIndex(of: quote) {
            // If found, set the current index to that quote
            currentIndex = index
            if Thread.isMainThread {
                currentQuoteText = quote
                SharedQuoteManager.shared.setCurrentQuote(quote)
            } else {
                DispatchQueue.main.sync {
                    self.currentQuoteText = quote
                    SharedQuoteManager.shared.setCurrentQuote(quote)
                }
            }
            
            // Add to history since it wasn't found there
            quoteHistory?.addQuote(quote)
        } else {
            // If the quote is not in our current quotes array (edge case),
            // still display it and update SharedQuoteManager, and add to history
            if Thread.isMainThread {
                currentQuoteText = quote
                SharedQuoteManager.shared.setCurrentQuote(quote)
            } else {
                DispatchQueue.main.sync {
                    self.currentQuoteText = quote
                    SharedQuoteManager.shared.setCurrentQuote(quote)
                }
            }
            
            // Add the quote to history even if not in main quotes array
            quoteHistory?.addQuote(quote)
        }
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
    
    // MARK: - Localization
    func localizedString(_ key: String) -> String {
        return LocalizationHelper.localizedString(key)
    }
    
    // MARK: - App Store Rating Management
    func checkAndRequestRatingAfterOnboarding() {
        if ratingManager.shouldRequestRatingAfterOnboarding() {
            // Delay rating request slightly to let notification permission dialog show first
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.ratingManager.requestRating()
            }
        }
    }
    
    func checkAndRequestRatingOnAppLaunch() {
        if ratingManager.shouldRequestRatingOnAppLaunch(for: self) {
            // Delay rating request to let app fully load
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.ratingManager.requestRating()
            }
        }
    }
}

// MARK: - Extensions for remaining functionality
extension QuoteManager {
    // This extension will contain the remaining methods - I'll create it in the next step to keep files manageable
}