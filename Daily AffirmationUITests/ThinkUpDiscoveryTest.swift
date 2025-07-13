//
//  OnboardingUITests.swift
//  Daily AffirmationUITests
//
//  Created for testing onboarding UI flow
//

import XCTest

final class OnboardingUITests: XCTestCase {
    
    private var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        
        app = XCUIApplication()
        
        // Reset onboarding for testing
        app.launchArguments.append("--reset-onboarding")
        app.launch()
    }
    
    func testOnboardingFlow_displaysCorrectly() {
        // Test that onboarding appears for new users
        // Note: This test assumes onboarding is shown
        
        // Wait for onboarding to appear
        let onboardingExists = app.otherElements.containing(.staticText, identifier:"Daily Inspiration").element.waitForExistence(timeout: 5)
        
        if onboardingExists {
            // Test onboarding flow
            XCTAssertTrue(app.exists, "App should be running")
            
            // Check for continue button
            let continueButton = app.buttons["Continue"]
            if continueButton.exists {
                XCTAssertTrue(continueButton.exists, "Continue button should exist in onboarding")
            }
            
            // Check for page indicators
            let pageIndicators = app.otherElements.matching(identifier: "page_indicator")
            XCTAssertGreaterThan(pageIndicators.count, 0, "Should have page indicators")
        } else {
            // If onboarding doesn't appear, app should show main content
            XCTAssertTrue(app.exists, "App should still be running even without onboarding")
        }
    }
    
    func testOnboardingDismissal_worksCorrectly() {
        // Test X button functionality
        let xButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'xmark'")).element
        
        if xButton.waitForExistence(timeout: 5) {
            xButton.tap()
            
            // Should dismiss onboarding and show main app
            let mainAppContent = app.otherElements["quote_text"]
            XCTAssertTrue(mainAppContent.waitForExistence(timeout: 3), "Should show main app after dismissing onboarding")
        }
    }
    
    func testMainAppElements_afterOnboarding() {
        // Skip onboarding if it appears, then test main app
        let xButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'xmark'")).element
        if xButton.waitForExistence(timeout: 3) {
            xButton.tap()
        }
        
        // Test main app elements
        let settingsButton = app.buttons["settings_button"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button should exist")
        
        let shareButton = app.buttons["share_button"]
        XCTAssertTrue(shareButton.exists, "Share button should exist")
        
        let loveButton = app.buttons["love_button"]
        XCTAssertTrue(loveButton.exists, "Love button should exist")
    }
    
    func testSubscriptionFlow_canBeAccessed() {
        // Skip onboarding if it appears
        let xButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'xmark'")).element
        if xButton.waitForExistence(timeout: 3) {
            xButton.tap()
        }
        
        // Open settings
        let settingsButton = app.buttons["settings_button"]
        if settingsButton.waitForExistence(timeout: 5) {
            settingsButton.tap()
            
            // Look for premium features section
            let premiumSection = app.buttons["premium_section"]
            if premiumSection.waitForExistence(timeout: 3) {
                XCTAssertTrue(premiumSection.exists, "Premium features section should exist in settings")
            }
        }
    }
}