import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showingSubscription = false
    @State private var showAnimations = false
    @State private var sampleQuoteIndex = 0
    @Environment(\.dismiss) private var dismiss
    
    let totalPages = 4
    
    // Sample quotes for interactive preview
    let sampleQuotes = [
        "I am learning to trust the process.",
        "My presence is enough.",
        "I create space for new beginnings.",
        "I choose to meet myself with kindness.",
        "I am allowed to grow at my own pace."
    ]
    
    var body: some View {
        ZStack {
            // Enhanced gradient background
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
            
            VStack(spacing: 0) {
                // Close button - only visible on last page
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
                    // Page 1: Welcome & Value Proposition
                    WelcomePageView()
                        .tag(0)
                    
                    // Page 2: Interactive Quote Preview
                    InteractiveQuotePageView(
                        sampleQuotes: sampleQuotes,
                        currentQuoteIndex: $sampleQuoteIndex
                    )
                    .tag(1)
                    
                    // Page 3: Smart Notifications
                    SmartNotificationsPageView()
                        .tag(2)
                    
                    // Page 4: Premium Features with Social Proof
                    PremiumFeaturesPageView(showingSubscription: $showingSubscription)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.5), value: currentPage)
                
                Spacer()
                
                // Enhanced page indicator
                HStack(spacing: 12) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 30)
                
                // Action buttons
                VStack(spacing: 16) {
                    if currentPage < totalPages - 1 {
                        // Continue button with enhanced design
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentPage += 1
                            }
                        }) {
                            HStack(spacing: 12) {
                                Text(currentPage == 0 ? "Get Started" : "Continue")
                                    .font(.system(size: 18, weight: .semibold))
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.4, green: 0.8, blue: 0.8),
                                        Color(red: 0.3, green: 0.7, blue: 0.9)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .cornerRadius(16)
                            )
                            .shadow(
                                color: Color(red: 0.4, green: 0.8, blue: 0.8).opacity(0.4),
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
                            HStack(spacing: 12) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 18))
                                
                                Text("Unlock Premium Features")
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.7, blue: 0.0),
                                        Color(red: 1.0, green: 0.5, blue: 0.0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .cornerRadius(16)
                            )
                            .shadow(
                                color: Color.orange.opacity(0.4),
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
            SubscriptionView()
                .onDisappear {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    dismiss()
                }
        }
        .onAppear {
            showAnimations = true
            startQuoteRotation()
        }
    }
    
    private func startQuoteRotation() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            if currentPage == 1 { // Only rotate on quote preview page
                withAnimation(.easeInOut(duration: 0.5)) {
                    sampleQuoteIndex = (sampleQuoteIndex + 1) % sampleQuotes.count
                }
            }
        }
    }
}

// MARK: - Welcome Page
struct WelcomePageView: View {
    @State private var showAnimation = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated hero icon
            ZStack {
                // Pulsing rings
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 2)
                        .frame(width: 120 + CGFloat(index * 40), height: 120 + CGFloat(index * 40))
                        .scaleEffect(showAnimation ? 1.0 : 0.8)
                        .opacity(showAnimation ? 0.3 : 0.8)
                        .animation(
                            .easeInOut(duration: 2.0 + Double(index) * 0.5)
                            .repeatForever(autoreverses: true),
                            value: showAnimation
                        )
                }
                
                // Main icon
                Image(systemName: "sparkles")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(.white)
                    .scaleEffect(showAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: showAnimation)
            }
            .frame(height: 200)
            
            // Title and subtitle
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Welcome to")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("ThinkUp")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Text("Transform your mindset with powerful daily affirmations designed to inspire and motivate you.")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 32)
            }
            
            // Social proof
            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    ForEach(0..<5) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                    }
                }
                
                Text("Designed to inspire your daily routine")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
            )
            
            Spacer()
        }
        .onAppear {
            showAnimation = true
        }
    }
}

// MARK: - Interactive Quote Preview Page
struct InteractiveQuotePageView: View {
    let sampleQuotes: [String]
    @Binding var currentQuoteIndex: Int
    @State private var showQuoteAnimation = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Interactive quote display
            VStack(spacing: 32) {
                Text("Experience Daily Inspiration")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Quote preview with animation
                VStack(spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .frame(height: 120)
                        
                        Text(sampleQuotes[currentQuoteIndex])
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .scaleEffect(showQuoteAnimation ? 1.0 : 0.95)
                            .opacity(showQuoteAnimation ? 1.0 : 0.8)
                            .animation(.easeInOut(duration: 0.5), value: currentQuoteIndex)
                    }
                    .padding(.horizontal, 24)
                    
                    // Swipe instruction
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "hand.point.up.left.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("Swipe to preview different quotes")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        HStack(spacing: 8) {
                            ForEach(0..<sampleQuotes.count, id: \.self) { index in
                                Circle()
                                    .fill(currentQuoteIndex == index ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                }
            }
            
            // Features list
            VStack(spacing: 16) {
                FeatureRowOnboarding(
                    icon: "calendar",
                    text: "Fresh inspiration every morning"
                )
                FeatureRowOnboarding(
                    icon: "heart.fill",
                    text: "Save and revisit your favorites"
                )
                FeatureRowOnboarding(
                    icon: "infinity",
                    text: "Thousands of curated quotes"
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 50 {
                        // Swipe right - previous quote
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentQuoteIndex = currentQuoteIndex > 0 ? currentQuoteIndex - 1 : sampleQuotes.count - 1
                        }
                    } else if value.translation.width < -50 {
                        // Swipe left - next quote
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentQuoteIndex = (currentQuoteIndex + 1) % sampleQuotes.count
                        }
                    }
                }
        )
        .onAppear {
            showQuoteAnimation = true
        }
        .onChange(of: currentQuoteIndex) { _ in
            showQuoteAnimation = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showQuoteAnimation = true
            }
        }
    }
}

// MARK: - Smart Notifications Page
struct SmartNotificationsPageView: View {
    @State private var showNotificationDemo = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Notification demo
            VStack(spacing: 32) {
                ZStack {
                    // Phone mockup background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 200, height: 120)
                    
                    // Notification popup
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.8))
                            
                            Text("ThinkUp")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("now")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Text("I am worthy of all good things")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.8))
                    )
                    .scaleEffect(showNotificationDemo ? 1.0 : 0.9)
                    .opacity(showNotificationDemo ? 1.0 : 0.7)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: showNotificationDemo)
                }
                
                VStack(spacing: 16) {
                    Text("Smart Notifications")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Get perfectly timed inspirations that fit your lifestyle and maximize impact")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            // Smart features
            VStack(spacing: 16) {
                FeatureRowOnboarding(
                    icon: "brain.head.profile",
                    text: "Smart optimal timing"
                )
                FeatureRowOnboarding(
                    icon: "moon.stars.fill",
                    text: "Respects your sleep schedule"
                )
                FeatureRowOnboarding(
                    icon: "gear",
                    text: "Fully customizable preferences"
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .onAppear {
            showNotificationDemo = true
        }
    }
}

// MARK: - Premium Features Page
struct PremiumFeaturesPageView: View {
    @Binding var showingSubscription: Bool
    @State private var showPremiumAnimation = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Premium crown with animation
            VStack(spacing: 32) {
                ZStack {
                    // Animated background
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showPremiumAnimation ? 1.2 : 1.0)
                        .opacity(showPremiumAnimation ? 0.3 : 0.8)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: showPremiumAnimation)
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow.opacity(0.5), radius: 10, x: 0, y: 0)
                        .scaleEffect(showPremiumAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: showPremiumAnimation)
                }
                
                VStack(spacing: 16) {
                    Text("Unlock Your Full Potential")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Take your daily inspiration to the next level with premium features")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            // Premium comparison
            VStack(spacing: 20) {
                HStack {
                    Text("Free")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text("Premium")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 40)
                
                VStack(spacing: 12) {
                    ComparisonRowOnboarding(
                        feature: "Daily Notifications",
                        freeValue: "1 per day",
                        premiumValue: "Up to 10 per day"
                    )
                    
                    ComparisonRowOnboarding(
                        feature: "Timing Control",
                        freeValue: "Fixed time",
                        premiumValue: "Custom range"
                    )
                    
                    ComparisonRowOnboarding(
                        feature: "Distribution",
                        freeValue: "❌",
                        premiumValue: "✅ Perfect spacing"
                    )
                }
            }
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
            
            // Social proof
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Experience the full potential of daily affirmations")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .onAppear {
            showPremiumAnimation = true
        }
    }
}

// MARK: - Helper Views
struct FeatureRowOnboarding: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.8))
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
}

struct ComparisonRowOnboarding: View {
    let feature: String
    let freeValue: String
    let premiumValue: String
    
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
            
            Text(premiumValue)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.yellow)
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    OnboardingView()
}