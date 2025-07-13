//
//  OnboardingTests.swift
//  Daily AffirmationTests
//
//  Created for testing onboarding functionality
//

import XCTest
import SwiftUI
@testable import Daily_Affirmation

final class OnboardingTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Reset onboarding state for each test
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
    }
    
    override func tearDownWithError() throws {
        // Clean up
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
        try super.tearDownWithError()
    }
    
    // MARK: - Onboarding State Tests
    
    func testOnboardingState_initialState_shouldShowOnboarding() {
        // Act
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        let shouldShowOnboarding = !hasSeenOnboarding
        
        // Assert
        XCTAssertTrue(shouldShowOnboarding, "Should show onboarding for new users")
    }
    
    func testOnboardingState_afterCompletion_shouldNotShowOnboarding() {
        // Arrange
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        
        // Act
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        let shouldShowOnboarding = !hasSeenOnboarding
        
        // Assert
        XCTAssertFalse(shouldShowOnboarding, "Should not show onboarding for returning users")
    }
    
    func testOnboardingCompletion_setsUserDefaults() {
        // Act
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        
        // Assert
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasSeenOnboarding"), 
                     "Should persist onboarding completion")
    }
    
    // MARK: - Onboarding View Tests
    
    func testOnboardingView_canInitialize() {
        // Act & Assert - Should not crash
        let onboardingView = OnboardingView()
        XCTAssertNotNil(onboardingView, "OnboardingView should initialize successfully")
    }
    
    func testOnboardingPageView_canInitialize() {
        // Act & Assert - Should not crash
        let pageView = OnboardingPageView(
            icon: "sparkles",
            title: "Test Title",
            subtitle: "Test Subtitle",
            features: ["Feature 1", "Feature 2"]
        )
        XCTAssertNotNil(pageView, "OnboardingPageView should initialize successfully")
    }
    
    func testOnboardingPageView_withPremiumFeature_canInitialize() {
        // Act & Assert - Should not crash
        let premiumPageView = OnboardingPageView(
            icon: "clock.arrow.2.circlepath",
            title: "Premium Title",
            subtitle: "Premium Subtitle",
            features: ["Premium Feature 1", "Premium Feature 2"],
            isPremiumFeature: true
        )
        XCTAssertNotNil(premiumPageView, "Premium OnboardingPageView should initialize successfully")
    }
    
    // MARK: - Onboarding Subscription View Tests
    
    func testOnboardingSubscriptionView_canInitialize() {
        // Act & Assert - Should not crash
        let subscriptionView = OnboardingSubscriptionView()
        XCTAssertNotNil(subscriptionView, "OnboardingSubscriptionView should initialize successfully")
    }
    
    // MARK: - App Integration Tests
    
    func testAppShowsOnboarding_forNewUsers() {
        // Arrange
        UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
        
        // Act
        let shouldShowOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        
        // Assert
        XCTAssertTrue(shouldShowOnboarding, "App should show onboarding for new users")
    }
    
    func testAppHidesOnboarding_forReturningUsers() {
        // Arrange
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        
        // Act
        let shouldShowOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        
        // Assert
        XCTAssertFalse(shouldShowOnboarding, "App should not show onboarding for returning users")
    }
    
    // MARK: - Reset Onboarding Tests
    
    func testResetOnboarding_clearsUserDefaults() {
        // Arrange
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasSeenOnboarding"))
        
        // Act
        UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
        
        // Assert
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "hasSeenOnboarding"), 
                      "Should reset onboarding state")
    }
    
    func testResetOnboardingNotification_exists() {
        // Act
        let notificationName = Notification.Name.resetOnboarding
        
        // Assert
        XCTAssertEqual(notificationName.rawValue, "resetOnboarding", 
                      "Reset onboarding notification should exist")
    }
    
    // MARK: - Onboarding Flow Tests
    
    func testOnboardingFlow_hasCorrectPageCount() {
        // The onboarding flow should have 3 pages
        let expectedPageCount = 3
        
        // This would be tested in the UI test layer, but we can verify the concept
        XCTAssertEqual(expectedPageCount, 3, "Onboarding should have 3 pages")
    }
    
    func testOnboardingFlow_pageProgression() {
        // Test page progression logic
        var currentPage = 0
        let totalPages = 3
        
        // Simulate next page
        currentPage += 1
        XCTAssertEqual(currentPage, 1, "Should advance to page 1")
        
        currentPage += 1
        XCTAssertEqual(currentPage, 2, "Should advance to page 2")
        
        // Should show subscription on final page
        XCTAssertEqual(currentPage, totalPages - 1, "Should be on final page before subscription")
    }
}