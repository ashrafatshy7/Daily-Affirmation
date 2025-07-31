//Daily Affirmation Widgets
import Foundation
import WidgetKit

// MARK: - Shared Data Models
struct SharedAffirmationEntry {
    let quote: String
    let isPinned: Bool
    let date: Date
    let backgroundImage: String
}

// MARK: - Shared Quote Manager
class SharedQuoteManager {
    static let shared = SharedQuoteManager()
    
    // App Groups identifier for shared data
    private let appGroupIdentifier = "group.com.ashrafatshy.Daily-Affirmation"
    private let pinnedQuoteKey = "pinnedQuote"
    private let isPinnedKey = "isPinned"
    private let pinnedDateKey = "pinnedDate"
    private let currentQuoteKey = "currentQuote"
    
    private var sharedUserDefaults: UserDefaults? {
        let defaults = UserDefaults(suiteName: appGroupIdentifier)
        if defaults == nil {
            print("⚠️ Widget SharedQuoteManager: Failed to create UserDefaults with App Group: \(appGroupIdentifier)")
            print("⚠️ Widget SharedQuoteManager: Falling back to standard UserDefaults")
            return UserDefaults.standard
        }
        return defaults
    }
    
    private init() {}
    
    // MARK: - Quote Loading
    private func loadQuotes() -> [String] {
        // Try to load from main app bundle first, then fall back to widget bundle
        var url: URL?
        
        // Get main app bundle identifier
        let mainAppBundleId = "com.ashrafatshy.Daily-Affirmation"
        if let mainAppBundle = Bundle(identifier: mainAppBundleId) {
            url = mainAppBundle.url(forResource: "quotes", withExtension: "json")
        }
        
        // Fallback to widget bundle if main app bundle not found
        if url == nil {
            url = Bundle.main.url(forResource: "quotes", withExtension: "json")
        }
        
        guard let quotesUrl = url,
              let data = try? Data(contentsOf: quotesUrl) else {
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
    
    // MARK: - Pin/Unpin Functionality
    func getPinnedQuote() -> String? {
        return sharedUserDefaults?.string(forKey: pinnedQuoteKey)
    }
    
    func isPinned() -> Bool {
        return sharedUserDefaults?.bool(forKey: isPinnedKey) ?? false
    }
    
    func pinQuote(_ quote: String) {
        // Always clear any existing pin first to enforce single pin behavior
        if isPinned() {
            sharedUserDefaults?.removeObject(forKey: pinnedQuoteKey)
            sharedUserDefaults?.set(false, forKey: isPinnedKey)
            sharedUserDefaults?.removeObject(forKey: pinnedDateKey)
        }
        
        // Set the new pin
        sharedUserDefaults?.set(quote, forKey: pinnedQuoteKey)
        sharedUserDefaults?.set(true, forKey: isPinnedKey)
        sharedUserDefaults?.set(Date(), forKey: pinnedDateKey)
        
        // Force synchronization to ensure data is written immediately
        sharedUserDefaults?.synchronize()
        
        // Reload widgets when pin state changes with delay to ensure data is written
        #if canImport(WidgetKit)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        #endif
    }
    
    func unpinQuote() {
        sharedUserDefaults?.removeObject(forKey: pinnedQuoteKey)
        sharedUserDefaults?.set(false, forKey: isPinnedKey)
        sharedUserDefaults?.removeObject(forKey: pinnedDateKey)
        
        // Force synchronization to ensure data is written immediately
        sharedUserDefaults?.synchronize()
        
        // Reload widgets when pin state changes with delay to ensure data is written
        #if canImport(WidgetKit)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        #endif
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
        print("🔶 Widget SharedQuoteManager: Getting current entry...")
        
        let currentQuote: String
        let pinned = isPinned()
        let pinnedQuote = getPinnedQuote()
        let appCurrentQuote = getCurrentQuoteFromApp()
        
        print("🔶 Widget SharedQuoteManager: isPinned: \(pinned), pinnedQuote: '\(pinnedQuote ?? "nil")', appCurrentQuote: '\(appCurrentQuote ?? "nil")'")
        
        if pinned, let pinnedQuote = pinnedQuote {
            currentQuote = pinnedQuote
            print("🔶 Widget SharedQuoteManager: Using pinned quote: '\(currentQuote)'")
        } else {
            // Use main app's current quote if available, otherwise fall back to daily quote
            if let appCurrentQuote = appCurrentQuote, !appCurrentQuote.isEmpty {
                currentQuote = appCurrentQuote
                print("🔶 Widget SharedQuoteManager: Using app current quote: '\(currentQuote)'")
            } else {
                currentQuote = getDailyQuote()
                print("🔶 Widget SharedQuoteManager: Using daily quote: '\(currentQuote)'")
            }
        }
        
        return SharedAffirmationEntry(
            quote: currentQuote,
            isPinned: pinned,
            date: Date(),
            backgroundImage: "background"
        )
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
