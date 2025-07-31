import Foundation

struct WeightedQuote {
    let text: String
    let type: QuoteType
    let baseWeight: Double
    var currentWeight: Double
    let personalQuoteId: UUID?
    
    init(text: String, type: QuoteType, baseWeight: Double = 1.0, personalQuoteId: UUID? = nil) {
        self.text = text
        self.type = type
        self.baseWeight = baseWeight
        self.currentWeight = baseWeight
        self.personalQuoteId = personalQuoteId
    }
    
    mutating func adjustWeight(multiplier: Double) {
        self.currentWeight = baseWeight * multiplier
    }
}