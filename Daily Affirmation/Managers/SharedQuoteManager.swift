//Daily Affirmation
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
            print("⚠️ SharedQuoteManager: Failed to create UserDefaults with App Group: \(appGroupIdentifier)")
            print("⚠️ SharedQuoteManager: Falling back to standard UserDefaults")
            return UserDefaults.standard
        }
        return defaults
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
        print("📌 SharedQuoteManager: Pinning quote: '\(quote)'")
        
        // Always clear any existing pin first to enforce single pin behavior
        if isPinned() {
            print("📌 SharedQuoteManager: Clearing existing pin first")
            sharedUserDefaults?.removeObject(forKey: pinnedQuoteKey)
            sharedUserDefaults?.set(false, forKey: isPinnedKey)
            sharedUserDefaults?.removeObject(forKey: pinnedDateKey)
        }
        
        // Set the new pin
        sharedUserDefaults?.set(quote, forKey: pinnedQuoteKey)
        sharedUserDefaults?.set(true, forKey: isPinnedKey)
        sharedUserDefaults?.set(Date(), forKey: pinnedDateKey)
        
        // Force synchronization to ensure data is written immediately
        let syncSuccess = sharedUserDefaults?.synchronize() ?? false
        print("📌 SharedQuoteManager: Data sync success: \(syncSuccess)")
        
        // Verify the data was written
        let savedQuote = sharedUserDefaults?.string(forKey: pinnedQuoteKey)
        let savedPinned = sharedUserDefaults?.bool(forKey: isPinnedKey) ?? false
        print("📌 SharedQuoteManager: Verification - Quote: '\(savedQuote ?? "nil")', Pinned: \(savedPinned)")
        
        // Reload widgets when pin state changes with multiple strategies
        #if canImport(WidgetKit)
        print("📌 SharedQuoteManager: Scheduling widget reload...")
        
        // Strategy 1: Immediate reload
        WidgetCenter.shared.reloadAllTimelines()
        
        // Strategy 2: Delayed reload to ensure data persistence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("📌 SharedQuoteManager: Executing delayed widget reload")
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        // Strategy 3: Specific widget reload after longer delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("📌 SharedQuoteManager: Executing specific widget reload")
            WidgetCenter.shared.reloadTimelines(ofKind: "Daily_Affirmation_Widgets")
        }
        #endif
    }
    
    func unpinQuote() {
        print("📌 SharedQuoteManager: Unpinning quote")
        
        sharedUserDefaults?.removeObject(forKey: pinnedQuoteKey)
        sharedUserDefaults?.set(false, forKey: isPinnedKey)
        sharedUserDefaults?.removeObject(forKey: pinnedDateKey)
        
        // Force synchronization to ensure data is written immediately
        let syncSuccess = sharedUserDefaults?.synchronize() ?? false
        print("📌 SharedQuoteManager: Unpin sync success: \(syncSuccess)")
        
        // Verify the data was cleared
        let savedQuote = sharedUserDefaults?.string(forKey: pinnedQuoteKey)
        let savedPinned = sharedUserDefaults?.bool(forKey: isPinnedKey) ?? false
        print("📌 SharedQuoteManager: Unpin verification - Quote: '\(savedQuote ?? "nil")', Pinned: \(savedPinned)")
        
        // Reload widgets when pin state changes with multiple strategies
        #if canImport(WidgetKit)
        print("📌 SharedQuoteManager: Scheduling widget reload after unpin...")
        
        // Strategy 1: Immediate reload
        WidgetCenter.shared.reloadAllTimelines()
        
        // Strategy 2: Delayed reload to ensure data persistence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("📌 SharedQuoteManager: Executing delayed widget reload after unpin")
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        // Strategy 3: Specific widget reload after longer delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("📌 SharedQuoteManager: Executing specific widget reload after unpin")
            WidgetCenter.shared.reloadTimelines(ofKind: "Daily_Affirmation_Widgets")
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
        let currentQuote: String
        let pinned = isPinned()
        
        if pinned, let pinnedQuote = getPinnedQuote() {
            currentQuote = pinnedQuote
        } else {
            // Use main app's current quote if available, otherwise fall back to daily quote
            if let appCurrentQuote = getCurrentQuoteFromApp(), !appCurrentQuote.isEmpty {
                currentQuote = appCurrentQuote
            } else {
                currentQuote = getDailyQuote()
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

