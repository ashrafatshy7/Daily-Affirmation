import Foundation

// MARK: - Personal Quote Model
struct PersonalQuote: Identifiable, Codable, Equatable {
    let id = UUID()
    var text: String
    let createdDate: Date
    var isActive: Bool
    
    init(text: String, isActive: Bool = true) {
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.createdDate = Date()
        self.isActive = isActive
    }
    
    // Validation
    var isValid: Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedText.isEmpty && trimmedText.count >= 4 && trimmedText.count <= 50
    }
    
    var displayText: String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Encoding keys for Codable
    enum CodingKeys: String, CodingKey {
        case id, text, createdDate, isActive
    }
}

// MARK: - Category Models
struct QuoteCategories: Codable {
    let categories: [String: [String]]
    let defaultCategory: String
    
    enum CodingKeys: String, CodingKey {
        case categories
        case defaultCategory = "default_category"
    }
}

enum QuoteCategory: String, CaseIterable {
    case general = "General"
    case love = "Love"
    case positivity = "Positivity"
    case stopOverthinking = "Stop overthinking"
    case loveYourself = "Love yourself"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Quote Frequency Models
enum QuoteType {
    case builtin
    case personal
}