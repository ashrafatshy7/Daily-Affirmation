import SwiftUI

// MARK: - Customize (Redesigned)
// A friendlier layout with live preview, simple tiles, and fewer modal jumps.

struct CustomizeOptionsView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss

    @State private var showPersonalQuotes = false
    @State private var showBackgroundThemes = false
    @State private var showQuoteCategories = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Customize")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Make it feel like you")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Single-column tiles layout
                    VStack(spacing: 16) {
                        FeatureTile(
                            title: "Personal Quotes",
                            subtitle: "Create your own inspiring collection",
                            systemImage: "quote.bubble.fill",
                            tint: .blue,
                            isFullWidth: true
                        ) { showPersonalQuotes = true }

                        FeatureTile(
                            title: "Background Themes",
                            subtitle: "Transform your visual experience",
                            systemImage: "paintbrush.pointed.fill",
                            tint: .orange,
                            isFullWidth: true
                        ) { showBackgroundThemes = true }

                        FeatureTile(
                            title: "Quote Categories",
                            subtitle: "Discover quotes that resonate with you",
                            systemImage: categoryIcon(quoteManager.selectedCategory),
                            tint: .purple,
                            isFullWidth: true
                        ) { showQuoteCategories = true }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
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

    private func categoryIcon(_ category: QuoteCategory) -> String {
        switch category {
        case .general: return "star.fill"
        case .love: return "heart.fill"
        case .positivity: return "sun.max.fill"
        case .stopOverthinking: return "brain.head.profile"
        case .loveYourself: return "figure.arms.open"
        }
    }
}

// MARK: - Reusable (Customize)

private struct FeatureTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    var isFullWidth: Bool = false
    let action: () -> Void

    @State private var isPressed = false
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                // Enhanced icon with gradient background
                ZStack {
                    // Dynamic gradient background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    tint.opacity(0.25),
                                    tint.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                        .shadow(
                            color: tint.opacity(0.3),
                            radius: isPressed ? 4 : 8,
                            x: 0,
                            y: isPressed ? 2 : 4
                        )
                    
                    Image(systemName: systemImage)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(tint)
                        .scaleEffect(isPressed ? 0.9 : 1.0)
                }
                
                // Enhanced text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Enhanced chevron with subtle animation
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(tint.opacity(0.8))
                    .scaleEffect(isPressed ? 0.9 : 1.0)
                    .offset(x: isPressed ? -2 : 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, minHeight: 84)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        tint.opacity(isPressed ? 0.3 : 0.1),
                                        tint.opacity(isPressed ? 0.1 : 0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: Color.primary.opacity(isPressed ? 0.15 : 0.08),
                        radius: isPressed ? 8 : 12,
                        x: 0,
                        y: isPressed ? 4 : 6
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
        .frame(maxWidth: isFullWidth ? .infinity : nil)
    }
}

#Preview {
    CustomizeOptionsView(quoteManager: QuoteManager())
}
