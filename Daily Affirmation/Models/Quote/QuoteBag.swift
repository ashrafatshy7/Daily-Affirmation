import Foundation

class QuoteBag {
    private var quotes: [WeightedQuote] = []
    private var usedQuotes: Set<String> = []
    private var recentBuffer: [String] = []
    private let maxRecentBuffer: Int = 10
    
    var isEmpty: Bool {
        return quotes.isEmpty
    }
    
    var totalQuotes: Int {
        return quotes.count
    }
    
    var availableQuotes: Int {
        return quotes.count - usedQuotes.count
    }
    
    var exhaustionPercentage: Double {
        guard totalQuotes > 0 else { return 0 }
        return Double(usedQuotes.count) / Double(totalQuotes)
    }
    
    func addQuote(_ weightedQuote: WeightedQuote) {
        quotes.append(weightedQuote)
    }
    
    func addQuotes(_ weightedQuotes: [WeightedQuote]) {
        quotes.append(contentsOf: weightedQuotes)
    }
    
    func updatePersonalQuoteFrequency(multiplier: Double) {
        for i in 0..<quotes.count {
            if quotes[i].type == .personal {
                quotes[i].adjustWeight(multiplier: multiplier)
            }
        }
    }
    
    func selectRandomQuote() -> WeightedQuote? {
        let availableQuotes = quotes.filter { quote in
            !usedQuotes.contains(quote.text) && !recentBuffer.contains(quote.text)
        }
        
        guard !availableQuotes.isEmpty else {
            // If all quotes are used or in recent buffer, check if we should reset
            if shouldResetBag() {
                resetBag()
                return selectRandomQuote()
            }
            return nil
        }
        
        // Apply boost to remaining quotes when bag is getting empty
        let boostedQuotes = applyEmptyBagBoost(to: availableQuotes)
        
        // Weighted random selection
        let totalWeight = boostedQuotes.reduce(0) { $0 + $1.currentWeight }
        guard totalWeight > 0 else { return availableQuotes.randomElement() }
        
        let randomValue = Double.random(in: 0..<totalWeight)
        var accumulatedWeight: Double = 0
        
        for quote in boostedQuotes {
            accumulatedWeight += quote.currentWeight
            if randomValue < accumulatedWeight {
                markQuoteAsUsed(quote.text)
                return quote
            }
        }
        
        // Fallback to random selection
        let selectedQuote = availableQuotes.randomElement()
        if let quote = selectedQuote {
            markQuoteAsUsed(quote.text)
        }
        return selectedQuote
    }
    
    private func shouldResetBag() -> Bool {
        // Reset when 90% of quotes have been used
        return exhaustionPercentage >= 0.9
    }
    
    private func resetBag() {
        usedQuotes.removeAll()
        recentBuffer.removeAll()
        
        // Shuffle the quotes array for variety
        quotes.shuffle()
    }
    
    private func markQuoteAsUsed(_ quoteText: String) {
        usedQuotes.insert(quoteText)
        
        // Add to recent buffer
        recentBuffer.append(quoteText)
        if recentBuffer.count > maxRecentBuffer {
            recentBuffer.removeFirst()
        }
    }
    
    private func applyEmptyBagBoost(to quotes: [WeightedQuote]) -> [WeightedQuote] {
        // When bag is getting empty (>60% used), boost remaining quotes
        guard exhaustionPercentage > 0.6 else { return quotes }
        
        let boostMultiplier = 1.0 + (exhaustionPercentage - 0.6) * 2.0 // Up to 2x boost
        
        return quotes.map { quote in
            var boostedQuote = quote
            boostedQuote.currentWeight *= boostMultiplier
            return boostedQuote
        }
    }
    
    func removeQuotesMatching(predicate: (WeightedQuote) -> Bool) {
        quotes.removeAll(where: predicate)
        // Clean up used quotes set to remove any that no longer exist
        let existingTexts = Set(quotes.map { $0.text })
        usedQuotes = usedQuotes.intersection(existingTexts)
    }
    
    func updateQuote(withId id: UUID, newText: String) {
        for i in 0..<quotes.count {
            if quotes[i].personalQuoteId == id {
                let oldText = quotes[i].text
                quotes[i] = WeightedQuote(
                    text: newText,
                    type: quotes[i].type,
                    baseWeight: quotes[i].baseWeight,
                    personalQuoteId: id
                )
                
                // Update tracking sets
                if usedQuotes.contains(oldText) {
                    usedQuotes.remove(oldText)
                    usedQuotes.insert(newText)
                }
                
                if let index = recentBuffer.firstIndex(of: oldText) {
                    recentBuffer[index] = newText
                }
                break
            }
        }
    }
    
    func getQuoteStatistics() -> (total: Int, used: Int, personal: Int, builtin: Int) {
        let personalCount = quotes.filter { $0.type == .personal }.count
        let builtinCount = quotes.filter { $0.type == .builtin }.count
        
        return (
            total: totalQuotes,
            used: usedQuotes.count,
            personal: personalCount,
            builtin: builtinCount
        )
    }
}