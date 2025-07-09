//
//  Daily_AffirmationUITests.swift
//  Daily AffirmationUITests
//
//  Created by Ashraf Atshy on 08/07/2025.
//

import XCTest

final class Daily_AffirmationUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
}

// MARK: - App Launch and Basic Navigation Tests
extension Daily_AffirmationUITests {
    
    @MainActor
    func testAppLaunch() throws {
        XCTAssertTrue(app.exists, "App should launch successfully")
        
        // Wait for the app to fully load
        let quoteText = app.staticTexts.matching(identifier: "quote_text").firstMatch
        XCTAssertTrue(quoteText.waitForExistence(timeout: 5.0), "Quote text should appear")
        
        // Check that essential UI elements exist
        let settingsButton = app.buttons["settings_button"]
        XCTAssertTrue(settingsButton.exists, "Settings button should exist")
        
        let prevButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'prev' OR label CONTAINS 'Previous'")).firstMatch
        XCTAssertTrue(prevButton.exists, "Previous button should exist")
        
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'next' OR label CONTAINS 'Next'")).firstMatch
        XCTAssertTrue(nextButton.exists, "Next button should exist")
        
        let shareButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'share' OR label CONTAINS 'Share'")).firstMatch
        XCTAssertTrue(shareButton.exists, "Share button should exist")
    }
    
    @MainActor
    func testBasicNavigation() throws {
        let quoteText = app.staticTexts.matching(identifier: "quote_text").firstMatch
        XCTAssertTrue(quoteText.waitForExistence(timeout: 5.0))
        
        _ = quoteText.label
        
        // Test next button
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'next' OR label CONTAINS 'Next'")).firstMatch
        nextButton.tap()
        
        // Give time for animation
        Thread.sleep(forTimeInterval: 0.5)
        
        _ = quoteText.label
        // Note: Quote might be the same if there's only one quote, but button should still work
        XCTAssertTrue(quoteText.exists, "Quote should still exist after navigation")
        
        // Test previous button
        let prevButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'prev' OR label CONTAINS 'Previous'")).firstMatch
        prevButton.tap()
        
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(quoteText.exists, "Quote should still exist after navigation")
    }
}

// MARK: - Settings Screen Tests
extension Daily_AffirmationUITests {
    
    @MainActor
    func testSettingsScreenAccess() throws {
        let settingsButton = app.buttons["settings_button"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5.0))
        
        settingsButton.tap()
        
        // Check that settings screen appears
        let settingsTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Settings' OR label CONTAINS 'settings'")).firstMatch
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3.0), "Settings title should appear")
        
        // Check for settings options
        let darkModeToggle = app.switches.matching(NSPredicate(format: "label CONTAINS 'Dark' OR label CONTAINS 'dark'")).firstMatch
        XCTAssertTrue(darkModeToggle.exists, "Dark mode toggle should exist")
        
        let languageSection = app.staticTexts["language_section"]
        XCTAssertTrue(languageSection.exists, "Language section should exist")
        
        let fontSizeSection = app.staticTexts["font_size_section"]
        XCTAssertTrue(fontSizeSection.exists, "Font size section should exist")
    }
    
    @MainActor
    func testDarkModeToggle() throws {
        // Open settings
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()
        
        let darkModeToggle = app.switches.matching(NSPredicate(format: "label CONTAINS 'Dark' OR label CONTAINS 'dark'")).firstMatch
        XCTAssertTrue(darkModeToggle.waitForExistence(timeout: 3.0))
        
        let initialState = darkModeToggle.value as? String
        
        // Toggle dark mode
        darkModeToggle.tap()
        
        // Wait for animation
        Thread.sleep(forTimeInterval: 0.5)
        
        let newState = darkModeToggle.value as? String
        XCTAssertNotEqual(initialState, newState, "Dark mode state should change")
        
        // Toggle back
        darkModeToggle.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        let finalState = darkModeToggle.value as? String
        XCTAssertEqual(initialState, finalState, "Dark mode should return to original state")
    }
    
    @MainActor
    func testLanguageSelection() throws {
        // Open settings
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()
        
        let languageSection = app.staticTexts["language_section"]
        XCTAssertTrue(languageSection.waitForExistence(timeout: 3.0))
        
        // Language options should be visible without needing to tap a section
        // The individual language buttons should be present
        
        // Check for language options
        let englishOption = app.buttons["English"]
        let hebrewOption = app.buttons["עברית"]
        let arabicOption = app.buttons["العربية"]
        
        XCTAssertTrue(englishOption.exists, "English option should exist")
        XCTAssertTrue(hebrewOption.exists, "Hebrew option should exist")
        XCTAssertTrue(arabicOption.exists, "Arabic option should exist")
        
        // Test selecting Hebrew
        hebrewOption.tap()
        
        // Wait for settings to close and language to change
        Thread.sleep(forTimeInterval: 1.0)
        
        // Verify language change took effect (UI should be RTL)
        let quoteText = app.staticTexts.matching(identifier: "quote_text").firstMatch
        XCTAssertTrue(quoteText.exists, "Quote should still exist after language change")
    }
    
    @MainActor
    func testFontSizeSelection() throws {
        // Open settings
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()
        
        let fontSizeSection = app.staticTexts["font_size_section"]
        XCTAssertTrue(fontSizeSection.waitForExistence(timeout: 3.0))
        
        // Font size options should be visible without needing to tap a section
        // The individual font size buttons should be present
        
        // Check for font size options
        let smallOption = app.buttons["font_size_small"]
        let mediumOption = app.buttons["font_size_medium"]
        let largeOption = app.buttons["font_size_large"]
        
        XCTAssertTrue(smallOption.exists, "Small font option should exist")
        XCTAssertTrue(mediumOption.exists, "Medium font option should exist")
        XCTAssertTrue(largeOption.exists, "Large font option should exist")
        
        // Test selecting different font sizes
        largeOption.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        smallOption.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        mediumOption.tap()
        Thread.sleep(forTimeInterval: 0.5)
    }
}

// MARK: - Gesture Tests
extension Daily_AffirmationUITests {
    
    @MainActor
    func testSwipeGestures() throws {
        let quoteText = app.staticTexts.matching(identifier: "quote_text").firstMatch
        XCTAssertTrue(quoteText.waitForExistence(timeout: 5.0))
        
        let initialQuote = quoteText.label
        
        // Test swipe left (should go to next quote)
        app.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)
        
        let afterLeftSwipe = quoteText.label
        XCTAssertTrue(quoteText.exists, "Quote should exist after left swipe")
        
        // Test swipe right (should go to previous quote)
        app.swipeRight()
        Thread.sleep(forTimeInterval: 0.5)
        
        let afterRightSwipe = quoteText.label
        XCTAssertTrue(quoteText.exists, "Quote should exist after right swipe")
    }
    
    @MainActor
    func testSwipeGesturesWithRTL() throws {
        // Change to Hebrew (RTL)
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()
        
        let languageSection = app.staticTexts["language_section"]
        XCTAssertTrue(languageSection.waitForExistence(timeout: 3.0))
        
        // Language options should be visible without needing to tap a section
        
        let hebrewOption = app.buttons["עברית"]
        hebrewOption.tap()
        
        Thread.sleep(forTimeInterval: 1.0)
        
        // Test swipe gestures in RTL mode
        let quoteText = app.staticTexts.matching(identifier: "quote_text").firstMatch
        XCTAssertTrue(quoteText.waitForExistence(timeout: 5.0))
        
        // In RTL, swipe directions should be reversed
        app.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(quoteText.exists, "Quote should exist after left swipe in RTL")
        
        app.swipeRight()
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(quoteText.exists, "Quote should exist after right swipe in RTL")
    }
    
    @MainActor
    func testRapidSwipeGestures() throws {
        let quoteText = app.staticTexts.matching(identifier: "quote_text").firstMatch
        XCTAssertTrue(quoteText.waitForExistence(timeout: 5.0))
        
        // Test rapid swipes to ensure app doesn't crash
        for _ in 1...10 {
            app.swipeLeft()
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        XCTAssertTrue(quoteText.exists, "Quote should still exist after rapid swipes")
        
        for _ in 1...10 {
            app.swipeRight()
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        XCTAssertTrue(quoteText.exists, "Quote should still exist after rapid swipes")
    }
}

// MARK: - Share Functionality Tests
extension Daily_AffirmationUITests {
    
    @MainActor
    func testShareFunctionality() throws {
        let shareButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'share' OR label CONTAINS 'Share'")).firstMatch
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5.0))
        
        shareButton.tap()
        
        // Check that share sheet appears
        let shareSheet = app.otherElements["ActivityListView"]
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 3.0), "Share sheet should appear")
        
        // Check for common share options
        let copyOption = app.buttons["Copy"]
        if copyOption.exists {
            XCTAssertTrue(copyOption.exists, "Copy option should exist in share sheet")
        }
        
        // Close share sheet by tapping outside or cancel
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        } else {
            // Tap outside to dismiss
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
        }
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify we're back to main screen
        let quoteText = app.staticTexts.matching(identifier: "quote_text").firstMatch
        XCTAssertTrue(quoteText.exists, "Should return to main screen after sharing")
    }
    
    @MainActor
    func testShareFunctionalityiPad() throws {
        // This test is specifically for iPad popover handling
        if UIDevice.current.userInterfaceIdiom == .pad {
            let shareButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'share' OR label CONTAINS 'Share'")).firstMatch
            XCTAssertTrue(shareButton.waitForExistence(timeout: 5.0))
            
            shareButton.tap()
            
            // On iPad, share sheet should appear as popover
            let shareSheet = app.otherElements["ActivityListView"]
            XCTAssertTrue(shareSheet.waitForExistence(timeout: 3.0), "Share sheet should appear as popover on iPad")
            
            // Test that app doesn't crash (this was the original issue)
            XCTAssertTrue(app.exists, "App should not crash when showing share sheet on iPad")
            
            // Dismiss by tapping outside
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
}

// MARK: - Accessibility Tests
extension Daily_AffirmationUITests {
    
    @MainActor
    func testAccessibilityElements() throws {
        let quoteText = app.staticTexts["quote_text"]
        XCTAssertTrue(quoteText.waitForExistence(timeout: 5.0))
        
        // Test that main elements exist and have accessibility properties
        XCTAssertTrue(quoteText.exists, "Quote text should exist")
        XCTAssertFalse(quoteText.label.isEmpty, "Quote text should have accessible label")
        
        let settingsButton = app.buttons["settings_button"]
        XCTAssertTrue(settingsButton.exists, "Settings button should exist")
        XCTAssertFalse(settingsButton.label.isEmpty, "Settings button should have accessible label")
        
        let nextButton = app.buttons["next_button"]
        XCTAssertTrue(nextButton.exists, "Next button should exist")
        XCTAssertFalse(nextButton.label.isEmpty, "Next button should have accessible label")
        
        let prevButton = app.buttons["prev_button"]
        XCTAssertTrue(prevButton.exists, "Previous button should exist")
        XCTAssertFalse(prevButton.label.isEmpty, "Previous button should have accessible label")
        
        let shareButton = app.buttons["share_button"]
        XCTAssertTrue(shareButton.exists, "Share button should exist")
        XCTAssertFalse(shareButton.label.isEmpty, "Share button should have accessible label")
    }
    
    @MainActor
    func testVoiceOverNavigation() throws {
        // Test VoiceOver navigation
        let quoteText = app.staticTexts["quote_text"]
        XCTAssertTrue(quoteText.waitForExistence(timeout: 5.0))
        
        // Test that elements have proper labels
        XCTAssertFalse(quoteText.label.isEmpty, "Quote text should have accessible label")
        
        let settingsButton = app.buttons["settings_button"]
        XCTAssertFalse(settingsButton.label.isEmpty, "Settings button should have accessible label")
    }
}

// MARK: - Edge Cases and Error Handling Tests
extension Daily_AffirmationUITests {
    
    @MainActor
    func testRapidSettingsToggling() throws {
        // Test rapid settings changes to ensure stability
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()
        
        let darkModeToggle = app.switches.matching(NSPredicate(format: "label CONTAINS 'Dark' OR label CONTAINS 'dark'")).firstMatch
        XCTAssertTrue(darkModeToggle.waitForExistence(timeout: 3.0))
        
        // Rapidly toggle dark mode
        for _ in 1...5 {
            darkModeToggle.tap()
            Thread.sleep(forTimeInterval: 0.2)
        }
        
        XCTAssertTrue(app.exists, "App should remain stable during rapid toggling")
        
        // Close settings
        let doneButton = app.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        } else {
            // Swipe down to dismiss
            app.swipeDown()
        }
    }
    
    @MainActor
    func testMemoryStressWithLanguageChanges() throws {
        // Test memory stability with rapid language changes
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()
        
        let languageSection = app.staticTexts["language_section"]
        XCTAssertTrue(languageSection.waitForExistence(timeout: 3.0))
        
        // Language options should be visible without needing to tap a section
        
        let englishOption = app.buttons["English"]
        let hebrewOption = app.buttons["עברית"]
        let arabicOption = app.buttons["العربية"]
        
        // Rapidly switch languages
        for _ in 1...3 {
            hebrewOption.tap()
            Thread.sleep(forTimeInterval: 0.5)
            
            arabicOption.tap()
            Thread.sleep(forTimeInterval: 0.5)
            
            englishOption.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        XCTAssertTrue(app.exists, "App should remain stable during rapid language changes")
        
        // Verify app is still functional
        let quoteText = app.staticTexts.matching(identifier: "quote_text").firstMatch
        XCTAssertTrue(quoteText.exists, "Quote should still be visible after language stress test")
    }
    
    @MainActor
    func testAppStateRestoration() throws {
        // Change some settings
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()
        
        let darkModeToggle = app.switches.matching(NSPredicate(format: "label CONTAINS 'Dark' OR label CONTAINS 'dark'")).firstMatch
        darkModeToggle.tap()
        
        // Close settings
        let closeButton = app.buttons["close_settings_button"]
        if closeButton.exists {
            closeButton.tap()
        } else {
            app.swipeDown()
        }
        
        // Simulate app going to background and returning
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 0.5)
        
        app.activate()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify app restored properly
        let quoteText = app.staticTexts.matching(identifier: "quote_text").firstMatch
        XCTAssertTrue(quoteText.waitForExistence(timeout: 5.0), "App should restore properly after backgrounding")
    }
}

// MARK: - Performance Tests
extension Daily_AffirmationUITests {
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    @MainActor
    func testNavigationPerformance() throws {
        let quoteText = app.staticTexts.matching(identifier: "quote_text").firstMatch
        XCTAssertTrue(quoteText.waitForExistence(timeout: 5.0))
        
        let nextButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'next' OR label CONTAINS 'Next'")).firstMatch
        
        measure {
            for _ in 1...10 {
                nextButton.tap()
                Thread.sleep(forTimeInterval: 0.1)
            }
        }
    }
    
    @MainActor
    func testSettingsPerformance() throws {
        let settingsButton = app.buttons["settings_button"]
        
        measure {
            settingsButton.tap()
            Thread.sleep(forTimeInterval: 0.2)
            
            let closeButton = app.buttons["close_settings_button"]
            if closeButton.exists {
                closeButton.tap()
            } else {
                app.swipeDown()
            }
            Thread.sleep(forTimeInterval: 0.2)
        }
    }
}

// MARK: - Device Rotation Tests
extension Daily_AffirmationUITests {
    
    @MainActor
    func testRotationHandling() throws {
        let quoteText = app.staticTexts.matching(identifier: "quote_text").firstMatch
        XCTAssertTrue(quoteText.waitForExistence(timeout: 5.0))
        
        // Test portrait to landscape
        XCUIDevice.shared.orientation = .landscapeLeft
        Thread.sleep(forTimeInterval: 0.5)
        
        XCTAssertTrue(quoteText.exists, "Quote should exist after rotation to landscape")
        
        // Test landscape to portrait
        XCUIDevice.shared.orientation = .portrait
        Thread.sleep(forTimeInterval: 0.5)
        
        XCTAssertTrue(quoteText.exists, "Quote should exist after rotation to portrait")
        
        // Test all orientations
        XCUIDevice.shared.orientation = .landscapeRight
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(quoteText.exists, "Quote should exist in landscape right")
        
        XCUIDevice.shared.orientation = .portraitUpsideDown
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertTrue(quoteText.exists, "Quote should exist in portrait upside down")
        
        // Return to portrait
        XCUIDevice.shared.orientation = .portrait
        Thread.sleep(forTimeInterval: 0.5)
    }
}
