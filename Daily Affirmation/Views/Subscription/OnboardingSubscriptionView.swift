import SwiftUI
import StoreKit

struct OnboardingSubscriptionView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedProduct: Product? = nil
    @State private var showComparisonAnimation = false

    var body: some View {
        ZStack {
            // Premium gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.3, blue: 0.5),
                    Color(red: 0.3, green: 0.2, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Close button
                    HStack {
                        Spacer()
                        Button(action: {
                            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 24)
                        .padding(.top, 16)
                    }

                    // Premium header
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.yellow.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .scaleEffect(showComparisonAnimation ? 1.2 : 1.0)
                                .opacity(showComparisonAnimation ? 0.3 : 0.8)
                                .animation(.easeInOut(duration: 2).repeatForever(), value: showComparisonAnimation)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.yellow)
                                .shadow(color: .yellow.opacity(0.5), radius: 10)
                        }
                        VStack(spacing: 12) {
                            Text("Unlock Your Full Potential")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            Text("Join thousands who've transformed their daily routine with premium features")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 20)

                    // Free vs Premium comparison
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Free")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                Text("Premium")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.yellow)
                            }
                            .padding(.horizontal, 32)

                            ComparisonRow(
                                feature: "Daily Notifications",
                                freeValue: "1 per day",
                                premiumValue: "Up to 10 per day",
                                isHighlight: true
                            )
                            ComparisonRow(
                                feature: "Timing Control",
                                freeValue: "Fixed time",
                                premiumValue: "Custom time range"
                            )
                            ComparisonRow(
                                feature: "Perfect Distribution",
                                freeValue: "❌",
                                premiumValue: "✅ Evenly spaced"
                            )
                            ComparisonRow(
                                feature: "Background Themes",
                                freeValue: "2 free themes",
                                premiumValue: "✅ All themes unlocked"
                            )  // ← New comparison row
                        }
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)

                        // Social proof
                        HStack {
                            Image(systemName: "star.fill").foregroundColor(.yellow)
                            Text("Join 50,000+ users who upgraded")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }

                    // Subscription options
                    VStack(spacing: 16) {
                        if subscriptionManager.isLoading {
                            ProgressView("Loading subscription options.")
                                .foregroundColor(.white)
                                .frame(height: 100)
                        } else {
                            ForEach(subscriptionManager.products, id: \.id) { product in
                                OnboardingSubscriptionCard(
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

                    // CTA buttons & terms
                    VStack(spacing: 16) {
                        Button(action: {
                            if let p = selectedProduct { purchaseProduct(p) }
                        }) {
                            HStack {
                                if isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 18))
                                    Text("Start Premium Now")
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.7, blue: 0.0),
                                             Color(red: 1.0, green: 0.5, blue: 0.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .cornerRadius(16)
                            )
                            .shadow(color: Color.orange.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .disabled(selectedProduct == nil || isPurchasing)
                        .padding(.horizontal, 24)

                        Button("Restore Purchases") {
                            restorePurchases()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                        VStack(spacing: 8) {
                            Text("• Auto-renewal, cancel anytime in Settings")
                            Text("• Payment charged to iTunes Account")
                            Text("• 3-day free trial for weekly plan")
                            HStack(spacing: 16) {
                                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.8))
                                Link("Privacy Policy", destination: URL(string: "https://daily-affirmation-gamma.vercel.app")!)
                                    .font(.caption)
                                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.8))
                            }
                            .padding(.top, 8)
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.top, 16)

                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            showComparisonAnimation = true
            Task {
                await subscriptionManager.loadProducts()
                if selectedProduct == nil {
                    selectedProduct = subscriptionManager.products.first { $0.id == "time_range_yearly" }
                }
            }
        }
    }

    private func purchaseProduct(_ product: Product) {
        Task {
            isPurchasing = true
            defer { isPurchasing = false }
            do {
                let txn = try await subscriptionManager.purchase(product)
                if txn != nil {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    dismiss()
                }
            } catch {
                errorMessage = "Purchase failed: \(error.localizedDescription)"
                showingError = true
            }
        }
    }

    private func restorePurchases() {
        Task {
            do {
                try await subscriptionManager.restorePurchases()
                if subscriptionManager.hasTimeRangeAccess {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    dismiss()
                }
            } catch {
                errorMessage = "Restore failed: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
}

struct ComparisonRow: View {
    let feature: String
    let freeValue: String
    let premiumValue: String
    var isHighlight: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(feature)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                Text(freeValue)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if isHighlight {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        Text("POPULAR")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.yellow)
                    }
                }
                Text(premiumValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.yellow)
            }
        }
        .padding(.horizontal, 32)
    }
}

struct OnboardingSubscriptionCard: View {
    let product: Product
    let isSelected: Bool
    let isPurchasing: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.yellow : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 12, height: 12)
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(subscriptionTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        if product.id == "time_range_yearly" {
                            Text("SAVE 70%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.yellow)
                                .cornerRadius(8)
                        }
                        Spacer()
                    }
                    if let sub = product.subscription {
                        Text("Per \(subscriptionPeriod(sub.subscriptionPeriod))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    if product.id == "time_range_weekly" {
                        Text("3-day free trial, then \(product.displayPrice)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.yellow)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    if product.id == "time_range_yearly" {
                        Text("$1.50/month")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding(20)
            .background(Color.white.opacity(isSelected ? 0.15 : 0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.yellow : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(16)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(), value: isSelected)
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

#Preview {
    OnboardingSubscriptionView()
}
