import Foundation
import SwiftUI

// MARK: - Quote Frequency Models
enum QuoteType {
    case builtin
    case personal
}

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

enum FontSize: String, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
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

enum NotificationMode: String, CaseIterable {
    case single = "single"
    case range = "range"
    
    var displayName: String {
        switch self {
        case .single: return "Single Daily"
        case .range: return "Time Range"
        }
    }
}