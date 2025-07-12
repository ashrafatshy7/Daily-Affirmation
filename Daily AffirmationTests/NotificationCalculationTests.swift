//
//  NotificationCalculationTests.swift
//  Daily AffirmationTests
//
//  Created by QA Engineer on 12/07/2025.
//

import XCTest
@testable import Daily_Affirmation

final class NotificationCalculationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var quoteManager: QuoteManager!
    private var calendar: Calendar!
    private var baseDate: Date!
    
    // MARK: - Setup and Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        quoteManager = QuoteManager()
        calendar = Calendar.current
        // Use a fixed date for consistent testing
        baseDate = calendar.date(from: DateComponents(year: 2025, month: 7, day: 12, hour: 12, minute: 0, second: 0))!
    }
    
    override func tearDownWithError() throws {
        quoteManager = nil
        calendar = nil
        baseDate = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Basic Time Calculation Tests
    
    func testCalculateNotificationTimes_withOneHourRange_returnsSingleNotification() {
        // Arrange
        let startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: baseDate)!
        let endTime = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: baseDate)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        quoteManager.notificationCount = 1
        
        // Act
        let times = quoteManager.calculateNotificationTimes()
        
        // Assert
        XCTAssertEqual(times.count, 1, "Should return exactly one notification time")
        
        let hour = calendar.component(.hour, from: times[0])
        let minute = calendar.component(.minute, from: times[0])
        XCTAssertEqual(hour, 9, "Single notification should be at 9:30 (center of range)")
        XCTAssertEqual(minute, 30, "Single notification should be at 9:30 (center of range)")
    }
    
    func testCalculateNotificationTimes_withTwoHourRange_distributesEvenly() {
        // Arrange
        let startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: baseDate)!
        let endTime = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: baseDate)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        quoteManager.notificationCount = 3
        
        // Act
        let times = quoteManager.calculateNotificationTimes()
        
        // Assert
        XCTAssertEqual(times.count, 3, "Should return exactly three notification times")
        
        let firstHour = calendar.component(.hour, from: times[0])
        let lastHour = calendar.component(.hour, from: times[2])
        
        XCTAssertEqual(firstHour, 9, "First notification should be at start time")
        XCTAssertEqual(lastHour, 11, "Last notification should be at end time")
        
        // Check that times are sorted chronologically
        for i in 1..<times.count {
            XCTAssertLessThanOrEqual(times[i-1], times[i], "Notification times should be sorted chronologically")
        }
    }
    
    func testCalculateNotificationTimes_withZeroMinuteRange_returnsSingleTime() {
        // Arrange
        let sameTime = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: baseDate)!
        
        quoteManager.startTime = sameTime
        quoteManager.endTime = sameTime
        quoteManager.notificationCount = 5
        
        // Act
        let times = quoteManager.calculateNotificationTimes()
        
        // Assert
        XCTAssertEqual(times.count, 1, "Should return single time when start equals end")
        
        let hour = calendar.component(.hour, from: times[0])
        let minute = calendar.component(.minute, from: times[0])
        XCTAssertEqual(hour, 9, "Should return the same hour")
        XCTAssertEqual(minute, 30, "Should return the same minute")
    }
    
    // MARK: - Cross-Midnight Time Tests
    
    func testCalculateNotificationTimes_crossMidnight_handlesCorrectly() {
        // Arrange
        let startTime = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: baseDate)!
        let endTime = calendar.date(bySettingHour: 2, minute: 0, second: 0, of: baseDate)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        quoteManager.notificationCount = 3
        
        // Act
        let times = quoteManager.calculateNotificationTimes()
        
        // Assert
        XCTAssertEqual(times.count, 3, "Should handle cross-midnight range")
        
        // Check that all times are valid
        for time in times {
            let hour = calendar.component(.hour, from: time)
            XCTAssertTrue(hour >= 22 || hour <= 2, "All times should be in valid cross-midnight range")
        }
        
        // Check that times are sorted even with cross-midnight
        for i in 1..<times.count {
            XCTAssertLessThanOrEqual(times[i-1], times[i], "Times should be sorted even with cross-midnight")
        }
    }
    
    func testCalculateNotificationTimes_crossMidnight_withOneNotification_returnsCenter() {
        // Arrange - 23:00 to 01:00 (2 hours across midnight)
        let startTime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: baseDate)!
        let endTime = calendar.date(bySettingHour: 1, minute: 0, second: 0, of: baseDate)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        quoteManager.notificationCount = 1
        
        // Act
        let times = quoteManager.calculateNotificationTimes()
        
        // Assert
        XCTAssertEqual(times.count, 1, "Should return single notification")
        
        let hour = calendar.component(.hour, from: times[0])
        XCTAssertEqual(hour, 0, "Center of 23:00-01:00 range should be midnight")
    }
    
    // MARK: - Edge Cases and Boundary Tests
    
    func testCalculateNotificationTimes_withMaximumCount_limitsCorrectly() {
        // Arrange
        let startTime = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: baseDate)!
        let endTime = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: baseDate)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        quoteManager.notificationCount = 1000 // Excessive count
        
        // Act
        let times = quoteManager.calculateNotificationTimes()
        
        // Assert
        XCTAssertLessThanOrEqual(times.count, quoteManager.maxNotificationsAllowed, 
                                "Should not exceed maximum allowed notifications")
        XCTAssertGreaterThan(times.count, 0, "Should return at least one notification")
    }
    
    func testCalculateNotificationTimes_withOneMinuteRange_returnsCorrectCount() {
        // Arrange
        let startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: baseDate)!
        let endTime = calendar.date(bySettingHour: 9, minute: 1, second: 0, of: baseDate)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        quoteManager.notificationCount = 5
        
        // Act
        let times = quoteManager.calculateNotificationTimes()
        
        // Assert
        XCTAssertEqual(times.count, 2, "One-minute range should allow maximum 2 notifications (start and end)")
        
        let firstTime = times[0]
        let lastTime = times[times.count - 1]
        
        XCTAssertEqual(calendar.component(.minute, from: firstTime), 0, "Should include start minute")
        XCTAssertEqual(calendar.component(.minute, from: lastTime), 1, "Should include end minute")
    }
    
    func testCalculateNotificationTimes_withLargeRange_distributesEvenly() {
        // Arrange - 12 hour range
        let startTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: baseDate)!
        let endTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: baseDate)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        quoteManager.notificationCount = 5
        
        // Act
        let times = quoteManager.calculateNotificationTimes()
        
        // Assert
        XCTAssertEqual(times.count, 5, "Should return requested count for large range")
        
        // Check distribution - should be roughly 3 hours apart
        for i in 1..<times.count {
            let timeDiff = times[i].timeIntervalSince(times[i-1])
            let hoursDiff = timeDiff / 3600 // Convert to hours
            XCTAssertGreaterThan(hoursDiff, 2.5, "Distribution should be roughly even")
            XCTAssertLessThan(hoursDiff, 3.5, "Distribution should be roughly even")
        }
    }
    
    // MARK: - Time Validation Tests
    
    func testIsValidTimeRange_withIdenticalTimes_returnsFalse() {
        // Arrange
        let sameTime = calendar.date(bySettingHour: 15, minute: 30, second: 0, of: baseDate)!
        
        quoteManager.startTime = sameTime
        quoteManager.endTime = sameTime
        
        // Act & Assert
        XCTAssertFalse(quoteManager.isValidTimeRange, "Identical start and end times should be invalid")
    }
    
    func testIsValidTimeRange_withDifferentTimes_returnsTrue() {
        // Arrange
        let startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: baseDate)!
        let endTime = calendar.date(bySettingHour: 17, minute: 30, second: 0, of: baseDate)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        
        // Act & Assert
        XCTAssertTrue(quoteManager.isValidTimeRange, "Different start and end times should be valid")
    }
    
    func testIsValidTimeRange_withCrossMidnightTimes_returnsTrue() {
        // Arrange
        let startTime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: baseDate)!
        let endTime = calendar.date(bySettingHour: 1, minute: 0, second: 0, of: baseDate)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        
        // Act & Assert
        XCTAssertTrue(quoteManager.isValidTimeRange, "Cross-midnight times should be valid")
    }
    
    // MARK: - Maximum Notifications Calculation Tests
    
    func testMaxNotificationsAllowed_withShortRange_limitsCorrectly() {
        // Arrange - 5 minute range
        let startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: baseDate)!
        let endTime = calendar.date(bySettingHour: 9, minute: 5, second: 0, of: baseDate)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        
        // Act
        let maxAllowed = quoteManager.maxNotificationsAllowed
        
        // Assert
        XCTAssertEqual(maxAllowed, 6, "5-minute range should allow 6 notifications (0,1,2,3,4,5 minutes)")
    }
    
    func testMaxNotificationsAllowed_withLongRange_appliesHardCap() {
        // Arrange - 24 hour range
        let startTime = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: baseDate)!
        let endTime = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: baseDate)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        
        // Act
        let maxAllowed = quoteManager.maxNotificationsAllowed
        
        // Assert
        XCTAssertEqual(maxAllowed, 10, "Should apply hard cap of 10 notifications")
    }
    
    func testMaxNotificationsAllowed_withCrossMidnightRange_calculatesCorrectly() {
        // Arrange - 21:00 to 03:00 (6 hours)
        let startTime = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: baseDate)!
        let endTime = calendar.date(bySettingHour: 3, minute: 0, second: 0, of: baseDate)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        
        // Act
        let maxAllowed = quoteManager.maxNotificationsAllowed
        
        // Assert
        XCTAssertEqual(maxAllowed, 361, "6-hour cross-midnight range should allow 361 notifications (6*60+1)")
    }
    
    // MARK: - Time Adjustment Tests
    
    func testAdjustEndTimeIfNeeded_whenStartEqualsEnd_adjustsEndTime() {
        // Arrange
        let sameTime = calendar.date(bySettingHour: 15, minute: 30, second: 0, of: baseDate)!
        quoteManager.notificationMode = .range
        
        // Act
        quoteManager.startTime = sameTime
        quoteManager.endTime = sameTime
        
        // Force adjustment by setting start time after end time is set
        quoteManager.startTime = sameTime
        
        // Assert
        XCTAssertNotEqual(quoteManager.endTime, sameTime, "End time should be adjusted when equal to start time")
        
        let endMinute = calendar.component(.minute, from: quoteManager.endTime)
        let startMinute = calendar.component(.minute, from: sameTime)
        XCTAssertEqual(endMinute, startMinute + 1, "End time should be 1 minute after start time")
    }
    
    func testAdjustEndTimeIfNeeded_withMidnightRollover_handlesCorrectly() {
        // Arrange
        let lateTime = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: baseDate)!
        quoteManager.notificationMode = .range
        
        // Act
        quoteManager.startTime = lateTime
        quoteManager.endTime = lateTime
        
        // Force adjustment
        quoteManager.startTime = lateTime
        
        // Assert
        let endHour = calendar.component(.hour, from: quoteManager.endTime)
        let endMinute = calendar.component(.minute, from: quoteManager.endTime)
        XCTAssertEqual(endHour, 0, "Should roll over to midnight hour")
        XCTAssertEqual(endMinute, 0, "Should roll over to zero minutes")
    }
    
    // MARK: - Notification Count Adjustment Tests
    
    func testAdjustNotificationCountIfNeeded_whenExceedsMaximum_reducesToMaximum() {
        // Arrange
        let startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: baseDate)!
        let endTime = calendar.date(bySettingHour: 9, minute: 5, second: 0, of: baseDate)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        quoteManager.notificationMode = .range
        quoteManager.notificationCount = 20 // Exceeds the 6-notification maximum for 5-minute range
        
        // Act - Trigger adjustment by setting end time
        quoteManager.endTime = endTime
        
        // Assert
        XCTAssertLessThanOrEqual(quoteManager.notificationCount, quoteManager.maxNotificationsAllowed,
                                "Notification count should be reduced to maximum allowed")
    }
    
    func testAdjustNotificationCountIfNeeded_whenWithinLimits_doesNotChange() {
        // Arrange
        let startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: baseDate)!
        let endTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: baseDate)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        quoteManager.notificationMode = .range
        quoteManager.notificationCount = 5
        
        let originalCount = quoteManager.notificationCount
        
        // Act - Trigger adjustment
        quoteManager.endTime = endTime
        
        // Assert
        XCTAssertEqual(quoteManager.notificationCount, originalCount,
                      "Notification count should not change when within limits")
    }
    
    // MARK: - Performance Tests
    
    func testCalculateNotificationTimes_performance_withMaximumRange() {
        // Arrange
        let startTime = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: baseDate)!
        let endTime = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: baseDate)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        quoteManager.notificationCount = 10
        
        // Act & Assert
        measure {
            for _ in 0..<100 {
                _ = quoteManager.calculateNotificationTimes()
            }
        }
    }
    
    func testCalculateNotificationTimes_performance_withCrossMidnight() {
        // Arrange
        let startTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: baseDate)!
        let endTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: baseDate)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        quoteManager.notificationCount = 10
        
        // Act & Assert
        measure {
            for _ in 0..<100 {
                _ = quoteManager.calculateNotificationTimes()
            }
        }
    }
    
    // MARK: - Helper Methods Tests
    
    func testCreateDateFromMinutes_withValidMinutes_returnsCorrectDate() {
        // This would test the private createDateFromMinutes method if it were made internal/public for testing
        // For now, we test the behavior through calculateNotificationTimes
        
        // Arrange
        let startTime = calendar.date(bySettingHour: 10, minute: 30, second: 0, of: baseDate)!
        let endTime = calendar.date(bySettingHour: 10, minute: 30, second: 0, of: baseDate)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        quoteManager.notificationCount = 1
        
        // Act
        let times = quoteManager.calculateNotificationTimes()
        
        // Assert
        XCTAssertEqual(times.count, 1, "Should return one time")
        
        let resultHour = calendar.component(.hour, from: times[0])
        let resultMinute = calendar.component(.minute, from: times[0])
        XCTAssertEqual(resultHour, 10, "Hour should be preserved")
        XCTAssertEqual(resultMinute, 30, "Minute should be preserved")
    }
    
    // MARK: - Integration with Formatted Properties Tests
    
    func testFormattedNotificationTime_returnsReadableFormat() {
        // Arrange
        let startTime = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: baseDate)!
        let endTime = calendar.date(bySettingHour: 17, minute: 45, second: 0, of: baseDate)!
        
        quoteManager.startTime = startTime
        quoteManager.endTime = endTime
        
        // Act
        let formattedTime = quoteManager.formattedNotificationTime
        
        // Assert
        XCTAssertTrue(formattedTime.contains("9:30"), "Should contain start time")
        XCTAssertTrue(formattedTime.contains("5:45") || formattedTime.contains("17:45"), "Should contain end time")
        XCTAssertTrue(formattedTime.contains("-"), "Should contain separator")
    }
    
    func testFormattedNotificationCount_returnsStringRepresentation() {
        // Arrange
        quoteManager.notificationCount = 7
        
        // Act
        let formattedCount = quoteManager.formattedNotificationCount
        
        // Assert
        XCTAssertEqual(formattedCount, "7", "Should return string representation of count")
    }
}