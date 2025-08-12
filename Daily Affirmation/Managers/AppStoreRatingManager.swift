import Foundation
import StoreKit
import UIKit

class AppStoreRatingManager: ObservableObject {
    static let shared = AppStoreRatingManager()
    
    private init() {}
    
    // MARK: - UserDefaults Keys
    private let hasRequestedRatingKey = "hasRequestedRating"
    private let hasUserRatedKey = "hasUserRated"
    private let ratingRequestDismissedDateKey = "ratingRequestDismissedDate"
    private let ratingRequestCountKey = "ratingRequestCount"
    private let lastRatingYearKey = "lastRatingYear"
    
    // MARK: - Rating Properties
    var hasRequestedRating: Bool {
        get { UserDefaults.standard.bool(forKey: hasRequestedRatingKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasRequestedRatingKey) }
    }
    
    var hasUserRated: Bool {
        get { UserDefaults.standard.bool(forKey: hasUserRatedKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasUserRatedKey) }
    }
    
    var ratingRequestDismissedDate: Date? {
        get { UserDefaults.standard.object(forKey: ratingRequestDismissedDateKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: ratingRequestDismissedDateKey) }
    }
    
    private var ratingRequestCount: Int {
        get { UserDefaults.standard.integer(forKey: ratingRequestCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: ratingRequestCountKey) }
    }
    
    private var lastRatingYear: Int {
        get { UserDefaults.standard.integer(forKey: lastRatingYearKey) }
        set { UserDefaults.standard.set(newValue, forKey: lastRatingYearKey) }
    }
    
    // MARK: - Rating Request Logic
    func shouldRequestRating(for quoteManager: QuoteManager) -> Bool {
        // Never show if user has already rated
        if hasUserRated {
            return false
        }
        
        // Respect Apple's 3 requests per year limit
        let currentYear = Calendar.current.component(.year, from: Date())
        if lastRatingYear == currentYear && ratingRequestCount >= 3 {
            return false
        }
        
        // Reset counter if it's a new year
        if lastRatingYear != currentYear {
            lastRatingYear = currentYear
            ratingRequestCount = 0
        }
        
        // If user just completed onboarding, show immediately
        if !hasRequestedRating {
            return true
        }
        
        // If user previously dismissed, check if enough time has passed
        if let dismissedDate = ratingRequestDismissedDate {
            let daysSinceDismissed = Calendar.current.dateComponents([.day], from: dismissedDate, to: Date()).day ?? 0
            let randomDelayDays = generateRandomDelay()
            
            // Only show if enough random days have passed
            if daysSinceDismissed >= randomDelayDays {
                return shouldShowBasedOnEngagement(quoteManager)
            }
        }
        
        return false
    }
    
    private func shouldShowBasedOnEngagement(_ quoteManager: QuoteManager) -> Bool {
        // Show rating request based on user engagement
        return quoteManager.totalAppOpens >= 3 || 
               quoteManager.consecutiveDays >= 2 || 
               quoteManager.totalQuotesViewed >= 5
    }
    
    private func generateRandomDelay() -> Int {
        // Generate random delay between 1-3 days
        return Int.random(in: 1...3)
    }
    
    // MARK: - Request Rating
    func requestRating() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            return
        }
        
        // Update tracking
        hasRequestedRating = true
        ratingRequestCount += 1
        lastRatingYear = Calendar.current.component(.year, from: Date())
        
        // Request review using native iOS dialog
        SKStoreReviewController.requestReview(in: windowScene)
        
        // Assume user might have rated (we can't detect this with SKStoreReviewController)
        // Set a flag that user has seen the rating dialog
        ratingRequestDismissedDate = Date()
    }
    
    // MARK: - User Actions
    func userDidRate() {
        hasUserRated = true
        ratingRequestDismissedDate = nil
    }
    
    func userDismissedRating() {
        ratingRequestDismissedDate = Date()
    }
    
    // MARK: - Testing Support
    func resetRatingState() {
        hasRequestedRating = false
        hasUserRated = false
        ratingRequestDismissedDate = nil
        ratingRequestCount = 0
        lastRatingYear = 0
    }
    
    // MARK: - Analytics
    func shouldRequestRatingAfterOnboarding() -> Bool {
        // Always request rating after first onboarding completion
        return !hasRequestedRating && !hasUserRated
    }
    
    func shouldRequestRatingOnAppLaunch(for quoteManager: QuoteManager) -> Bool {
        // Check if we should show rating on app launch (not after onboarding)
        return shouldRequestRating(for: quoteManager) && hasRequestedRating
    }
}