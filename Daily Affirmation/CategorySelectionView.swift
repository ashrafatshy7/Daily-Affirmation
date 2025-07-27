import SwiftUI

struct CategorySelectionView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.8))
                }
                
                Text("Quote Categories")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .background(Color.white)
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Category Selection Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Select Category")
                                .font(.headline)
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            ForEach(quoteManager.availableCategories, id: \.self) { category in
                                Button(action: {
                                    quoteManager.selectedCategory = category
                                }) {
                                    CategoryCard(
                                        category: category,
                                        isSelected: quoteManager.selectedCategory == category,
                                        quotesCount: getCategoryQuoteCount(category)
                                    )
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                    
                    // Current Selection Info
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Current Selection")
                                .font(.headline)
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(quoteManager.selectedCategory.displayName)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                
                                Text("\(getCategoryQuoteCount(quoteManager.selectedCategory)) quotes available")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: getCategoryIcon(quoteManager.selectedCategory))
                                .font(.title2)
                                .foregroundColor(getCategoryColor(quoteManager.selectedCategory))
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(getCategoryColor(quoteManager.selectedCategory).opacity(0.1))
                        )
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
    }
    
    private func getCategoryQuoteCount(_ category: QuoteCategory) -> Int {
        // This is a placeholder - in a real implementation, you'd get this from the quoteManager
        switch category {
        case .general: return 261
        case .love: return 564
        case .positivity: return 294
        case .stopOverthinking: return 300
        case .loveYourself: return 192
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

struct CategoryCard: View {
    let category: QuoteCategory
    let isSelected: Bool
    let quotesCount: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: getCategoryIcon(category))
                .font(.title2)
                .foregroundColor(isSelected ? .white : getCategoryColor(category))
                .frame(width: 40, height: 40)
                .background(isSelected ? getCategoryColor(category) : getCategoryColor(category).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(category.displayName)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .black)
                    .multilineTextAlignment(.leading)
                
                Text("\(quotesCount) quotes")
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? getCategoryColor(category) : Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
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