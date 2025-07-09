import Foundation
import UserNotifications
import SwiftUI

class QuoteManager: ObservableObject {
    @Published var quotes: [String] = []
    @Published var currentIndex: Int = 0
    @Published var isDarkMode: Bool = false {
        willSet {
            objectWillChange.send()
        }
    }
    @Published var dailyNotifications: Bool = false {
        didSet {
            saveSettings()
            if dailyNotifications {
                requestNotificationPermission()
            } else {
                cancelNotifications()
            }
        }
    }
    @Published var notificationTime: Date = QuoteManager.loadSavedNotificationTime() {
        didSet {
            saveSettings()
            if dailyNotifications {
                scheduleNotification()
            }
        }
    }
    @Published var fontSize: FontSize = .medium
    @Published var selectedLanguage: AppLanguage = .english {
        didSet {
            if selectedLanguage != oldValue {
                loadQuotes()
                setDailyQuote()
                saveSettings()
                if dailyNotifications {
                    scheduleNotification()
                }
            }
        }
    }
    
    enum AppLanguage: String, CaseIterable {
        case english = "en"
        case hebrew = "he"
        case arabic = "ar"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .hebrew: return "עברית"
            case .arabic: return "العربية"
            }
        }
        
        var isRTL: Bool {
            return self == .hebrew || self == .arabic
        }
        
        var quotesFileName: String {
            switch self {
            case .english: return "quotes"
            case .hebrew: return "quotes_he"
            case .arabic: return "quotes_ar"
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
    
    // MARK: - Static Helper Methods
    private static func loadSavedNotificationTime() -> Date {
        if let savedTime = UserDefaults.standard.object(forKey: "notificationTime") as? Date {
            return savedTime
        } else {
            // Default to 9:00 AM if no saved time exists
            return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        }
    }
    
    init() {
        loadQuotes()
        setDailyQuote()
        loadSettings()
    }
    
    private func loadQuotes() {
        guard let url = Bundle.main.url(forResource: selectedLanguage.quotesFileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let quotesArray = try? JSONDecoder().decode([String].self, from: data) else {
            print("Failed to load quotes for language: \(selectedLanguage.rawValue)")
            return
        }
        
        self.quotes = quotesArray
    }
    
    private func setDailyQuote() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        
        if !quotes.isEmpty {
            currentIndex = (dayOfYear - 1) % quotes.count
        }
    }
    
    func nextQuote() {
        if !quotes.isEmpty {
            currentIndex = (currentIndex + 1) % quotes.count
        }
    }
    
    func previousQuote() {
        if !quotes.isEmpty {
            currentIndex = currentIndex > 0 ? currentIndex - 1 : quotes.count - 1
        }
    }
    
    var currentQuote: String {
        guard !quotes.isEmpty else { return NSLocalizedString("loading", comment: "") }
        return quotes[currentIndex]
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
    
    // MARK: - Settings Persistence
    private func saveSettings() {
        UserDefaults.standard.set(dailyNotifications, forKey: "dailyNotifications")
        UserDefaults.standard.set(notificationTime, forKey: "notificationTime")
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        UserDefaults.standard.set(fontSize.rawValue, forKey: "fontSize")
        UserDefaults.standard.set(selectedLanguage.rawValue, forKey: "selectedLanguage")
    }
    
    private func loadSettings() {
        dailyNotifications = UserDefaults.standard.bool(forKey: "dailyNotifications")
        isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        
        if let savedFontSize = FontSize(rawValue: UserDefaults.standard.string(forKey: "fontSize") ?? "") {
            fontSize = savedFontSize
        }
        
        if let savedLanguage = AppLanguage(rawValue: UserDefaults.standard.string(forKey: "selectedLanguage") ?? "") {
            selectedLanguage = savedLanguage
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
        
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("daily_inspiration", comment: "")
        content.body = getDailyQuote()
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: "dailyInspiration", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled successfully for \(components.hour ?? 0):\(components.minute ?? 0)")
            }
        }
    }
    
    private func cancelNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyInspiration"])
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
        return formatter.string(from: notificationTime)
    }
    
    // MARK: - Custom Localization
    func localizedString(_ key: String) -> String {
        guard let bundle = Bundle.main.path(forResource: selectedLanguage.rawValue, ofType: "lproj"),
              let localizationBundle = Bundle(path: bundle) else {
            return NSLocalizedString(key, comment: "")
        }
        return NSLocalizedString(key, bundle: localizationBundle, comment: "")
    }
}
