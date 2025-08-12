import SwiftUI
import StoreKit

/// A premium subscription page designed specifically for the final
/// screen of the onboarding flow.  It replicates the functionality
/// of the standalone `SubscriptionView` but omits the navigation
/// chrome so it can be embedded within the onboarding `TabView`.
///
/// The view uses the app’s accent colour for highlights and
/// `primary`/`secondary` colours for text to ensure legibility in
/// both light and dark modes.  When a subscription is successfully
/// purchased or restored, the provided `onCompletion` closure is
/// invoked to dismiss the onboarding.
struct PremiumOnboardingPageView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedProduct: Product? = nil

    /// Called when the user completes the subscription flow.  This
    /// closure should dismiss the onboarding view.
    let onCompletion: () -> Void

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 20) {
                // Header: icon and title/subtitle
                VStack(spacing: 12) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.accentColor)
                    Text("Unlock Time Range Notifications")
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    // Break the long subscription description into two lines for improved readability and ensure it wraps gracefully.
                    Text("Get up to 10 daily inspirations throughout your chosen time period\n" +
                         "instead of just one notification per day.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 10)

                // Feature grid: display features in two columns to conserve vertical space
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    PremiumFeatureItem(icon: "clock.fill", title: "Custom Range", description: "Set start and end times")
                    PremiumFeatureItem(icon: "slider.horizontal.3", title: "Multiple Quotes", description: "Up to 10 per day")
                    PremiumFeatureItem(icon: "waveform.path.ecg", title: "Even Spread", description: "Quotes evenly spaced")
                    PremiumFeatureItem(icon: "paintbrush.pointed.fill", title: "Themes", description: "Free & premium backgrounds")
                }
                .padding(.horizontal, 20)

                // Subscription options: show all available products
                VStack(spacing: 12) {
                    if subscriptionManager.isLoading {
                        ProgressView("Loading options…")
                            .frame(height: 80)
                    } else {
                        ForEach(subscriptionManager.products, id: \.id) { product in
                            PremiumSubscriptionOptionItem(
                                product: product,
                                isSelected: selectedProduct?.id == product.id,
                                isPurchasing: isPurchasing
                            ) {
                                selectedProduct = product
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Subscribe and restore buttons & terms
                VStack(spacing: 12) {
                    Button(action: {
                        if let product = selectedProduct {
                            purchaseProduct(product)
                        }
                    }) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Subscribe")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selectedProduct != nil ? Color.accentColor : Color.gray)
                        )
                        .shadow(
                            color: selectedProduct != nil ? Color.accentColor.opacity(0.3) : Color.clear,
                            radius: 6, x: 0, y: 3
                        )
                    }
                    .disabled(selectedProduct == nil || isPurchasing)

                    Button("Restore Purchases") {
                        restorePurchases()
                    }
                    .font(.footnote)
                    .foregroundColor(.accentColor)

                    // Terms & notes compressed into fewer lines to save vertical space
                    Text("Subscription renews automatically. Cancel anytime in Settings. Payment charged to Apple ID.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    HStack(spacing: 16) {
                        Link("Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .font(.caption2)
                            .foregroundColor(.accentColor)
                        Link("Privacy", destination: URL(string: "https://daily-affirmation-gamma.vercel.app")!)
                            .font(.caption2)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                Spacer()
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            Task {
                await subscriptionManager.loadProducts()
                if selectedProduct == nil {
                    selectedProduct = subscriptionManager.products.first { $0.id == "time_range_yearly" }
                }
            }
        }
    }

    /// Performs a purchase and calls `onCompletion` on success.
    private func purchaseProduct(_ product: Product) {
        Task {
            isPurchasing = true
            defer { isPurchasing = false }
            do {
                if let _ = try await subscriptionManager.purchase(product) {
                    onCompletion()
                }
            } catch {
                errorMessage = "Purchase failed: \(error.localizedDescription)"
                showingError = true
            }
        }
    }

    /// Attempts to restore previous purchases and calls `onCompletion` if
    /// access is granted.
    private func restorePurchases() {
        Task {
            do {
                try await subscriptionManager.restorePurchases()
                if subscriptionManager.hasTimeRangeAccess {
                    onCompletion()
                }
            } catch {
                errorMessage = "Restore failed: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
}

// MARK: - Helper Views

/// Compact feature item used in the premium onboarding page.
private struct PremiumFeatureItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// A selectable subscription option item used in the premium onboarding page.
/// Mirrors the behaviour of the onboarding subscription option view but has a
/// unique name to avoid lookup issues when used inside this file.
private struct PremiumSubscriptionOptionItem: View {
    let product: Product
    let isSelected: Bool
    let isPurchasing: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.5), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(subscriptionTitle)
                            .font(.headline)
                            .foregroundColor(.primary)
                        if product.id == "time_range_yearly" {
                            Text("BEST VALUE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor)
                                .cornerRadius(8)
                        }
                    }
                    if let sub = product.subscription {
                        Text("Per \(subscriptionPeriod(sub.subscriptionPeriod))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    if product.id == "time_range_weekly" {
                        Text("3‑day free trial")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    if product.id == "time_range_yearly" {
                        Text("$1.50/month")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                    )
                    .shadow(
                        color: isSelected ? Color.accentColor.opacity(0.2) : Color.black.opacity(0.1),
                        radius: isSelected ? 8 : 2,
                        x: 0,
                        y: isSelected ? 4 : 1
                    )
            )
        }
        .disabled(isPurchasing)
    }

    private var subscriptionTitle: String {
        switch product.id {
        case "time_range_weekly": return "Weekly Plan"
        case "time_range_yearly": return "Yearly Plan"
        default: return product.displayName
        }
    }

    private func subscriptionPeriod(_ period: Product.SubscriptionPeriod) -> String {
        switch period.unit {
        case .day: return period.value == 1 ? "day" : "\(period.value) days"
        case .week: return period.value == 1 ? "week" : "\(period.value) weeks"
        case .month: return period.value == 1 ? "month" : "\(period.value) months"
        case .year: return period.value == 1 ? "year" : "\(period.value) years"
        @unknown default: return ""
        }
    }
}
