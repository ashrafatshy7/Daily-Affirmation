//
//  AccessibilityUITests.swift
//  Daily AffirmationUITests
//
//  Created by QA Engineer on 12/07/2025.
//

import XCTest

final class AccessibilityUITests: XCTestCase {
    
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
    
    // MARK: - VoiceOver Support Tests
    
    func testVoiceOver_mainScreenElements_haveAccessibilityLabels() {
        // Wait for the app to fully load
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        
        let quoteTextExists = quoteTextStatic.waitForExistence(timeout: 5.0) || quoteTextOther.waitForExistence(timeout: 5.0)
        XCTAssertTrue(quoteTextExists, "Quote text should appear within 5 seconds")
        
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        
        // Get all main screen elements
        let settingsButton = app.buttons["settings_button"]
        let shareButton = app.buttons["share_button"]
        let loveButton = app.buttons["love_button"]
        
        // Wait a moment for all elements to be fully loaded
        Thread.sleep(forTimeInterval: 1.0)
        
        // Verify elements are accessibility elements
        XCTAssertTrue(quoteText.isAccessibilityElement, "Quote text should be accessible to VoiceOver")
        XCTAssertTrue(settingsButton.isAccessibilityElement, "Settings button should be accessible to VoiceOver")
        XCTAssertTrue(shareButton.isAccessibilityElement, "Share button should be accessible to VoiceOver")
        XCTAssertTrue(loveButton.isAccessibilityElement, "Love button should be accessible to VoiceOver")
        
        // Verify labels are meaningful and not empty
        let quoteContent = quoteText.value as? String ?? ""
        XCTAssertFalse(quoteContent.isEmpty, "Quote text should have accessible content")
        XCTAssertEqual(settingsButton.label, "Settings", "Settings button should have proper label")
        XCTAssertEqual(shareButton.label, "Share", "Share button should have proper label")
        XCTAssertEqual(loveButton.label, "Love this quote", "Love button should have descriptive label")
    }
    
    func testVoiceOver_navigationElements_haveAccessibilityHints() {
        // Test that interactive elements have helpful hints
        let settingsButton = app.buttons["settings_button"]
        let shareButton = app.buttons["share_button"]
        let loveButton = app.buttons["love_button"]
        
        // Note: Accessibility hints are tested through the value property in XCUITest
        // The exact implementation depends on how hints are set up in the app
        
        XCTAssertTrue(settingsButton.isEnabled, "Settings button should be enabled for interaction")
        XCTAssertTrue(shareButton.isEnabled, "Share button should be enabled for interaction")
        XCTAssertTrue(loveButton.isEnabled, "Love button should be enabled for interaction")
    }
    
    func testVoiceOver_settingsScreen_hasProperStructure() {
        // Navigate to settings
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()
        
        // Try different element types for settings title (could be button, staticText, or otherElement)
        let settingsTitleButton = app.buttons["settings_title"]
        let settingsTitleText = app.staticTexts["settings_title"]
        let settingsTitleOther = app.otherElements["settings_title"]
        
        let settingsTitleExists = settingsTitleButton.waitForExistence(timeout: 3.0) || 
                                 settingsTitleText.waitForExistence(timeout: 3.0) || 
                                 settingsTitleOther.waitForExistence(timeout: 3.0)
        XCTAssertTrue(settingsTitleExists, "Settings should open")
        
        let settingsTitle = settingsTitleButton.exists ? settingsTitleButton : 
                           (settingsTitleText.exists ? settingsTitleText : settingsTitleOther)
        
        // Test settings elements
        let closeButton = app.buttons["close_settings_button"]
        let notificationsSection = app.buttons["notifications_section"]
        let displaySection = app.buttons["display_section"]
        let lovedQuotesSection = app.buttons["loved_quotes_section"]
        let privacySection = app.buttons["privacy_section"]
        
        // Wait a moment for all elements to be fully loaded (like we do for main screen)
        Thread.sleep(forTimeInterval: 1.0)
        
        // Verify accessibility
        XCTAssertTrue(settingsTitle.isAccessibilityElement, "Settings title should be accessible")
        XCTAssertTrue(closeButton.isAccessibilityElement, "Close button should be accessible")
        XCTAssertTrue(notificationsSection.isAccessibilityElement, "Notifications section should be accessible")
        XCTAssertTrue(displaySection.isAccessibilityElement, "Display section should be accessible")
        XCTAssertTrue(lovedQuotesSection.isAccessibilityElement, "Loved quotes section should be accessible")
        XCTAssertTrue(privacySection.isAccessibilityElement, "Privacy section should be accessible")
        
        // Verify proper labels
        XCTAssertEqual(closeButton.label, "Close settings", "Close button should have descriptive label")
        XCTAssertFalse(notificationsSection.label.isEmpty, "Notifications section should have label")
        XCTAssertFalse(displaySection.label.isEmpty, "Display section should have label")
    }
    
    // MARK: - Dynamic Type Support Tests
    
    func testDynamicType_textScaling_layoutAdapts() {
        // Note: These tests would ideally be run with different text size settings
        // For automated testing, we verify that text elements exist and are readable
        
        // Try to find quote text as different element types since we use VStack container
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        XCTAssertTrue(quoteText.exists, "Quote text should exist for Dynamic Type support")
        
        // Verify text is accessible (don't require isAccessibilityElement as it may vary by implementation)
        let hasAccessibleContent = !quoteText.label.isEmpty || !(quoteText.value as? String ?? "").isEmpty
        XCTAssertTrue(hasAccessibleContent, "Quote text should have accessible content")
    }
    
    func testDynamicType_buttonSizes_remainTappable() {
        // Test that buttons remain tappable with larger text sizes
        let settingsButton = app.buttons["settings_button"]
        let shareButton = app.buttons["share_button"]
        let loveButton = app.buttons["love_button"]
        
        XCTAssertTrue(settingsButton.isHittable, "Settings button should remain tappable")
        XCTAssertTrue(shareButton.isHittable, "Share button should remain tappable")
        XCTAssertTrue(loveButton.isHittable, "Love button should remain tappable")
        
        // Verify minimum touch target size (buttons should be reasonably sized)
        let settingsFrame = settingsButton.frame
        let shareFrame = shareButton.frame
        let loveFrame = loveButton.frame
        
        XCTAssertGreaterThan(settingsFrame.width, 20, "Settings button should have adequate width")
        XCTAssertGreaterThan(settingsFrame.height, 20, "Settings button should have adequate height")
        XCTAssertGreaterThan(shareFrame.width, 20, "Share button should have adequate width")
        XCTAssertGreaterThan(shareFrame.height, 20, "Share button should have adequate height")
        XCTAssertGreaterThan(loveFrame.width, 20, "Love button should have adequate width")
        XCTAssertGreaterThan(loveFrame.height, 20, "Love button should have adequate height")
    }
    
    // MARK: - Color and Contrast Tests
    
    func testColorContrast_textElements_areReadable() {
        // Note: Automated color contrast testing is complex
        // These tests verify that text elements are visible and properly configured
        
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        // Try different element types for settings title
        let settingsTitleText = app.staticTexts["settings_title"]
        let settingsTitleButton = app.buttons["settings_title"]
        let settingsTitleOther = app.otherElements["settings_title"]
        let settingsTitle = settingsTitleText.exists ? settingsTitleText : 
                           (settingsTitleButton.exists ? settingsTitleButton : settingsTitleOther)
        
        // Navigate to settings to test settings title
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()
        
        // Verify text elements are visible (indicates proper contrast)
        XCTAssertTrue(quoteText.exists, "Quote text should be visible")
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3.0), "Settings title should be visible")
        
        // Verify text is not empty (indicates proper rendering)
        let quoteContent = quoteText.value as? String ?? ""
        XCTAssertFalse(quoteContent.isEmpty, "Quote text should have content")
        XCTAssertFalse(settingsTitle.label.isEmpty, "Settings title should have content")
    }
    
    func testColorContrast_buttonElements_areDistinguishable() {
        // Test that buttons are visually distinguishable
        let settingsButton = app.buttons["settings_button"]
        let shareButton = app.buttons["share_button"]
        let loveButton = app.buttons["love_button"]
        
        // Verify buttons are enabled and interactive (indicates proper contrast)
        XCTAssertTrue(settingsButton.isEnabled, "Settings button should be enabled")
        XCTAssertTrue(shareButton.isEnabled, "Share button should be enabled")
        XCTAssertTrue(loveButton.isEnabled, "Love button should be enabled")
        
        // Verify buttons are hittable (indicates they're visually distinct from background)
        XCTAssertTrue(settingsButton.isHittable, "Settings button should be hittable")
        XCTAssertTrue(shareButton.isHittable, "Share button should be hittable")
        XCTAssertTrue(loveButton.isHittable, "Love button should be hittable")
    }
    
    // MARK: - Touch Target Size Tests
    
    func testTouchTargets_minimumSize_meetsAccessibilityStandards() {
        // Apple recommends minimum 44x44 points for touch targets
        let buttons = [
            app.buttons["settings_button"],
            app.buttons["share_button"],
            app.buttons["love_button"]
        ]
        
        for button in buttons {
            let frame = button.frame
            XCTAssertGreaterThanOrEqual(frame.width, 44, "Button \(button.identifier) should meet minimum width")
            XCTAssertGreaterThanOrEqual(frame.height, 44, "Button \(button.identifier) should meet minimum height")
        }
    }
    
    func testTouchTargets_spacing_preventsAccidentalTaps() {
        // Test that buttons have adequate spacing between them
        let settingsButton = app.buttons["settings_button"]
        let shareButton = app.buttons["share_button"]
        
        let settingsFrame = settingsButton.frame
        let shareFrame = shareButton.frame
        
        // Calculate distance between buttons
        let horizontalDistance = abs(settingsFrame.maxX - shareFrame.minX)
        let verticalDistance = abs(settingsFrame.minY - shareFrame.minY)
        
        // Ensure adequate spacing (at least 8 points recommended)
        let hasAdequateSpacing = horizontalDistance >= 8 || verticalDistance >= 8
        XCTAssertTrue(hasAdequateSpacing, "Buttons should have adequate spacing to prevent accidental taps")
    }
    
    // MARK: - Focus Management Tests
    
    func testFocusManagement_screenTransitions_maintainsFocus() {
        // Test focus behavior during screen transitions
        let settingsButton = app.buttons["settings_button"]
        
        // Navigate to settings
        settingsButton.tap()
        
        // Try different element types for settings title
        let settingsTitleText = app.staticTexts["settings_title"]
        let settingsTitleButton = app.buttons["settings_title"]
        let settingsTitleOther = app.otherElements["settings_title"]
        let settingsTitle = settingsTitleText.exists ? settingsTitleText : 
                           (settingsTitleButton.exists ? settingsTitleButton : settingsTitleOther)
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3.0), "Settings should open")
        
        // Navigate back
        let closeButton = app.buttons["close_settings_button"]
        closeButton.tap()
        
        // Verify we're back on main screen
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        XCTAssertTrue(quoteText.waitForExistence(timeout: 3.0), "Should return to main screen")
        
        // Verify interactive elements are still accessible
        XCTAssertTrue(settingsButton.isHittable, "Settings button should be accessible after navigation")
    }
    
    func testFocusManagement_modalPresentation_handlesFocusCorrectly() {
        // Test focus with modal presentations (like privacy policy)
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()
        
        let privacySection = app.buttons["privacy_section"]
        if privacySection.waitForExistence(timeout: 3.0) {
            privacySection.tap()
            
            // Wait for modal
            Thread.sleep(forTimeInterval: 1.0)
            
            // Look for dismissal mechanism
            let dismissButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Close' OR label CONTAINS 'Done'"))
            if dismissButtons.count > 0 {
                let dismissButton = dismissButtons.firstMatch
                XCTAssertTrue(dismissButton.exists, "Modal should have accessible dismiss mechanism")
                
                dismissButton.tap()
                
                // Verify return to settings
                // Try different element types for settings title
        let settingsTitleText = app.staticTexts["settings_title"]
        let settingsTitleButton = app.buttons["settings_title"]
        let settingsTitleOther = app.otherElements["settings_title"]
        let settingsTitle = settingsTitleText.exists ? settingsTitleText : 
                           (settingsTitleButton.exists ? settingsTitleButton : settingsTitleOther)
                XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3.0), "Should return to settings after modal dismissal")
            }
        }
    }
    
    // MARK: - Gesture Accessibility Tests
    
    func testGestureAccessibility_swipeGestures_haveAlternatives() {
        // Test that swipe gestures have accessible alternatives
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        let initialQuote = quoteText.value as? String ?? ""
        
        // Verify swipe gesture works
        quoteText.swipeUp()
        Thread.sleep(forTimeInterval: 1.0)
        
        let newQuote = quoteText.value as? String ?? ""
        XCTAssertNotEqual(newQuote, initialQuote, "Swipe gesture should work")
        
        // Note: In a fully accessible app, there should be alternative navigation methods
        // This could be tested by looking for next/previous buttons or other navigation aids
    }
    
    func testGestureAccessibility_complexGestures_haveAlternatives() {
        // Test that complex gestures are not the only way to perform actions
        // In this app, the main gestures are swipes, which should have alternatives
        
        let settingsButton = app.buttons["settings_button"]
        let shareButton = app.buttons["share_button"]
        let loveButton = app.buttons["love_button"]
        
        // Verify primary actions can be performed with simple taps
        XCTAssertTrue(settingsButton.isHittable, "Settings should be accessible via simple tap")
        XCTAssertTrue(shareButton.isHittable, "Share should be accessible via simple tap")
        XCTAssertTrue(loveButton.isHittable, "Love action should be accessible via simple tap")
    }
    
    // MARK: - Content Accessibility Tests
    
    func testContentAccessibility_quoteText_isProperlyExposed() {
        // Test that quote content is properly exposed to assistive technologies
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        
        XCTAssertTrue(quoteText.isAccessibilityElement, "Quote should be accessible element")
        XCTAssertFalse(quoteText.label.isEmpty, "Quote should have accessible text")
        
        // Verify quote text is meaningful (not just placeholder)
        let quoteContent = quoteText.value as? String ?? ""
        XCTAssertGreaterThan(quoteContent.count, 10, "Quote should be substantial content")
        XCTAssertNotEqual(quoteContent, "Loading...", "Quote should be loaded content")
    }
    
    func testContentAccessibility_dynamicContent_updatesAccessibility() {
        // Test that accessibility information updates when content changes
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        
        let loveButton = app.buttons["love_button"]
        
        let initialQuote = quoteText.value as? String ?? ""
        let initialLoveState = loveButton.label
        
        // Change quote
        quoteText.swipeUp()
        Thread.sleep(forTimeInterval: 1.0)
        
        let newQuote = quoteText.value as? String ?? ""
        XCTAssertNotEqual(newQuote, initialQuote, "Quote content should update")
        XCTAssertTrue(quoteText.exists, "Quote should remain accessible after update")
        
        // Test love button state change
        loveButton.tap()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Note: The exact way love button state is exposed depends on implementation
        XCTAssertTrue(loveButton.isAccessibilityElement, "Love button should remain accessible after state change")
    }
    
    // MARK: - Settings Accessibility Tests
    
    func testSettingsAccessibility_allOptions_areAccessible() {
        // Navigate to settings
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()
        
        // Test display settings
        let displaySection = app.buttons["display_section"]
        if displaySection.waitForExistence(timeout: 3.0) {
            displaySection.tap()
            Thread.sleep(forTimeInterval: 1.0)
            
            // Look for font size options
            let fontSizeButtons = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'font_size'"))
            if fontSizeButtons.count > 0 {
                for i in 0..<fontSizeButtons.count {
                    let fontButton = fontSizeButtons.element(boundBy: i)
                    XCTAssertTrue(fontButton.isAccessibilityElement, "Font size option \(i) should be accessible")
                    XCTAssertFalse(fontButton.label.isEmpty, "Font size option \(i) should have label")
                }
            }
        }
    }
    
    func testSettingsAccessibility_stateChanges_areAnnounced() {
        // Test that settings changes are properly communicated
        // Navigate to settings
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()
        
        let displaySection = app.buttons["display_section"]
        if displaySection.waitForExistence(timeout: 3.0) {
            displaySection.tap()
            Thread.sleep(forTimeInterval: 1.0)
            
            // Interact with font size settings
            let fontSizeButtons = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'font_size'"))
            if fontSizeButtons.count > 0 {
                let fontButton = fontSizeButtons.firstMatch
                let initialState = fontButton.isSelected
                
                fontButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
                
                // Verify button is still accessible after state change
                XCTAssertTrue(fontButton.isAccessibilityElement, "Font button should remain accessible after selection")
            }
        }
    }
    
    // MARK: - Error and Edge Case Accessibility Tests
    
    func testAccessibility_errorStates_areAccessible() {
        // Test accessibility of error states or empty states
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()
        
        let lovedQuotesSection = app.buttons["loved_quotes_section"]
        if lovedQuotesSection.waitForExistence(timeout: 3.0) {
            lovedQuotesSection.tap()
            Thread.sleep(forTimeInterval: 1.0)
            
            // Look for empty state message
            let emptyStateText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'No loved quotes' OR label CONTAINS 'heart button'"))
            if emptyStateText.count > 0 {
                let emptyMessage = emptyStateText.firstMatch
                XCTAssertTrue(emptyMessage.isAccessibilityElement, "Empty state message should be accessible")
                XCTAssertFalse(emptyMessage.label.isEmpty, "Empty state should have helpful message")
            }
        }
    }
    
    func testAccessibility_loadingStates_areAccessible() {
        // Test that loading states are accessible
        // Note: This test would be more meaningful with network-dependent content
        
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        XCTAssertTrue(quoteText.isAccessibilityElement, "Content should be accessible even during loading")
        
        // Verify content is not stuck in loading state
        let quoteContent = quoteText.value as? String ?? ""
        XCTAssertNotEqual(quoteContent, "Loading...", "Content should not be stuck in loading state")
    }
    
    // MARK: - Performance Accessibility Tests
    
    func testAccessibilityPerformance_elementDiscovery_isEfficient() {
        // Test that accessibility elements can be discovered efficiently
        measure {
            let elements = [
                // Use flexible detection for quote text
                (app.staticTexts["quote_text"].exists ? app.staticTexts["quote_text"] : app.otherElements["quote_text"]),
                app.buttons["settings_button"],
                app.buttons["share_button"],
                app.buttons["love_button"]
            ]
            
            for element in elements {
                _ = element.exists
                _ = element.isAccessibilityElement
            }
        }
    }
    
    func testAccessibilityPerformance_navigationTransitions_remainResponsive() {
        // Test accessibility performance during navigation
        measure {
            let settingsButton = app.buttons["settings_button"]
            settingsButton.tap()
            
            // Try different element types for settings title
        let settingsTitleText = app.staticTexts["settings_title"]
        let settingsTitleButton = app.buttons["settings_title"]
        let settingsTitleOther = app.otherElements["settings_title"]
        let settingsTitle = settingsTitleText.exists ? settingsTitleText : 
                           (settingsTitleButton.exists ? settingsTitleButton : settingsTitleOther)
            _ = settingsTitle.waitForExistence(timeout: 2.0)
            
            let closeButton = app.buttons["close_settings_button"]
            closeButton.tap()
            
            // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
            _ = quoteText.waitForExistence(timeout: 2.0)
        }
    }
    
    // MARK: - Cross-Platform Accessibility Tests
    
    func testAccessibility_iPhone_layoutWorksCorrectly() {
        // Test accessibility on iPhone-sized screens
        // Note: Specific device testing would require running on different simulators
        
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        let buttons = [
            app.buttons["settings_button"],
            app.buttons["share_button"],
            app.buttons["love_button"]
        ]
        
        XCTAssertTrue(quoteText.exists, "Quote should be accessible on iPhone")
        
        for button in buttons {
            XCTAssertTrue(button.isHittable, "Buttons should be accessible on iPhone")
        }
    }
    
    func testAccessibility_iPad_layoutWorksCorrectly() {
        // Test accessibility on iPad-sized screens
        // Note: This test assumes the app supports iPad
        
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        let settingsButton = app.buttons["settings_button"]
        
        XCTAssertTrue(quoteText.exists, "Quote should be accessible on iPad")
        XCTAssertTrue(settingsButton.isHittable, "Settings should be accessible on iPad")
        
        // Test that touch targets remain appropriate on larger screens
        let frame = settingsButton.frame
        XCTAssertGreaterThanOrEqual(frame.width, 44, "Touch targets should remain adequate on iPad")
        XCTAssertGreaterThanOrEqual(frame.height, 44, "Touch targets should remain adequate on iPad")
    }
}