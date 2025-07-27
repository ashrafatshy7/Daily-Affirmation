import SwiftUI

struct CategorySelectionView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    
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
                // Modern Header
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
                            Button(action: {
                                dismiss()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                                    
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black.opacity(0.7))
                                }
                            }
                            .accessibilityLabel("Back")
                            
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 4) {
                                Text("Categories")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                
                                Text("Choose your vibe")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.black.opacity(0.6))
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
                                action: {
                                    withAnimation(.spring(dampingFraction: 0.7, blendDuration: 0.3)) {
                                        quoteManager.selectedCategory = category
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
        .preferredColorScheme(.light)
    }
    
}

struct ModernCategoryCard: View {
    let category: QuoteCategory
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
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
                                isSelected ? Color.clear : getCategoryColor(category).opacity(0.2),
                                lineWidth: 2
                            )
                    )
                    .frame(height: 100)
                    .shadow(
                        color: isSelected ? getCategoryColor(category).opacity(0.3) : .black.opacity(0.08),
                        radius: isPressed ? 8 : 12,
                        x: 0,
                        y: isPressed ? 2 : 6
                    )
                
                // Content
                HStack(spacing: 20) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.2) : getCategoryColor(category).opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: getCategoryIcon(category))
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(isSelected ? .white : getCategoryColor(category))
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 6) {
                        Text(category.displayName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(isSelected ? .white : .black)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.2) : Color.clear)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(isSelected ? .white : getCategoryColor(category).opacity(0.5))
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