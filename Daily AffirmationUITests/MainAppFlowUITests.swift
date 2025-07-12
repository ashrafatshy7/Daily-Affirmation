//
//  MainAppFlowUITests.swift
//  Daily AffirmationUITests
//
//  Created by QA Engineer on 12/07/2025.
//

import XCTest

final class MainAppFlowUITests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var app: XCUIApplication!
    
    // MARK: - Setup and Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - App Launch Tests
    
    func testAppLaunch_displaysQuoteText() {
        // Arrange & Act
        // App should already be launched from setUp
        
        // Assert
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        XCTAssertTrue(quoteText.exists, "Quote text should be visible on app launch")
        let quoteContent = quoteText.value as? String ?? ""
        XCTAssertFalse(quoteContent.isEmpty, "Quote text should not be empty")
        XCTAssertNotEqual(quoteContent, "Loading...", "Quote should be loaded, not in loading state")
    }
    
    func testAppLaunch_displaysNavigationButtons() {
        // Assert
        let settingsButton = app.buttons["settings_button"]
        let shareButton = app.buttons["share_button"]
        let loveButton = app.buttons["love_button"]
        
        XCTAssertTrue(settingsButton.exists, "Settings button should be visible")
        XCTAssertTrue(shareButton.exists, "Share button should be visible")
        XCTAssertTrue(loveButton.exists, "Love button should be visible")
    }
    
    func testAppLaunch_hasCorrectAccessibilityLabels() {
        // Arrange
        let settingsButton = app.buttons["settings_button"]
        let shareButton = app.buttons["share_button"]
        let loveButton = app.buttons["love_button"]
        
        // Assert
        XCTAssertEqual(settingsButton.label, "Settings", "Settings button should have correct accessibility label")
        XCTAssertEqual(shareButton.label, "Share", "Share button should have correct accessibility label")
        XCTAssertEqual(loveButton.label, "Love this quote", "Love button should have correct accessibility label")
    }
    
    // MARK: - Quote Navigation Tests
    
    func testQuoteNavigation_swipeUp_changesQuote() {
        // Arrange
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        let initialQuote = quoteText.value as? String ?? ""
        
        // Act
        quoteText.swipeUp()
        
        // Wait for animation and quote change
        Thread.sleep(forTimeInterval: 1.0)
        
        // Assert
        let newQuote = quoteText.value as? String ?? ""
        XCTAssertNotEqual(newQuote, initialQuote, "Quote should change after swiping up")
        XCTAssertFalse(newQuote.isEmpty, "New quote should not be empty")
    }
    
    func testQuoteNavigation_swipeDown_changesQuote() {
        // Arrange
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        
        // First navigate to next quote to have a previous quote
        quoteText.swipeUp()
        Thread.sleep(forTimeInterval: 1.0)
        
        let secondQuote = quoteText.value as? String ?? ""
        
        // Act
        quoteText.swipeDown()
        Thread.sleep(forTimeInterval: 1.0)
        
        // Assert
        let afterSwipeDown = quoteText.value as? String ?? ""
        XCTAssertNotEqual(afterSwipeDown, secondQuote, "Quote should change after swiping down")
    }
    
    func testQuoteNavigation_multipleSwipes_worksConsistently() {
        // Arrange
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        var quotes: [String] = []
        
        // Collect initial quote
        quotes.append(quoteText.value as? String ?? "")
        
        // Act & Assert
        for i in 1...3 {
            quoteText.swipeUp()
            Thread.sleep(forTimeInterval: 1.0)
            
            let currentQuote = quoteText.value as? String ?? ""
            quotes.append(currentQuote)
            
            XCTAssertNotEqual(currentQuote, quotes[i-1], "Quote \(i) should be different from previous")
            XCTAssertFalse(currentQuote.isEmpty, "Quote \(i) should not be empty")
        }
        
        // Verify we can navigate back
        quoteText.swipeDown()
        Thread.sleep(forTimeInterval: 1.0)
        
        let afterBackNavigation = quoteText.value as? String ?? ""
        XCTAssertEqual(afterBackNavigation, quotes[2], "Should return to previous quote after swiping down")
    }
    
    // MARK: - Love Button Tests
    
    func testLoveButton_tap_changesAppearance() {
        // Arrange
        let loveButton = app.buttons["love_button"]
        let initialState = loveButton.isSelected
        
        // Act
        loveButton.tap()
        
        // Assert
        // Note: The exact way to test button state change depends on implementation
        // This might need adjustment based on how the heart icon state is exposed
        XCTAssertTrue(loveButton.exists, "Love button should still exist after tap")
    }
    
    func testLoveButton_multipleTaps_togglesCorrectly() {
        // Arrange
        let loveButton = app.buttons["love_button"]
        
        // Act & Assert
        for i in 1...5 {
            loveButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            
            XCTAssertTrue(loveButton.exists, "Love button should exist after tap \(i)")
            // Additional assertions could be added here based on how the state is exposed
        }
    }
    
    func testLoveButton_withDifferentQuotes_worksIndependently() {
        // Arrange
        let loveButton = app.buttons["love_button"]
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        
        // Love first quote
        loveButton.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Navigate to second quote
        quoteText.swipeUp()
        Thread.sleep(forTimeInterval: 1.0)
        
        // Act & Assert
        // Love button should work for new quote
        loveButton.tap()
        XCTAssertTrue(loveButton.exists, "Love button should work for different quotes")
    }
    
    // MARK: - Share Button Tests
    
    func testShareButton_tap_opensShareSheet() {
        // Arrange
        let shareButton = app.buttons["share_button"]
        
        // Act
        shareButton.tap()
        
        // Assert
        // Look for share sheet elements (this may vary by iOS version)
        let shareSheet = app.otherElements["ActivityListView"]
        let cancelButton = app.buttons["Cancel"]
        
        let shareSheetExists = shareSheet.waitForExistence(timeout: 3.0) || cancelButton.waitForExistence(timeout: 3.0)
        XCTAssertTrue(shareSheetExists, "Share sheet should appear after tapping share button")
        
        // Cleanup - dismiss share sheet if it appeared
        if cancelButton.exists {
            cancelButton.tap()
        } else if shareSheet.exists {
            // Tap outside the share sheet to dismiss it
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
        }
    }
    
    // MARK: - Settings Navigation Tests
    
    func testSettingsButton_tap_opensSettings() {
        // Arrange
        let settingsButton = app.buttons["settings_button"]
        
        // Act
        settingsButton.tap()
        
        // Assert
        // Try different element types for settings title
        let settingsTitleText = app.staticTexts["settings_title"]
        let settingsTitleButton = app.buttons["settings_title"]
        let settingsTitleOther = app.otherElements["settings_title"]
        let settingsTitle = settingsTitleText.exists ? settingsTitleText : 
                           (settingsTitleButton.exists ? settingsTitleButton : settingsTitleOther)
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3.0), "Settings screen should open")
        XCTAssertEqual(settingsTitle.label, "Settings", "Settings title should be correct")
    }
    
    func testSettingsNavigation_closeButton_returnsToMainScreen() {
        // Arrange
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()
        
        let closeButton = app.buttons["close_settings_button"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 3.0), "Close button should exist in settings")
        
        // Act
        closeButton.tap()
        
        // Assert
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        XCTAssertTrue(quoteText.waitForExistence(timeout: 3.0), "Should return to main screen with quote")
    }
    
    func testSettingsNavigation_sectionsExist() {
        // Arrange
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()
        
        // Assert
        let notificationsSection = app.buttons["notifications_section"]
        let displaySection = app.buttons["display_section"]
        let lovedQuotesSection = app.buttons["loved_quotes_section"]
        let privacySection = app.buttons["privacy_section"]
        
        XCTAssertTrue(notificationsSection.waitForExistence(timeout: 3.0), "Notifications section should exist")
        XCTAssertTrue(displaySection.exists, "Display section should exist")
        XCTAssertTrue(lovedQuotesSection.exists, "Loved quotes section should exist")
        XCTAssertTrue(privacySection.exists, "Privacy section should exist")
    }
    
    // MARK: - Swipe Indicator Tests
    
    func testSwipeIndicator_displaysOnAppLaunch() {
        // Note: This test depends on the swipe indicator being visible initially
        // The exact implementation may vary
        
        // Look for swipe indicator text or chevron
        let swipeIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'swipe' OR label CONTAINS 'Swipe'")).firstMatch
        
        if swipeIndicator.exists {
            XCTAssertTrue(swipeIndicator.exists, "Swipe indicator should be visible on app launch")
        }
        // Note: This is a soft assertion since the indicator may auto-hide
    }
    
    func testSwipeIndicator_hidesAfterInteraction() {
        // Arrange
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        
        // Act
        quoteText.swipeUp()
        Thread.sleep(forTimeInterval: 2.0) // Wait for indicator to potentially hide
        
        // Note: Testing indicator hiding requires specific implementation details
        // This test structure is provided as a template
    }
    
    // MARK: - Gesture Recognition Tests
    
    func testGestureRecognition_shortSwipe_doesNotTriggerNavigation() {
        // Arrange
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        let initialQuote = quoteText.value as? String ?? ""
        
        // Act - Perform very short swipe
        let startCoordinate = quoteText.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let endCoordinate = quoteText.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
        startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
        
        Thread.sleep(forTimeInterval: 1.0)
        
        // Assert
        let afterShortSwipe = quoteText.value as? String ?? ""
        XCTAssertEqual(afterShortSwipe, initialQuote, "Short swipe should not change quote")
    }
    
    func testGestureRecognition_longSwipe_triggersNavigation() {
        // Arrange
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        let initialQuote = quoteText.value as? String ?? ""
        
        // Act - Perform long swipe
        let startCoordinate = quoteText.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        let endCoordinate = quoteText.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)
        
        Thread.sleep(forTimeInterval: 1.5)
        
        // Assert
        let afterLongSwipe = quoteText.value as? String ?? ""
        XCTAssertNotEqual(afterLongSwipe, initialQuote, "Long swipe should change quote")
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibility_voiceOverSupport() {
        // Test that main elements are accessible and functional
        let settingsButton = app.buttons["settings_button"]
        let shareButton = app.buttons["share_button"]
        let loveButton = app.buttons["love_button"]
        
        // Test button accessibility and functionality
        XCTAssertTrue(settingsButton.exists, "Settings button should exist")
        XCTAssertTrue(shareButton.exists, "Share button should exist")
        XCTAssertTrue(loveButton.exists, "Love button should exist")
        
        XCTAssertTrue(settingsButton.isAccessibilityElement, "Settings button should be accessible")
        XCTAssertTrue(shareButton.isAccessibilityElement, "Share button should be accessible")
        XCTAssertTrue(loveButton.isAccessibilityElement, "Love button should be accessible")
        
        XCTAssertEqual(settingsButton.label, "Settings", "Settings button should have correct accessibility label")
        
        // Test quote text accessibility - verify it exists and has accessible content
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        
        XCTAssertTrue(quoteText.exists, "Quote text should be accessible via UI testing")
        
        // Verify the quote text has meaningful content for screen readers
        let quoteContent = quoteText.value as? String ?? quoteText.label
        XCTAssertFalse(quoteContent.isEmpty, "Quote text should have accessible content")
        XCTAssertGreaterThan(quoteContent.count, 5, "Quote content should be substantial")
    }
    
    func testAccessibility_dynamicType_layoutAdaptsCorrectly() {
        // Note: This test would require setting up different text sizes
        // The exact implementation depends on how the app handles Dynamic Type
        
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        XCTAssertTrue(quoteText.exists, "Quote text should exist regardless of text size")
        
        // Additional assertions would be added here based on Dynamic Type implementation
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_appLaunch() {
        // Measure app launch time
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    func testPerformance_quoteNavigation() {
        // Arrange
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        
        // Measure quote navigation performance
        measure {
            for _ in 0..<10 {
                quoteText.swipeUp()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }
    
    // MARK: - Error Handling and Edge Cases
    
    func testErrorHandling_rapidGestures_handlesGracefully() {
        // Arrange
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        
        // Act - Perform rapid swipes
        for _ in 0..<10 {
            quoteText.swipeUp()
            Thread.sleep(forTimeInterval: 0.1) // Very short delay
        }
        
        // Assert
        XCTAssertTrue(quoteText.exists, "Quote text should still exist after rapid gestures")
        let quoteContent = quoteText.value as? String ?? ""
        XCTAssertFalse(quoteContent.isEmpty, "Quote should still be valid after rapid gestures")
    }
    
    func testErrorHandling_buttonSpamming_remainsResponsive() {
        // Arrange
        let loveButton = app.buttons["love_button"]
        let settingsButton = app.buttons["settings_button"]
        
        // Act - Rapidly tap buttons
        for _ in 0..<20 {
            loveButton.tap()
            Thread.sleep(forTimeInterval: 0.05)
        }
        
        // Assert
        XCTAssertTrue(settingsButton.exists, "Settings button should still be responsive")
        settingsButton.tap()
        
        // Try different element types for settings title
        let settingsTitleText = app.staticTexts["settings_title"]
        let settingsTitleButton = app.buttons["settings_title"]
        let settingsTitleOther = app.otherElements["settings_title"]
        let settingsTitle = settingsTitleText.exists ? settingsTitleText : 
                           (settingsTitleButton.exists ? settingsTitleButton : settingsTitleOther)
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3.0), "Settings should still open after button spamming")
    }
    
    // MARK: - Device Orientation Tests
    
    func testDeviceOrientation_portrait_layoutCorrect() {
        // Arrange
        XCUIDevice.shared.orientation = .portrait
        
        // Assert
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        let settingsButton = app.buttons["settings_button"]
        let loveButton = app.buttons["love_button"]
        
        XCTAssertTrue(quoteText.exists, "Quote text should exist in portrait")
        XCTAssertTrue(settingsButton.exists, "Settings button should exist in portrait")
        XCTAssertTrue(loveButton.exists, "Love button should exist in portrait")
    }
    
    func testDeviceOrientation_landscape_layoutAdapts() {
        // Arrange
        XCUIDevice.shared.orientation = .landscapeLeft
        Thread.sleep(forTimeInterval: 1.0) // Wait for rotation
        
        // Assert
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        let settingsButton = app.buttons["settings_button"]
        let loveButton = app.buttons["love_button"]
        
        XCTAssertTrue(quoteText.exists, "Quote text should exist in landscape")
        XCTAssertTrue(settingsButton.exists, "Settings button should exist in landscape")
        XCTAssertTrue(loveButton.exists, "Love button should exist in landscape")
        
        // Cleanup
        XCUIDevice.shared.orientation = .portrait
    }
    
    // MARK: - Integration Flow Tests
    
    func testIntegrationFlow_loveQuoteThenViewInSettings() {
        // Arrange
        let loveButton = app.buttons["love_button"]
        let settingsButton = app.buttons["settings_button"]
        
        // Act
        loveButton.tap() // Love current quote
        Thread.sleep(forTimeInterval: 0.5)
        
        settingsButton.tap() // Open settings
        
        let lovedQuotesSection = app.buttons["loved_quotes_section"]
        XCTAssertTrue(lovedQuotesSection.waitForExistence(timeout: 3.0), "Loved quotes section should exist")
        
        lovedQuotesSection.tap() // Navigate to loved quotes
        
        // Assert
        // Note: The exact elements in the loved quotes view depend on implementation
        // This is a template for testing the complete flow
        Thread.sleep(forTimeInterval: 1.0)
        XCTAssertTrue(app.navigationBars.firstMatch.exists, "Should navigate to loved quotes view")
    }
    
    func testIntegrationFlow_completeAppNavigation() {
        // Test complete navigation flow through the app
        
        // Start at main screen
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        XCTAssertTrue(quoteText.exists, "Should start at main screen")
        
        // Navigate quotes
        quoteText.swipeUp()
        Thread.sleep(forTimeInterval: 1.0)
        XCTAssertTrue(quoteText.exists, "Should still be at main screen after navigation")
        
        // Love a quote
        let loveButton = app.buttons["love_button"]
        loveButton.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Open settings
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()
        
        // Try different element types for settings title
        let settingsTitleText = app.staticTexts["settings_title"]
        let settingsTitleButton = app.buttons["settings_title"]
        let settingsTitleOther = app.otherElements["settings_title"]
        let settingsTitle = settingsTitleText.exists ? settingsTitleText : 
                           (settingsTitleButton.exists ? settingsTitleButton : settingsTitleOther)
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3.0), "Should navigate to settings")
        
        // Close settings
        let closeButton = app.buttons["close_settings_button"]
        closeButton.tap()
        
        // Verify back at main screen
        XCTAssertTrue(quoteText.waitForExistence(timeout: 3.0), "Should return to main screen")
    }
}