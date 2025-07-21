import SwiftUI

struct BackgroundThemesView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    
    let availableBackgrounds = ["background", "background1", "background2", "background3", "background4"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {}) {
                        Text("Background Themes")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }
                    .disabled(true)
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityIdentifier("background_themes_title")
                    .accessibilityLabel("Background Themes")
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
                    .accessibilityIdentifier("close_background_themes_button")
                    .accessibilityLabel("Close background themes")
                    .accessibility(addTraits: .isButton)
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .background(Color.white)
                
                // Background Selection Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(availableBackgrounds, id: \.self) { backgroundName in
                            BackgroundTile(
                                backgroundName: backgroundName,
                                isSelected: quoteManager.selectedBackgroundImage == backgroundName,
                                onSelect: {
                                    quoteManager.selectedBackgroundImage = backgroundName
                                }
                            )
                        }
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
    }
}

struct BackgroundTile: View {
    let backgroundName: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            ZStack {
                Image(backgroundName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 160)
                    .clipped()
                    .cornerRadius(16)
                
                // Selection overlay
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.4, green: 0.8, blue: 0.8), lineWidth: 4)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.4, green: 0.8, blue: 0.8).opacity(0.2))
                        )
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.8))
                                .background(Color.white)
                                .clipShape(Circle())
                                .padding(8)
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("background_tile_\(backgroundName)")
        .accessibilityLabel("Background \(backgroundName)")
        .accessibility(addTraits: .isButton)
        .accessibility(addTraits: isSelected ? .isSelected : [])
    }
}

#Preview {
    BackgroundThemesView(quoteManager: QuoteManager())
}