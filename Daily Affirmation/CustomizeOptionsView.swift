import SwiftUI

struct CustomizeOptionsView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    @State private var showPersonalQuotes = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header - Fixed at top
                HStack {
                    Button(action: {}) {
                        Text("Customize")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                    .disabled(true)
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityIdentifier("customize_title")
                    .accessibilityLabel("Customize")
                    .accessibility(addTraits: .isHeader)
                    .accessibility(removeTraits: .isButton)
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.8))
                    }
                    .accessibilityIdentifier("close_customize_button")
                    .accessibilityLabel("Close customize options")
                    .accessibility(addTraits: .isButton)
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .background(Color.white)
                
                // Customize content - Scrollable
                ScrollView {
                    VStack(spacing: 16) {
                        // Personal Quotes Section (Active)
                        Button(action: {
                            showPersonalQuotes.toggle()
                        }) {
                            CustomizeCard(
                                icon: "quote.bubble.fill",
                                title: "Personal Quotes",
                                subtitle: "\(quoteManager.personalQuotes.count) quotes added",
                                iconColor: Color(red: 0.659, green: 0.902, blue: 0.812),
                                isActive: true
                            )
                        }
                        .accessibilityIdentifier("personal_quotes_section")
                        .accessibility(addTraits: .isButton)
                        
                        // Background Themes Section (Coming Soon)
                        CustomizeCard(
                            icon: "paintbrush.pointed.fill",
                            title: "Background Themes",
                            subtitle: "Coming Soon",
                            iconColor: Color(red: 1.0, green: 0.584, blue: 0.0),
                            isActive: false
                        )
                        .accessibilityIdentifier("background_themes_section")
                        
                        // Advanced Display Section (Coming Soon)
                        CustomizeCard(
                            icon: "slider.horizontal.3",
                            title: "Advanced Display",
                            subtitle: "Coming Soon",
                            iconColor: Color(red: 0.0, green: 0.478, blue: 1.0),
                            isActive: false
                        )
                        .accessibilityIdentifier("advanced_display_section")
                        
                        // Quote Categories Section (Coming Soon)
                        CustomizeCard(
                            icon: "folder.fill",
                            title: "Quote Categories",
                            subtitle: "Coming Soon",
                            iconColor: Color(red: 0.5, green: 0.5, blue: 0.5),
                            isActive: false
                        )
                        .accessibilityIdentifier("quote_categories_section")
                        
                        // Import/Export Section (Coming Soon)
                        CustomizeCard(
                            icon: "arrow.up.arrow.down.square",
                            title: "Import & Export",
                            subtitle: "Coming Soon",
                            iconColor: Color.purple,
                            isActive: false
                        )
                        .accessibilityIdentifier("import_export_section")
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.white)
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showPersonalQuotes) {
            PersonalQuotesView(quoteManager: quoteManager)
        }
    }
}

struct CustomizeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    var isActive: Bool = true
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isActive ? iconColor : iconColor.opacity(0.5))
                .frame(width: 40, height: 40)
                .background((isActive ? iconColor : iconColor.opacity(0.3)).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isActive ? .black : .secondary)
                        .multilineTextAlignment(.leading)
                    
                    if !isActive {
                        Text("SOON")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary)
                            .cornerRadius(4)
                    }
                }
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Chevron (only for active sections)
            if isActive {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(isActive ? 0.1 : 0.05), radius: 2, x: 0, y: 1)
        )
        .opacity(isActive ? 1.0 : 0.6)
    }
}

#Preview {
    CustomizeOptionsView(quoteManager: QuoteManager())
}