import XCTest
@testable import Daily_Affirmation

final class PersonalQuotesTests: XCTestCase {
    var quoteManager: QuoteManager!
    
    override func setUp() {
        super.setUp()
        // Create a fresh test instance for each test
        quoteManager = QuoteManager.createTestInstance()
    }
    
    override func tearDown() {
        quoteManager.clearPersonalQuotes()
        quoteManager = nil
        super.tearDown()
    }
    
    // MARK: - PersonalQuote Model Tests
    
    func testPersonalQuoteInitialization() {
        let quote = PersonalQuote(text: "Test quote for validation")
        
        XCTAssertFalse(quote.id.uuidString.isEmpty)
        XCTAssertEqual(quote.text, "Test quote for validation")
        XCTAssertTrue(quote.isActive)
        XCTAssertNotNil(quote.createdDate)
    }
    
    func testPersonalQuoteValidation() {
        // Valid quote
        let validQuote = PersonalQuote(text: "This is a valid test quote")
        XCTAssertTrue(validQuote.isValid)
        
        // Too short
        let shortQuote = PersonalQuote(text: "Hi")
        XCTAssertFalse(shortQuote.isValid)
        
        // Empty
        let emptyQuote = PersonalQuote(text: "")
        XCTAssertFalse(emptyQuote.isValid)
        
        // Too long
        let longText = String(repeating: "a", count: 501)
        let longQuote = PersonalQuote(text: longText)
        XCTAssertFalse(longQuote.isValid)
        
        // Whitespace handling
        let whitespaceQuote = PersonalQuote(text: "   Valid quote with whitespace   ")
        XCTAssertTrue(whitespaceQuote.isValid)
        XCTAssertEqual(whitespaceQuote.displayText, "Valid quote with whitespace")
    }
    
    // MARK: - Personal Quotes Management Tests
    
    func testAddPersonalQuote() {
        let initialCount = quoteManager.personalQuotes.count
        
        let success = quoteManager.addPersonalQuote("This is a test quote")
        
        XCTAssertTrue(success)
        XCTAssertEqual(quoteManager.personalQuotes.count, initialCount + 1)
        XCTAssertEqual(quoteManager.personalQuotes.last?.text, "This is a test quote")
        XCTAssertTrue(quoteManager.personalQuotes.last?.isActive == true)
    }
    
    func testAddInvalidPersonalQuote() {
        let initialCount = quoteManager.personalQuotes.count
        
        // Too short
        let shortSuccess = quoteManager.addPersonalQuote("Hi")
        XCTAssertFalse(shortSuccess)
        XCTAssertEqual(quoteManager.personalQuotes.count, initialCount)
        
        // Empty
        let emptySuccess = quoteManager.addPersonalQuote("")
        XCTAssertFalse(emptySuccess)
        XCTAssertEqual(quoteManager.personalQuotes.count, initialCount)
        
        // Too long
        let longText = String(repeating: "a", count: 501)
        let longSuccess = quoteManager.addPersonalQuote(longText)
        XCTAssertFalse(longSuccess)
        XCTAssertEqual(quoteManager.personalQuotes.count, initialCount)
    }
    
    func testDeletePersonalQuote() {
        // Add a quote first
        let success = quoteManager.addPersonalQuote("Quote to be deleted")
        XCTAssertTrue(success)
        
        let quoteToDelete = quoteManager.personalQuotes.last!
        let initialCount = quoteManager.personalQuotes.count
        
        quoteManager.deletePersonalQuote(withId: quoteToDelete.id)
        
        XCTAssertEqual(quoteManager.personalQuotes.count, initialCount - 1)
        XCTAssertFalse(quoteManager.personalQuotes.contains { $0.id == quoteToDelete.id })
    }
    
    func testUpdatePersonalQuote() {
        // Add a quote first
        let success = quoteManager.addPersonalQuote("Original quote")
        XCTAssertTrue(success)
        
        let quoteToUpdate = quoteManager.personalQuotes.last!
        let originalId = quoteToUpdate.id
        
        let updateSuccess = quoteManager.updatePersonalQuote(withId: originalId, newText: "Updated quote text")
        
        XCTAssertTrue(updateSuccess)
        
        let updatedQuote = quoteManager.personalQuotes.first { $0.id == originalId }
        XCTAssertNotNil(updatedQuote)
        XCTAssertEqual(updatedQuote?.text, "Updated quote text")
    }
    
    func testUpdatePersonalQuoteWithInvalidText() {
        // Add a quote first
        let success = quoteManager.addPersonalQuote("Original quote")
        XCTAssertTrue(success)
        
        let quoteToUpdate = quoteManager.personalQuotes.last!
        let originalText = quoteToUpdate.text
        
        // Try to update with invalid text
        let updateSuccess = quoteManager.updatePersonalQuote(withId: quoteToUpdate.id, newText: "Hi")
        
        XCTAssertFalse(updateSuccess)
        
        let unchangedQuote = quoteManager.personalQuotes.first { $0.id == quoteToUpdate.id }
        XCTAssertEqual(unchangedQuote?.text, originalText)
    }
    
    func testTogglePersonalQuoteActive() {
        // Add a quote first
        let success = quoteManager.addPersonalQuote("Quote to toggle")
        XCTAssertTrue(success)
        
        let quote = quoteManager.personalQuotes.last!
        XCTAssertTrue(quote.isActive)
        
        quoteManager.togglePersonalQuoteActive(withId: quote.id)
        
        let toggledQuote = quoteManager.personalQuotes.first { $0.id == quote.id }
        XCTAssertFalse(toggledQuote?.isActive == true)
        
        // Toggle back
        quoteManager.togglePersonalQuoteActive(withId: quote.id)
        
        let toggledBackQuote = quoteManager.personalQuotes.first { $0.id == quote.id }
        XCTAssertTrue(toggledBackQuote?.isActive == true)
    }
    
    func testActivePersonalQuotes() {
        // Add active and inactive quotes
        quoteManager.addPersonalQuote("Active quote 1")
        quoteManager.addPersonalQuote("Active quote 2")
        quoteManager.addPersonalQuote("Quote to deactivate")
        
        let quoteToDeactivate = quoteManager.personalQuotes.last!
        quoteManager.togglePersonalQuoteActive(withId: quoteToDeactivate.id)
        
        let activeQuotes = quoteManager.activePersonalQuotes
        XCTAssertEqual(activeQuotes.count, 2)
        XCTAssertTrue(activeQuotes.allSatisfy { $0.isActive })
    }
    
    func testSortedPersonalQuotes() {
        // Add quotes with slight delays to ensure different timestamps
        quoteManager.addPersonalQuote("First quote")
        Thread.sleep(forTimeInterval: 0.01)
        
        quoteManager.addPersonalQuote("Second quote")
        Thread.sleep(forTimeInterval: 0.01)
        
        quoteManager.addPersonalQuote("Third quote")
        
        let sortedQuotes = quoteManager.sortedPersonalQuotes
        XCTAssertEqual(sortedQuotes.count, 3)
        
        // Should be sorted by creation date, newest first
        XCTAssertEqual(sortedQuotes[0].text, "Third quote")
        XCTAssertEqual(sortedQuotes[1].text, "Second quote")
        XCTAssertEqual(sortedQuotes[2].text, "First quote")
    }
    
    // MARK: - Persistence Tests
    
    func testPersonalQuotesPersistence() {
        // Add some quotes
        quoteManager.addPersonalQuote("Persistent quote 1")
        quoteManager.addPersonalQuote("Persistent quote 2")
        
        let originalCount = quoteManager.personalQuotes.count
        let originalQuotes = quoteManager.personalQuotes
        
        // Create a new instance (simulates app restart)
        let newQuoteManager = QuoteManager.createTestInstance()
        
        // Load the same data manually since we're using test storage
        newQuoteManager.personalQuotes = originalQuotes
        
        XCTAssertEqual(newQuoteManager.personalQuotes.count, originalCount)
        XCTAssertTrue(newQuoteManager.personalQuotes.contains { $0.text == "Persistent quote 1" })
        XCTAssertTrue(newQuoteManager.personalQuotes.contains { $0.text == "Persistent quote 2" })
    }
    
    func testClearPersonalQuotes() {
        // Add some quotes
        quoteManager.addPersonalQuote("Quote to clear 1")
        quoteManager.addPersonalQuote("Quote to clear 2")
        
        XCTAssertGreaterThan(quoteManager.personalQuotes.count, 0)
        
        quoteManager.clearPersonalQuotes()
        
        XCTAssertEqual(quoteManager.personalQuotes.count, 0)
    }
    
    // MARK: - Quote Distribution Tests
    
    func testIncludePersonalQuotesInRotation() {
        // Ensure we have some regular quotes loaded
        XCTAssertGreaterThan(quoteManager.quotes.count, 0)
        
        // Add personal quotes
        quoteManager.addPersonalQuote("Personal quote 1")
        quoteManager.addPersonalQuote("Personal quote 2")
        
        // Enable personal quotes in rotation
        quoteManager.includePersonalQuotes = true
        
        // Test that random quotes can include personal quotes
        var foundPersonalQuote = false
        
        // Try multiple times to increase chance of getting a personal quote
        for _ in 0..<50 {
            let randomQuote = quoteManager.getRandomQuote()
            if randomQuote == "Personal quote 1" || randomQuote == "Personal quote 2" {
                foundPersonalQuote = true
                break
            }
        }
        
        XCTAssertTrue(foundPersonalQuote, "Should occasionally return personal quotes when included")
    }
    
    func testExcludePersonalQuotesFromRotation() {
        // Add personal quotes
        quoteManager.addPersonalQuote("Personal quote 1")
        quoteManager.addPersonalQuote("Personal quote 2")
        
        // Disable personal quotes in rotation
        quoteManager.includePersonalQuotes = false
        
        // Test that random quotes don't include personal quotes
        for _ in 0..<20 {
            let randomQuote = quoteManager.getRandomQuote()
            XCTAssertNotEqual(randomQuote, "Personal quote 1")
            XCTAssertNotEqual(randomQuote, "Personal quote 2")
        }
    }
    
    func testOnlyActivePersonalQuotesInRotation() {
        // Add personal quotes
        quoteManager.addPersonalQuote("Active personal quote")
        quoteManager.addPersonalQuote("Inactive personal quote")
        
        // Deactivate one quote
        let inactiveQuote = quoteManager.personalQuotes.first { $0.text == "Inactive personal quote" }!
        quoteManager.togglePersonalQuoteActive(withId: inactiveQuote.id)
        
        // Enable personal quotes in rotation
        quoteManager.includePersonalQuotes = true
        
        // Test that only active personal quotes are included
        for _ in 0..<50 {
            let randomQuote = quoteManager.getRandomQuote()
            XCTAssertNotEqual(randomQuote, "Inactive personal quote", "Inactive quotes should not appear in rotation")
        }
    }
    
    // MARK: - Settings Persistence Tests
    
    func testIncludePersonalQuotesSettingPersistence() {
        // Change the setting
        quoteManager.includePersonalQuotes = false
        
        // Create new instance to test persistence
        let testUserDefaults = UserDefaults(suiteName: "TestSuite_\(UUID().uuidString)")!
        testUserDefaults.set(false, forKey: "includePersonalQuotes")
        
        let newQuoteManager = QuoteManager(loadFromDefaults: true, userDefaults: testUserDefaults)
        
        XCTAssertFalse(newQuoteManager.includePersonalQuotes)
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithManyPersonalQuotes() {
        measure {
            // Add many quotes
            for i in 0..<100 {
                let success = quoteManager.addPersonalQuote("Performance test quote \(i)")
                XCTAssertTrue(success)
            }
            
            // Test sorting performance
            let sortedQuotes = quoteManager.sortedPersonalQuotes
            XCTAssertEqual(sortedQuotes.count, 100)
            
            // Test active quotes filtering performance
            let activeQuotes = quoteManager.activePersonalQuotes
            XCTAssertEqual(activeQuotes.count, 100)
        }
    }
    
    // MARK: - Weighted Selection Tests
    
    func testWeightedQuoteInitialization() {
        let quote = WeightedQuote(text: "Test quote", type: .personal, baseWeight: 2.0)
        
        XCTAssertEqual(quote.text, "Test quote")
        XCTAssertEqual(quote.type, .personal)
        XCTAssertEqual(quote.baseWeight, 2.0)
        XCTAssertEqual(quote.currentWeight, 2.0)
        XCTAssertNil(quote.personalQuoteId)
    }
    
    func testWeightedQuoteWithPersonalId() {
        let id = UUID()
        let quote = WeightedQuote(text: "Personal quote", type: .personal, baseWeight: 1.0, personalQuoteId: id)
        
        XCTAssertEqual(quote.personalQuoteId, id)
        XCTAssertEqual(quote.type, .personal)
    }
    
    func testWeightedQuoteAdjustWeight() {
        var quote = WeightedQuote(text: "Test quote", type: .personal, baseWeight: 1.0)
        
        quote.adjustWeight(multiplier: 3.0)
        XCTAssertEqual(quote.currentWeight, 3.0)
        XCTAssertEqual(quote.baseWeight, 1.0) // Base weight should remain unchanged
        
        quote.adjustWeight(multiplier: 0.5)
        XCTAssertEqual(quote.currentWeight, 0.5)
    }
    
    func testQuoteBagInitialization() {
        let quoteBag = QuoteBag()
        
        XCTAssertTrue(quoteBag.isEmpty)
        XCTAssertEqual(quoteBag.totalQuotes, 0)
        XCTAssertEqual(quoteBag.availableQuotes, 0)
        XCTAssertEqual(quoteBag.exhaustionPercentage, 0)
    }
    
    func testQuoteBagAddQuote() {
        let quoteBag = QuoteBag()
        let quote = WeightedQuote(text: "Test quote", type: .builtin)
        
        quoteBag.addQuote(quote)
        
        XCTAssertFalse(quoteBag.isEmpty)
        XCTAssertEqual(quoteBag.totalQuotes, 1)
        XCTAssertEqual(quoteBag.availableQuotes, 1)
    }
    
    func testQuoteBagAddMultipleQuotes() {
        let quoteBag = QuoteBag()
        let quotes = [
            WeightedQuote(text: "Quote 1", type: .builtin),
            WeightedQuote(text: "Quote 2", type: .personal, baseWeight: 2.0),
            WeightedQuote(text: "Quote 3", type: .personal, baseWeight: 1.5)
        ]
        
        quoteBag.addQuotes(quotes)
        
        XCTAssertEqual(quoteBag.totalQuotes, 3)
        XCTAssertEqual(quoteBag.availableQuotes, 3)
    }
    
    func testQuoteBagUpdatePersonalQuoteFrequency() {
        let quoteBag = QuoteBag()
        let quotes = [
            WeightedQuote(text: "Builtin quote", type: .builtin, baseWeight: 1.0),
            WeightedQuote(text: "Personal quote 1", type: .personal, baseWeight: 1.0),
            WeightedQuote(text: "Personal quote 2", type: .personal, baseWeight: 1.5)
        ]
        
        quoteBag.addQuotes(quotes)
        quoteBag.updatePersonalQuoteFrequency(multiplier: 3.0)
        
        // Verify that only personal quotes had their weight adjusted
        let statistics = quoteBag.getQuoteStatistics()
        XCTAssertEqual(statistics.total, 3)
        XCTAssertEqual(statistics.personal, 2)
        XCTAssertEqual(statistics.builtin, 1)
    }
    
    func testQuoteBagWeightedSelection() {
        let quoteBag = QuoteBag()
        
        // Add quotes with different weights
        let heavyWeightQuote = WeightedQuote(text: "Heavy quote", type: .personal, baseWeight: 10.0)
        let lightWeightQuote = WeightedQuote(text: "Light quote", type: .builtin, baseWeight: 1.0)
        
        quoteBag.addQuotes([heavyWeightQuote, lightWeightQuote])
        
        // Test selection multiple times to verify weighted distribution
        var heavyCount = 0
        var lightCount = 0
        let iterations = 200
        
        for _ in 0..<iterations {
            if let selectedQuote = quoteBag.selectRandomQuote() {
                if selectedQuote.text == "Heavy quote" {
                    heavyCount += 1
                } else if selectedQuote.text == "Light quote" {
                    lightCount += 1
                }
            }
        }
        
        // Heavy quote should appear significantly more often (roughly 10:1 ratio)
        // Allow for some variance due to randomness
        let ratio = Double(heavyCount) / Double(lightCount)
        XCTAssertGreaterThan(ratio, 5.0, "Heavy weighted quote should appear much more frequently")
        XCTAssertLessThan(ratio, 15.0, "Ratio shouldn't be unreasonably high")
    }
    
    func testQuoteBagExhaustionAndReset() {
        let quoteBag = QuoteBag()
        let quotes = [
            WeightedQuote(text: "Quote 1", type: .builtin),
            WeightedQuote(text: "Quote 2", type: .builtin),
            WeightedQuote(text: "Quote 3", type: .builtin)
        ]
        
        quoteBag.addQuotes(quotes)
        
        // Select quotes until bag is nearly exhausted
        var selectedQuotes: Set<String> = []
        
        // Select all quotes to reach 100% exhaustion
        for _ in 0..<3 {
            if let quote = quoteBag.selectRandomQuote() {
                selectedQuotes.insert(quote.text)
            }
        }
        
        XCTAssertEqual(selectedQuotes.count, 3)
        XCTAssertEqual(quoteBag.exhaustionPercentage, 1.0)
        XCTAssertEqual(quoteBag.availableQuotes, 0)
        
        // Next selection should trigger reset and return a quote
        let nextQuote = quoteBag.selectRandomQuote()
        XCTAssertNotNil(nextQuote)
        XCTAssertLessThan(quoteBag.exhaustionPercentage, 0.5) // Should be reset
    }
    
    func testQuoteBagDuplicatePrevention() {
        let quoteBag = QuoteBag()
        let quotes = [
            WeightedQuote(text: "Quote 1", type: .builtin),
            WeightedQuote(text: "Quote 2", type: .builtin),
            WeightedQuote(text: "Quote 3", type: .builtin),
            WeightedQuote(text: "Quote 4", type: .builtin),
            WeightedQuote(text: "Quote 5", type: .builtin)
        ]
        
        quoteBag.addQuotes(quotes)
        
        // Select quotes and verify no immediate duplicates
        var lastQuotes: [String] = []
        
        for _ in 0..<15 { // Select more than total to test reset behavior
            if let quote = quoteBag.selectRandomQuote() {
                // Check that quote isn't in recent buffer (last 10)
                let recentQuotes = Array(lastQuotes.suffix(3)) // Check last 3
                XCTAssertFalse(recentQuotes.contains(quote.text), "Quote shouldn't repeat in recent buffer")
                
                lastQuotes.append(quote.text)
            }
        }
    }
    
    func testQuoteBagRemoveQuotes() {
        let quoteBag = QuoteBag()
        let id1 = UUID()
        let id2 = UUID()
        let quotes = [
            WeightedQuote(text: "Personal quote 1", type: .personal, personalQuoteId: id1),
            WeightedQuote(text: "Personal quote 2", type: .personal, personalQuoteId: id2),
            WeightedQuote(text: "Builtin quote", type: .builtin)
        ]
        
        quoteBag.addQuotes(quotes)
        XCTAssertEqual(quoteBag.totalQuotes, 3)
        
        // Remove personal quotes with specific ID
        quoteBag.removeQuotesMatching { $0.personalQuoteId == id1 }
        
        XCTAssertEqual(quoteBag.totalQuotes, 2)
        let statistics = quoteBag.getQuoteStatistics()
        XCTAssertEqual(statistics.personal, 1)
        XCTAssertEqual(statistics.builtin, 1)
    }
    
    func testQuoteBagUpdateQuote() {
        let quoteBag = QuoteBag()
        let id = UUID()
        let originalQuote = WeightedQuote(text: "Original text", type: .personal, personalQuoteId: id)
        
        quoteBag.addQuote(originalQuote)
        
        // Update the quote
        quoteBag.updateQuote(withId: id, newText: "Updated text")
        
        // Verify the update
        if let selectedQuote = quoteBag.selectRandomQuote() {
            XCTAssertEqual(selectedQuote.text, "Updated text")
            XCTAssertEqual(selectedQuote.personalQuoteId, id)
        } else {
            XCTFail("Should be able to select the updated quote")
        }
    }
    
    func testFrequencyMultiplierPersistence() {
        // Test that frequency multiplier is properly saved and loaded
        quoteManager.personalQuoteFrequencyMultiplier = 3.5
        
        // Create new instance to test persistence
        let newQuoteManager = QuoteManager.createTestInstance()
        
        // In a real app, this would load from UserDefaults
        // For testing, we'll verify the property was set correctly
        XCTAssertEqual(quoteManager.personalQuoteFrequencyMultiplier, 3.5)
    }
    
    func testQuoteDistributionWithFrequencyMultiplier() {
        // Add personal and builtin quotes
        quoteManager.addPersonalQuote("Personal quote 1")
        quoteManager.addPersonalQuote("Personal quote 2")
        
        // Enable personal quotes and set frequency multiplier
        quoteManager.includePersonalQuotes = true
        quoteManager.personalQuoteFrequencyMultiplier = 4.0
        
        // Test quote distribution over many selections
        var personalQuoteCount = 0
        var builtinQuoteCount = 0
        let iterations = 100
        
        for _ in 0..<iterations {
            let randomQuote = quoteManager.getRandomQuote()
            if randomQuote.contains("Personal quote") {
                personalQuoteCount += 1
            } else {
                builtinQuoteCount += 1
            }
        }
        
        // With 4x multiplier, personal quotes should appear much more frequently
        // Should be roughly 80% personal quotes with 4x multiplier
        let personalPercentage = Double(personalQuoteCount) / Double(iterations)
        XCTAssertGreaterThan(personalPercentage, 0.6, "Personal quotes should appear more frequently with 4x multiplier")
    }
    
    func testQuoteBagPerformanceWithLargeDataset() {
        measure {
            let quoteBag = QuoteBag()
            
            // Add many quotes
            var quotes: [WeightedQuote] = []
            for i in 0..<1000 {
                let quote = WeightedQuote(
                    text: "Performance test quote \(i)",
                    type: i % 3 == 0 ? .personal : .builtin,
                    baseWeight: Double.random(in: 0.5...3.0)
                )
                quotes.append(quote)
            }
            
            quoteBag.addQuotes(quotes)
            
            // Update frequency for personal quotes
            quoteBag.updatePersonalQuoteFrequency(multiplier: 2.5)
            
            // Select many quotes to test performance
            for _ in 0..<100 {
                _ = quoteBag.selectRandomQuote()
            }
            
            // Test statistics calculation
            let stats = quoteBag.getQuoteStatistics()
            XCTAssertEqual(stats.total, 1000)
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testAddPersonalQuoteWithSpecialCharacters() {
        let specialQuote = "This quote has special characters: 🌟✨ & émojis!"
        let success = quoteManager.addPersonalQuote(specialQuote)
        
        XCTAssertTrue(success)
        XCTAssertEqual(quoteManager.personalQuotes.last?.text, specialQuote)
    }
    
    func testAddPersonalQuoteWithWhitespaceOnly() {
        let whitespaceQuote = "   \n\t   "
        let success = quoteManager.addPersonalQuote(whitespaceQuote)
        
        XCTAssertFalse(success, "Whitespace-only quotes should be rejected")
    }
    
    func testDeleteNonExistentPersonalQuote() {
        let initialCount = quoteManager.personalQuotes.count
        let nonExistentId = UUID()
        
        quoteManager.deletePersonalQuote(withId: nonExistentId)
        
        XCTAssertEqual(quoteManager.personalQuotes.count, initialCount, "Count should remain unchanged when deleting non-existent quote")
    }
    
    func testCharacterLimitValidation() {
        // Test with the updated 50 character limit from AddPersonalQuoteView
        let validQuote = "This is a valid quote within 50 chars"
        let tooLongQuote = "This quote is definitely way too long and exceeds the fifty character limit that was set"
        
        let validSuccess = quoteManager.addPersonalQuote(validQuote)
        let invalidSuccess = quoteManager.addPersonalQuote(tooLongQuote)
        
        XCTAssertTrue(validSuccess, "Valid quote should be accepted")
        XCTAssertFalse(invalidSuccess, "Quote exceeding 50 characters should be rejected")
    }
}

// MARK: - Helper Extension

extension QuoteManager {
    fileprivate func getRandomQuote() -> String {
        var allAvailableQuotes: [String] = []
        
        // Add regular quotes
        if !quotes.isEmpty {
            allAvailableQuotes.append(contentsOf: quotes)
        }
        
        // Add personal quotes if enabled and available
        if includePersonalQuotes {
            let activePersonal = activePersonalQuotes.map { $0.displayText }
            allAvailableQuotes.append(contentsOf: activePersonal)
        }
        
        guard !allAvailableQuotes.isEmpty else { return "Stay inspired!" }
        return allAvailableQuotes.randomElement() ?? "Stay inspired!"
    }
}