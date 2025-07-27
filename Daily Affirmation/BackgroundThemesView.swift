import SwiftUI

struct BackgroundThemesView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    @State private var showSubscription = false
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    let availableBackgrounds = ["background", "background1", "background2", "background3", "background4"]
    let freeBackgrounds = ["background", "background1"]
    
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
                                    Color(red: 1.0, green: 0.584, blue: 0.0).opacity(0.1),
                                    Color(red: 1.0, green: 0.384, blue: 0.2).opacity(0.05)
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
                                Text("Background Themes")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                
                                Text("Beautiful themes")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            
                            Spacer()
                            
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
                                isFree: freeBackgrounds.contains(backgroundName),
                                hasSubscription: subscriptionManager.hasTimeRangeAccess,
                                onSelect: {
                                    if freeBackgrounds.contains(backgroundName) || subscriptionManager.hasTimeRangeAccess {
                                        quoteManager.selectedBackgroundImage = backgroundName
                                    } else {
                                        showSubscription.toggle()
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
        }
    }
}

struct BackgroundTile: View {
    let backgroundName: String
    let isSelected: Bool
    let isFree: Bool
    let hasSubscription: Bool
    let onSelect: () -> Void
    
    private var isAccessible: Bool {
        return isFree || hasSubscription
    }
    
    var body: some View {
        Button(action: onSelect) {
            ZStack {
                Image(backgroundName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 160)
                    .clipped()
                    .cornerRadius(16)
                    .opacity(isAccessible ? 1.0 : 0.7)
                
                // Lock icon for premium backgrounds
                if !isFree && !hasSubscription {
                    VStack {
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(8)
                        }
                        Spacer()
                    }
                }
                
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