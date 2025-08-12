import SwiftUI

/// An improved onboarding experience for the Daily‑Affirmation app.
///
/// The onboarding is presented as a series of pages highlighting key
/// features of the app.  It includes a persistent page indicator and
/// a contextual Next button.  The final page embeds a premium
/// subscription screen so users can subscribe without leaving the
/// onboarding flow.  An exit (X) button is only shown on this last
/// page so users see the premium offering before dismissing the
/// onboarding.  The layout and colours adapt to light and dark
/// appearances and use system accent colours for better
/// accessibility and contrast.
struct OnboardingView: View {
    @State private var currentPage: Int = 0
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var quoteManager: QuoteManager

    /// Total number of onboarding pages.  The last page is the premium
    /// subscription page.
    private let totalPages: Int = 3

    var body: some View {
        ZStack {
            // Gradient background for good contrast
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.accentColor.opacity(0.3),
                    Color.accentColor.opacity(0.15),
                    Color.accentColor.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Show an X button only on the last page
                HStack {
                    Spacer()
                    if currentPage == totalPages - 1 {
                        Button(action: finishOnboarding) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 36, height: 36)
                                .background(Color.secondary.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Close onboarding")
                        .padding(.top, 20)
                        .padding(.trailing, 24)
                    }
                }

                Spacer()

                // TabView containing the pages; last page is the premium screen
                TabView(selection: $currentPage) {
                    OnboardingPageView(
                        icon: "sparkles",
                        title: "Daily Inspiration",
                        subtitle: "Transform your mindset with powerful quotes delivered exactly when you need them most.",
                        features: [
                            "Fresh inspiration every morning",
                            "Thousands of motivational quotes",
                            "Save your favorite quotes"
                        ]
                    )
                    .tag(0)

                    OnboardingPageView(
                        icon: "bell.badge",
                        title: "Smart Notifications",
                        subtitle: "Never miss your daily dose of motivation with intelligent timing that fits your lifestyle.",
                        features: [
                            "Perfect timing for maximum impact",
                            "Personalized to your schedule",
                            "No spam, just inspiration"
                        ]
                    )
                    .tag(1)

                    // Final page: embed premium subscription
                    PremiumOnboardingPageView(onCompletion: {
                        finishOnboarding()
                    })
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: currentPage)
                .frame(height: 520)

                Spacer()

                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.accentColor : Color.accentColor.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }
                .padding(.vertical, 16)
                .accessibilityLabel("Page indicator")
                .accessibilityValue("Page \(currentPage + 1) of \(totalPages)")

                // Next button for all but the last page
                if currentPage < totalPages - 1 {
                    Button(action: nextPage) {
                        Text("Next")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(14)
                            .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 30)
                    }
                    .accessibilityIdentifier("onboarding_next_button")
                }
            }
        }
    }

    private func nextPage() {
        if currentPage < totalPages - 1 {
            withAnimation {
                currentPage += 1
            }
        }
    }

    private func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        
        // Request app rating after onboarding completion
        quoteManager.checkAndRequestRatingAfterOnboarding()
        
        dismiss()
    }
}

/// Single onboarding page with icon, title, subtitle, and bullet points.
struct OnboardingPageView: View {
    let icon: String
    let title: String
    let subtitle: String
    let features: [String]
    var isPremiumFeature: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundColor(.accentColor)

                if isPremiumFeature {
                    Text("Premium")
                        .font(.caption2.bold())
                        .foregroundColor(.black)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 6)
                        .background(Color.yellow.opacity(0.8))
                        .clipShape(Capsule())
                        .offset(x: 18, y: -12)
                }
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.system(size: 17))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        Text(feature)
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
