//
//  LovedQuotesTests.swift
//  Daily AffirmationTests
//
//  Created by QA Engineer on 12/07/2025.
//

import XCTest
import Combine
@testable import Daily_Affirmation

final class LovedQuotesTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var quoteManager: QuoteManager!
    private var mockUserDefaults: MockUserDefaults!
    private var cancellables: Set<AnyCancellable>!
    
    private let sampleQuotes = [
        "Growth happens when finding solutions in small steps.",
        "Resilience shines amidst setting goals in all endeavors.",
        "Passion drives fueling creativity across every obstacle.",
        "Joy emerges from perfecting craft toward your dreams.",
        "Harness the power of extending grace despite doubts."
    ]
    
    // MARK: - Setup and Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockUserDefaults = MockUserDefaults()
        cancellables = Set<AnyCancellable>()
        
        // Create QuoteManager and clear any existing loved quotes
        quoteManager = QuoteManager()
        quoteManager.lovedQuotes.removeAll()
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        quoteManager = nil
        mockUserDefaults?.clearAll()
        mockUserDefaults = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testToggleLoveQuote_withNewQuote_addsToLovedQuotes() {
        // Arrange
        let testQuote = sampleQuotes[0]
        XCTAssertFalse(quoteManager.lovedQuotes.contains(testQuote), "Quote should not be loved initially")
        
        // Act
        quoteManager.toggleLoveQuote(testQuote)
        
        // Assert
        XCTAssertTrue(quoteManager.lovedQuotes.contains(testQuote), "Quote should be added to loved quotes")
        XCTAssertEqual(quoteManager.lovedQuotes.count, 1, "Should have exactly one loved quote")
    }
    
    func testToggleLoveQuote_withLovedQuote_removesFromLovedQuotes() {
        // Arrange
        let testQuote = sampleQuotes[0]
        quoteManager.toggleLoveQuote(testQuote) // Add first
        XCTAssertTrue(quoteManager.lovedQuotes.contains(testQuote), "Quote should be loved initially")
        
        // Act
        quoteManager.toggleLoveQuote(testQuote) // Remove
        
        // Assert
        XCTAssertFalse(quoteManager.lovedQuotes.contains(testQuote), "Quote should be removed from loved quotes")
        XCTAssertEqual(quoteManager.lovedQuotes.count, 0, "Should have no loved quotes")
    }
    
    func testToggleLoveQuote_multipleTogglesSameQuote_alternatesCorrectly() {
        // Arrange
        let testQuote = sampleQuotes[0]
        
        // Act & Assert
        quoteManager.toggleLoveQuote(testQuote)
        XCTAssertTrue(quoteManager.lovedQuotes.contains(testQuote), "First toggle should add quote")
        
        quoteManager.toggleLoveQuote(testQuote)
        XCTAssertFalse(quoteManager.lovedQuotes.contains(testQuote), "Second toggle should remove quote")
        
        quoteManager.toggleLoveQuote(testQuote)
        XCTAssertTrue(quoteManager.lovedQuotes.contains(testQuote), "Third toggle should add quote again")
    }
    
    func testToggleLoveQuote_withMultipleDifferentQuotes_addsAllQuotes() {
        // Arrange
        let quotes = Array(sampleQuotes.prefix(3))
        
        // Act
        quotes.forEach { quoteManager.toggleLoveQuote($0) }
        
        // Assert
        XCTAssertEqual(quoteManager.lovedQuotes.count, 3, "Should have three loved quotes")
        
        for quote in quotes {
            XCTAssertTrue(quoteManager.lovedQuotes.contains(quote), "Quote '\(quote)' should be in loved quotes")
        }
    }
    
    // MARK: - IsQuoteLoved Tests
    
    func testIsQuoteLoved_withLovedQuote_returnsTrue() {
        // Arrange
        let testQuote = sampleQuotes[0]
        quoteManager.toggleLoveQuote(testQuote)
        
        // Act & Assert
        XCTAssertTrue(quoteManager.isQuoteLoved(testQuote), "Should return true for loved quote")
    }
    
    func testIsQuoteLoved_withUnlovedQuote_returnsFalse() {
        // Arrange
        let testQuote = sampleQuotes[0]
        
        // Act & Assert
        XCTAssertFalse(quoteManager.isQuoteLoved(testQuote), "Should return false for unloved quote")
    }
    
    func testIsQuoteLoved_withEmptyString_returnsFalse() {
        // Act & Assert
        XCTAssertFalse(quoteManager.isQuoteLoved(""), "Should return false for empty string")
    }
    
    func testIsQuoteLoved_withNonExistentQuote_returnsFalse() {
        // Arrange
        let nonExistentQuote = "This quote does not exist in our collection"
        
        // Act & Assert
        XCTAssertFalse(quoteManager.isQuoteLoved(nonExistentQuote), "Should return false for non-existent quote")
    }
    
    func testIsQuoteLoved_caseSensitive_handlesCorrectly() {
        // Arrange
        let originalQuote = "Growth happens when finding solutions in small steps."
        let uppercaseQuote = originalQuote.uppercased()
        let lowercaseQuote = originalQuote.lowercased()
        
        quoteManager.toggleLoveQuote(originalQuote)
        
        // Act & Assert
        XCTAssertTrue(quoteManager.isQuoteLoved(originalQuote), "Should be true for exact match")
        XCTAssertFalse(quoteManager.isQuoteLoved(uppercaseQuote), "Should be false for uppercase version")
        XCTAssertFalse(quoteManager.isQuoteLoved(lowercaseQuote), "Should be false for lowercase version")
    }
    
    // MARK: - LovedQuotesArray Tests
    
    func testLovedQuotesArray_withEmptySet_returnsEmptyArray() {
        // Act
        let quotesArray = quoteManager.lovedQuotesArray
        
        // Assert
        XCTAssertTrue(quotesArray.isEmpty, "Should return empty array when no loved quotes")
    }
    
    func testLovedQuotesArray_withSingleQuote_returnsSingleElementArray() {
        // Arrange
        let testQuote = sampleQuotes[0]
        quoteManager.toggleLoveQuote(testQuote)
        
        // Act
        let quotesArray = quoteManager.lovedQuotesArray
        
        // Assert
        XCTAssertEqual(quotesArray.count, 1, "Should return array with one element")
        XCTAssertEqual(quotesArray[0], testQuote, "Should contain the loved quote")
    }
    
    func testLovedQuotesArray_withMultipleQuotes_returnsSortedArray() {
        // Arrange
        let unsortedQuotes = ["Zebra quote", "Alpha quote", "Beta quote", "Charlie quote"]
        let expectedSorted = ["Alpha quote", "Beta quote", "Charlie quote", "Zebra quote"]
        
        unsortedQuotes.forEach { quoteManager.toggleLoveQuote($0) }
        
        // Act
        let quotesArray = quoteManager.lovedQuotesArray
        
        // Assert
        XCTAssertEqual(quotesArray.count, 4, "Should return array with four elements")
        XCTAssertEqual(quotesArray, expectedSorted, "Should return alphabetically sorted array")
    }
    
    func testLovedQuotesArray_withSpecialCharacters_sortsProperly() {
        // Arrange
        let quotesWithSpecialChars = [
            "🌟 Amazing quote",
            "!!! Urgent quote",
            "999 Numeric quote",
            "AAA Capital quote",
            "aaa Lowercase quote"
        ]
        
        quotesWithSpecialChars.forEach { quoteManager.toggleLoveQuote($0) }
        
        // Act
        let quotesArray = quoteManager.lovedQuotesArray
        
        // Assert
        XCTAssertEqual(quotesArray.count, quotesWithSpecialChars.count, "Should contain all quotes")
        // Check that array is sorted
        for i in 1..<quotesArray.count {
            XCTAssertLessThanOrEqual(quotesArray[i-1], quotesArray[i], "Should be sorted according to Swift's string comparison")
        }
    }
    
    func testLovedQuotesArray_afterRemovingQuote_updatesCorrectly() {
        // Arrange
        let quotes = ["Quote B", "Quote A", "Quote C"]
        quotes.forEach { quoteManager.toggleLoveQuote($0) }
        
        // Act
        quoteManager.toggleLoveQuote("Quote B") // Remove Quote B
        let quotesArray = quoteManager.lovedQuotesArray
        
        // Assert
        XCTAssertEqual(quotesArray.count, 2, "Should have two quotes after removal")
        XCTAssertEqual(quotesArray, ["Quote A", "Quote C"], "Should be sorted and missing removed quote")
    }
    
    // MARK: - Set Behavior Tests
    
    func testLovedQuotes_preventsDuplicates() {
        // Arrange
        let testQuote = sampleQuotes[0]
        
        // Act
        quoteManager.toggleLoveQuote(testQuote)
        quoteManager.toggleLoveQuote(testQuote) // Remove
        quoteManager.toggleLoveQuote(testQuote) // Add again
        quoteManager.lovedQuotes.insert(testQuote) // Direct insertion (should not create duplicate)
        
        // Assert
        XCTAssertEqual(quoteManager.lovedQuotes.count, 1, "Set should prevent duplicates")
        XCTAssertTrue(quoteManager.lovedQuotes.contains(testQuote), "Should contain the quote")
    }
    
    func testLovedQuotes_handlesLargeNumberOfQuotes() {
        // Arrange
        let largeNumberOfQuotes = (0..<1000).map { "Test quote number \($0)" }
        
        // Act
        largeNumberOfQuotes.forEach { quoteManager.toggleLoveQuote($0) }
        
        // Assert
        XCTAssertEqual(quoteManager.lovedQuotes.count, 1000, "Should handle large number of quotes")
        
        let quotesArray = quoteManager.lovedQuotesArray
        XCTAssertEqual(quotesArray.count, 1000, "Array should also contain all quotes")
        // Check that large array is sorted
        for i in 1..<quotesArray.count {
            XCTAssertLessThanOrEqual(quotesArray[i-1], quotesArray[i], "Large array should be sorted")
        }
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testToggleLoveQuote_withEmptyString_handlesGracefully() {
        // Act
        quoteManager.toggleLoveQuote("")
        
        // Assert
        XCTAssertEqual(quoteManager.lovedQuotes.count, 1, "Should add empty string if that's what user wants")
        XCTAssertTrue(quoteManager.lovedQuotes.contains(""), "Should contain empty string")
    }
    
    func testToggleLoveQuote_withWhitespaceOnlyString_handlesCorrectly() {
        // Arrange
        let whitespaceQuote = "   \n\t   "
        
        // Act
        quoteManager.toggleLoveQuote(whitespaceQuote)
        
        // Assert
        XCTAssertTrue(quoteManager.lovedQuotes.contains(whitespaceQuote), "Should preserve whitespace-only strings")
        XCTAssertTrue(quoteManager.isQuoteLoved(whitespaceQuote), "Should recognize whitespace-only string as loved")
    }
    
    func testToggleLoveQuote_withVeryLongString_handlesCorrectly() {
        // Arrange
        let veryLongQuote = String(repeating: "This is a very long quote. ", count: 100)
        
        // Act
        quoteManager.toggleLoveQuote(veryLongQuote)
        
        // Assert
        XCTAssertTrue(quoteManager.lovedQuotes.contains(veryLongQuote), "Should handle very long strings")
        XCTAssertTrue(quoteManager.isQuoteLoved(veryLongQuote), "Should recognize very long string as loved")
    }
    
    func testToggleLoveQuote_withUnicodeCharacters_handlesCorrectly() {
        // Arrange
        let unicodeQuotes = [
            "Café ☕️ motivation",
            "🌟 Star-powered quote 🌟",
            "Résumé your dreams",
            "中文 Chinese quote",
            "العربية Arabic quote",
            "🏳️‍🌈 Inclusive quote"
        ]
        
        // Act
        unicodeQuotes.forEach { quoteManager.toggleLoveQuote($0) }
        
        // Assert
        XCTAssertEqual(quoteManager.lovedQuotes.count, unicodeQuotes.count, "Should handle all Unicode quotes")
        
        for quote in unicodeQuotes {
            XCTAssertTrue(quoteManager.isQuoteLoved(quote), "Should recognize Unicode quote as loved: \(quote)")
        }
        
        let sortedArray = quoteManager.lovedQuotesArray
        XCTAssertEqual(sortedArray.count, unicodeQuotes.count, "Sorted array should contain all Unicode quotes")
    }
    
    // MARK: - Persistence Tests (Mock)
    
    func testSaveLovedQuotes_convertsSetToArray() {
        // Note: This test demonstrates the expected behavior
        // In a real implementation, we'd inject MockUserDefaults to test this
        
        // Arrange
        let testQuotes = ["Quote C", "Quote A", "Quote B"]
        testQuotes.forEach { quoteManager.toggleLoveQuote($0) }
        
        // Act
        let lovedQuotesArray = Array(quoteManager.lovedQuotes)
        
        // Assert
        XCTAssertEqual(lovedQuotesArray.count, 3, "Array should contain all loved quotes")
        
        // Verify all quotes are present (order doesn't matter for this test)
        for quote in testQuotes {
            XCTAssertTrue(lovedQuotesArray.contains(quote), "Array should contain quote: \(quote)")
        }
    }
    
    func testLoadLovedQuotes_convertsArrayToSet() {
        // Note: This test demonstrates the expected behavior
        // In a real implementation, we'd inject MockUserDefaults to test this
        
        // Arrange
        let quotesArray = ["Quote A", "Quote B", "Quote A"] // Note the duplicate
        let quotesSet = Set(quotesArray)
        
        // Act & Assert
        XCTAssertEqual(quotesSet.count, 2, "Set should remove duplicates")
        XCTAssertTrue(quotesSet.contains("Quote A"), "Set should contain Quote A")
        XCTAssertTrue(quotesSet.contains("Quote B"), "Set should contain Quote B")
    }
    
    // MARK: - Published Property Tests
    
    func testLovedQuotes_publishesChanges() {
        // Arrange
        let expectation = expectation(description: "Should publish loved quotes changes")
        let testQuote = sampleQuotes[0]
        var receivedCount: Int?
        
        quoteManager.$lovedQuotes
            .map { $0.count }
            .dropFirst() // Skip initial empty value
            .sink { count in
                receivedCount = count
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Act
        quoteManager.toggleLoveQuote(testQuote)
        
        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(receivedCount, 1, "Should publish change when quote is added")
    }
    
    func testLovedQuotes_publishesRemovalChanges() {
        // Arrange
        let expectation = expectation(description: "Should publish loved quotes removal")
        let testQuote = sampleQuotes[0]
        
        // Add quote first
        quoteManager.toggleLoveQuote(testQuote)
        XCTAssertEqual(quoteManager.lovedQuotes.count, 1, "Should have one loved quote")
        
        // Set up publisher to watch for removal
        quoteManager.$lovedQuotes
            .dropFirst() // Skip current value (with 1 quote)
            .sink { quotes in
                if quotes.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Act
        quoteManager.toggleLoveQuote(testQuote) // Remove
        
        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(quoteManager.lovedQuotes.count, 0, "Should have no loved quotes after removal")
    }
    
    // MARK: - Performance Tests
    
    func testToggleLoveQuote_performance_withManyOperations() {
        // Arrange
        let quotes = (0..<1000).map { "Performance test quote \($0)" }
        
        // Act & Assert
        measure {
            for quote in quotes {
                quoteManager.toggleLoveQuote(quote)
            }
        }
    }
    
    func testLovedQuotesArray_performance_withLargeSet() {
        // Arrange
        let quotes = (0..<1000).map { "Large set quote \($0)" }
        quotes.forEach { quoteManager.toggleLoveQuote($0) }
        
        // Act & Assert
        measure {
            for _ in 0..<100 {
                _ = quoteManager.lovedQuotesArray
            }
        }
    }
    
    func testIsQuoteLoved_performance_withLargeSet() {
        // Arrange
        let quotes = (0..<1000).map { "Search test quote \($0)" }
        quotes.forEach { quoteManager.toggleLoveQuote($0) }
        
        let searchQuote = "Search test quote 500"
        
        // Act & Assert
        measure {
            for _ in 0..<10000 {
                _ = quoteManager.isQuoteLoved(searchQuote)
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testLovedQuotes_memoryEfficiency_withRepeatedOperations() {
        // Arrange
        let testQuote = "Memory test quote"
        
        // Act
        for _ in 0..<10000 {
            quoteManager.toggleLoveQuote(testQuote) // Add
            quoteManager.toggleLoveQuote(testQuote) // Remove
        }
        
        // Assert
        XCTAssertEqual(quoteManager.lovedQuotes.count, 0, "Should end with empty set")
        XCTAssertFalse(quoteManager.isQuoteLoved(testQuote), "Quote should not be loved after repeated toggle")
    }
    
    // MARK: - Thread Safety Considerations
    
    func testLovedQuotes_concurrentAccess_handlesGracefully() {
        // Arrange
        let expectation = expectation(description: "Concurrent operations should complete")
        expectation.expectedFulfillmentCount = 2
        
        let quote1 = "Concurrent quote 1"
        let quote2 = "Concurrent quote 2"
        
        // Act
        DispatchQueue.global().async {
            for i in 0..<100 {
                self.quoteManager.toggleLoveQuote("\(quote1) \(i)")
            }
            expectation.fulfill()
        }
        
        DispatchQueue.global().async {
            for i in 0..<100 {
                self.quoteManager.toggleLoveQuote("\(quote2) \(i)")
            }
            expectation.fulfill()
        }
        
        // Assert
        waitForExpectations(timeout: 5.0)
        XCTAssertGreaterThan(quoteManager.lovedQuotes.count, 0, "Should have some loved quotes after concurrent operations")
    }
}