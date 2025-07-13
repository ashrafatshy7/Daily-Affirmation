//
//  QuoteHistoryTests.swift
//  Daily AffirmationTests
//
//  Created by QA Engineer on 12/07/2025.
//

import XCTest
@testable import Daily_Affirmation

final class QuoteHistoryTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var sampleQuotes: [String]!
    private var quoteHistory: QuoteHistory!
    
    // MARK: - Setup and Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sampleQuotes = [
            "Growth happens when finding solutions in small steps.",
            "Resilience shines amidst setting goals in all endeavors.",
            "Passion drives fueling creativity across every obstacle.",
            "Joy emerges from perfecting craft toward your dreams.",
            "Harness the power of extending grace despite doubts."
        ]
        quoteHistory = QuoteHistory(initialQuote: sampleQuotes[0], availableQuotes: sampleQuotes)
    }
    
    override func tearDownWithError() throws {
        sampleQuotes = nil
        quoteHistory = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testInit_withValidQuoteAndArray_setsUpCorrectly() {
        // Arrange
        let initialQuote = "Test quote"
        let quotes = ["Test quote", "Another quote"]
        
        // Act
        let history = QuoteHistory(initialQuote: initialQuote, availableQuotes: quotes)
        
        // Assert
        XCTAssertEqual(history.currentQuote, initialQuote, "Initial quote should be set correctly")
    }
    
    func testInit_withEmptyQuotesArray_stillWorksWithInitialQuote() {
        // Arrange
        let initialQuote = "Test quote"
        let emptyQuotes: [String] = []
        
        // Act
        let history = QuoteHistory(initialQuote: initialQuote, availableQuotes: emptyQuotes)
        
        // Assert
        XCTAssertEqual(history.currentQuote, initialQuote, "Should work with empty quotes array")
    }
    
    // MARK: - Current Quote Tests
    
    func testCurrentQuote_withValidHistory_returnsCorrectQuote() {
        // Arrange & Act
        let currentQuote = quoteHistory.currentQuote
        
        // Assert
        XCTAssertEqual(currentQuote, sampleQuotes[0], "Should return the initial quote")
    }
    
    func testCurrentQuote_afterMovingNext_returnsUpdatedQuote() {
        // Arrange
        let expectedQuote = quoteHistory.moveNext()
        
        // Act
        let currentQuote = quoteHistory.currentQuote
        
        // Assert
        XCTAssertEqual(currentQuote, expectedQuote, "Current quote should match the quote from moveNext()")
    }
    
    // MARK: - Move Next Tests
    
    func testMoveNext_fromInitialPosition_generatesNewQuote() {
        // Arrange
        let initialQuote = quoteHistory.currentQuote
        
        // Act
        let nextQuote = quoteHistory.moveNext()
        
        // Assert
        XCTAssertNotEqual(nextQuote, initialQuote, "Next quote should be different from initial")
        XCTAssertTrue(sampleQuotes.contains(nextQuote), "Next quote should be from available quotes")
    }
    
    func testMoveNext_multipleTimes_maintainsHistory() {
        // Arrange & Act
        let firstNext = quoteHistory.moveNext()
        let secondNext = quoteHistory.moveNext()
        let thirdNext = quoteHistory.moveNext()
        
        // Assert
        XCTAssertNotEqual(firstNext, secondNext, "Sequential quotes should be different")
        XCTAssertNotEqual(secondNext, thirdNext, "Sequential quotes should be different")
        XCTAssertEqual(quoteHistory.currentQuote, thirdNext, "Current quote should be the latest")
    }
    
    func testMoveNext_withSingleQuoteArray_returnsOnlyAvailableQuote() {
        // Arrange
        let singleQuote = "Only quote"
        let singleQuoteArray = [singleQuote]
        let history = QuoteHistory(initialQuote: singleQuote, availableQuotes: singleQuoteArray)
        
        // Act
        let nextQuote = history.moveNext()
        
        // Assert
        XCTAssertEqual(nextQuote, singleQuote, "Should return the only available quote")
    }
    
    func testMoveNext_withEmptyQuotesArray_returnsFallbackQuote() {
        // Arrange
        let initialQuote = "Test quote"
        let emptyQuotes: [String] = []
        let history = QuoteHistory(initialQuote: initialQuote, availableQuotes: emptyQuotes)
        
        // Act
        let nextQuote = history.moveNext()
        
        // Assert
        XCTAssertEqual(nextQuote, "Stay inspired!", "Should return fallback quote when no quotes available")
    }
    
    // MARK: - Move Previous Tests
    
    func testMovePrevious_fromInitialPosition_returnsNil() {
        // Arrange & Act
        let previousQuote = quoteHistory.movePrevious()
        
        // Assert
        XCTAssertNil(previousQuote, "Should return nil when at initial position")
    }
    
    func testMovePrevious_afterMoveNext_returnsInitialQuote() {
        // Arrange
        let initialQuote = quoteHistory.currentQuote
        _ = quoteHistory.moveNext()
        
        // Act
        let previousQuote = quoteHistory.movePrevious()
        
        // Assert
        XCTAssertEqual(previousQuote, initialQuote, "Should return initial quote when moving back")
    }
    
    func testMovePrevious_multipleMoves_navigatesCorrectly() {
        // Arrange
        let initialQuote = quoteHistory.currentQuote
        let firstNext = quoteHistory.moveNext()
        let secondNext = quoteHistory.moveNext()
        
        // Act
        let firstPrevious = quoteHistory.movePrevious()
        let secondPrevious = quoteHistory.movePrevious()
        
        // Assert
        XCTAssertEqual(firstPrevious, firstNext, "First previous should match first next")
        XCTAssertEqual(secondPrevious, initialQuote, "Second previous should match initial quote")
    }
    
    func testMovePrevious_beyondHistory_staysAtBeginning() {
        // Arrange
        _ = quoteHistory.moveNext()
        _ = quoteHistory.movePrevious()
        
        // Act
        let extraPrevious = quoteHistory.movePrevious()
        
        // Assert
        XCTAssertNil(extraPrevious, "Should return nil when trying to go before beginning")
    }
    
    // MARK: - Get Preview Quote Tests
    
    func testGetPreviewQuote_withZeroOffset_returnsCurrentQuote() {
        // Arrange & Act
        let previewQuote = quoteHistory.getPreviewQuote(offset: 0)
        
        // Assert
        XCTAssertEqual(previewQuote, quoteHistory.currentQuote, "Offset 0 should return current quote")
    }
    
    func testGetPreviewQuote_withNegativeOneOffset_atInitialPosition_returnsCurrentQuote() {
        // Arrange & Act
        let previewQuote = quoteHistory.getPreviewQuote(offset: -1)
        
        // Assert
        XCTAssertEqual(previewQuote, quoteHistory.currentQuote, "Should return current quote when no previous")
    }
    
    func testGetPreviewQuote_withNegativeOneOffset_afterMoveNext_returnsPreviousQuote() {
        // Arrange
        let initialQuote = quoteHistory.currentQuote
        _ = quoteHistory.moveNext()
        
        // Act
        let previewQuote = quoteHistory.getPreviewQuote(offset: -1)
        
        // Assert
        XCTAssertEqual(previewQuote, initialQuote, "Should return previous quote from history")
    }
    
    func testGetPreviewQuote_withPositiveOneOffset_generatesNextQuote() {
        // Arrange & Act
        let previewQuote = quoteHistory.getPreviewQuote(offset: 1)
        
        // Assert
        XCTAssertTrue(sampleQuotes.contains(previewQuote), "Preview should be from available quotes")
        XCTAssertNotEqual(previewQuote, quoteHistory.currentQuote, "Preview should be different from current")
    }
    
    func testGetPreviewQuote_withPositiveOneOffset_usesCachedQuote() {
        // Arrange
        let firstPreview = quoteHistory.getPreviewQuote(offset: 1)
        
        // Act
        let secondPreview = quoteHistory.getPreviewQuote(offset: 1)
        
        // Assert
        XCTAssertEqual(firstPreview, secondPreview, "Should return same cached preview")
    }
    
    func testGetPreviewQuote_withPositiveOneOffset_afterMoveNext_usesHistoryQuote() {
        // Arrange
        _ = quoteHistory.getPreviewQuote(offset: 1) // Generate cache
        let nextQuote = quoteHistory.moveNext()
        
        // Act
        let previewQuote = quoteHistory.getPreviewQuote(offset: 1)
        
        // Assert
        XCTAssertNotEqual(previewQuote, nextQuote, "Should generate new preview after moving")
    }
    
    func testGetPreviewQuote_withInvalidOffset_returnsCurrentQuote() {
        // Arrange & Act
        let previewQuote = quoteHistory.getPreviewQuote(offset: 5)
        
        // Assert
        XCTAssertEqual(previewQuote, quoteHistory.currentQuote, "Invalid offset should return current quote")
    }
    
    // MARK: - Cache Management Tests
    
    func testCacheClearing_onMoveNext_clearsNextQuoteCache() {
        // Arrange
        let firstPreview = quoteHistory.getPreviewQuote(offset: 1)
        
        // Act
        _ = quoteHistory.moveNext()
        let secondPreview = quoteHistory.getPreviewQuote(offset: 1)
        
        // Assert
        XCTAssertNotEqual(firstPreview, secondPreview, "Cache should be cleared after moveNext")
    }
    
    func testCacheClearing_onMovePrevious_clearsNextQuoteCache() {
        // Arrange
        _ = quoteHistory.moveNext() // Move forward to enable going back
        let preview = quoteHistory.getPreviewQuote(offset: 1)
        
        // Act
        _ = quoteHistory.movePrevious()
        let newPreview = quoteHistory.getPreviewQuote(offset: 1)
        
        // Assert
        XCTAssertNotEqual(preview, newPreview, "Cache should be cleared after movePrevious")
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testQuoteGeneration_avoidsCurrentQuote_whenMultipleQuotesAvailable() {
        // Arrange
        var generatedQuotes: Set<String> = []
        
        // Act
        for _ in 0..<10 {
            let nextQuote = quoteHistory.getPreviewQuote(offset: 1)
            generatedQuotes.insert(nextQuote)
        }
        
        // Assert
        XCTAssertFalse(generatedQuotes.contains(quoteHistory.currentQuote), 
                      "Generated quotes should not include current quote")
        XCTAssertTrue(generatedQuotes.count >= 1, "Should generate at least one different quote")
    }
    
    func testQuoteGeneration_withOnlyCurrentQuoteInArray_returnsCurrentQuote() {
        // Arrange
        let currentQuote = "Only quote"
        let singleQuoteArray = [currentQuote]
        let history = QuoteHistory(initialQuote: currentQuote, availableQuotes: singleQuoteArray)
        
        // Act
        let nextQuote = history.getPreviewQuote(offset: 1)
        
        // Assert
        XCTAssertEqual(nextQuote, currentQuote, "Should return current quote when it's the only option")
    }
    
    func testComplexNavigation_forwardAndBackward_maintainsConsistency() {
        // Arrange
        let initialQuote = quoteHistory.currentQuote
        
        // Act
        let next1 = quoteHistory.moveNext()
        let next2 = quoteHistory.moveNext()
        let back1 = quoteHistory.movePrevious()
        let back2 = quoteHistory.movePrevious()
        
        // Assert
        XCTAssertEqual(back1, next1, "Moving back should return to previous position")
        XCTAssertEqual(back2, initialQuote, "Moving back should return to initial position")
        XCTAssertEqual(quoteHistory.currentQuote, initialQuote, "Current quote should be initial after navigation")
    }
    
    // MARK: - Performance Tests
    
    func testMoveNext_performance_withLargeQuoteArray() {
        // Arrange
        let largeQuoteArray = Array(repeating: "Test quote", count: 1000)
        let history = QuoteHistory(initialQuote: "Initial", availableQuotes: largeQuoteArray)
        
        // Act & Assert
        measure {
            for _ in 0..<100 {
                _ = history.moveNext()
            }
        }
    }
    
    func testGetPreviewQuote_performance_withRepeatedCalls() {
        // Act & Assert
        measure {
            for _ in 0..<1000 {
                _ = quoteHistory.getPreviewQuote(offset: 1)
            }
        }
    }
}