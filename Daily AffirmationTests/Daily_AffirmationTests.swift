//
//  Daily_AffirmationTests.swift
//  Daily AffirmationTests
//
//  Created by Ashraf Atshy on 08/07/2025.
//

import XCTest
import SwiftUI
import UserNotifications
@testable import Daily_Affirmation

final class Daily_AffirmationTests: XCTestCase {
    
    var quoteManager: QuoteManager!
    
    override func setUpWithError() throws {
        super.setUp()
        quoteManager = QuoteManager()
        // Reset UserDefaults for clean test state
        UserDefaults.standard.removeObject(forKey: "dailyNotifications")
        UserDefaults.standard.removeObject(forKey: "notificationTime")
        UserDefaults.standard.removeObject(forKey: "isDarkMode")
        UserDefaults.standard.removeObject(forKey: "fontSize")
        UserDefaults.standard.removeObject(forKey: "selectedLanguage")
    }
    
    override func tearDownWithError() throws {
        quoteManager = nil
        super.tearDown()
    }
}

// MARK: - QuoteManager Core Functionality Tests
extension Daily_AffirmationTests {
    
    func testQuoteManagerInitialization() throws {
        XCTAssertNotNil(quoteManager)
        XCTAssertFalse(quoteManager.quotes.isEmpty, "Quotes should be loaded on initialization")
        XCTAssertGreaterThanOrEqual(quoteManager.currentIndex, 0)
        XCTAssertLessThan(quoteManager.currentIndex, quoteManager.quotes.count)
    }
    
    func testCurrentQuoteNotEmpty() throws {
        let currentQuote = quoteManager.currentQuote
        XCTAssertFalse(currentQuote.isEmpty, "Current quote should not be empty")
        XCTAssertNotEqual(currentQuote, NSLocalizedString("loading", comment: ""))
    }
    
    func testNextQuoteNavigation() throws {
        let initialIndex = quoteManager.currentIndex
        let initialQuote = quoteManager.currentQuote
        
        quoteManager.nextQuote()
        
        if quoteManager.quotes.count > 1 {
            XCTAssertNotEqual(initialQuote, quoteManager.currentQuote, "Quote should change after nextQuote()")
        }
        
        let expectedIndex = (initialIndex + 1) % quoteManager.quotes.count
        XCTAssertEqual(quoteManager.currentIndex, expectedIndex, "Index should wrap around correctly")
    }
    
    func testPreviousQuoteNavigation() throws {
        quoteManager.currentIndex = 0
        let initialQuote = quoteManager.currentQuote
        
        quoteManager.previousQuote()
        
        if quoteManager.quotes.count > 1 {
            XCTAssertNotEqual(initialQuote, quoteManager.currentQuote, "Quote should change after previousQuote()")
            XCTAssertEqual(quoteManager.currentIndex, quoteManager.quotes.count - 1, "Should wrap to last quote")
        }
    }
    
    func testQuoteNavigationWithSingleQuote() throws {
        // Test edge case with mock single quote
        let originalQuotes = quoteManager.quotes
        quoteManager.quotes = ["Single quote"]
        quoteManager.currentIndex = 0
        
        let initialQuote = quoteManager.currentQuote
        
        quoteManager.nextQuote()
        XCTAssertEqual(quoteManager.currentQuote, initialQuote, "Quote should remain same with single quote")
        XCTAssertEqual(quoteManager.currentIndex, 0, "Index should remain 0")
        
        quoteManager.previousQuote()
        XCTAssertEqual(quoteManager.currentQuote, initialQuote, "Quote should remain same with single quote")
        XCTAssertEqual(quoteManager.currentIndex, 0, "Index should remain 0")
        
        // Restore original quotes
        quoteManager.quotes = originalQuotes
    }
    
    func testEmptyQuotesHandling() throws {
        let originalQuotes = quoteManager.quotes
        quoteManager.quotes = []
        
        let currentQuote = quoteManager.currentQuote
        XCTAssertEqual(currentQuote, NSLocalizedString("loading", comment: ""), "Should return loading message for empty quotes")
        
        quoteManager.nextQuote()
        XCTAssertEqual(quoteManager.currentIndex, 0, "Index should remain 0 for empty quotes")
        
        quoteManager.previousQuote()
        XCTAssertEqual(quoteManager.currentIndex, 0, "Index should remain 0 for empty quotes")
        
        // Restore original quotes
        quoteManager.quotes = originalQuotes
    }
}

// MARK: - Language and Localization Tests
extension Daily_AffirmationTests {
    
    func testLanguageEnumValues() throws {
        let english = QuoteManager.AppLanguage.english
        XCTAssertEqual(english.rawValue, "en")
        XCTAssertEqual(english.displayName, "English")
        XCTAssertFalse(english.isRTL)
        XCTAssertEqual(english.quotesFileName, "quotes")
        
        let hebrew = QuoteManager.AppLanguage.hebrew
        XCTAssertEqual(hebrew.rawValue, "he")
        XCTAssertEqual(hebrew.displayName, "עברית")
        XCTAssertTrue(hebrew.isRTL)
        XCTAssertEqual(hebrew.quotesFileName, "quotes_he")
        
        let arabic = QuoteManager.AppLanguage.arabic
        XCTAssertEqual(arabic.rawValue, "ar")
        XCTAssertEqual(arabic.displayName, "العربية")
        XCTAssertTrue(arabic.isRTL)
        XCTAssertEqual(arabic.quotesFileName, "quotes_ar")
    }
    
    func testLanguageChanging() throws {
        let originalLanguage = quoteManager.selectedLanguage
        let originalQuotes = quoteManager.quotes
        
        // Change to Hebrew
        quoteManager.selectedLanguage = .hebrew
        XCTAssertEqual(quoteManager.selectedLanguage, .hebrew)
        XCTAssertNotEqual(quoteManager.quotes, originalQuotes, "Quotes should change with language")
        
        // Change to Arabic
        quoteManager.selectedLanguage = .arabic
        XCTAssertEqual(quoteManager.selectedLanguage, .arabic)
        
        // Change back to original
        quoteManager.selectedLanguage = originalLanguage
        XCTAssertEqual(quoteManager.selectedLanguage, originalLanguage)
    }
    
    func testRTLLanguageDetection() throws {
        XCTAssertFalse(QuoteManager.AppLanguage.english.isRTL)
        XCTAssertTrue(QuoteManager.AppLanguage.hebrew.isRTL)
        XCTAssertTrue(QuoteManager.AppLanguage.arabic.isRTL)
    }
    
    func testCustomLocalization() throws {
        let testKey = "settings"
        
        // Test with different languages
        quoteManager.selectedLanguage = .english
        let englishText = quoteManager.localizedString(testKey)
        XCTAssertFalse(englishText.isEmpty)
        
        quoteManager.selectedLanguage = .hebrew
        let hebrewText = quoteManager.localizedString(testKey)
        XCTAssertFalse(hebrewText.isEmpty)
        
        quoteManager.selectedLanguage = .arabic
        let arabicText = quoteManager.localizedString(testKey)
        XCTAssertFalse(arabicText.isEmpty)
    }
}

// MARK: - Font Size Tests
extension Daily_AffirmationTests {
    
    func testFontSizeEnum() throws {
        let small = QuoteManager.FontSize.small
        XCTAssertEqual(small.rawValue, "small")
        XCTAssertEqual(small.multiplier, 0.9)
        XCTAssertEqual(small.displayName(using: quoteManager), quoteManager.localizedString("font_small"))
        
        let medium = QuoteManager.FontSize.medium
        XCTAssertEqual(medium.rawValue, "medium")
        XCTAssertEqual(medium.multiplier, 1.0)
        XCTAssertEqual(medium.displayName(using: quoteManager), quoteManager.localizedString("font_medium"))
        
        let large = QuoteManager.FontSize.large
        XCTAssertEqual(large.rawValue, "large")
        XCTAssertEqual(large.multiplier, 1.2)
        XCTAssertEqual(large.displayName(using: quoteManager), quoteManager.localizedString("font_large"))
    }
    
    func testFontSizeChanging() throws {
        quoteManager.fontSize = .small
        XCTAssertEqual(quoteManager.fontSize, .small)
        
        quoteManager.fontSize = .large
        XCTAssertEqual(quoteManager.fontSize, .large)
        
        quoteManager.fontSize = .medium
        XCTAssertEqual(quoteManager.fontSize, .medium)
    }
}

// MARK: - Settings Persistence Tests
extension Daily_AffirmationTests {
    
    func testSettingsPersistence() throws {
        // Change settings
        quoteManager.isDarkMode = true
        quoteManager.fontSize = .large
        quoteManager.selectedLanguage = .hebrew
        quoteManager.dailyNotifications = false
        
        // Create new instance to test persistence
        let newQuoteManager = QuoteManager()
        
        XCTAssertEqual(newQuoteManager.isDarkMode, true)
        XCTAssertEqual(newQuoteManager.fontSize, .large)
        XCTAssertEqual(newQuoteManager.selectedLanguage, .hebrew)
        XCTAssertEqual(newQuoteManager.dailyNotifications, false)
    }
    
    func testDefaultValues() throws {
        let freshQuoteManager = QuoteManager()
        
        XCTAssertEqual(freshQuoteManager.fontSize, .medium)
        XCTAssertEqual(freshQuoteManager.selectedLanguage, .english)
        XCTAssertFalse(freshQuoteManager.isDarkMode)
        XCTAssertFalse(freshQuoteManager.dailyNotifications)
    }
}

// MARK: - Date and Time Tests
extension Daily_AffirmationTests {
    
    func testFormattedDate() throws {
        let formattedDate = quoteManager.formattedDate
        XCTAssertFalse(formattedDate.isEmpty, "Formatted date should not be empty")
        
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        let expectedDate = formatter.string(from: Date())
        XCTAssertEqual(formattedDate, expectedDate)
    }
    
    func testFormattedNotificationTime() throws {
        let testTime = Calendar.current.date(bySettingHour: 15, minute: 30, second: 0, of: Date()) ?? Date()
        quoteManager.notificationTime = testTime
        
        let formattedTime = quoteManager.formattedNotificationTime
        XCTAssertFalse(formattedTime.isEmpty)
        XCTAssertTrue(formattedTime.contains("15") || formattedTime.contains("3"), "Should contain hour")
        XCTAssertTrue(formattedTime.contains("30"), "Should contain minute")
    }
    
    func testDailyQuoteConsistency() throws {
        let initialQuote = quoteManager.currentQuote
        let initialIndex = quoteManager.currentIndex
        
        // Create new instance - should have same daily quote
        let secondManager = QuoteManager()
        
        XCTAssertEqual(secondManager.currentQuote, initialQuote, "Daily quote should be consistent")
        XCTAssertEqual(secondManager.currentIndex, initialIndex, "Daily index should be consistent")
    }
}

// MARK: - Edge Cases and Error Handling Tests
extension Daily_AffirmationTests {
    
    func testExtremeIndexValues() throws {
        let originalQuotes = quoteManager.quotes
        quoteManager.quotes = ["Quote 1", "Quote 2", "Quote 3"]
        
        // Test with extreme positive index
        quoteManager.currentIndex = 1000
        quoteManager.nextQuote()
        XCTAssertLessThan(quoteManager.currentIndex, quoteManager.quotes.count)
        
        // Test with negative index (should be handled gracefully)
        quoteManager.currentIndex = 0
        quoteManager.previousQuote()
        XCTAssertEqual(quoteManager.currentIndex, 2, "Should wrap to last index")
        
        // Restore original quotes
        quoteManager.quotes = originalQuotes
    }
    
    func testBoundaryConditions() throws {
        let originalQuotes = quoteManager.quotes
        
        // Test with very large quotes array
        let largeQuotesArray = Array(1...1000).map { "Quote \($0)" }
        quoteManager.quotes = largeQuotesArray
        quoteManager.currentIndex = 999
        
        quoteManager.nextQuote()
        XCTAssertEqual(quoteManager.currentIndex, 0, "Should wrap to beginning")
        
        // Test with minimal quotes array
        quoteManager.quotes = ["Only quote"]
        quoteManager.currentIndex = 0
        
        for _ in 1...10 {
            quoteManager.nextQuote()
            XCTAssertEqual(quoteManager.currentIndex, 0, "Should stay at 0 with single quote")
        }
        
        // Restore original quotes
        quoteManager.quotes = originalQuotes
    }
    
    func testCorruptedDataHandling() throws {
        // Test invalid font size recovery
        UserDefaults.standard.set("invalid_font", forKey: "fontSize")
        let testManager = QuoteManager()
        XCTAssertEqual(testManager.fontSize, .medium, "Should default to medium for invalid font size")
        
        // Test invalid language recovery
        UserDefaults.standard.set("invalid_lang", forKey: "selectedLanguage")
        let testManager2 = QuoteManager()
        XCTAssertEqual(testManager2.selectedLanguage, .english, "Should default to english for invalid language")
    }
}

// MARK: - Performance Tests
extension Daily_AffirmationTests {
    
    func testQuoteNavigationPerformance() throws {
        measure {
            for _ in 1...1000 {
                quoteManager.nextQuote()
            }
        }
    }
    
    func testLanguageSwitchingPerformance() throws {
        measure {
            quoteManager.selectedLanguage = .hebrew
            quoteManager.selectedLanguage = .arabic
            quoteManager.selectedLanguage = .english
        }
    }
    
    func testLocalizationPerformance() throws {
        let keys = ["settings", "dark_mode", "notifications", "font_size", "language"]
        
        measure {
            for key in keys {
                _ = quoteManager.localizedString(key)
            }
        }
    }
}

// MARK: - Memory and Resource Tests
extension Daily_AffirmationTests {
    
    func testMemoryLeaks() throws {
        weak var weakManager: QuoteManager?
        
        autoreleasepool {
            let strongManager = QuoteManager()
            weakManager = strongManager
            
            // Use the manager
            strongManager.nextQuote()
            strongManager.selectedLanguage = .hebrew
            strongManager.fontSize = .large
        }
        
        XCTAssertNil(weakManager, "QuoteManager should be deallocated")
    }
    
    func testResourceLoading() throws {
        // Test all language files exist and are loadable
        for language in QuoteManager.AppLanguage.allCases {
            let url = Bundle.main.url(forResource: language.quotesFileName, withExtension: "json")
            XCTAssertNotNil(url, "Should find quotes file for \(language.rawValue)")
            
            if let url = url {
                let data = try Data(contentsOf: url)
                let quotes = try JSONDecoder().decode([String].self, from: data)
                XCTAssertFalse(quotes.isEmpty, "Quotes array should not be empty for \(language.rawValue)")
            }
        }
    }
}