import SwiftUI
import StoreKit

/// A premium subscription page that offers time‑range notifications and
/// other bonus features.  Styled to match the onboarding screens,
/// using the accent colour for highlights and dynamic primary/secondary
/// colours for text.  Users can select a subscription option and
/// purchase it via StoreKit.  Restore purchases and links to terms
/// and privacy are provided.
struct SubscriptionView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedProduct: Product? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header: icon and description
                    VStack(spacing: 16) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)

                        Text("Unlock Time Range Notifications")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)

                        Text("Get up to 10 daily inspirations throughout your chosen time period instead of just one notification per day.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)

                    // Features list using backwards-compatible wrapper
                    VStack(alignment: .leading, spacing: 16) {
                        FeatureRow(
                            icon: "clock.fill",
                            title: "Custom Time Range",
                            description: "Set your preferred start and end times for notifications"
                        )
                        FeatureRow(
                            icon: "slider.horizontal.3",
                            title: "Multiple Notifications",
                            description: "Receive up to 10 inspirational quotes throughout your day"
                        )
                        FeatureRow(
                            icon: "waveform.path.ecg",
                            title: "Perfect Distribution",
                            description: "Quotes are evenly spaced throughout your chosen time range"
                        )
                        FeatureRow(
                            icon: "paintbrush.pointed.fill",
                            title: "Background Themes",
                            description: "Choose from free and premium backgrounds to customise your experience"
                        )
                    }
                    .padding(.horizontal, 24)

                    // Subscription options list using backwards-compatible wrapper
                    VStack(spacing: 12) {
                        if subscriptionManager.isLoading {
                            ProgressView("Loading subscription options…")
                                .frame(height: 100)
                        } else {
                            ForEach(subscriptionManager.products, id: \.id) { product in
                                SubscriptionOptionView(
                                    product: product,
                                    isSelected: selectedProduct?.id == product.id,
                                    isPurchasing: isPurchasing
                                ) {
                                    selectedProduct = product
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Subscribe and terms
                    VStack(spacing: 16) {
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
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedProduct != nil ? Color.accentColor : Color.gray)
                            )
                            .shadow(
                                color: selectedProduct != nil ? Color.accentColor.opacity(0.3) : Color.clear,
                                radius: 8, x: 0, y: 4
                            )
                        }
                        .disabled(selectedProduct == nil || isPurchasing)
                        .padding(.horizontal, 24)

                        Button("Restore Purchases") {
                            restorePurchases()
                        }
                        .font(.subheadline)
                        .foregroundColor(.accentColor)

                        VStack(spacing: 8) {
                            Text("• Subscription automatically renews unless cancelled")
                            Text("• Cancel anytime in Settings > Subscriptions")
                            Text("• Payment charged to iTunes Account")

                            HStack(spacing: 16) {
                                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                    .font(.caption)
                                    .foregroundColor(.accentColor)

                                Link("Privacy Policy", destination: URL(string: "https://daily-affirmation-gamma.vercel.app")!)
                                    .font(.caption)
                                    .foregroundColor(.accentColor)
                            }
                            .padding(.top, 8)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 30)
                    }

                    Spacer(minLength: 40)
                }
                .navigationTitle("Premium Features")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") { dismiss() }
                    }
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
        }
    }

    /// Purchase the selected product and handle the result.
    private func purchaseProduct(_ product: Product) {
        Task {
            isPurchasing = true
            defer { isPurchasing = false }
            do {
                if let _ = try await subscriptionManager.purchase(product) {
                    dismiss()
                }
            } catch {
                errorMessage = "Purchase failed: \(error.localizedDescription)"
                showingError = true
            }
        }
    }

    /// Restore previous purchases and dismiss on success.
    private func restorePurchases() {
        Task {
            do {
                try await subscriptionManager.restorePurchases()
                if subscriptionManager.hasTimeRangeAccess {
                    dismiss()
                }
            } catch {
                errorMessage = "Restore failed: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
}

// MARK: - Supporting row types and wrappers

/// Internal row type describing a single feature; defined privately to avoid naming conflicts.
private struct SubscriptionFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

/// Internal row type representing a subscription option; defined privately to avoid naming conflicts.
private struct SubscriptionOptionRow: View {
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
                            .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3),
                                    lineWidth: isSelected ? 3 : 1)
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

/// Compatibility wrapper around `SubscriptionFeatureRow` to allow legacy code to reference `FeatureRow`.
private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        SubscriptionFeatureRow(icon: icon, title: title, description: description)
    }
}

/// Compatibility wrapper around `SubscriptionOptionRow` to allow legacy code to reference `SubscriptionOptionView`.
private struct SubscriptionOptionView: View {
    let product: Product
    let isSelected: Bool
    let isPurchasing: Bool
    let onTap: () -> Void

    var body: some View {
        SubscriptionOptionRow(
            product: product,
            isSelected: isSelected,
            isPurchasing: isPurchasing,
            onTap: onTap
        )
    }
}
