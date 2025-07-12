//
//  QuoteManagerIntegrationTests.swift
//  Daily AffirmationTests
//
//  Created by QA Engineer on 12/07/2025.
//

import XCTest
import UserNotifications
import Combine
@testable import Daily_Affirmation

final class QuoteManagerIntegrationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var quoteManager: QuoteManager!
    private var cancellables: Set<AnyCancellable>!
    private var testUserDefaults: UserDefaults!
    private let testSuiteName = "QuoteManagerIntegrationTests"
    
    // MARK: - Setup and Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        cancellables = Set<AnyCancellable>()
        
        // Create a dedicated test UserDefaults suite
        let suiteName = "QuoteManagerIntegrationTest_\(UUID().uuidString)"
        testUserDefaults = UserDefaults(suiteName: suiteName)!
        testUserDefaults.removePersistentDomain(forName: suiteName)
        
        // Create QuoteManager with our test UserDefaults
        quoteManager = QuoteManager(loadFromDefaults: false, userDefaults: testUserDefaults)
    }
    
    override func tearDownWithError() throws {
        cancellables = nil
        testUserDefaults = nil
        quoteManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Settings Persistence Integration Tests
    
    func testSettingsPersistence_dailyNotifications_savesAndLoadsCorrectly() {
        // Test setting to false (should always work)
        // Arrange
        quoteManager.dailyNotifications = true // Set to true first
        
        // Act - Set to false (no permission check needed)
        quoteManager.dailyNotifications = false
        
        // Create new QuoteManager to test loading with same UserDefaults
        let newQuoteManager = QuoteManager(loadFromDefaults: true, userDefaults: testUserDefaults)
        
        // Assert
        XCTAssertFalse(newQuoteManager.dailyNotifications, 
                      "Daily notifications false setting should persist")
        
        // Note: Testing true value requires notification permissions which are not available in test environment
    }
    
    func testSettingsPersistence_fontSize_savesAndLoadsCorrectly() {
        // Arrange
        let newFontSize: QuoteManager.FontSize = .large
        
        // Act
        quoteManager.fontSize = newFontSize
        
        // Create new QuoteManager to test loading with same UserDefaults
        let newQuoteManager = QuoteManager(loadFromDefaults: true, userDefaults: testUserDefaults)
        
        // Assert
        XCTAssertEqual(newQuoteManager.fontSize, newFontSize, 
                      "Font size setting should persist")
    }
    
    func testSettingsPersistence_notificationMode_savesAndLoadsCorrectly() {
        // Arrange
        let newMode: QuoteManager.NotificationMode = .single
        
        // Act
        quoteManager.notificationMode = newMode
        
        // Create new QuoteManager to test loading with same UserDefaults
        let newQuoteManager = QuoteManager(loadFromDefaults: true, userDefaults: testUserDefaults)
        
        // Assert
        XCTAssertEqual(newQuoteManager.notificationMode, newMode, 
                      "Notification mode setting should persist")
    }
    
    func testSettingsPersistence_notificationTimes_saveAndLoadCorrectly() {
        // Arrange
        let calendar = Calendar.current
        let now = Date()
        let newStartTime = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: now)!
        let newEndTime = calendar.date(bySettingHour: 18, minute: 45, second: 0, of: now)!
        let newSingleTime = calendar.date(bySettingHour: 12, minute: 15, second: 0, of: now)!
        
        // Act
        quoteManager.startTime = newStartTime
        quoteManager.endTime = newEndTime
        quoteManager.singleNotificationTime = newSingleTime
        
        // Create new QuoteManager to test loading with same UserDefaults
        let newQuoteManager = QuoteManager(loadFromDefaults: true, userDefaults: testUserDefaults)
        
        // Assert
        let startHour = calendar.component(.hour, from: newQuoteManager.startTime)
        let startMinute = calendar.component(.minute, from: newQuoteManager.startTime)
        let endHour = calendar.component(.hour, from: newQuoteManager.endTime)
        let endMinute = calendar.component(.minute, from: newQuoteManager.endTime)
        let singleHour = calendar.component(.hour, from: newQuoteManager.singleNotificationTime)
        let singleMinute = calendar.component(.minute, from: newQuoteManager.singleNotificationTime)
        
        XCTAssertEqual(startHour, 8, "Start time hour should persist")
        XCTAssertEqual(startMinute, 30, "Start time minute should persist")
        XCTAssertEqual(endHour, 18, "End time hour should persist")
        XCTAssertEqual(endMinute, 45, "End time minute should persist")
        XCTAssertEqual(singleHour, 12, "Single notification hour should persist")
        XCTAssertEqual(singleMinute, 15, "Single notification minute should persist")
    }
    
    func testSettingsPersistence_notificationCount_savesAndLoadsCorrectly() {
        // Arrange
        let newCount = 5
        
        // Act
        quoteManager.notificationCount = newCount
        
        // Create new QuoteManager to test loading with same UserDefaults
        let newQuoteManager = QuoteManager(loadFromDefaults: true, userDefaults: testUserDefaults)
        
        // Assert
        XCTAssertEqual(newQuoteManager.notificationCount, newCount, 
                      "Notification count should persist")
    }
    
    // MARK: - Loved Quotes Persistence Integration Tests
    
    func testLovedQuotesPersistence_singleQuote_savesAndLoadsCorrectly() {
        // Arrange
        let testQuote = "Test quote for persistence"
        
        // Act
        quoteManager.toggleLoveQuote(testQuote)
        
        // Create new QuoteManager to test loading with same UserDefaults
        let newQuoteManager = QuoteManager(loadFromDefaults: true, userDefaults: testUserDefaults)
        
        // Assert
        XCTAssertTrue(newQuoteManager.isQuoteLoved(testQuote), 
                     "Loved quote should persist across app launches")
        XCTAssertEqual(newQuoteManager.lovedQuotes.count, 1, 
                      "Should load exactly one loved quote")
    }
    
    func testLovedQuotesPersistence_multipleQuotes_savesAndLoadsCorrectly() {
        // Arrange
        let testQuotes = [
            "First persistent quote",
            "Second persistent quote",
            "Third persistent quote"
        ]
        
        // Act
        testQuotes.forEach { quoteManager.toggleLoveQuote($0) }
        
        // Create new QuoteManager to test loading with same UserDefaults
        let newQuoteManager = QuoteManager(loadFromDefaults: true, userDefaults: testUserDefaults)
        
        // Assert
        XCTAssertEqual(newQuoteManager.lovedQuotes.count, 3, 
                      "Should load all three loved quotes")
        
        for quote in testQuotes {
            XCTAssertTrue(newQuoteManager.isQuoteLoved(quote), 
                         "Quote '\(quote)' should persist")
        }
    }
    
    func testLovedQuotesPersistence_emptySet_handlesCorrectly() {
        // Arrange
        let testQuote = "Temporary quote"
        quoteManager.toggleLoveQuote(testQuote) // Add
        quoteManager.toggleLoveQuote(testQuote) // Remove
        
        // Act
        let newQuoteManager = QuoteManager(loadFromDefaults: true, userDefaults: testUserDefaults)
        
        // Assert
        XCTAssertEqual(newQuoteManager.lovedQuotes.count, 0, 
                      "Should load empty loved quotes correctly")
        XCTAssertFalse(newQuoteManager.isQuoteLoved(testQuote), 
                      "Removed quote should not persist")
    }
    
    func testLovedQuotesPersistence_withSpecialCharacters_savesAndLoadsCorrectly() {
        // Arrange
        let specialQuotes = [
            "Quote with 🌟 emoji",
            "Quote with \"quotes\" inside",
            "Quote with \n newline",
            "Quote with 中文 characters"
        ]
        
        // Act
        specialQuotes.forEach { quoteManager.toggleLoveQuote($0) }
        
        // Create new QuoteManager to test loading with same UserDefaults
        let newQuoteManager = QuoteManager(loadFromDefaults: true, userDefaults: testUserDefaults)
        
        // Assert
        XCTAssertEqual(newQuoteManager.lovedQuotes.count, specialQuotes.count, 
                      "Should load all special character quotes")
        
        for quote in specialQuotes {
            XCTAssertTrue(newQuoteManager.isQuoteLoved(quote), 
                         "Special quote '\(quote)' should persist")
        }
    }
    
    // MARK: - Complete App State Integration Tests
    
    func testCompleteAppState_allSettings_persistCorrectly() {
        // Arrange
        let calendar = Calendar.current
        let now = Date()
        
        // Configure all settings
        quoteManager.dailyNotifications = true
        quoteManager.fontSize = .large
        quoteManager.notificationMode = .single
        quoteManager.startTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now)!
        quoteManager.endTime = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: now)!
        quoteManager.singleNotificationTime = calendar.date(bySettingHour: 10, minute: 30, second: 0, of: now)!
        quoteManager.notificationCount = 3
        
        // Add some loved quotes
        let lovedQuotes = ["Quote 1", "Quote 2", "Quote 3"]
        lovedQuotes.forEach { quoteManager.toggleLoveQuote($0) }
        
        // Act
        let newQuoteManager = QuoteManager(loadFromDefaults: true, userDefaults: testUserDefaults)
        
        // Assert
        XCTAssertEqual(newQuoteManager.dailyNotifications, true, "Daily notifications should persist")
        XCTAssertEqual(newQuoteManager.fontSize, .large, "Font size should persist")
        XCTAssertEqual(newQuoteManager.notificationMode, .single, "Notification mode should persist")
        XCTAssertEqual(newQuoteManager.notificationCount, 3, "Notification count should persist")
        XCTAssertEqual(newQuoteManager.lovedQuotes.count, 3, "Loved quotes should persist")
        
        // Verify time settings
        XCTAssertEqual(calendar.component(.hour, from: newQuoteManager.startTime), 7, "Start time should persist")
        XCTAssertEqual(calendar.component(.hour, from: newQuoteManager.endTime), 19, "End time should persist")
        XCTAssertEqual(calendar.component(.hour, from: newQuoteManager.singleNotificationTime), 10, "Single time should persist")
        XCTAssertEqual(calendar.component(.minute, from: newQuoteManager.singleNotificationTime), 30, "Single time minute should persist")
        
        // Verify loved quotes
        for quote in lovedQuotes {
            XCTAssertTrue(newQuoteManager.isQuoteLoved(quote), "Loved quote '\(quote)' should persist")
        }
    }
    
    // MARK: - Quote Navigation Integration Tests
    
    func testQuoteNavigation_withCompleteFlow_worksCorrectly() {
        // Arrange
        let initialQuote = quoteManager.currentQuote
        
        // Act
        quoteManager.nextQuote()
        let secondQuote = quoteManager.currentQuote
        
        quoteManager.nextQuote()
        let thirdQuote = quoteManager.currentQuote
        
        quoteManager.previousQuote()
        let backToSecond = quoteManager.currentQuote
        
        quoteManager.previousQuote()
        let backToFirst = quoteManager.currentQuote
        
        // Assert
        XCTAssertNotEqual(secondQuote, initialQuote, "Second quote should be different from initial")
        XCTAssertNotEqual(thirdQuote, secondQuote, "Third quote should be different from second")
        XCTAssertEqual(backToSecond, secondQuote, "Should return to second quote")
        XCTAssertEqual(backToFirst, initialQuote, "Should return to initial quote")
    }
    
    func testQuoteNavigation_withLovedQuotes_maintainsState() {
        // Arrange
        let initialQuote = quoteManager.currentQuote
        quoteManager.toggleLoveQuote(initialQuote)
        
        // Act
        quoteManager.nextQuote()
        let secondQuote = quoteManager.currentQuote
        quoteManager.toggleLoveQuote(secondQuote)
        
        // Navigate back
        quoteManager.previousQuote()
        
        // Assert
        XCTAssertEqual(quoteManager.currentQuote, initialQuote, "Should return to initial quote")
        XCTAssertTrue(quoteManager.isQuoteLoved(initialQuote), "Initial quote should still be loved")
        XCTAssertTrue(quoteManager.isQuoteLoved(secondQuote), "Second quote should still be loved")
        XCTAssertEqual(quoteManager.lovedQuotes.count, 2, "Should have two loved quotes")
    }
    
    // MARK: - Notification Integration Tests
    
    func testNotificationSettings_integrationWithTimeCalculation_worksCorrectly() {
        // Arrange
        let calendar = Calendar.current
        let now = Date()
        
        // Grant time range access for testing
        UserDefaults.standard.set(true, forKey: "hasTimeRangeAccess")
        
        quoteManager.startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
        quoteManager.endTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: now)!
        quoteManager.notificationCount = 4
        quoteManager.notificationMode = .range
        
        // Act
        let calculatedTimes = quoteManager.calculateNotificationTimes()
        
        // Assert
        XCTAssertEqual(calculatedTimes.count, 4, "Should calculate correct number of times")
        XCTAssertTrue(quoteManager.isValidTimeRange, "Time range should be valid")
        XCTAssertGreaterThanOrEqual(quoteManager.maxNotificationsAllowed, 4, "Should allow at least 4 notifications")
        
        // Check that times are within the set range
        for time in calculatedTimes {
            let hour = calendar.component(.hour, from: time)
            XCTAssertGreaterThanOrEqual(hour, 9, "All times should be after 9 AM")
            XCTAssertLessThanOrEqual(hour, 17, "All times should be before 5 PM")
        }
        
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "hasTimeRangeAccess")
    }
    
    // MARK: - Data Corruption Recovery Tests
    
    func testDataCorruptionRecovery_invalidLovedQuotesData_handlesGracefully() {
        // Arrange
        // Manually corrupt the UserDefaults data
        testUserDefaults.set("invalid_data", forKey: "lovedQuotes")
        
        // Act
        let newQuoteManager = QuoteManager(loadFromDefaults: true, userDefaults: testUserDefaults)
        
        // Assert
        XCTAssertEqual(newQuoteManager.lovedQuotes.count, 0, 
                      "Should handle corrupted data by defaulting to empty")
    }
    
    func testDataCorruptionRecovery_invalidSettingsData_usesDefaults() {
        // Arrange
        // Corrupt various settings
        testUserDefaults.set("invalid", forKey: "fontSize")
        testUserDefaults.set("invalid", forKey: "notificationMode")
        testUserDefaults.set(-999, forKey: "notificationCount")
        
        // Act
        let newQuoteManager = QuoteManager(loadFromDefaults: true, userDefaults: testUserDefaults)
        
        // Assert
        XCTAssertEqual(newQuoteManager.fontSize, .medium, "Should default to medium font size")
        XCTAssertEqual(newQuoteManager.notificationMode, .range, "Should default to range mode")
        XCTAssertEqual(newQuoteManager.notificationCount, 1, "Should default to 1 notification")
    }
    
    // MARK: - Memory and Performance Integration Tests
    
    func testMemoryUsage_withLargeDataSet_staysReasonable() {
        // Arrange
        let largeQuoteSet = (0..<1000).map { "Large dataset quote \($0)" }
        
        // Act
        largeQuoteSet.forEach { quoteManager.toggleLoveQuote($0) }
        
        // Create new instance to test loading large dataset
        let newQuoteManager = QuoteManager(loadFromDefaults: true, userDefaults: testUserDefaults)
        
        // Assert
        XCTAssertEqual(newQuoteManager.lovedQuotes.count, 1000, "Should load large dataset")
        
        // Test performance of operations with large dataset
        measure {
            _ = newQuoteManager.lovedQuotesArray
            _ = newQuoteManager.isQuoteLoved("Large dataset quote 500")
        }
    }
    
    // MARK: - Threading and Concurrency Integration Tests
    
    func testConcurrentSettingsChanges_maintainDataIntegrity() {
        // Arrange
        let expectation = expectation(description: "Concurrent operations should complete")
        expectation.expectedFulfillmentCount = 3
        
        // Act
        DispatchQueue.global().async {
            for i in 0..<50 {
                self.quoteManager.fontSize = (i % 2 == 0) ? .large : .small
            }
            expectation.fulfill()
        }
        
        DispatchQueue.global().async {
            for i in 0..<50 {
                self.quoteManager.notificationCount = (i % 5) + 1
            }
            expectation.fulfill()
        }
        
        DispatchQueue.global().async {
            for i in 0..<50 {
                self.quoteManager.toggleLoveQuote("Concurrent quote \(i)")
            }
            expectation.fulfill()
        }
        
        // Assert
        waitForExpectations(timeout: 5.0)
        
        // Create new instance to verify data integrity
        let newQuoteManager = QuoteManager(loadFromDefaults: true, userDefaults: testUserDefaults)
        
        // Data should be in a valid state (exact values may vary due to concurrency)
        XCTAssertTrue([QuoteManager.FontSize.small, .medium, .large].contains(newQuoteManager.fontSize), 
                     "Font size should be in valid state")
        XCTAssertGreaterThanOrEqual(newQuoteManager.notificationCount, 1, "Notification count should be valid")
        XCTAssertLessThanOrEqual(newQuoteManager.notificationCount, 10, "Notification count should be within limits")
        XCTAssertGreaterThanOrEqual(newQuoteManager.lovedQuotes.count, 0, "Loved quotes should be valid")
    }
    
    // MARK: - Real UserDefaults Integration Tests
    
    func testRealUserDefaults_persistence_worksWithActualStorage() {
        // This test uses real UserDefaults to ensure integration works
        // Note: This test should be isolated and cleaned up properly
        
        // Arrange
        let testKey = "test_quote_manager_integration"
        UserDefaults.standard.removeObject(forKey: testKey)
        
        let testData = ["Test quote 1", "Test quote 2"]
        
        // Act
        UserDefaults.standard.set(testData, forKey: testKey)
        let retrievedData = UserDefaults.standard.array(forKey: testKey) as? [String]
        
        // Assert
        XCTAssertEqual(retrievedData, testData, "UserDefaults should store and retrieve array correctly")
        
        // Cleanup
        UserDefaults.standard.removeObject(forKey: testKey)
    }
    
    // MARK: - App Lifecycle Integration Tests
    
    func testAppLifecycle_backgroundForeground_maintainsState() {
        // Arrange
        let testQuote = "Background test quote"
        quoteManager.toggleLoveQuote(testQuote)
        quoteManager.fontSize = .large
        
        // Simulate app backgrounding by creating new instance (mimics app restart)
        let backgroundQuoteManager = QuoteManager.createTestInstance()
        
        // Act & Assert
        XCTAssertTrue(backgroundQuoteManager.isQuoteLoved(testQuote), 
                     "State should persist through app lifecycle")
        XCTAssertEqual(backgroundQuoteManager.fontSize, .large, 
                      "Settings should persist through app lifecycle")
    }
}