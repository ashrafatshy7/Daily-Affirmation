import Foundation

// MARK: - Quote Bag Management
extension QuoteManager {
    
    // MARK: - Quote Bag Management
    func rebuildQuoteBag() {
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
    
    func ensureQuoteBagInitialized() {
        if quoteBag.isEmpty && (!quotes.isEmpty || !personalQuotes.isEmpty) {
            rebuildQuoteBag()
        }
    }
    
    func getQuoteBagStatistics() -> (total: Int, used: Int, personal: Int, builtin: Int) {
        return quoteBag.getQuoteStatistics()
    }
}