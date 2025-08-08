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
                VStack(spacing: 16) {
                    // Live preview
                    LivePreviewCard(
                        backgroundName: quoteManager.selectedBackgroundImage,
                        sampleText: "Believe in yourself."
                    )

                    // Tiles grid
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            FeatureTile(
                                title: "Personal Quotes",
                                subtitle: "Create and edit",
                                systemImage: "quote.bubble.fill",
                                tint: .blue
                            ) { showPersonalQuotes = true }

                            FeatureTile(
                                title: "Backgrounds",
                                subtitle: "Pick a vibe",
                                systemImage: "paintbrush.pointed.fill",
                                tint: .orange
                            ) { showBackgroundThemes = true }
                        }

                        FeatureTile(
                            title: "Categories",
                            subtitle: quoteManager.selectedCategory.displayName,
                            systemImage: categoryIcon(quoteManager.selectedCategory),
                            tint: .purple,
                            isFullWidth: true
                        ) { showQuoteCategories = true }
                    }

                    // Helpful tip
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.secondary)
                        Text("Changes appear instantly across the app.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
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

private struct LivePreviewCard: View {
    let backgroundName: String
    let sampleText: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if UIImage(named: backgroundName) != nil {
                Image(backgroundName)
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [.accentColor.opacity(0.25), .accentColor.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 180)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(sampleText)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
                    .shadow(radius: 6)
                Text("This is how your quotes will look")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(16)
        }
        .frame(height: 180)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

private struct FeatureTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    var isFullWidth: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(tint.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: systemImage)
                        .foregroundColor(tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.systemBackground))
            )
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.0).onChanged { _ in
            withAnimation(.easeInOut(duration: 0.08)) { isPressed = true }
        }.onEnded { _ in
            withAnimation(.easeInOut(duration: 0.08)) { isPressed = false }
        })
        .frame(maxWidth: isFullWidth ? .infinity : nil)
    }
}

#Preview {
    CustomizeOptionsView(quoteManager: QuoteManager())
}
