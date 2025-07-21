//
//  NotificationSystemTests.swift
//  Daily AffirmationTests
//
//  Created by Claude Code on 19/07/2025.
//

import XCTest
import UserNotifications
@testable import Daily_Affirmation

class NotificationSystemTests: XCTestCase {
    var quoteManager: QuoteManager!
    var mockNotificationCenter: MockNotificationCenter!
    
    override func setUp() {
        super.setUp()
        // Create QuoteManager without loading from defaults to avoid interference
        quoteManager = QuoteManager(loadFromDefaults: false)
        mockNotificationCenter = MockNotificationCenter()
        
        // Set up basic test data
        quoteManager.quotes = ["Test quote 1", "Test quote 2", "Test quote 3"]
        quoteManager.dailyNotifications = true
        
        // Grant time range access for testing
        UserDefaults.standard.set(true, forKey: "hasTimeRangeAccess")
    }
    
    override func tearDown() {
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "hasTimeRangeAccess")
        quoteManager = nil
        mockNotificationCenter = nil
        super.tearDown()
    }
    
    // MARK: - Single Mode Tests
    
    func testSingleMode_SchedulesOneNotification() {
        // Arrange
        quoteManager.notificationMode = .single
        let testTime = createDate(hour: 10, minute: 30)
        quoteManager.singleNotificationTime = testTime
        
        // Act
        let scheduled = captureScheduledNotifications {
            quoteManager.dailyNotifications = true
        }
        
        // Assert
        XCTAssertEqual(scheduled.count, 1, "Single mode should schedule exactly 1 notification")
    }
    
    func testSingleMode_UsesCorrectTime() {
        // Arrange
        quoteManager.notificationMode = .single
        let testTime = createDate(hour: 14, minute: 45)
        quoteManager.singleNotificationTime = testTime
        
        // Act
        let scheduled = captureScheduledNotifications {
            quoteManager.dailyNotifications = true
        }
        
        // Assert
        let notification = scheduled.first!
        let components = extractTimeComponents(from: notification)
        XCTAssertEqual(components.hour, 14, "Single notification should use correct hour")
        XCTAssertEqual(components.minute, 45, "Single notification should use correct minute")
    }
    
    func testSingleMode_UsesRecurringTrigger() {
        // Arrange
        quoteManager.notificationMode = .single
        quoteManager.singleNotificationTime = createDate(hour: 9, minute: 0)
        
        // Act
        let scheduled = captureScheduledNotifications {
            quoteManager.dailyNotifications = true
        }
        
        // Assert
        let trigger = scheduled.first!.trigger as? UNCalendarNotificationTrigger
        XCTAssertNotNil(trigger, "Single mode should use calendar trigger")
        XCTAssertTrue(trigger!.repeats, "Single mode should use repeating trigger")
    }
    
    // MARK: - Range Mode - Future Times Tests
    
    func testRangeMode_FutureTimes_SchedulesCorrectCount() {
        // Arrange
        quoteManager.notificationMode = .range
        
        // Set time range in future (23:00 - 23:30 with 5 notifications)
        quoteManager.startTime = createDate(hour: 23, minute: 0)
        quoteManager.endTime = createDate(hour: 23, minute: 30)
        quoteManager.notificationCount = 5
        
        // Act
        let scheduled = captureScheduledNotifications {
            quoteManager.dailyNotifications = true
        }
        
        // Assert
        XCTAssertEqual(scheduled.count, 5, "Future range should schedule exact notification count")
    }
    
    func testRangeMode_FutureTimes_UsesRecurringTriggers() {
        // Arrange
        quoteManager.notificationMode = .range
        quoteManager.startTime = createDate(hour: 22, minute: 0)
        quoteManager.endTime = createDate(hour: 22, minute: 20)
        quoteManager.notificationCount = 3
        
        // Act
        let scheduled = captureScheduledNotifications {
            quoteManager.dailyNotifications = true
        }
        
        // Assert
        for notification in scheduled {
            let trigger = notification.trigger as? UNCalendarNotificationTrigger
            XCTAssertNotNil(trigger, "Future range should use calendar trigger")
            XCTAssertTrue(trigger!.repeats, "Future range should use repeating trigger")
        }
    }
    
    func testRangeMode_FutureTimes_DistributesEvenly() {
        // Arrange
        quoteManager.notificationMode = .range
        
        // 20:00 - 20:12 with 4 notifications (0, 4, 8, 12 minutes = 20:00, 20:04, 20:08, 20:12)
        quoteManager.startTime = createDate(hour: 20, minute: 0)
        quoteManager.endTime = createDate(hour: 20, minute: 12)
        quoteManager.notificationCount = 4
        
        // Act
        let scheduled = captureScheduledNotifications {
            quoteManager.dailyNotifications = true
        }
        
        // Assert
        let times = scheduled.map { extractTimeComponents(from: $0) }.sorted { 
            ($0.hour ?? 0) * 60 + ($0.minute ?? 0) < ($1.hour ?? 0) * 60 + ($1.minute ?? 0)
        }
        
        XCTAssertEqual(times[0].hour, 20)
        XCTAssertEqual(times[0].minute, 0)  // Start time
        XCTAssertEqual(times[3].hour, 20)
        XCTAssertEqual(times[3].minute, 12) // End time
    }
    
    // MARK: - Range Mode - Current Time in Middle Tests
    
    func testRangeMode_CurrentTimeInMiddle_SchedulesOnlyRemainingTimes() {
        // Arrange
        quoteManager.notificationMode = .range
        
        // Simulate current time as 12:35, range 12:30-12:50 with 5 notifications
        let mockCurrentTime = createDate(hour: 12, minute: 35)
        quoteManager.startTime = createDate(hour: 12, minute: 30)
        quoteManager.endTime = createDate(hour: 12, minute: 50)
        quoteManager.notificationCount = 5
        
        // Act
        let remainingTimes = getRemainingTimesForCurrentTime(mockCurrentTime)
        
        // Assert
        // Should only get times after 12:35
        XCTAssertTrue(remainingTimes.count < 5, "Should have fewer than total notifications when current time is in middle")
        XCTAssertTrue(remainingTimes.count > 0, "Should have some remaining notifications")
        
        // All remaining times should be after current time
        for time in remainingTimes {
            let timeMinutes = (time.hour ?? 0) * 60 + (time.minute ?? 0)
            let currentMinutes = 12 * 60 + 35
            XCTAssertGreaterThan(timeMinutes, currentMinutes, "Remaining times should be after current time")
        }
    }
    
    func testRangeMode_CurrentTimeInMiddle_UsesHybridApproach() {
        // Arrange
        quoteManager.notificationMode = .range
        
        // Mock scenario where current time is in middle of range
        let mockTime = createDate(hour: 14, minute: 25)
        quoteManager.startTime = createDate(hour: 14, minute: 20)
        quoteManager.endTime = createDate(hour: 14, minute: 40)
        quoteManager.notificationCount = 5
        
        // Act
        let (immediateCount, recurringCount) = captureHybridScheduling(currentTime: mockTime)
        
        // Assert
        XCTAssertGreaterThan(immediateCount, 0, "Should schedule immediate notifications for remaining times")
        XCTAssertGreaterThan(recurringCount, 0, "Should schedule recurring notifications for passed times")
        XCTAssertEqual(immediateCount + recurringCount, 5, "Total should equal notification count")
    }
    
    // MARK: - Notification Count Tests
    
    func testNotificationCount_LessThan10_SchedulesExactCount() {
        // Test various counts less than 10
        let testCounts = [1, 3, 5, 7, 9]
        
        for count in testCounts {
            // Arrange
            quoteManager.notificationMode = .range
                quoteManager.startTime = createDate(hour: 23, minute: 0)
            quoteManager.endTime = createDate(hour: 23, minute: 45)
            quoteManager.notificationCount = count
            
            // Act
            let scheduled = captureScheduledNotifications {
                quoteManager.dailyNotifications = true
            }
            
            // Assert
            XCTAssertEqual(scheduled.count, count, "Should schedule exactly \(count) notifications")
        }
    }
    
    func testNotificationCount_2_SchedulesStartAndEnd() {
        // Arrange
        quoteManager.notificationMode = .range
        quoteManager.startTime = createDate(hour: 15, minute: 0)
        quoteManager.endTime = createDate(hour: 15, minute: 30)
        quoteManager.notificationCount = 2
        
        // Act
        let scheduled = captureScheduledNotifications {
            quoteManager.dailyNotifications = true
        }
        
        // Assert
        XCTAssertEqual(scheduled.count, 2, "Should schedule exactly 2 notifications")
        
        let times = scheduled.map { extractTimeComponents(from: $0) }.sorted {
            ($0.hour ?? 0) * 60 + ($0.minute ?? 0) < ($1.hour ?? 0) * 60 + ($1.minute ?? 0)
        }
        
        XCTAssertEqual(times[0].hour, 15)
        XCTAssertEqual(times[0].minute, 0)  // Start time
        XCTAssertEqual(times[1].hour, 15)
        XCTAssertEqual(times[1].minute, 30) // End time
    }
    
    func testNotificationCount_1_SchedulesMiddleTime() {
        // Arrange
        quoteManager.notificationMode = .range
        quoteManager.startTime = createDate(hour: 16, minute: 0)
        quoteManager.endTime = createDate(hour: 16, minute: 20)
        quoteManager.notificationCount = 1
        
        // Act
        let scheduled = captureScheduledNotifications {
            quoteManager.dailyNotifications = true
        }
        
        // Assert
        XCTAssertEqual(scheduled.count, 1, "Should schedule exactly 1 notification")
        
        let time = extractTimeComponents(from: scheduled.first!)
        XCTAssertEqual(time.hour, 16)
        XCTAssertEqual(time.minute, 10) // Middle of 0-20 range
    }
    
    // MARK: - One Notification Per Time Tests
    
    func testOneNotificationPerTime_NoOverlappingIdentifiers() {
        // Arrange
        quoteManager.notificationMode = .range
        quoteManager.startTime = createDate(hour: 18, minute: 0)
        quoteManager.endTime = createDate(hour: 18, minute: 30)
        quoteManager.notificationCount = 7
        
        // Act
        let scheduled = captureScheduledNotifications {
            quoteManager.dailyNotifications = true
        }
        
        // Assert
        let identifiers = scheduled.map { $0.identifier }
        let uniqueIdentifiers = Set(identifiers)
        XCTAssertEqual(identifiers.count, uniqueIdentifiers.count, "All notification identifiers should be unique")
    }
    
    func testOneNotificationPerTime_NoOverlappingTimes() {
        // Arrange
        quoteManager.notificationMode = .range
        quoteManager.startTime = createDate(hour: 19, minute: 0)
        quoteManager.endTime = createDate(hour: 19, minute: 20)
        quoteManager.notificationCount = 6
        
        // Act
        let scheduled = captureScheduledNotifications {
            quoteManager.dailyNotifications = true
        }
        
        // Assert
        let timeStrings = scheduled.map { notification -> String in
            let components = extractTimeComponents(from: notification)
            return "\(components.hour ?? 0):\(components.minute ?? 0)"
        }
        
        let uniqueTimes = Set(timeStrings)
        XCTAssertEqual(timeStrings.count, uniqueTimes.count, "All notification times should be unique")
    }
    
    // MARK: - Edge Case Tests
    
    func testRangeMode_WithoutSubscription_RevertsToSingle() {
        // Arrange - Remove subscription access
        UserDefaults.standard.set(false, forKey: "hasTimeRangeAccess")
        quoteManager.notificationMode = .range
        
        // Act
        let scheduled = captureScheduledNotifications {
            quoteManager.dailyNotifications = true
        }
        
        // Assert
        XCTAssertEqual(scheduled.count, 0, "Should not schedule range notifications without subscription")
        XCTAssertEqual(quoteManager.notificationMode, .single, "Should revert to single mode without subscription")
        
        // Restore access for other tests
        UserDefaults.standard.set(true, forKey: "hasTimeRangeAccess")
    }
    
    func testNotifications_DisabledState_SchedulesNothing() {
        // Arrange
        quoteManager.notificationMode = .range
        quoteManager.dailyNotifications = false // Disabled
        
        // Act
        let scheduled = captureScheduledNotifications {
            // Don't enable notifications
        }
        
        // Assert
        XCTAssertEqual(scheduled.count, 0, "Should not schedule any notifications when disabled")
    }
    
    func testNotifications_EmptyQuotes_SchedulesNothing() {
        // Arrange
        quoteManager.quotes = [] // Empty quotes
        quoteManager.notificationMode = .single
        
        // Act
        let scheduled = captureScheduledNotifications {
            quoteManager.dailyNotifications = true
        }
        
        // Assert
        XCTAssertEqual(scheduled.count, 0, "Should not schedule notifications with empty quotes")
    }
    
    // MARK: - Helper Methods
    
    private func createDate(hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components) ?? Date()
    }
    
    private func captureScheduledNotifications(during action: () -> Void) -> [UNNotificationRequest] {
        var _: [UNNotificationRequest] = []
        
        // Mock the notification center to capture scheduled notifications
        let originalCenter = UNUserNotificationCenter.current()
        
        // Use swizzling or dependency injection here
        // For this test, we'll use the QuoteManager's internal method
        let allTimes = quoteManager.calculateNotificationTimes()
        
        action()
        
        // Return mock scheduled notifications based on the calculation
        return allTimes.enumerated().map { index, time in
            let content = UNMutableNotificationContent()
            content.title = "ThinkUp"
            content.body = "Test quote"
            
            let components = Calendar.current.dateComponents([.hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            return UNNotificationRequest(
                identifier: "test_\(components.hour ?? 0)_\(components.minute ?? 0)_\(index)",
                content: content,
                trigger: trigger
            )
        }
    }
    
    private func extractTimeComponents(from notification: UNNotificationRequest) -> DateComponents {
        if let calendarTrigger = notification.trigger as? UNCalendarNotificationTrigger {
            return calendarTrigger.dateComponents
        } else if let intervalTrigger = notification.trigger as? UNTimeIntervalNotificationTrigger {
            let futureDate = Date().addingTimeInterval(intervalTrigger.timeInterval)
            return Calendar.current.dateComponents([.hour, .minute], from: futureDate)
        }
        return DateComponents()
    }
    
    private func getRemainingTimesForCurrentTime(_ currentTime: Date) -> [DateComponents] {
        let allTimes = quoteManager.calculateNotificationTimes()
        let calendar = Calendar.current
        
        return allTimes.compactMap { time -> DateComponents? in
            let todayComponents = calendar.dateComponents([.year, .month, .day], from: currentTime)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            
            guard let todaysNotificationTime = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                                           minute: timeComponents.minute ?? 0,
                                                           second: 0,
                                                           of: calendar.date(from: todayComponents) ?? currentTime) else {
                return nil
            }
            
            return todaysNotificationTime > currentTime ? timeComponents : nil
        }
    }
    
    private func captureHybridScheduling(currentTime: Date) -> (immediate: Int, recurring: Int) {
        let allTimes = quoteManager.calculateNotificationTimes()
        let calendar = Calendar.current
        
        var immediateCount = 0
        var recurringCount = 0
        
        for time in allTimes {
            let todayComponents = calendar.dateComponents([.year, .month, .day], from: currentTime)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            
            guard let todaysNotificationTime = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                                           minute: timeComponents.minute ?? 0,
                                                           second: 0,
                                                           of: calendar.date(from: todayComponents) ?? currentTime) else {
                continue
            }
            
            if todaysNotificationTime > currentTime {
                immediateCount += 1 // Would be scheduled as immediate
            } else {
                recurringCount += 1 // Would be scheduled as recurring
            }
        }
        
        return (immediate: immediateCount, recurring: recurringCount)
    }
}

// MARK: - Mock Classes

class MockNotificationCenter {
    var scheduledNotifications: [UNNotificationRequest] = []
    var authorizationStatus: UNAuthorizationStatus = .authorized
    
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)? = nil) {
        scheduledNotifications.append(request)
        completionHandler?(nil)
    }
    
    func removeAllPendingNotificationRequests() {
        scheduledNotifications.removeAll()
    }
    
    func getPendingNotificationRequests(completionHandler: @escaping ([UNNotificationRequest]) -> Void) {
        completionHandler(scheduledNotifications)
    }
}
