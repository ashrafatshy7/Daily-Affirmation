import SwiftUI

struct CategorySelectionView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    @State private var showSubscription = false
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        ZStack {
            // Background matches onboarding style
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.accentColor.opacity(0.30),
                    Color.accentColor.opacity(0.15),
                    Color.accentColor.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Modern Header
                ZStack {
                    // Subtle header panel using accent tint
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.12),
                                    Color.accentColor.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(width: 36, height: 36)
                                    .background(Color.secondary.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            .accessibilityLabel("Back")
                            
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 4) {
                                Text("Categories")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Choose your vibe")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Placeholder for symmetry
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 44, height: 44)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                // Category Grid
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(quoteManager.availableCategories, id: \.self) { category in
                            ModernCategoryCard(
                                category: category,
                                isSelected: quoteManager.selectedCategory == category,
                                isPremiumCategory: category != .general,
                                hasSubscription: subscriptionManager.hasTimeRangeAccess,
                                action: {
                                    if category == .general || subscriptionManager.hasTimeRangeAccess {
                                        withAnimation(.spring(dampingFraction: 0.7, blendDuration: 0.3)) {
                                            quoteManager.selectedCategory = category
                                        }
                                    } else {
                                        showSubscription.toggle()
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
        }
    }
    
}

struct ModernCategoryCard: View {
    let category: QuoteCategory
    let isSelected: Bool
    let isPremiumCategory: Bool
    let hasSubscription: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    private var isAccessible: Bool {
        return !isPremiumCategory || hasSubscription
    }
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: isSelected ? [
                                getCategoryColor(category),
                                getCategoryColor(category).opacity(0.8)
                            ] : [
                                Color.white,
                                Color.white.opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? Color.clear : getCategoryColor(category).opacity(isAccessible ? 0.2 : 0.1),
                                lineWidth: 2
                            )
                    )
                    .frame(height: 100)
                    .shadow(
                        color: isSelected ? getCategoryColor(category).opacity(0.25) : Color(red: 0.85, green: 0.9, blue: 0.95).opacity(0.4),
                        radius: isPressed ? 10 : 15,
                        x: 0,
                        y: isPressed ? 4 : 8
                    )
                    .opacity(isAccessible ? 1.0 : 0.7)
                
                // Content
                HStack(spacing: 20) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.2) : getCategoryColor(category).opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: getCategoryIcon(category))
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(isSelected ? .white : (isAccessible ? getCategoryColor(category) : getCategoryColor(category).opacity(0.5)))
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(category.displayName)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(isSelected ? .white : (isAccessible ? .black : .black.opacity(0.6)))
                                .multilineTextAlignment(.leading)
                            
                            if isPremiumCategory && !hasSubscription {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(isSelected ? .white.opacity(0.8) : .gray)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.2) : Color.clear)
                            .frame(width: 32, height: 32)
                        
                        if isPremiumCategory && !hasSubscription && !isSelected {
                            Image(systemName: "lock.circle")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(getCategoryColor(category).opacity(0.5))
                        } else {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(isSelected ? .white : getCategoryColor(category).opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .animation(.spring(dampingFraction: 0.7, blendDuration: 0.3), value: isSelected)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { isPressing in
            isPressed = isPressing
        } perform: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
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

#Preview {
    CategorySelectionView(quoteManager: QuoteManager())
}