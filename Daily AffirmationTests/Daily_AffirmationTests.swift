//
//  Daily_AffirmationTests.swift
//  Daily AffirmationTests
//
//  Created by Ashraf Atshy on 11/07/2025.
//

import XCTest
@testable import Daily_Affirmation

final class Daily_AffirmationTests: XCTestCase {
    
    func testAppLaunch() {
        // Basic test to ensure the app can initialize
        let app = Daily_AffirmationApp()
        XCTAssertNotNil(app, "App should initialize successfully")
    }
    
    func testOnboardingUserDefaults() {
        // Test onboarding tracking
        UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "hasSeenOnboarding"))
        
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasSeenOnboarding"))
        
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
    }
}
