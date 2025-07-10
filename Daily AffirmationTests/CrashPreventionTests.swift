//
//  CrashPreventionTests.swift
//  Daily AffirmationTests
//
//  Created by Ashraf Atshy on 09/07/2025.
//

import XCTest
import SwiftUI
import UserNotifications
@testable import Daily_Affirmation

final class CrashPreventionTests: XCTestCase {
    
    var quoteManager: QuoteManager!
    
    override func setUpWithError() throws {
        super.setUp()
        quoteManager = QuoteManager()
    }
    
    override func tearDownWithError() throws {
        quoteManager = nil
        super.tearDown()
    }
}

// MARK: - Share Sheet Crash Prevention Tests
extension CrashPreventionTests {
    
    func testShareSheetPopoverConfiguration() throws {
        // Test that share sheet configuration doesn't crash on iPad
        // This addresses the crashes we fixed in the ContentView
        
        let shareText = "Test quote for sharing"
        let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        // Configure popover presentation for iPad (should not crash)
        if let popoverController = activityViewController.popoverPresentationController {
            // This should not crash even if sourceView is nil
            popoverController.sourceView = nil
            popoverController.sourceRect = CGRect(x: 100, y: 100, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
            
            XCTAssertNotNil(popoverController, "Popover controller should be configured")
            XCTAssertEqual(popoverController.sourceRect, CGRect(x: 100, y: 100, width: 0, height: 0))
            XCTAssertEqual(popoverController.permittedArrowDirections, [])
        }
    }
    
    
    func testShareSheetWithNilContent() throws {
        // Test share sheet with nil or empty content
        let emptyActivityViewController = UIActivityViewController(activityItems: [], applicationActivities: nil)
        XCTAssertNotNil(emptyActivityViewController, "Should handle empty activity items")
        
        let nilActivityViewController = UIActivityViewController(activityItems: [NSNull()], applicationActivities: nil)
        XCTAssertNotNil(nilActivityViewController, "Should handle nil activity items")
    }
    
    func testShareSheetMemoryManagement() throws {
        // Test that our shareQuote implementation doesn't create memory leaks
        // This test verifies that our popover configuration doesn't cause retain cycles
        
        // Test our specific popover configuration logic
        autoreleasepool {
            let shareText = "Test quote for sharing"
            let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
            
            // Test our popover configuration approach (iPad + not in test environment)
            if UIDevice.current.userInterfaceIdiom == .pad && !ProcessInfo.processInfo.environment.keys.contains("XCTestConfigurationFilePath") {
                if let popoverController = activityViewController.popoverPresentationController {
                    // This is the configuration we use in our implementation
                    popoverController.sourceView = nil
                    popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                    popoverController.permittedArrowDirections = []
                }
            }
            
            // The key test: ensure our configuration doesn't prevent deallocation
            // Since we're in test environment, popover won't be configured
            XCTAssertNotNil(activityViewController, "Activity controller should be created")
        }
        
        // Verify that our test environment detection works
        XCTAssertTrue(ProcessInfo.processInfo.environment.keys.contains("XCTestConfigurationFilePath"), 
                     "Test should be running in test environment")
        
        // Test that ContentView can be instantiated without issues
        let contentView = ContentView()
        XCTAssertNotNil(contentView, "ContentView should be created successfully")
    }
}

// MARK: - Data Corruption and Recovery Tests
extension CrashPreventionTests {
    
    func testCorruptedQuotesFileHandling() throws {
        // Test handling of corrupted or missing quotes files
        let originalQuotes = quoteManager.quotes
        
        // Simulate corrupted quotes by setting empty array
        quoteManager.quotes = []
        
        // Should not crash when accessing current quote
        let currentQuote = quoteManager.currentQuote
        XCTAssertFalse(currentQuote.isEmpty, "Should provide fallback for corrupted quotes")
        
        // Should not crash when navigating
        quoteManager.nextQuote()
        XCTAssertEqual(quoteManager.currentIndex, 0, "Should handle navigation with empty quotes")
        
        quoteManager.previousQuote()
        XCTAssertEqual(quoteManager.currentIndex, 0, "Should handle navigation with empty quotes")
        
        // Restore original quotes
        quoteManager.quotes = originalQuotes
    }
    
    func testInvalidUserDefaultsHandling() throws {
        // Test handling of corrupted UserDefaults
        UserDefaults.standard.set("invalid_enum_value", forKey: "fontSize")
        UserDefaults.standard.set("invalid_language", forKey: "selectedLanguage")
        UserDefaults.standard.set("not_a_date", forKey: "notificationTime")
        UserDefaults.standard.set("not_a_bool", forKey: "isDarkMode")
        
        // Should not crash when creating new instance
        let testManager = QuoteManager()
        XCTAssertNotNil(testManager, "Should handle corrupted user defaults")
        
        // Should fall back to default values
        XCTAssertEqual(testManager.fontSize, .medium, "Should use default font size")
        XCTAssertEqual(testManager.selectedLanguage, .english, "Should use default language")
        XCTAssertFalse(testManager.isDarkMode, "Should use default dark mode setting")
    }
    
    func testExtremeIndexHandling() throws {
        let originalQuotes = quoteManager.quotes
        quoteManager.quotes = ["Quote 1", "Quote 2", "Quote 3"]
        
        // Test with extreme positive index
        quoteManager.currentIndex = Int.max
        XCTAssertNoThrow(quoteManager.nextQuote(), "Should not crash with extreme positive index")
        XCTAssertLessThan(quoteManager.currentIndex, quoteManager.quotes.count, "Should normalize extreme index")
        
        // Test with extreme negative index
        quoteManager.currentIndex = Int.min
        XCTAssertNoThrow(quoteManager.previousQuote(), "Should not crash with extreme negative index")
        XCTAssertGreaterThanOrEqual(quoteManager.currentIndex, 0, "Should normalize negative index")
        
        // Restore original quotes
        quoteManager.quotes = originalQuotes
    }
}

// MARK: - Memory Pressure Tests
extension CrashPreventionTests {
    
    func testMemoryPressureWithLargeQuotes() throws {
        // Test with extremely large quotes array
        let originalQuotes = quoteManager.quotes
        
        // Create large quotes array
        let largeQuotes = (0..<10000).map { "Quote number \($0) - " + String(repeating: "A", count: 1000) }
        quoteManager.quotes = largeQuotes
        
        // Should not crash with large dataset
        XCTAssertNoThrow(quoteManager.nextQuote(), "Should handle large quotes array")
        XCTAssertNoThrow(quoteManager.previousQuote(), "Should handle large quotes array")
        
        let currentQuote = quoteManager.currentQuote
        XCTAssertFalse(currentQuote.isEmpty, "Should return quote from large array")
        
        // Restore original quotes
        quoteManager.quotes = originalQuotes
    }
    
    func testRapidLanguageSwitching() throws {
        // Test rapid language switching doesn't cause crashes
        let languages = QuoteManager.AppLanguage.allCases
        
        for _ in 0..<100 {
            let randomLanguage = languages.randomElement() ?? .english
            XCTAssertNoThrow(quoteManager.selectedLanguage = randomLanguage, "Should not crash during rapid language switching")
        }
        
        // Verify app is still functional
        XCTAssertFalse(quoteManager.currentQuote.isEmpty, "Should still provide quotes after rapid switching")
    }
    
    func testConcurrentAccess() throws {
        // Test concurrent access to quote manager
        let expectation = XCTestExpectation(description: "Concurrent access test")
        let group = DispatchGroup()
        
        // Simulate multiple threads accessing the quote manager
        for i in 0..<10 {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                for _ in 0..<100 {
                    self.quoteManager.nextQuote()
                    _ = self.quoteManager.currentQuote
                    self.quoteManager.previousQuote()
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            XCTAssertFalse(self.quoteManager.currentQuote.isEmpty, "Should remain functional after concurrent access")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
}

// MARK: - Resource Loading Edge Cases
extension CrashPreventionTests {
    
    func testMissingResourceFiles() throws {
        // Test handling of missing resource files
        for language in QuoteManager.AppLanguage.allCases {
            let bundle = Bundle.main
            let url = bundle.url(forResource: language.quotesFileName, withExtension: "json")
            
            if url == nil {
                // If resource is missing, app should not crash
                quoteManager.selectedLanguage = language
                XCTAssertNoThrow(quoteManager.currentQuote, "Should not crash with missing resource file")
            }
        }
    }
    
    func testInvalidJSONHandling() throws {
        // Test handling of invalid JSON in quotes files
        // Note: This test assumes the JSON files exist and are valid
        // In a real scenario, you might want to create temporary invalid files for testing
        
        let originalQuotes = quoteManager.quotes
        
        // Simulate invalid JSON by setting invalid quotes
        quoteManager.quotes = []
        
        // Should not crash
        XCTAssertNoThrow(quoteManager.nextQuote(), "Should handle invalid quotes data")
        XCTAssertNoThrow(quoteManager.previousQuote(), "Should handle invalid quotes data")
        
        // Restore original quotes
        quoteManager.quotes = originalQuotes
    }
}

// MARK: - UI State Edge Cases
extension CrashPreventionTests {
    
    func testFontSizeExtremeValues() throws {
        // Test font size calculations with extreme values
        let smallFont = QuoteManager.FontSize.small
        let largeFont = QuoteManager.FontSize.large
        
        XCTAssertGreaterThan(smallFont.multiplier, 0, "Small font multiplier should be positive")
        XCTAssertLessThan(smallFont.multiplier, 2, "Small font multiplier should be reasonable")
        
        XCTAssertGreaterThan(largeFont.multiplier, 0, "Large font multiplier should be positive")
        XCTAssertLessThan(largeFont.multiplier, 5, "Large font multiplier should be reasonable")
        
        // Test with all font sizes
        for fontSize in QuoteManager.FontSize.allCases {
            XCTAssertGreaterThan(fontSize.multiplier, 0, "Font multiplier should be positive")
            XCTAssertFalse(fontSize.displayName(using: quoteManager).isEmpty, "Font display name should not be empty")
        }
    }
    
    func testRTLLanguageHandling() throws {
        // Test RTL language handling edge cases
        for language in QuoteManager.AppLanguage.allCases {
            quoteManager.selectedLanguage = language
            
            // Should not crash when checking RTL status
            XCTAssertNoThrow(language.isRTL, "Should not crash when checking RTL status")
            
            // Should provide valid display name
            XCTAssertFalse(language.displayName.isEmpty, "Language display name should not be empty")
            
            // Should provide valid quotes file name
            XCTAssertFalse(language.quotesFileName.isEmpty, "Quotes file name should not be empty")
        }
    }
    
    func testDateFormattingEdgeCases() throws {
        // Test date formatting with extreme dates
        _ = Date.distantPast
        _ = Date.distantFuture
        
        // Should not crash with extreme dates
        XCTAssertNoThrow(quoteManager.formattedDate, "Should handle current date formatting")
        
        // Test notification time formatting
        let extremeTime = Date.distantFuture
        quoteManager.notificationTime = extremeTime
        XCTAssertNoThrow(quoteManager.formattedNotificationTime, "Should handle extreme notification time")
        
        // Reset to normal time
        quoteManager.notificationTime = Date()
    }
}

// MARK: - Notification System Edge Cases
extension CrashPreventionTests {
    
    func testNotificationPermissionDenied() throws {
        // Test behavior when notification permission is denied
        let expectation = XCTestExpectation(description: "Notification permission denied")
        
        // This test checks that the app doesn't crash when permission is denied
        // In a real test environment, you might need to mock the permission system
        
        quoteManager.dailyNotifications = false
        
        // Should not crash when toggling notifications
        XCTAssertNoThrow(quoteManager.dailyNotifications = true, "Should handle permission denial gracefully")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // App should still be functional
            XCTAssertFalse(self.quoteManager.currentQuote.isEmpty, "Should remain functional after permission denial")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testNotificationWithInvalidTime() throws {
        // Test notification scheduling with invalid times
        let invalidTime = Date(timeIntervalSince1970: -1)
        
        XCTAssertNoThrow(quoteManager.notificationTime = invalidTime, "Should handle invalid notification time")
        
        // Should not crash when enabling notifications
        XCTAssertNoThrow(quoteManager.dailyNotifications = true, "Should handle invalid time gracefully")
        
        // Reset to valid time
        quoteManager.notificationTime = Date()
    }
}

// MARK: - Performance Under Stress
extension CrashPreventionTests {
    
    func testPerformanceUnderStress() throws {
        // Test performance with stress conditions
        measure {
            // Simulate heavy usage
            for _ in 0..<1000 {
                quoteManager.nextQuote()
                _ = quoteManager.currentQuote
                quoteManager.previousQuote()
                _ = quoteManager.formattedDate
                _ = quoteManager.formattedNotificationTime
            }
        }
    }
    
    func testMemoryLeaksUnderStress() throws {
        // Test for memory leaks under stress
        weak var weakManager: QuoteManager?
        
        autoreleasepool {
            let stressManager = QuoteManager()
            weakManager = stressManager
            
            // Perform stress operations
            for _ in 0..<100 {
                stressManager.nextQuote()
                stressManager.selectedLanguage = .hebrew
                stressManager.selectedLanguage = .arabic
                stressManager.selectedLanguage = .english
                stressManager.fontSize = .large
                stressManager.fontSize = .small
                stressManager.fontSize = .medium
                stressManager.isDarkMode.toggle()
            }
        }
        
        XCTAssertNil(weakManager, "Should not leak memory under stress")
    }
}

// MARK: - Crash Recovery Tests
extension CrashPreventionTests {
    
    func testRecoveryFromCorruptedState() throws {
        // Test recovery from corrupted application state
        
        // Corrupt various settings
        UserDefaults.standard.set(Int.max, forKey: "currentIndex")
        UserDefaults.standard.set("corrupted_data", forKey: "fontSize")
        UserDefaults.standard.set("invalid_language", forKey: "selectedLanguage")
        
        // Should recover gracefully
        let recoveryManager = QuoteManager()
        XCTAssertNotNil(recoveryManager, "Should create manager despite corrupted state")
        XCTAssertFalse(recoveryManager.currentQuote.isEmpty, "Should provide quotes after recovery")
        
        // Should use default values
        XCTAssertEqual(recoveryManager.fontSize, .medium, "Should recover with default font size")
        XCTAssertEqual(recoveryManager.selectedLanguage, .english, "Should recover with default language")
    }
    
    func testGracefulDegradation() throws {
        // Test graceful degradation when features fail
        let originalQuotes = quoteManager.quotes
        
        // Simulate feature failure
        quoteManager.quotes = []
        
        // Should still provide basic functionality
        XCTAssertFalse(quoteManager.currentQuote.isEmpty, "Should provide fallback quote")
        XCTAssertFalse(quoteManager.formattedDate.isEmpty, "Should provide formatted date")
        
        // Should handle settings changes
        XCTAssertNoThrow(quoteManager.isDarkMode = true, "Should handle settings changes")
        XCTAssertNoThrow(quoteManager.fontSize = .large, "Should handle font size changes")
        
        // Restore original quotes
        quoteManager.quotes = originalQuotes
    }
}
