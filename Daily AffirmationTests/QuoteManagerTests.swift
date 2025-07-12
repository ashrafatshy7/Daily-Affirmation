//
//  QuoteManagerTests.swift
//  Daily AffirmationTests
//
//  Created by QA Engineer on 12/07/2025.
//

import XCTest
import UserNotifications
import Combine
@testable import Daily_Affirmation

// MARK: - Mock Classes

class MockUserDefaults: UserDefaults {
    private var storage: [String: Any] = [:]
    
    override func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }
    
    override func object(forKey defaultName: String) -> Any? {
        return storage[defaultName]
    }
    
    override func bool(forKey defaultName: String) -> Bool {
        return storage[defaultName] as? Bool ?? false
    }
    
    override func integer(forKey defaultName: String) -> Int {
        return storage[defaultName] as? Int ?? 0
    }
    
    override func string(forKey defaultName: String) -> String? {
        return storage[defaultName] as? String
    }
    
    override func array(forKey defaultName: String) -> [Any]? {
        return storage[defaultName] as? [Any]
    }
    
    func clearAll() {
        storage.removeAll()
    }
}

class MockBundle {
    var mockData: Data?
    var mockURL: URL?
    
    func url(forResource name: String?, withExtension ext: String?) -> URL? {
        return mockURL
    }
    
    func data(contentsOf url: URL) throws -> Data {
        guard let data = mockData else {
            throw NSError(domain: "MockBundle", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found"])
        }
        return data
    }
}

final class QuoteManagerTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var mockUserDefaults: MockUserDefaults!
    private var mockBundle: MockBundle!
    private var quoteManager: QuoteManager!
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
        mockBundle = MockBundle()
        cancellables = Set<AnyCancellable>()
        
        // Create QuoteManager with dependency injection capability
        quoteManager = QuoteManager()
        
        // Inject mock data for quotes
        let quotesData = try JSONEncoder().encode(sampleQuotes)
        mockBundle.mockData = quotesData
        mockBundle.mockURL = URL(string: "file://mock/quotes.json")
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        quoteManager = nil
        mockBundle = nil
        mockUserDefaults?.clearAll()
        mockUserDefaults = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testInit_setsDefaultValues() {
        // Arrange & Act
        let manager = QuoteManager()
        
        // Assert
        XCTAssertFalse(manager.dailyNotifications, "Daily notifications should be disabled by default")
        XCTAssertEqual(manager.fontSize, .medium, "Font size should be medium by default")
        XCTAssertEqual(manager.notificationMode, .range, "Notification mode should be range by default")
        XCTAssertEqual(manager.notificationCount, 1, "Notification count should be 1 by default")
        XCTAssertTrue(manager.lovedQuotes.isEmpty, "Loved quotes should be empty by default")
    }
    
    func testInit_setsDefaultNotificationTimes() {
        // Arrange & Act
        let manager = QuoteManager()
        let calendar = Calendar.current
        
        // Assert
        let startHour = calendar.component(.hour, from: manager.startTime)
        let endHour = calendar.component(.hour, from: manager.endTime)
        let singleHour = calendar.component(.hour, from: manager.singleNotificationTime)
        
        XCTAssertEqual(startHour, 9, "Start time should default to 9:00 AM")
        XCTAssertEqual(endHour, 10, "End time should default to 10:00 AM")
        XCTAssertEqual(singleHour, 9, "Single notification time should default to 9:00 AM")
    }
    
    // MARK: - Quote Loading Tests
    
    func testLoadQuotes_withValidJSON_populatesQuotesArray() {
        // This test would require dependency injection or a testable version of loadQuotes()
        // For now, we test the result after initialization
        
        // Assert
        XCTAssertFalse(quoteManager.quotes.isEmpty, "Quotes should be loaded from bundle")
    }
    
    func testSetDailyQuote_withValidQuotes_setsDailyQuote() {
        // Arrange
        let manager = QuoteManager()
        let today = Date()
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        
        // Act
        let currentQuote = manager.currentQuote
        
        // Assert
        XCTAssertFalse(currentQuote.isEmpty, "Should have a current quote")
        XCTAssertNotEqual(currentQuote, "Loading...", "Should not be in loading state")
    }
    
    // MARK: - Quote Navigation Tests
    
    func testNextQuote_changesCurrentQuote() {
        // Arrange
        let initialQuote = quoteManager.currentQuote
        
        // Act
        quoteManager.nextQuote()
        
        // Assert
        let newQuote = quoteManager.currentQuote
        XCTAssertNotEqual(newQuote, initialQuote, "Quote should change after nextQuote()")
    }
    
    func testPreviousQuote_fromInitialPosition_doesNotChangeQuote() {
        // Arrange
        let initialQuote = quoteManager.currentQuote
        
        // Act
        quoteManager.previousQuote()
        
        // Assert
        XCTAssertEqual(quoteManager.currentQuote, initialQuote, "Quote should not change when no previous quote exists")
    }
    
    func testPreviousQuote_afterNextQuote_returnsToInitialQuote() {
        // Arrange
        let initialQuote = quoteManager.currentQuote
        quoteManager.nextQuote()
        
        // Act
        quoteManager.previousQuote()
        
        // Assert
        XCTAssertEqual(quoteManager.currentQuote, initialQuote, "Should return to initial quote after next then previous")
    }
    
    // MARK: - Loved Quotes Tests
    
    func testToggleLoveQuote_withNewQuote_addsToLovedQuotes() {
        // Arrange
        let testQuote = "Test quote for loving"
        XCTAssertFalse(quoteManager.isQuoteLoved(testQuote), "Quote should not be loved initially")
        
        // Act
        quoteManager.toggleLoveQuote(testQuote)
        
        // Assert
        XCTAssertTrue(quoteManager.isQuoteLoved(testQuote), "Quote should be loved after toggle")
        XCTAssertTrue(quoteManager.lovedQuotes.contains(testQuote), "Quote should be in loved quotes set")
    }
    
    func testToggleLoveQuote_withLovedQuote_removesFromLovedQuotes() {
        // Arrange
        let testQuote = "Test quote for loving"
        quoteManager.toggleLoveQuote(testQuote) // Add to loved quotes
        XCTAssertTrue(quoteManager.isQuoteLoved(testQuote), "Quote should be loved initially")
        
        // Act
        quoteManager.toggleLoveQuote(testQuote) // Remove from loved quotes
        
        // Assert
        XCTAssertFalse(quoteManager.isQuoteLoved(testQuote), "Quote should not be loved after toggle")
        XCTAssertFalse(quoteManager.lovedQuotes.contains(testQuote), "Quote should not be in loved quotes set")
    }
    
    func testIsQuoteLoved_withUnlovedQuote_returnsFalse() {
        // Arrange
        let testQuote = "Unloved quote"
        
        // Act & Assert
        XCTAssertFalse(quoteManager.isQuoteLoved(testQuote), "Unknown quote should not be loved")
    }
    
    func testLovedQuotesArray_returnsAlphabeticallySortedArray() {
        // Arrange
        let quotes = ["Zebra quote", "Alpha quote", "Beta quote"]
        quotes.forEach { quoteManager.toggleLoveQuote($0) }
        
        // Act
        let sortedQuotes = quoteManager.lovedQuotesArray
        
        // Assert
        XCTAssertEqual(sortedQuotes, ["Alpha quote", "Beta quote", "Zebra quote"], 
                      "Loved quotes should be sorted alphabetically")
    }
    
    func testLovedQuotesArray_withEmptySet_returnsEmptyArray() {
        // Act
        let quotes = quoteManager.lovedQuotesArray
        
        // Assert
        XCTAssertTrue(quotes.isEmpty, "Should return empty array when no loved quotes")
    }
    
    // MARK: - Font Size Tests
    
    func testFontSize_allCases_haveValidDisplayNames() {
        // Arrange & Act
        for fontSize in QuoteManager.FontSize.allCases {
            let displayName = fontSize.displayName(using: quoteManager)
            
            // Assert
            XCTAssertFalse(displayName.isEmpty, "Font size \(fontSize) should have a display name")
        }
    }
    
    func testFontSize_multipliers_areValidValues() {
        // Arrange & Act & Assert
        XCTAssertEqual(QuoteManager.FontSize.small.multiplier, 0.9, "Small font should have 0.9 multiplier")
        XCTAssertEqual(QuoteManager.FontSize.medium.multiplier, 1.0, "Medium font should have 1.0 multiplier")
        XCTAssertEqual(QuoteManager.FontSize.large.multiplier, 1.2, "Large font should have 1.2 multiplier")
    }
    
    func testSetFontSize_triggersPublishedUpdate() {
        // Arrange
        let expectation = expectation(description: "Font size should update")
        var receivedFontSize: QuoteManager.FontSize?
        
        quoteManager.$fontSize
            .dropFirst() // Skip initial value
            .sink { fontSize in
                receivedFontSize = fontSize
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Act
        quoteManager.fontSize = .large
        
        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(receivedFontSize, .large, "Published font size should update")
    }
    
    // MARK: - Notification Mode Tests
    
    func testNotificationMode_allCases_haveValidDisplayNames() {
        // Arrange & Act
        for mode in QuoteManager.NotificationMode.allCases {
            let displayName = mode.displayName(using: quoteManager)
            
            // Assert
            XCTAssertFalse(displayName.isEmpty, "Notification mode \(mode) should have a display name")
        }
    }
    
    func testSetNotificationMode_triggersPublishedUpdate() {
        // Arrange
        let expectation = expectation(description: "Notification mode should update")
        var receivedMode: QuoteManager.NotificationMode?
        
        quoteManager.$notificationMode
            .dropFirst() // Skip initial value
            .sink { mode in
                receivedMode = mode
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Act
        quoteManager.notificationMode = .single
        
        // Assert
        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(receivedMode, .single, "Published notification mode should update")
    }
    
    // MARK: - Notification Time Calculation Tests
    
    func testCalculateNotificationTimes_withValidRange_returnsCorrectTimes() {
        // Arrange
        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
        let endTime = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: now)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        quoteManager.notificationCount = 3
        
        // Act
        let times = quoteManager.calculateNotificationTimes()
        
        // Assert
        XCTAssertEqual(times.count, 3, "Should return requested number of notification times")
        // Check that times are sorted
        for i in 1..<times.count {
            XCTAssertLessThanOrEqual(times[i-1], times[i], "Notification times should be sorted")
        }
        
        // Check that times are within range
        for time in times {
            let hour = calendar.component(.hour, from: time)
            XCTAssertGreaterThanOrEqual(hour, 9, "All times should be at or after start time")
            XCTAssertLessThanOrEqual(hour, 11, "All times should be at or before end time")
        }
    }
    
    func testCalculateNotificationTimes_withSameStartAndEndTime_returnsSingleTime() {
        // Arrange
        let calendar = Calendar.current
        let now = Date()
        let sameTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
        
        quoteManager.startTime = sameTime
        quoteManager.endTime = sameTime
        
        // Act
        let times = quoteManager.calculateNotificationTimes()
        
        // Assert
        XCTAssertEqual(times.count, 1, "Should return single time when start equals end")
    }
    
    func testCalculateNotificationTimes_withCrossMidnightRange_handlesCorrectly() {
        // Arrange
        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now)!
        let endTime = calendar.date(bySettingHour: 2, minute: 0, second: 0, of: now)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        quoteManager.notificationCount = 2
        
        // Act
        let times = quoteManager.calculateNotificationTimes()
        
        // Assert
        XCTAssertEqual(times.count, 2, "Should handle cross-midnight times")
        // Check that times are sorted even with cross-midnight
        for i in 1..<times.count {
            XCTAssertLessThanOrEqual(times[i-1], times[i], "Times should be sorted even with cross-midnight")
        }
    }
    
    // MARK: - Time Validation Tests
    
    func testIsValidTimeRange_withDifferentTimes_returnsTrue() {
        // Arrange
        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
        let endTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        
        // Act & Assert
        XCTAssertTrue(quoteManager.isValidTimeRange, "Different start and end times should be valid")
    }
    
    func testIsValidTimeRange_withSameTimes_returnsFalse() {
        // Arrange
        let calendar = Calendar.current
        let now = Date()
        let sameTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
        
        quoteManager.startTime = sameTime
        quoteManager.endTime = sameTime
        
        // Act & Assert
        XCTAssertFalse(quoteManager.isValidTimeRange, "Same start and end times should be invalid")
    }
    
    func testMaxNotificationsAllowed_withValidRange_returnsCorrectMaximum() {
        // Arrange
        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
        let endTime = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: now)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        
        // Act
        let maxAllowed = quoteManager.maxNotificationsAllowed
        
        // Assert
        XCTAssertGreaterThan(maxAllowed, 0, "Should allow at least one notification")
        XCTAssertLessThanOrEqual(maxAllowed, 10, "Should not exceed hard cap of 10")
    }
    
    // MARK: - Localization Tests
    
    func testLocalizedString_withValidKey_returnsString() {
        // Arrange
        let key = "settings"
        
        // Act
        let localizedString = quoteManager.localizedString(key)
        
        // Assert
        XCTAssertFalse(localizedString.isEmpty, "Should return a non-empty string")
    }
    
    func testLocalizedString_withInvalidKey_returnsKey() {
        // Arrange
        let invalidKey = "nonexistent_key_12345"
        
        // Act
        let localizedString = quoteManager.localizedString(invalidKey)
        
        // Assert
        // Note: This behavior depends on how NSLocalizedString handles missing keys
        XCTAssertEqual(localizedString, invalidKey, "Should return key when localization not found")
    }
    
    // MARK: - Edge Cases and Error Handling
    
    func testNotificationCount_boundaryValues_stayWithinLimits() {
        // Arrange & Act
        quoteManager.notificationCount = -5
        let negativeResult = quoteManager.notificationCount
        
        quoteManager.notificationCount = 1000
        let largeResult = quoteManager.notificationCount
        
        // Assert
        XCTAssertGreaterThanOrEqual(negativeResult, 1, "Notification count should not go below 1")
        XCTAssertLessThanOrEqual(largeResult, quoteManager.maxNotificationsAllowed, "Should not exceed maximum allowed")
    }
    
    func testGetPreviewQuote_withValidOffsets_returnsValidQuotes() {
        // Arrange & Act
        let currentPreview = quoteManager.getPreviewQuote(offset: 0)
        let nextPreview = quoteManager.getPreviewQuote(offset: 1)
        let previousPreview = quoteManager.getPreviewQuote(offset: -1)
        
        // Assert
        XCTAssertFalse(currentPreview.isEmpty, "Current preview should not be empty")
        XCTAssertFalse(nextPreview.isEmpty, "Next preview should not be empty")
        XCTAssertFalse(previousPreview.isEmpty, "Previous preview should not be empty")
    }
    
    // MARK: - Performance Tests
    
    func testToggleLoveQuote_performance_withManyQuotes() {
        // Arrange
        let testQuotes = (0..<1000).map { "Test quote \($0)" }
        
        // Act & Assert
        measure {
            for quote in testQuotes {
                quoteManager.toggleLoveQuote(quote)
            }
        }
    }
    
    func testCalculateNotificationTimes_performance_withMaximumCount() {
        // Arrange
        let calendar = Calendar.current
        let now = Date()
        let startTime = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now)!
        let endTime = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: now)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        quoteManager.notificationCount = 10
        
        // Act & Assert
        measure {
            _ = quoteManager.calculateNotificationTimes()
        }
    }
    
    // MARK: - Threading and Async Tests
    
    func testPublishedProperties_updateOnMainThread() {
        // Arrange
        let expectation = expectation(description: "Should receive update on main thread")
        
        quoteManager.dailyNotificationsPublisher
            .dropFirst()
            .sink { _ in
                XCTAssertTrue(Thread.isMainThread, "Published updates should be on main thread")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Act
        DispatchQueue.global().async {
            self.quoteManager.dailyNotifications = true
        }
        
        // Assert
        waitForExpectations(timeout: 1.0)
    }
}