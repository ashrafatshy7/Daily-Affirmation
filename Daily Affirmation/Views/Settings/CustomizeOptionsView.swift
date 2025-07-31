import SwiftUI

struct CustomizeOptionsView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    @State private var showPersonalQuotes = false
    @State private var showBackgroundThemes = false
    @State private var showQuoteCategories = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.98, green: 0.99, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Hero Header
                ZStack {
                    // Header gradient background
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.8, blue: 0.8).opacity(0.1),
                                    Color(red: 0.5, green: 0.7, blue: 0.9).opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)
                    
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Customize")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                
                                Text("Make it yours")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                dismiss()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                                    
                                    Image(systemName: "xmark")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black.opacity(0.7))
                                }
                            }
                            .accessibilityLabel("Close")
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                // Modern Card Grid
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Two-column grid for first two cards
                        HStack(spacing: 16) {
                            // Personal Quotes Card
                            ModernFeatureCard(
                                icon: "quote.bubble.fill",
                                title: "Personal Quotes",
                                description: "Your custom quotes",
                                gradientColors: [
                                    Color(red: 0.659, green: 0.902, blue: 0.812),
                                    Color(red: 0.459, green: 0.802, blue: 0.712)
                                ],
                                action: {
                                    showPersonalQuotes.toggle()
                                }
                            )
                            .accessibilityIdentifier("personal_quotes_section")
                            
                            // Background Themes Card
                            ModernFeatureCard(
                                icon: "paintbrush.pointed.fill",
                                title: "Background Themes",
                                description: "Beautiful themes",
                                gradientColors: [
                                    Color(red: 1.0, green: 0.584, blue: 0.0),
                                    Color(red: 1.0, green: 0.384, blue: 0.2)
                                ],
                                action: {
                                    showBackgroundThemes.toggle()
                                }
                            )
                            .accessibilityIdentifier("background_themes_section")
                        }
                        
                        // Quote Categories Card (Full Width)
                        ModernFeatureCard(
                            icon: getCategoryIcon(quoteManager.selectedCategory),
                            title: "Quote Categories",
                            description: "\(quoteManager.selectedCategory.displayName)",
                            gradientColors: [
                                getCategoryColor(quoteManager.selectedCategory),
                                getCategoryColor(quoteManager.selectedCategory).opacity(0.8)
                            ],
                            isFullWidth: true,
                            action: {
                                showQuoteCategories.toggle()
                            }
                        )
                        .accessibilityIdentifier("quote_categories_section")
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
        .sheet(isPresented: $showPersonalQuotes) {
            PersonalQuotesView(quoteManager: quoteManager)
        }
        .sheet(isPresented: $showBackgroundThemes) {
            BackgroundThemesView(quoteManager: quoteManager)
        }
        .sheet(isPresented: $showQuoteCategories) {
            CategorySelectionView(quoteManager: quoteManager)
        }
    }
    
    private func getCategoryIcon(_ category: QuoteCategory) -> String {
        switch category {
        case .general: return "star.fill"
        case .love: return "heart.fill"
        case .positivity: return "sun.max.fill"
        case .stopOverthinking: return "brain.head.profile"
        case .loveYourself: return "figure.arms.open"
        }
    }
    
    private func getCategoryColor(_ category: QuoteCategory) -> Color {
        switch category {
        case .general: return Color(red: 0.0, green: 0.478, blue: 1.0)
        case .love: return Color.red
        case .positivity: return Color(red: 1.0, green: 0.584, blue: 0.0)
        case .stopOverthinking: return Color(red: 0.659, green: 0.902, blue: 0.812)
        case .loveYourself: return Color.purple
        }
    }
}

struct ModernFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let gradientColors: [Color]
    var isFullWidth: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background with gradient
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: isFullWidth ? 120 : 140)
                    .shadow(
                        color: gradientColors.first?.opacity(0.3) ?? .clear,
                        radius: isPressed ? 8 : 12,
                        x: 0,
                        y: isPressed ? 2 : 6
                    )
                
                // Content
                VStack(spacing: 12) {
                    HStack {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: icon)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        if !isFullWidth {
                            Spacer()
                        }
                        
                        if isFullWidth {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(title)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                
                                Text(description)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    if !isFullWidth {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(description)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding(isFullWidth ? 20 : 16)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { isPressing in
            isPressed = isPressing
        } perform: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }
    }
}

#Preview {
    CustomizeOptionsView(quoteManager: QuoteManager())
}