import SwiftUI

// MARK: - Background Themes (Redesigned)
// Cleaner grid with inline selection and premium visibility.

struct BackgroundThemesView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    @State private var showSubscription = false
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    // Dynamic background detection
    @State private var availableBackgrounds: [String] = []
    let freeBackgrounds = ["background", "background8", "background13", "background18"] // Updated free backgrounds

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Circle())
                }
                Spacer()
                Text("Backgrounds")
                    .font(.headline)
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(availableBackgrounds, id: \.self) { name in
                        BackgroundTile(
                            backgroundName: name,
                            isSelected: quoteManager.selectedBackgroundImage == name,
                            isFree: freeBackgrounds.contains(name),
                            hasSubscription: subscriptionManager.hasTimeRangeAccess
                        ) {
                            if freeBackgrounds.contains(name) || subscriptionManager.hasTimeRangeAccess {
                                quoteManager.selectedBackgroundImage = name
                            } else {
                                showSubscription = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)

                // Premium hint
                if !subscriptionManager.hasTimeRangeAccess {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                        Text("Some backgrounds are premium.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Upgrade") { showSubscription = true }
                            .buttonStyle(.borderedProminent)
                            .tint(.yellow)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            loadAvailableBackgrounds()
        }
        .sheet(isPresented: $showSubscription) { SubscriptionView() }
    }
    
    // MARK: - Dynamic Background Loading
    private func loadAvailableBackgrounds() {
        var backgrounds: [String] = []
        
        // All possible background images with simple naming
        // This list will be automatically filtered to only include available images
        let allPossibleBackgrounds = [
            // All backgrounds using simple numeric naming
            "background", "background1", "background2", "background3", "background4",
            "background5", "background6", "background7", "background8", "background9",
            "background10", "background11", "background12", "background13", "background14",
            "background15", "background16", "background17", "background18", "background19",
            "background20", "background21", "background22", "background23", "background24",
            "background25", "background26"
            
            // To add new backgrounds in the future:
            // 1. Add the exact asset name to this array (e.g., "background27", "background28", etc.)
            // 2. The system will automatically detect if it exists and include it
            // 3. If you remove an image from assets, it will automatically be excluded
        ]
        
        // Filter to only include images that actually exist in the bundle
        for imageName in allPossibleBackgrounds {
            if UIImage(named: imageName) != nil {
                backgrounds.append(imageName)
            }
        }
        
        // Sort backgrounds by natural numeric order
        availableBackgrounds = backgrounds.sorted { bg1, bg2 in
            // Extract numeric values for proper sorting
            let num1 = extractBackgroundNumber(from: bg1)
            let num2 = extractBackgroundNumber(from: bg2)
            return num1 < num2
        }
    }
    
    // MARK: - Helper Functions
    private func extractBackgroundNumber(from name: String) -> Int {
        if name == "background" { return 0 }
        
        // Extract number from "backgroundN" format
        let numberString = name.replacingOccurrences(of: "background", with: "")
        return Int(numberString) ?? 999
    }
}

struct BackgroundTile: View {
    let backgroundName: String
    let isSelected: Bool
    let isFree: Bool
    let hasSubscription: Bool
    let onSelect: () -> Void

    private var isAccessible: Bool { isFree || hasSubscription }
    
    // Extract user-friendly name from the background name
    private var displayName: String {
        return backgroundName.capitalized
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // Image area
                ZStack(alignment: .topTrailing) {
                    ZStack(alignment: .bottomTrailing) {
                        if UIImage(named: backgroundName) != nil {
                            Image(backgroundName)
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(colors: [.accentColor.opacity(0.25), .accentColor.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(height: 120)
                        }

                        if isSelected {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            }
                            .padding(8)
                            .background(Color.accentColor.opacity(0.9))
                            .clipShape(Circle())
                            .padding(8)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Free label overlay for free backgrounds
                    if isFree {
                        VStack {
                            HStack {
                                Text("Free")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Capsule())
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Background \(displayName)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    BackgroundThemesView(quoteManager: QuoteManager())
}
