import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showingSubscription = false
    @Environment(\.dismiss) private var dismiss
    
    let totalPages = 3
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.3, blue: 0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // X button - always reserve space, only visible on last page
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
                    .opacity(currentPage == totalPages - 1 ? 1.0 : 0.0)
                    .disabled(currentPage != totalPages - 1)
                    .padding(.trailing, 24)
                    .padding(.top, 16)
                }
                
                // Main content
                TabView(selection: $currentPage) {
                    OnboardingPageView(
                        icon: "sparkles",
                        title: "Daily Inspiration\nAt Your Fingertips",
                        subtitle: "Transform your mindset with powerful quotes delivered exactly when you need them most",
                        features: [
                            "🌅 Fresh inspiration every morning",
                            "💡 Thousands of motivational quotes",
                            "❤️ Save your favorite quotes"
                        ]
                    )
                    .tag(0)
                    
                    OnboardingPageView(
                        icon: "bell.badge",
                        title: "Smart Notifications\nThat Actually Help",
                        subtitle: "Never miss your daily dose of motivation with intelligent timing that fits your lifestyle",
                        features: [
                            "⏰ Perfect timing for maximum impact",
                            "🎯 Personalized to your schedule",
                            "🔕 No spam, just inspiration"
                        ]
                    )
                    .tag(1)
                    
                    OnboardingPageView(
                        icon: "clock.arrow.2.circlepath",
                        title: "Unlock Your Full\nPotential",
                        subtitle: "Upgrade to Premium and get multiple daily inspirations throughout your chosen time range",
                        features: [
                            "⚡ Up to 10 notifications per day",
                            "⏱️ Custom time range control",
                            "🎪 Perfect distribution throughout your day"
                        ],
                        isPremiumFeature: true
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: currentPage)
                
                Spacer()
                
                // Page indicator
                HStack(spacing: 12) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 30)
                
                // Action buttons
                VStack(spacing: 16) {
                    if currentPage < totalPages - 1 {
                        // Continue button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentPage += 1
                            }
                        }) {
                            HStack {
                                Text("Continue")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(red: 0.4, green: 0.8, blue: 0.8))
                            )
                            .shadow(
                                color: Color(red: 0.4, green: 0.8, blue: 0.8).opacity(0.3),
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                        }
                        .padding(.horizontal, 32)
                        
                    } else {
                        // Premium CTA buttons
                        Button(action: {
                            showingSubscription = true
                        }) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 18))
                                
                                Text("Unlock Premium Features")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 1.0, green: 0.7, blue: 0.0),
                                                Color(red: 1.0, green: 0.5, blue: 0.0)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(
                                color: Color.orange.opacity(0.3),
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showingSubscription) {
            OnboardingSubscriptionView()
                .onDisappear {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    dismiss()
                }
        }
    }
}

struct OnboardingPageView: View {
    let icon: String
    let title: String
    let subtitle: String
    let features: [String]
    var isPremiumFeature: Bool = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon with premium badge
            ZStack {
                // Main icon background
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.white)
                
                // Premium crown badge
                if isPremiumFeature {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "crown.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.yellow)
                                .background(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 32, height: 32)
                                )
                            Spacer()
                        }
                        Spacer()
                    }
                    .offset(x: 35, y: -35)
                }
            }
            .frame(height: 120)
            
            // Title and subtitle
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                
                Text(subtitle)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 32)
            }
            
            // Features list
            VStack(spacing: 16) {
                ForEach(features, id: \.self) { feature in
                    HStack {
                        Text(feature)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    OnboardingView()
}