//Daily Affirmation
import Foundation
import WidgetKit

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
    
    private var sharedUserDefaults: UserDefaults? {
        print("🔧 App SharedQuoteManager: Attempting to create UserDefaults with App Group: \(appGroupIdentifier)")
        let defaults = UserDefaults(suiteName: appGroupIdentifier)
        if defaults == nil {
            print("⚠️ App SharedQuoteManager: Failed to create UserDefaults with App Group: \(appGroupIdentifier)")
            print("⚠️ App SharedQuoteManager: Falling back to standard UserDefaults")
            let fallbackDefaults = UserDefaults.standard
            print("🔧 App SharedQuoteManager: Fallback UserDefaults created successfully")
            return fallbackDefaults
        } else {
            print("✅ App SharedQuoteManager: Successfully created UserDefaults with App Group")
            return defaults
        }
    }
    
    private init() {}
    
    // MARK: - Quote Loading
    private func loadQuotes() -> [String] {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return defaultQuotes
        }
        
        // Try to decode categorized structure first
        if let categorizedQuotes = try? JSONDecoder().decode(QuoteCategories.self, from: data) {
            return categorizedQuotes.categories["General"] ?? defaultQuotes
        } else if let quotesArray = try? JSONDecoder().decode([String].self, from: data) {
            return quotesArray
        }
        
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
        return sharedUserDefaults?.string(forKey: currentQuoteKey)
    }
    
    // MARK: - Widget Entry Creation
    func getCurrentEntry() -> SharedAffirmationEntry {
        print("📱 App SharedQuoteManager: Getting current entry...")
        
        let currentQuote: String
        let appCurrentQuote = getCurrentQuoteFromApp()
        
        print("📱 App SharedQuoteManager: appCurrentQuote: '\(appCurrentQuote ?? "nil")'")
        
        // Use main app's current quote if available, otherwise fall back to daily quote
        if let appCurrentQuote = appCurrentQuote, !appCurrentQuote.isEmpty {
            currentQuote = appCurrentQuote
            print("📱 App SharedQuoteManager: Using app current quote: '\(currentQuote)'")
        } else {
            currentQuote = getDailyQuote()
            print("📱 App SharedQuoteManager: Using daily quote: '\(currentQuote)'")
        }
        
        return SharedAffirmationEntry(
            quote: currentQuote,
            date: Date(),
            backgroundImage: "background"
        )
    }
}

