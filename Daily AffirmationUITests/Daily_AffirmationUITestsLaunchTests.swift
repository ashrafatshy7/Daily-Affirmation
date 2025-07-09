//
//  Daily_AffirmationUITestsLaunchTests.swift
//  Daily AffirmationUITests
//
//  Created by Ashraf Atshy on 08/07/2025.
//

import XCTest

final class Daily_AffirmationUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify app launches successfully
        XCTAssertTrue(app.exists, "App should launch successfully")
        
        // Wait for main content to load
        let quoteText = app.staticTexts["quote_text"]
        XCTAssertTrue(quoteText.waitForExistence(timeout: 10.0), "Quote text should appear within 10 seconds")

        // Take screenshot of launch screen
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchWithDifferentLanguages() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Test launch with different languages
        let languages = ["English", "עברית", "العربية"]
        
        for (index, language) in languages.enumerated() {
            // Navigate to settings
            let settingsButton = app.buttons["settings_button"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 5.0), "Settings button should be available")
            settingsButton.tap()
            
            // Language options should be visible without needing to tap a section
            let languageButton = app.buttons[language]
            if languageButton.waitForExistence(timeout: 3.0) {
                languageButton.tap()
                
                // Wait for language to apply and settings to auto-dismiss
                Thread.sleep(forTimeInterval: 1.5)
                
                // Verify settings sheet is dismissed by checking main screen elements
                let quoteText = app.staticTexts["quote_text"]
                XCTAssertTrue(quoteText.waitForExistence(timeout: 5.0), "Quote text should be visible after language change")
                
                // Take screenshot
                let attachment = XCTAttachment(screenshot: app.screenshot())
                attachment.name = "Launch Screen - \(language)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }
    
    @MainActor
    func testLaunchWithDarkMode() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to settings
        let settingsButton = app.buttons["settings_button"]
        settingsButton.tap()
        
        // Toggle dark mode
        let darkModeToggle = app.switches.matching(NSPredicate(format: "label CONTAINS 'Dark' OR label CONTAINS 'dark'")).firstMatch
        darkModeToggle.tap()
        
        // Close settings
        let closeButton = app.buttons["close_settings_button"]
        if closeButton.exists {
            closeButton.tap()
        } else {
            app.swipeDown()
        }
        
        // Wait for dark mode to apply
        Thread.sleep(forTimeInterval: 1.0)
        
        // Take screenshot
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Dark Mode"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchPerformanceMetrics() throws {
        // Test launch performance with metrics
        let app = XCUIApplication()
        
        measure(metrics: [
            XCTApplicationLaunchMetric(),
            XCTMemoryMetric(),
            XCTCPUMetric()
        ]) {
            app.launch()
            
            // Wait for key elements to load
            let quoteText = app.staticTexts["quote_text"]
            _ = quoteText.waitForExistence(timeout: 5.0)
            
            app.terminate()
        }
    }
    
    @MainActor
    func testLaunchStability() throws {
        // Test multiple launches for stability
        for i in 1...5 {
            let app = XCUIApplication()
            app.launch()
            
            // Verify app launches successfully each time
            XCTAssertTrue(app.exists, "App should launch successfully on attempt \(i)")
            
            let quoteText = app.staticTexts["quote_text"]
            XCTAssertTrue(quoteText.waitForExistence(timeout: 5.0), "Quote text should appear on attempt \(i)")
            
            // Perform some basic interactions
            let nextButton = app.buttons["next_button"]
            nextButton.tap()
            
            Thread.sleep(forTimeInterval: 0.5)
            
            // Take screenshot
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Launch Stability Test - Attempt \(i)"
            attachment.lifetime = .keepAlways
            add(attachment)
            
            app.terminate()
        }
    }
    
    @MainActor
    func testLaunchWithRotation() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Test launch in different orientations
        let orientations: [UIDeviceOrientation] = [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown]
        
        for orientation in orientations {
            XCUIDevice.shared.orientation = orientation
            Thread.sleep(forTimeInterval: 1.0)
            
            // Verify app still works after rotation
            let quoteText = app.staticTexts["quote_text"]
            XCTAssertTrue(quoteText.exists, "Quote text should exist in \(orientation) orientation")
            
            // Take screenshot
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Launch Screen - \(orientation)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        
        // Return to portrait
        XCUIDevice.shared.orientation = .portrait
    }
    
    @MainActor
    func testLaunchAccessibility() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Test launch with accessibility features
        let quoteText = app.staticTexts["quote_text"]
        XCTAssertTrue(quoteText.waitForExistence(timeout: 5.0))
        
        // Check accessibility elements
        XCTAssertTrue(quoteText.exists, "Quote text should exist")
        XCTAssertFalse(quoteText.label.isEmpty, "Quote text should have accessibility label")
        
        // Test navigation with accessibility
        let nextButton = app.buttons["next_button"]
        XCTAssertTrue(nextButton.exists, "Next button should exist")
        XCTAssertFalse(nextButton.label.isEmpty, "Next button should have accessibility label")
        
        // Take screenshot
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Accessibility"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}