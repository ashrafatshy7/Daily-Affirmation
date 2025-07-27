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
    
    private var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
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
    
    // MARK: - Pin/Unpin Functionality
    func getPinnedQuote() -> String? {
        return sharedUserDefaults?.string(forKey: pinnedQuoteKey)
    }
    
    func isPinned() -> Bool {
        return sharedUserDefaults?.bool(forKey: isPinnedKey) ?? false
    }
    
    func pinQuote(_ quote: String) {
        sharedUserDefaults?.set(quote, forKey: pinnedQuoteKey)
        sharedUserDefaults?.set(true, forKey: isPinnedKey)
        sharedUserDefaults?.set(Date(), forKey: pinnedDateKey)
        
        // Reload widgets when pin state changes
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "Daily_Affirmation_Widgets")
        #endif
    }
    
    func unpinQuote() {
        sharedUserDefaults?.removeObject(forKey: pinnedQuoteKey)
        sharedUserDefaults?.set(false, forKey: isPinnedKey)
        sharedUserDefaults?.removeObject(forKey: pinnedDateKey)
        
        // Reload widgets when pin state changes
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "Daily_Affirmation_Widgets")
        #endif
    }
    
    // MARK: - Widget Entry Creation
    func getCurrentEntry() -> SharedAffirmationEntry {
        let currentQuote: String
        let pinned = isPinned()
        
        if pinned, let pinnedQuote = getPinnedQuote() {
            currentQuote = pinnedQuote
        } else {
            currentQuote = getDailyQuote()
        }
        
        return SharedAffirmationEntry(
            quote: currentQuote,
            isPinned: pinned,
            date: Date(),
            backgroundImage: "background"
        )
    }
}

