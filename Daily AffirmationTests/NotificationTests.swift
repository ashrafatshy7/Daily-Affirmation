//
//  NotificationTests.swift
//  Daily AffirmationTests
//
//  Created by Ashraf Atshy on 09/07/2025.
//

import XCTest
import UserNotifications
@testable import Daily_Affirmation

final class NotificationTests: XCTestCase {
    
    var quoteManager: QuoteManager!
    var mockNotificationCenter: UNUserNotificationCenter!
    
    override func setUpWithError() throws {
        super.setUp()
        quoteManager = QuoteManager()
        mockNotificationCenter = UNUserNotificationCenter.current()
        
        // Clean up any existing notifications
        mockNotificationCenter.removeAllPendingNotificationRequests()
        mockNotificationCenter.removeAllDeliveredNotifications()
        
        // Reset notification settings
        UserDefaults.standard.removeObject(forKey: "dailyNotifications")
        UserDefaults.standard.removeObject(forKey: "notificationTime")
    }
    
    override func tearDownWithError() throws {
        mockNotificationCenter.removeAllPendingNotificationRequests()
        mockNotificationCenter.removeAllDeliveredNotifications()
        quoteManager = nil
        super.tearDown()
    }
}

// MARK: - Notification Permission Tests
extension NotificationTests {
    
    func testNotificationPermissionRequest() throws {
        let expectation = XCTestExpectation(description: "Notification permission request")
        
        // Enable notifications which should trigger permission request
        quoteManager.dailyNotifications = true
        
        // Check that permission was requested
        mockNotificationCenter.getNotificationSettings { settings in
            XCTAssertNotEqual(settings.authorizationStatus, .notDetermined, "Permission should have been requested")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testNotificationSettingsInitialization() throws {
        XCTAssertFalse(quoteManager.dailyNotifications, "Notifications should be disabled by default")
        
        // Test default notification time (should be 9:00 AM for a fresh instance)
        // Clear UserDefaults first to test true defaults
        UserDefaults.standard.removeObject(forKey: "notificationTime")
        UserDefaults.standard.removeObject(forKey: "dailyNotifications")
        
        // Create a fresh instance to test default values
        let freshQuoteManager = QuoteManager()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: freshQuoteManager.notificationTime)
        XCTAssertEqual(components.hour, 9, "Default notification time should be 9:00 AM")
        XCTAssertEqual(components.minute, 0, "Default notification time should be 9:00 AM")
    }
    
    func testNotificationTimeFormatting() throws {
        let testTime = Calendar.current.date(bySettingHour: 14, minute: 30, second: 0, of: Date()) ?? Date()
        quoteManager.notificationTime = testTime
        
        let formattedTime = quoteManager.formattedNotificationTime
        XCTAssertFalse(formattedTime.isEmpty, "Formatted time should not be empty")
        
        // Should contain hour and minute information
        XCTAssertTrue(formattedTime.contains("14") || formattedTime.contains("2"), "Should contain hour")
        XCTAssertTrue(formattedTime.contains("30"), "Should contain minute")
    }
}

// MARK: - Notification Scheduling Tests
extension NotificationTests {
    
    func testNotificationScheduling() throws {
        let expectation = XCTestExpectation(description: "Notification scheduling")
        
        // Enable notifications
        quoteManager.dailyNotifications = true
        
        // Set a specific time
        let testTime = Calendar.current.date(bySettingHour: 10, minute: 15, second: 0, of: Date()) ?? Date()
        quoteManager.notificationTime = testTime
        
        // Give time for notification to be scheduled
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Check that notification was scheduled
            self.mockNotificationCenter.getPendingNotificationRequests { requests in
                XCTAssertFalse(requests.isEmpty, "Should have pending notifications")
                
                if let request = requests.first {
                    XCTAssertEqual(request.identifier, "dailyInspiration", "Should have correct identifier")
                    
                    if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                        XCTAssertEqual(trigger.dateComponents.hour, 10, "Should trigger at correct hour")
                        XCTAssertEqual(trigger.dateComponents.minute, 15, "Should trigger at correct minute")
                        XCTAssertTrue(trigger.repeats, "Should repeat daily")
                    }
                }
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testNotificationCancellation() throws {
        let expectation = XCTestExpectation(description: "Notification cancellation")
        
        // First enable notifications
        quoteManager.dailyNotifications = true
        
        // Wait for notification to be scheduled
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Then disable notifications
            self.quoteManager.dailyNotifications = false
            
            // Check that notifications were cancelled
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.mockNotificationCenter.getPendingNotificationRequests { requests in
                    XCTAssertTrue(requests.isEmpty, "Should have no pending notifications after cancellation")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testNotificationReschedulingOnTimeChange() throws {
        let expectation = XCTestExpectation(description: "Notification rescheduling")
        
        // Enable notifications
        quoteManager.dailyNotifications = true
        
        // Set initial time
        let initialTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        quoteManager.notificationTime = initialTime
        
        // Wait for notification to be scheduled
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Change time
            let newTime = Calendar.current.date(bySettingHour: 15, minute: 30, second: 0, of: Date()) ?? Date()
            self.quoteManager.notificationTime = newTime
            
            // Check that notification was rescheduled
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.mockNotificationCenter.getPendingNotificationRequests { requests in
                    XCTAssertFalse(requests.isEmpty, "Should have rescheduled notification")
                    
                    if let request = requests.first,
                       let trigger = request.trigger as? UNCalendarNotificationTrigger {
                        XCTAssertEqual(trigger.dateComponents.hour, 15, "Should have new hour")
                        XCTAssertEqual(trigger.dateComponents.minute, 30, "Should have new minute")
                    }
                    
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Notification Content Tests
extension NotificationTests {
    
    func testNotificationContentGeneration() throws {
        // Test with different languages
        for language in QuoteManager.AppLanguage.allCases {
            quoteManager.selectedLanguage = language
            
            // Enable notifications to trigger content generation
            quoteManager.dailyNotifications = true
            
            // Wait for notification to be scheduled
            let expectation = XCTestExpectation(description: "Notification content for \(language.rawValue)")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.mockNotificationCenter.getPendingNotificationRequests { requests in
                    XCTAssertFalse(requests.isEmpty, "Should have notification for \(language.rawValue)")
                    
                    if let request = requests.first {
                        XCTAssertFalse(request.content.title.isEmpty, "Title should not be empty")
                        XCTAssertFalse(request.content.body.isEmpty, "Body should not be empty")
                        XCTAssertEqual(request.content.sound, .default, "Should have default sound")
                        XCTAssertEqual(request.content.badge, 1, "Should have badge")
                    }
                    
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
            
            // Clean up for next iteration
            quoteManager.dailyNotifications = false
        }
    }
    
    func testDailyQuoteConsistency() throws {
        // Test that the same quote is returned for the same day
        let today = Date()
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        
        // Create multiple managers and verify they return the same daily quote
        let manager1 = QuoteManager()
        let manager2 = QuoteManager()
        
        XCTAssertEqual(manager1.currentQuote, manager2.currentQuote, "Daily quote should be consistent across instances")
        XCTAssertEqual(manager1.currentIndex, manager2.currentIndex, "Daily index should be consistent across instances")
    }
}

// MARK: - Notification Edge Cases Tests
extension NotificationTests {
    
    func testNotificationWithEmptyQuotes() throws {
        // Test notification behavior with empty quotes
        let originalQuotes = quoteManager.quotes
        quoteManager.quotes = []
        
        let expectation = XCTestExpectation(description: "Notification with empty quotes")
        
        quoteManager.dailyNotifications = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.mockNotificationCenter.getPendingNotificationRequests { requests in
                if !requests.isEmpty {
                    let request = requests.first!
                    XCTAssertFalse(request.content.body.isEmpty, "Should have fallback content for empty quotes")
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Restore original quotes
        quoteManager.quotes = originalQuotes
    }
    
    func testNotificationLanguageChange() throws {
        // Test notification content changes with language
        let expectation = XCTestExpectation(description: "Notification language change")
        
        quoteManager.dailyNotifications = true
        quoteManager.selectedLanguage = .english
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.mockNotificationCenter.getPendingNotificationRequests { requests in
                let englishRequest = requests.first
                let englishContent = englishRequest?.content.body ?? ""
                
                // Change language to Hebrew
                self.quoteManager.selectedLanguage = .hebrew
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.mockNotificationCenter.getPendingNotificationRequests { newRequests in
                        let hebrewRequest = newRequests.first
                        let hebrewContent = hebrewRequest?.content.body ?? ""
                        
                        XCTAssertNotEqual(englishContent, hebrewContent, "Notification content should change with language")
                        expectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testNotificationBoundaryTimes() throws {
        // Test notification scheduling with boundary times
        let expectation = XCTestExpectation(description: "Notification boundary times")
        
        quoteManager.dailyNotifications = true
        
        // Test midnight
        let midnight = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date()) ?? Date()
        quoteManager.notificationTime = midnight
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.mockNotificationCenter.getPendingNotificationRequests { requests in
                XCTAssertFalse(requests.isEmpty, "Should schedule notification for midnight")
                
                if let request = requests.first,
                   let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    XCTAssertEqual(trigger.dateComponents.hour, 0, "Should schedule for midnight")
                    XCTAssertEqual(trigger.dateComponents.minute, 0, "Should schedule for midnight")
                }
                
                // Test 11:59 PM
                let lateNight = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: Date()) ?? Date()
                self.quoteManager.notificationTime = lateNight
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.mockNotificationCenter.getPendingNotificationRequests { lateRequests in
                        if let request = lateRequests.first,
                           let trigger = request.trigger as? UNCalendarNotificationTrigger {
                            XCTAssertEqual(trigger.dateComponents.hour, 23, "Should schedule for 11 PM")
                            XCTAssertEqual(trigger.dateComponents.minute, 59, "Should schedule for 11:59 PM")
                        }
                        expectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testRapidNotificationToggling() throws {
        let expectation = XCTestExpectation(description: "Rapid notification toggling")
        
        // Rapidly toggle notifications on/off
        var completionCount = 0
        let totalToggles = 10
        
        for i in 0..<totalToggles {
            quoteManager.dailyNotifications = (i % 2 == 0)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 * Double(i)) {
                completionCount += 1
                if completionCount == totalToggles {
                    // Check final state
                    self.mockNotificationCenter.getPendingNotificationRequests { requests in
                        // Should be stable after rapid toggling
                        XCTAssertTrue(requests.isEmpty, "Should have no pending notifications after rapid toggling")
                        expectation.fulfill()
                    }
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Notification Performance Tests
extension NotificationTests {
    
    func testNotificationSchedulingPerformance() throws {
        measure {
            quoteManager.dailyNotifications = true
            quoteManager.dailyNotifications = false
        }
    }
    
    func testNotificationTimeChangePerformance() throws {
        quoteManager.dailyNotifications = true
        
        measure {
            let randomHour = Int.random(in: 0...23)
            let randomMinute = Int.random(in: 0...59)
            let testTime = Calendar.current.date(bySettingHour: randomHour, minute: randomMinute, second: 0, of: Date()) ?? Date()
            quoteManager.notificationTime = testTime
        }
    }
}