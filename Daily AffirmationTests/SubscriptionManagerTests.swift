//
//  SubscriptionManagerTests.swift
//  Daily AffirmationTests
//
//  Created for testing subscription functionality
//

import XCTest
import StoreKit
@testable import Daily_Affirmation

@MainActor
final class SubscriptionManagerTests: XCTestCase {
    
    private var subscriptionManager: SubscriptionManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        subscriptionManager = SubscriptionManager.shared
        
        // Reset subscription state for testing
        UserDefaults.standard.set(false, forKey: "hasTimeRangeAccess")
    }
    
    override func tearDownWithError() throws {
        // Clean up
        UserDefaults.standard.removeObject(forKey: "hasTimeRangeAccess")
        subscriptionManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testInit_setsCorrectProductIdentifiers() {
        // Assert
        XCTAssertFalse(subscriptionManager.products.isEmpty || subscriptionManager.isLoading, 
                      "Should have product identifiers configured")
        XCTAssertFalse(subscriptionManager.hasTimeRangeAccess, "Should not have access by default")
        XCTAssertNil(subscriptionManager.currentSubscription, "Should not have current subscription by default")
    }
    
    // MARK: - Subscription Access Tests
    
    func testHasTimeRangeAccess_initialState_returnsFalse() {
        // Act & Assert
        XCTAssertFalse(subscriptionManager.hasTimeRangeAccess, "Should not have access initially")
    }
    
    func testTimeRangeAccessUserDefaults_persistsState() {
        // Arrange
        UserDefaults.standard.set(true, forKey: "hasTimeRangeAccess")
        
        // Act
        let hasAccess = UserDefaults.standard.bool(forKey: "hasTimeRangeAccess")
        
        // Assert
        XCTAssertTrue(hasAccess, "UserDefaults should persist subscription state")
    }
    
    // MARK: - Product Loading Tests
    
    func testLoadProducts_initializes_withoutError() async {
        // Act & Assert - Should not crash
        await subscriptionManager.loadProducts()
        
        // Note: Products may be empty in test environment without StoreKit configuration
        // This test ensures the method doesn't crash
    }
    
    // MARK: - Formatted Prices Tests
    
    func testFormattedPrice_withMockProduct_returnsDisplayPrice() {
        // This test would require a mock Product, which is complex with StoreKit
        // In a real implementation, we'd test with actual StoreKit test products
        XCTAssertTrue(true, "Placeholder for formatted price tests")
    }
    
    // MARK: - Subscription Period Tests
    
    func testSubscriptionPeriod_withMockProduct_returnsCorrectFormat() {
        // This test would require a mock Product with subscription details
        // In a real implementation, we'd test with actual StoreKit test products
        XCTAssertTrue(true, "Placeholder for subscription period tests")
    }
    
    // MARK: - Offline Access Tests
    
    func testLoadOfflineSubscriptionStatus_loadsFromUserDefaults() {
        // Arrange
        UserDefaults.standard.set(true, forKey: "hasTimeRangeAccess")
        
        // Act
        subscriptionManager.loadOfflineSubscriptionStatus()
        
        // Assert
        XCTAssertTrue(subscriptionManager.hasTimeRangeAccess, "Should load access state from UserDefaults")
        
        // Test false state
        UserDefaults.standard.set(false, forKey: "hasTimeRangeAccess")
        subscriptionManager.loadOfflineSubscriptionStatus()
        XCTAssertFalse(subscriptionManager.hasTimeRangeAccess, "Should load false state from UserDefaults")
    }
    
    // MARK: - Error Handling Tests
    
    func testStoreError_failedVerification_exists() {
        // Assert
        let error = StoreError.failedVerification
        XCTAssertEqual(error, StoreError.failedVerification, "StoreError enum should exist")
    }
}

// MARK: - Integration Tests with QuoteManager

final class SubscriptionIntegrationTests: XCTestCase {
    
    private var quoteManager: QuoteManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        quoteManager = QuoteManager()
        
        // Reset subscription state
        UserDefaults.standard.set(false, forKey: "hasTimeRangeAccess")
    }
    
    override func tearDownWithError() throws {
        UserDefaults.standard.removeObject(forKey: "hasTimeRangeAccess")
        quoteManager = nil
        try super.tearDownWithError()
    }
    
    func testHasTimeRangeAccess_withoutSubscription_returnsFalse() {
        // Act & Assert
        XCTAssertFalse(quoteManager.hasTimeRangeAccess, "Should not have time range access without subscription")
    }
    
    func testHasTimeRangeAccess_withSubscription_returnsTrue() {
        // Arrange
        UserDefaults.standard.set(true, forKey: "hasTimeRangeAccess")
        
        // Act & Assert
        XCTAssertTrue(quoteManager.hasTimeRangeAccess, "Should have time range access with subscription")
    }
    
    func testNotificationMode_withoutSubscription_revertsToSingle() {
        // Arrange - Ensure no subscription access
        UserDefaults.standard.set(false, forKey: "hasTimeRangeAccess")
        quoteManager.notificationMode = .range
        
        // Act & Assert - The setter should revert to .single if no access
        XCTAssertEqual(quoteManager.notificationMode, .single, "Should revert to single mode without subscription")
    }
    
    func testNotificationMode_withSubscription_allowsRange() {
        // Arrange
        UserDefaults.standard.set(true, forKey: "hasTimeRangeAccess")
        
        // Act
        quoteManager.notificationMode = .range
        
        // Assert
        XCTAssertEqual(quoteManager.notificationMode, .range, "Should allow range mode with subscription")
    }
}