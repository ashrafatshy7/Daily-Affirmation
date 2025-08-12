//Daily Affirmation Widgets
import Foundation
import WidgetKit
import UIKit

// MARK: - Shared Data Models
struct SharedAffirmationEntry {
    let quote: String
    let date: Date
    let backgroundImage: String
}

// MARK: - Shared Quote Manager
class SharedQuoteManager {
    static let shared = SharedQuoteManager()
    
    // App Groups identifier for shared data
    private let appGroupIdentifier = "group.com.ashrafatshy.Daily-Affirmation"
    private let currentQuoteKey = "currentQuote"
    private let currentBackgroundKey = "currentBackground"
    
    private var sharedUserDefaults: UserDefaults? {
        print("🔧 Widget SharedQuoteManager: Attempting to create UserDefaults with App Group: \(appGroupIdentifier)")
        print("🔧 Widget SharedQuoteManager: Device: \(UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone")")
        
        let defaults = UserDefaults(suiteName: appGroupIdentifier)
        if defaults == nil {
            print("⚠️ Widget SharedQuoteManager: Failed to create UserDefaults with App Group: \(appGroupIdentifier)")
            print("⚠️ Widget SharedQuoteManager: This is expected if App Groups are not configured")
            print("⚠️ Widget SharedQuoteManager: Falling back to standard UserDefaults")
            let fallbackDefaults = UserDefaults.standard
            print("🔧 Widget SharedQuoteManager: Fallback UserDefaults created successfully")
            
            // Test if we can access standard UserDefaults
            let testKey = "widget_test_key"
            fallbackDefaults.set("test_value", forKey: testKey)
            let testValue = fallbackDefaults.string(forKey: testKey)
            print("🔧 Widget SharedQuoteManager: Standard UserDefaults test - set/get: \(testValue == "test_value" ? "SUCCESS" : "FAILED")")
            fallbackDefaults.removeObject(forKey: testKey)
            
            return fallbackDefaults
        } else {
            print("✅ Widget SharedQuoteManager: Successfully created UserDefaults with App Group")
            
            // Test if we can access App Group UserDefaults
            let testKey = "widget_appgroup_test_key"
            defaults?.set("test_value", forKey: testKey)
            let testValue = defaults?.string(forKey: testKey)
            print("🔧 Widget SharedQuoteManager: App Group UserDefaults test - set/get: \(testValue == "test_value" ? "SUCCESS" : "FAILED")")
            defaults?.removeObject(forKey: testKey)
            
            return defaults
        }
    }
    
    private init() {}
    
    // MARK: - Quote Loading
    private func loadQuotes() -> [String] {
        print("🔶 Widget SharedQuoteManager: Loading quotes...")
        
        // Try to load from main app bundle first, then fall back to widget bundle
        var url: URL?
        
        // Get main app bundle identifier
        let mainAppBundleId = "com.ashrafatshy.Daily-Affirmation"
        print("🔶 Widget SharedQuoteManager: Trying main app bundle: \(mainAppBundleId)")
        if let mainAppBundle = Bundle(identifier: mainAppBundleId) {
            url = mainAppBundle.url(forResource: "quotes", withExtension: "json")
            print("🔶 Widget SharedQuoteManager: Main app bundle URL: \(url?.absoluteString ?? "nil")")
        }
        
        // Fallback to widget bundle if main app bundle not found
        if url == nil {
            print("🔶 Widget SharedQuoteManager: Fallback to widget bundle")
            url = Bundle.main.url(forResource: "quotes", withExtension: "json")
            print("🔶 Widget SharedQuoteManager: Widget bundle URL: \(url?.absoluteString ?? "nil")")
        }
        
        guard let quotesUrl = url,
              let data = try? Data(contentsOf: quotesUrl) else {
            print("🔶 Widget SharedQuoteManager: Failed to load quotes, using defaults")
            return defaultQuotes
        }
        
        print("🔶 Widget SharedQuoteManager: Successfully loaded quotes data (\(data.count) bytes)")
        
        // Try to decode categorized structure first
        if let categorizedQuotes = try? JSONDecoder().decode(QuoteCategories.self, from: data) {
            let generalQuotes = categorizedQuotes.categories["General"] ?? defaultQuotes
            print("🔶 Widget SharedQuoteManager: Loaded \(generalQuotes.count) categorized quotes")
            return generalQuotes
        } else if let quotesArray = try? JSONDecoder().decode([String].self, from: data) {
            print("🔶 Widget SharedQuoteManager: Loaded \(quotesArray.count) array quotes")
            return quotesArray
        }
        
        print("🔶 Widget SharedQuoteManager: Failed to decode quotes, using defaults")
        return defaultQuotes
    }
    
    private var defaultQuotes: [String] {
        return [
            "I honor my intrinsic worth",
            "I deserve respect and kindness",
            "I value my opinions and feelings",
            "I acknowledge my strengths",
            "I accept my value beyond achievements",
            "I am worthy of good things",
            "I embrace my inherent dignity",
            "I trust my value is constant",
            "I respect myself wholeheartedly",
            "I treat myself with honor"
        ]
    }
    
    // MARK: - Daily Quote Logic
    func getDailyQuote() -> String {
        let quotes = loadQuotes()
        guard !quotes.isEmpty else { return "Stay inspired!" }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        
        let dailyIndex = (dayOfYear - 1) % quotes.count
        return quotes[dailyIndex]
    }
    
    
    // MARK: - Current Quote Synchronization
    func setCurrentQuote(_ quote: String) {
        sharedUserDefaults?.set(quote, forKey: currentQuoteKey)
        sharedUserDefaults?.synchronize()
    }
    
    func getCurrentQuoteFromApp() -> String? {
        let quote = sharedUserDefaults?.string(forKey: currentQuoteKey)
        print("🔶 Widget SharedQuoteManager: getCurrentQuoteFromApp() -> '\(quote ?? "nil")'")
        return quote
    }
    
    // MARK: - Background Image Synchronization
    func setCurrentBackground(_ backgroundImage: String) {
        print("🔶 Widget SharedQuoteManager: Setting current background: '\(backgroundImage)'")
        sharedUserDefaults?.set(backgroundImage, forKey: currentBackgroundKey)
        sharedUserDefaults?.synchronize()
    }
    
    func getCurrentBackgroundFromApp() -> String? {
        let background = sharedUserDefaults?.string(forKey: currentBackgroundKey)
        print("🔶 Widget SharedQuoteManager: getCurrentBackgroundFromApp() -> '\(background ?? "nil")'")
        return background
    }
    
    
    // MARK: - Widget Entry Creation
    func getCurrentEntry() -> SharedAffirmationEntry {
        print("🔶 Widget SharedQuoteManager: Getting current entry...")
        print("🔶 Widget SharedQuoteManager: Timestamp: \(Date())")
        print("🔶 Widget SharedQuoteManager: Device: \(UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone")")
        print("🔶 Widget SharedQuoteManager: Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        
        let currentQuote: String
        let appCurrentQuote = getCurrentQuoteFromApp()
        
        print("🔶 Widget SharedQuoteManager: appCurrentQuote: '\(appCurrentQuote ?? "nil")'")
        
        // Cold start detection - check if app has been opened
        let hasAppBeenOpened = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        print("🔶 Widget SharedQuoteManager: hasAppBeenOpened: \(hasAppBeenOpened)")
        
        // Use main app's current quote if available and app has been opened
        if let appCurrentQuote = appCurrentQuote, !appCurrentQuote.isEmpty, hasAppBeenOpened {
            currentQuote = appCurrentQuote
            print("🔶 Widget SharedQuoteManager: Using app current quote: '\(currentQuote)'")
        } else {
            // Fallback to daily quote with cold start message
            let dailyQuote = getDailyQuote()
            if hasAppBeenOpened {
                currentQuote = dailyQuote
                print("🔶 Widget SharedQuoteManager: Using daily quote: '\(currentQuote)'")
            } else {
                currentQuote = dailyQuote.isEmpty ? "Welcome! Open the app to start your daily inspiration journey ✨" : dailyQuote
                print("🔶 Widget SharedQuoteManager: Using cold start quote: '\(currentQuote)'")
            }
        }
        
        // Get current background from shared storage, fallback to "background"
        let currentBackground = getCurrentBackgroundFromApp() ?? "background"
        print("🔶 Widget SharedQuoteManager: Using background: '\(currentBackground)'")
        
        let entry = SharedAffirmationEntry(
            quote: currentQuote,
            date: Date(),
            backgroundImage: currentBackground
        )
        
        print("🔶 Widget SharedQuoteManager: FINAL ENTRY - quote: '\(entry.quote)', background: '\(entry.backgroundImage)'")
        return entry
    }
}

// MARK: - Supporting Models
private struct QuoteCategories: Codable {
    let categories: [String: [String]]
    let defaultCategory: String
    
    enum CodingKeys: String, CodingKey {
        case categories
        case defaultCategory = "default_category"
    }
}
