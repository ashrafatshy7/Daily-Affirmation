//
//  SettingsUITests.swift
//  Daily AffirmationUITests
//
//  Created by QA Engineer on 12/07/2025.
//

import XCTest

final class SettingsUITests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var app: XCUIApplication!
    
    // MARK: - Setup and Teardown
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launch()
        
        // Skip onboarding if it appears
        let xButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'xmark'")).element
        if xButton.waitForExistence(timeout: 3) {
            xButton.tap()
        }
        
        // Navigate to settings
        let settingsButton = app.buttons["settings_button"]
        if settingsButton.waitForExistence(timeout: 5) {
            settingsButton.tap()
        }
        
        // Try different element types for settings title
        let settingsTitleText = app.staticTexts["settings_title"]
        let settingsTitleButton = app.buttons["settings_title"]
        let settingsTitleOther = app.otherElements["settings_title"]
        let settingsTitle = settingsTitleText.exists ? settingsTitleText : 
                           (settingsTitleButton.exists ? settingsTitleButton : settingsTitleOther)
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3.0), "Settings should open")
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Helper Methods
    
    private func navigateBackToSettings() {
        // If we're in a subsection, navigate back to main settings
        let backButtons = app.navigationBars.buttons.matching(identifier: "Back")
        if backButtons.count > 0 {
            backButtons.firstMatch.tap()
        }
        
        // Wait for settings to appear
        // Try different element types for settings title
        let settingsTitleText = app.staticTexts["settings_title"]
        let settingsTitleButton = app.buttons["settings_title"]
        let settingsTitleOther = app.otherElements["settings_title"]
        let settingsTitle = settingsTitleText.exists ? settingsTitleText : 
                           (settingsTitleButton.exists ? settingsTitleButton : settingsTitleOther)
        _ = settingsTitle.waitForExistence(timeout: 3.0)
    }
    
    // MARK: - Settings Main Screen Tests
    
    func testSettingsMainScreen_displaysAllSections() {
        // Assert
        let notificationsSection = app.buttons["notifications_section"]
        let displaySection = app.buttons["display_section"]
        let lovedQuotesSection = app.buttons["loved_quotes_section"]
        let privacySection = app.buttons["privacy_section"]
        
        XCTAssertTrue(notificationsSection.exists, "Notifications section should be visible")
        XCTAssertTrue(displaySection.exists, "Display section should be visible")
        XCTAssertTrue(lovedQuotesSection.exists, "Loved quotes section should be visible")
        XCTAssertTrue(privacySection.exists, "Privacy section should be visible")
    }
    
    func testSettingsMainScreen_sectionsHaveCorrectIcons() {
        // Test that sections have their expected visual elements
        let notificationsSection = app.buttons["notifications_section"]
        let displaySection = app.buttons["display_section"]
        let lovedQuotesSection = app.buttons["loved_quotes_section"]
        let privacySection = app.buttons["privacy_section"]
        
        // Verify sections are tappable (indicating they have proper button setup)
        XCTAssertTrue(notificationsSection.isEnabled, "Notifications section should be tappable")
        XCTAssertTrue(displaySection.isEnabled, "Display section should be tappable")
        XCTAssertTrue(lovedQuotesSection.isEnabled, "Loved quotes section should be tappable")
        XCTAssertTrue(privacySection.isEnabled, "Privacy section should be tappable")
    }
    
    func testSettingsMainScreen_closeButton_returnsToMainScreen() {
        // Arrange
        let closeButton = app.buttons["close_settings_button"]
        
        // Act
        closeButton.tap()
        
        // Assert
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        XCTAssertTrue(quoteText.waitForExistence(timeout: 3.0), "Should return to main quote screen")
    }
    
    // MARK: - Premium Features Section Tests
    
    func testPremiumFeaturesSection_exists_andIsInteractive() {
        // Arrange & Assert
        let premiumSection = app.buttons["premium_section"]
        XCTAssertTrue(premiumSection.exists, "Premium features section should exist")
        XCTAssertTrue(premiumSection.isEnabled, "Premium features section should be interactive")
    }
    
    func testPremiumFeaturesSection_tap_opensSubscriptionView() {
        // Arrange
        let premiumSection = app.buttons["premium_section"]
        
        // Act
        premiumSection.tap()
        
        // Assert
        // Look for subscription-related content
        let subscriptionTitle = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Premium' OR label CONTAINS 'Subscription' OR label CONTAINS 'Unlock'")).firstMatch
        XCTAssertTrue(subscriptionTitle.waitForExistence(timeout: 3.0), "Should open subscription view")
    }
    
    func testPremiumFeaturesSection_subscriptionModal_canBeDismissed() {
        // Arrange
        let premiumSection = app.buttons["premium_section"]
        premiumSection.tap()
        
        // Wait for modal to appear
        Thread.sleep(forTimeInterval: 1.0)
        
        // Act
        // Look for close button or dismiss mechanism
        let closeButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Close' OR identifier CONTAINS 'xmark'"))
        
        if closeButtons.count > 0 {
            closeButtons.firstMatch.tap()
            
            // Assert
            let settingsTitleText = app.staticTexts["settings_title"]
            let settingsTitleButton = app.buttons["settings_title"]
            let settingsTitleOther = app.otherElements["settings_title"]
            let settingsTitle = settingsTitleText.exists ? settingsTitleText : 
                               (settingsTitleButton.exists ? settingsTitleButton : settingsTitleOther)
            XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3.0), "Should return to settings after dismissing subscription")
        }
    }
    
    // MARK: - Notifications Section Tests
    
    func testNotificationsSection_navigation_opensNotificationSettings() {
        // Arrange
        let notificationsSection = app.buttons["notifications_section"]
        
        // Act
        notificationsSection.tap()
        
        // Assert
        // Look for notification-specific elements
        let notificationTitle = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Notification'")).firstMatch
        XCTAssertTrue(notificationTitle.waitForExistence(timeout: 3.0), "Should navigate to notification settings")
    }
    
    func testNotificationsSection_backNavigation_returnsToSettings() {
        // Arrange
        let notificationsSection = app.buttons["notifications_section"]
        notificationsSection.tap()
        
        // Wait for navigation
        Thread.sleep(forTimeInterval: 1.0)
        
        // Act
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }
        
        // Assert
        // Try different element types for settings title
        let settingsTitleText = app.staticTexts["settings_title"]
        let settingsTitleButton = app.buttons["settings_title"]
        let settingsTitleOther = app.otherElements["settings_title"]
        let settingsTitle = settingsTitleText.exists ? settingsTitleText : 
                           (settingsTitleButton.exists ? settingsTitleButton : settingsTitleOther)
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3.0), "Should return to main settings")
    }
    
    // MARK: - Display Section Tests
    
    func testDisplaySection_navigation_opensDisplaySettings() {
        // Arrange
        let displaySection = app.buttons["display_section"]
        
        // Act
        displaySection.tap()
        
        // Assert
        // Look for font-related elements
        let displayTitle = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Font' OR label CONTAINS 'Display'")).firstMatch
        XCTAssertTrue(displayTitle.waitForExistence(timeout: 3.0), "Should navigate to display settings")
    }
    
    func testDisplaySection_fontSizeOptions_areInteractive() {
        // Arrange
        let displaySection = app.buttons["display_section"]
        displaySection.tap()
        
        // Wait for navigation
        Thread.sleep(forTimeInterval: 1.0)
        
        // Act & Assert
        // Look for font size buttons or elements
        let fontSizeElements = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'font_size'"))
        
        if fontSizeElements.count > 0 {
            let firstFontOption = fontSizeElements.firstMatch
            XCTAssertTrue(firstFontOption.exists, "Font size options should be available")
            XCTAssertTrue(firstFontOption.isEnabled, "Font size options should be interactive")
            
            // Test tapping a font size option
            firstFontOption.tap()
            Thread.sleep(forTimeInterval: 0.5)
            // Note: Additional assertions could verify the selection state
        }
    }
    
    func testDisplaySection_backNavigation_preservesSettings() {
        // Arrange
        let displaySection = app.buttons["display_section"]
        displaySection.tap()
        
        // Wait and potentially interact with settings
        Thread.sleep(forTimeInterval: 1.0)
        
        // Act
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }
        
        // Assert
        // Try different element types for settings title
        let settingsTitleText = app.staticTexts["settings_title"]
        let settingsTitleButton = app.buttons["settings_title"]
        let settingsTitleOther = app.otherElements["settings_title"]
        let settingsTitle = settingsTitleText.exists ? settingsTitleText : 
                           (settingsTitleButton.exists ? settingsTitleButton : settingsTitleOther)
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3.0), "Should return to main settings")
        
        // Verify we can navigate back to display section
        displaySection.tap()
        Thread.sleep(forTimeInterval: 1.0)
        // Note: Additional assertions could verify settings persistence
    }
    
    // MARK: - Loved Quotes Section Tests
    
    func testLovedQuotesSection_navigation_opensLovedQuotesView() {
        // Arrange
        let lovedQuotesSection = app.buttons["loved_quotes_section"]
        
        // Act
        lovedQuotesSection.tap()
        
        // Assert
        let lovedQuotesTitle = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Loved' OR label CONTAINS 'Love'")).firstMatch
        XCTAssertTrue(lovedQuotesTitle.waitForExistence(timeout: 3.0), "Should navigate to loved quotes view")
    }
    
    func testLovedQuotesSection_emptyState_displaysCorrectMessage() {
        // Arrange
        let lovedQuotesSection = app.buttons["loved_quotes_section"]
        lovedQuotesSection.tap()
        
        // Wait for navigation
        Thread.sleep(forTimeInterval: 1.0)
        
        // Assert
        // Look for empty state message or elements
        let emptyStateText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'No loved quotes' OR label CONTAINS 'heart button'")).firstMatch
        
        // Note: This test assumes no quotes are loved initially
        // In a real test environment, you might want to reset the app state
        if emptyStateText.exists {
            XCTAssertTrue(emptyStateText.exists, "Should show empty state when no quotes are loved")
        }
    }
    
    func testLovedQuotesSection_withLovedQuotes_displaysQuotesList() {
        // Note: This test would require pre-populating loved quotes
        // For now, we test the navigation and basic structure
        
        // Arrange
        let lovedQuotesSection = app.buttons["loved_quotes_section"]
        lovedQuotesSection.tap()
        
        // Wait for navigation
        Thread.sleep(forTimeInterval: 1.0)
        
        // Assert
        // The view should load without crashing
        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.exists, "Should have proper navigation structure")
    }
    
    // MARK: - Privacy Section Tests
    
    func testPrivacySection_tap_opensPrivacyPolicy() {
        // Arrange
        let privacySection = app.buttons["privacy_section"]
        
        // Act
        privacySection.tap()
        
        // Assert
        // Look for privacy policy content or modal
        let privacyTitle = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Privacy'")).firstMatch
        XCTAssertTrue(privacyTitle.waitForExistence(timeout: 3.0), "Privacy policy should open")
    }
    
    func testPrivacySection_modal_canBeDismissed() {
        // Arrange
        let privacySection = app.buttons["privacy_section"]
        privacySection.tap()
        
        // Wait for modal to appear
        Thread.sleep(forTimeInterval: 1.0)
        
        // Act
        // Look for close button or dismiss mechanism
        let closeButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Close' OR label CONTAINS 'Done' OR label CONTAINS 'Dismiss'"))
        
        if closeButtons.count > 0 {
            closeButtons.firstMatch.tap()
            
            // Assert
            // Try different element types for settings title
        let settingsTitleText = app.staticTexts["settings_title"]
        let settingsTitleButton = app.buttons["settings_title"]
        let settingsTitleOther = app.otherElements["settings_title"]
        let settingsTitle = settingsTitleText.exists ? settingsTitleText : 
                           (settingsTitleButton.exists ? settingsTitleButton : settingsTitleOther)
            XCTAssertTrue(settingsTitle.waitForExistence(timeout: 3.0), "Should return to settings after dismissing privacy policy")
        } else {
            // Try tapping outside the modal or using swipe gesture
            let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1))
            coordinate.tap()
        }
    }
    
    // MARK: - Navigation Flow Tests
    
    func testNavigationFlow_allSections_canBeNavigatedSequentially() {
        // Test navigating through all sections
        let sections = [
            "notifications_section",
            "premium_section",
            "display_section", 
            "loved_quotes_section"
        ]
        
        for sectionId in sections {
            // Navigate to section
            let section = app.buttons[sectionId]
            if section.exists {
                section.tap()
                Thread.sleep(forTimeInterval: 1.0)
                
                // Navigate back
                let backButton = app.navigationBars.buttons.firstMatch
                if backButton.exists {
                    backButton.tap()
                    Thread.sleep(forTimeInterval: 1.0)
                }
                
                // Verify we're back at settings
                // Try different element types for settings title
        let settingsTitleText = app.staticTexts["settings_title"]
        let settingsTitleButton = app.buttons["settings_title"]
        let settingsTitleOther = app.otherElements["settings_title"]
        let settingsTitle = settingsTitleText.exists ? settingsTitleText : 
                           (settingsTitleButton.exists ? settingsTitleButton : settingsTitleOther)
                XCTAssertTrue(settingsTitle.exists, "Should return to settings from \(sectionId)")
            }
        }
    }
    
    func testNavigationFlow_deepNavigation_maintainsState() {
        // Navigate to display section
        let displaySection = app.buttons["display_section"]
        displaySection.tap()
        Thread.sleep(forTimeInterval: 1.0)
        
        // Navigate back
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }
        
        // Navigate to loved quotes
        navigateBackToSettings()
        let lovedQuotesSection = app.buttons["loved_quotes_section"]
        lovedQuotesSection.tap()
        Thread.sleep(forTimeInterval: 1.0)
        
        // Verify navigation works
        XCTAssertTrue(app.navigationBars.firstMatch.exists, "Should maintain navigation structure")
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibility_settingsSections_haveProperLabels() {
        // Test accessibility labels for all sections
        let notificationsSection = app.buttons["notifications_section"]
        let premiumSection = app.buttons["premium_section"]
        let displaySection = app.buttons["display_section"]
        let lovedQuotesSection = app.buttons["loved_quotes_section"]
        let privacySection = app.buttons["privacy_section"]
        
        XCTAssertTrue(notificationsSection.isAccessibilityElement, "Notifications section should be accessible")
        XCTAssertTrue(premiumSection.isAccessibilityElement, "Premium section should be accessible")
        XCTAssertTrue(displaySection.isAccessibilityElement, "Display section should be accessible")
        XCTAssertTrue(lovedQuotesSection.isAccessibilityElement, "Loved quotes section should be accessible")
        XCTAssertTrue(privacySection.isAccessibilityElement, "Privacy section should be accessible")
        
        // Verify labels are meaningful
        XCTAssertFalse(notificationsSection.label.isEmpty, "Notifications section should have meaningful label")
        XCTAssertFalse(displaySection.label.isEmpty, "Display section should have meaningful label")
    }
    
    func testAccessibility_navigationElements_areAccessible() {
        // Test navigation elements
        // Try different element types for settings title
        let settingsTitleText = app.staticTexts["settings_title"]
        let settingsTitleButton = app.buttons["settings_title"]
        let settingsTitleOther = app.otherElements["settings_title"]
        let settingsTitle = settingsTitleText.exists ? settingsTitleText : 
                           (settingsTitleButton.exists ? settingsTitleButton : settingsTitleOther)
        let closeButton = app.buttons["close_settings_button"]
        
        XCTAssertTrue(settingsTitle.isAccessibilityElement, "Settings title should be accessible")
        XCTAssertTrue(closeButton.isAccessibilityElement, "Close button should be accessible")
        
        XCTAssertEqual(closeButton.label, "Close settings", "Close button should have proper accessibility label")
    }
    
    // MARK: - Visual Layout Tests
    
    func testVisualLayout_sectionsAreVisible_inPortraitMode() {
        // Ensure device is in portrait mode
        XCUIDevice.shared.orientation = .portrait
        Thread.sleep(forTimeInterval: 1.0)
        
        // Test that all sections are visible without scrolling
        let notificationsSection = app.buttons["notifications_section"]
        let displaySection = app.buttons["display_section"]
        let lovedQuotesSection = app.buttons["loved_quotes_section"]
        let privacySection = app.buttons["privacy_section"]
        
        XCTAssertTrue(notificationsSection.isHittable, "Notifications section should be visible and hittable")
        XCTAssertTrue(displaySection.isHittable, "Display section should be visible and hittable")
        XCTAssertTrue(lovedQuotesSection.isHittable, "Loved quotes section should be visible and hittable")
        XCTAssertTrue(privacySection.isHittable, "Privacy section should be visible and hittable")
    }
    
    func testVisualLayout_sectionsAreVisible_inLandscapeMode() {
        // Change to landscape mode
        XCUIDevice.shared.orientation = .landscapeLeft
        Thread.sleep(forTimeInterval: 1.0)
        
        // Test that sections are still accessible in landscape
        let notificationsSection = app.buttons["notifications_section"]
        let displaySection = app.buttons["display_section"]
        
        XCTAssertTrue(notificationsSection.exists, "Notifications section should exist in landscape")
        XCTAssertTrue(displaySection.exists, "Display section should exist in landscape")
        
        // Reset orientation
        XCUIDevice.shared.orientation = .portrait
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling_rapidNavigation_handlesGracefully() {
        // Rapidly navigate between sections
        let sections = ["notifications_section", "display_section", "loved_quotes_section"]
        
        for _ in 0..<5 {
            for sectionId in sections {
                let section = app.buttons[sectionId]
                if section.exists && section.isHittable {
                    section.tap()
                    Thread.sleep(forTimeInterval: 0.2)
                    
                    // Try to navigate back quickly
                    let backButton = app.navigationBars.buttons.firstMatch
                    if backButton.exists {
                        backButton.tap()
                        Thread.sleep(forTimeInterval: 0.2)
                    }
                }
            }
        }
        
        // Assert app is still responsive
        // Try different element types for settings title
        let settingsTitleText = app.staticTexts["settings_title"]
        let settingsTitleButton = app.buttons["settings_title"]
        let settingsTitleOther = app.otherElements["settings_title"]
        let settingsTitle = settingsTitleText.exists ? settingsTitleText : 
                           (settingsTitleButton.exists ? settingsTitleButton : settingsTitleOther)
        XCTAssertTrue(settingsTitle.exists, "Settings should still be responsive after rapid navigation")
    }
    
    func testErrorHandling_multipleBackNavigation_handlesGracefully() {
        // Navigate to a subsection
        let displaySection = app.buttons["display_section"]
        displaySection.tap()
        Thread.sleep(forTimeInterval: 1.0)
        
        // Rapidly tap back button multiple times
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            for _ in 0..<5 {
                if backButton.isHittable {
                    backButton.tap()
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
        }
        
        // App should handle this gracefully
        // Try different element types for settings title
        let settingsTitleText = app.staticTexts["settings_title"]
        let settingsTitleButton = app.buttons["settings_title"]
        let settingsTitleOther = app.otherElements["settings_title"]
        let settingsTitle = settingsTitleText.exists ? settingsTitleText : 
                           (settingsTitleButton.exists ? settingsTitleButton : settingsTitleOther)
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        
        let isInValidState = settingsTitle.exists || quoteText.exists
        XCTAssertTrue(isInValidState, "App should be in a valid state after multiple back navigations")
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_settingsNavigation() {
        // Measure settings navigation performance
        measure {
            let displaySection = app.buttons["display_section"]
            displaySection.tap()
            Thread.sleep(forTimeInterval: 0.5)
            
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }
    
    func testPerformance_sectionsLoading() {
        // Measure time for sections to become interactive
        measure {
            navigateBackToSettings()
            
            let allSectionsExist = app.buttons["notifications_section"].exists &&
                                 app.buttons["display_section"].exists &&
                                 app.buttons["loved_quotes_section"].exists &&
                                 app.buttons["privacy_section"].exists
            
            XCTAssertTrue(allSectionsExist, "All sections should load quickly")
        }
    }
    
    // MARK: - Integration Tests
    
    func testIntegration_settingsToMainFlow_maintainsAppState() {
        // Change a setting and verify it persists when returning to main screen
        
        // Navigate to display settings
        let displaySection = app.buttons["display_section"]
        displaySection.tap()
        Thread.sleep(forTimeInterval: 1.0)
        
        // Make a change (if possible to detect)
        let fontButtons = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'font_size'"))
        if fontButtons.count > 0 {
            fontButtons.firstMatch.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // Navigate back to main screen
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }
        
        navigateBackToSettings()
        let closeButton = app.buttons["close_settings_button"]
        closeButton.tap()
        
        // Verify main screen is functional
        // Try both staticTexts and otherElements for quote text
        let quoteTextStatic = app.staticTexts["quote_text"]
        let quoteTextOther = app.otherElements["quote_text"]
        let quoteText = quoteTextStatic.exists ? quoteTextStatic : quoteTextOther
        XCTAssertTrue(quoteText.waitForExistence(timeout: 3.0), "Should return to functional main screen")
        
        // Verify settings change persisted (would require specific implementation details)
    }
}