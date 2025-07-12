import Foundation
import StoreKit
import SwiftUI

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var hasTimeRangeAccess = false
    @Published var currentSubscription: Product? = nil
    
    private let productIdentifiers = [
        "time_range_weekly",
        "time_range_yearly"
    ]
    
    private var updateListenerTask: Task<Void, Error>? = nil
    
    init() {
        updateListenerTask = listenForTransactions()
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let storeProducts = try await Product.products(for: productIdentifiers)
            
            products = storeProducts.sorted { product1, product2 in
                // Sort weekly first, then yearly
                if product1.id == "time_range_weekly" { return true }
                if product2.id == "time_range_weekly" { return false }
                return product1.price < product2.price
            }
            
            #if DEBUG
            if products.isEmpty {
                print("⚠️ No products loaded. Make sure StoreKit Configuration is enabled in Xcode scheme:")
                print("   1. Edit Scheme > Run > Options")
                print("   2. Set StoreKit Configuration to 'Products.storekit'")
            }
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to load products: \(error)")
            print("   This usually means StoreKit Configuration is not set up properly in Xcode")
            #endif
        }
    }
    
    // MARK: - Purchase
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await checkSubscriptionStatus()
            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }
    
    // MARK: - Subscription Status
    func checkSubscriptionStatus() async {
        var hasAccess = false
        var currentSub: Product? = nil
        
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if productIdentifiers.contains(transaction.productID) {
                    hasAccess = true
                    currentSub = products.first { $0.id == transaction.productID }
                    break
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        hasTimeRangeAccess = hasAccess
        currentSubscription = currentSub
        
        // Store subscription status in UserDefaults for offline access
        UserDefaults.standard.set(hasAccess, forKey: "hasTimeRangeAccess")
    }
    
    // MARK: - Restore Purchases
    func restorePurchases() async throws {
        try await AppStore.sync()
        await checkSubscriptionStatus()
    }
    
    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in StoreKit.Transaction.updates {
                do {
                    guard let self = self else { return }
                    let transaction = try await self.checkVerified(result)
                    await transaction.finish()
                    await self.checkSubscriptionStatus()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Formatted Prices
    func formattedPrice(for product: Product) -> String {
        return product.displayPrice
    }
    
    func subscriptionPeriod(for product: Product) -> String {
        guard let subscription = product.subscription else { return "" }
        
        let period = subscription.subscriptionPeriod
        switch period.unit {
        case .day:
            return period.value == 1 ? "day" : "\(period.value) days"
        case .week:
            return period.value == 1 ? "week" : "\(period.value) weeks"
        case .month:
            return period.value == 1 ? "month" : "\(period.value) months"
        case .year:
            return period.value == 1 ? "year" : "\(period.value) years"
        @unknown default:
            return ""
        }
    }
    
    // MARK: - Offline Access Check
    func loadOfflineSubscriptionStatus() {
        hasTimeRangeAccess = UserDefaults.standard.bool(forKey: "hasTimeRangeAccess")
    }
}

// MARK: - Store Errors
enum StoreError: Error {
    case failedVerification
}