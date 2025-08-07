import Foundation

class QuoteHistory {
    private var history: [String] = []
    private var currentIndex: Int = 0
    private let quotes: [String]
    private var cachedNextQuote: String?
    private weak var quoteManager: QuoteManager?
    
    init(initialQuote: String, availableQuotes: [String], quoteManager: QuoteManager? = nil) {
        self.quotes = availableQuotes
        self.history = [initialQuote]
        self.currentIndex = 0
        self.quoteManager = quoteManager
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
        // Try to use weighted selection from quote manager
        if let manager = quoteManager {
            manager.ensureQuoteBagInitialized()
            
            // Try to get a weighted quote that's different from current
            let currentQuote = history[currentIndex]
            
            // Try multiple times to get a different quote
            for _ in 0..<10 {
                if let selectedQuote = manager.quoteBag.selectRandomQuote() {
                    if selectedQuote.text != currentQuote {
                        return selectedQuote.text
                    }
                }
            }
        }
        
        // Fallback to original logic
        var allAvailableQuotes: [String] = []
        
        // Add regular quotes
        if !quotes.isEmpty {
            allAvailableQuotes.append(contentsOf: quotes)
        }
        
        // Add personal quotes if enabled and available
        if let manager = quoteManager, manager.includePersonalQuotes {
            let activePersonal = manager.activePersonalQuotes.map { $0.displayText }
            allAvailableQuotes.append(contentsOf: activePersonal)
        }
        
        guard !allAvailableQuotes.isEmpty else { return "Stay inspired!" }
        
        // Ensure we don't return the same quote as current
        let currentQuote = history[currentIndex]
        let availableQuotes = allAvailableQuotes.filter { $0 != currentQuote }
        if availableQuotes.isEmpty {
            return allAvailableQuotes.randomElement() ?? "Stay inspired!"
        }
        
        return availableQuotes.randomElement() ?? "Stay inspired!"
    }
    
    // MARK: - Deep Link Support
    func addQuote(_ quote: String) {
        // Add quote to history and move to it
        history.append(quote)
        currentIndex = history.count - 1
        // Clear cached next quote since we've moved to a specific quote
        cachedNextQuote = nil
    }
    
    func navigateToQuote(_ quote: String) -> Bool {
        // Check if quote already exists in history
        if let existingIndex = history.firstIndex(of: quote) {
            // Navigate to existing quote
            currentIndex = existingIndex
            // Clear cached next quote since we've moved to a specific position
            cachedNextQuote = nil
            return true
        }
        return false
    }
}