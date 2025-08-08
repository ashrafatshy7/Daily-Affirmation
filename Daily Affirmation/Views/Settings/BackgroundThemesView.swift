import SwiftUI

// MARK: - Background Themes (Redesigned)
// Cleaner grid with inline selection and premium visibility.

struct BackgroundThemesView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    @State private var showSubscription = false
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    let availableBackgrounds = ["background", "background1", "background2", "background3", "background4"]
    let freeBackgrounds = ["background", "background1"]

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
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
        .sheet(isPresented: $showSubscription) { SubscriptionView() }
    }
}

struct BackgroundTile: View {
    let backgroundName: String
    let isSelected: Bool
    let isFree: Bool
    let hasSubscription: Bool
    let onSelect: () -> Void

    private var isAccessible: Bool { isFree || hasSubscription }

    var body: some View {
        Button(action: onSelect) {
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .bottomTrailing) {
                    if UIImage(named: backgroundName) != nil {
                        Image(backgroundName)
                            .resizable()
                            .aspectRatio(1, contentMode: .fill)
                            .frame(height: 150)
                            .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [.accentColor.opacity(0.25), .accentColor.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 150)
                    }

                    if isSelected {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.white)
                            Text("Selected").font(.footnote.weight(.semibold)).foregroundColor(.white)
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(8)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .opacity(isAccessible ? 1.0 : 0.7)

                if !isAccessible {
                    ZStack {
                        Circle().fill(Color.black.opacity(0.55)).frame(width: 30, height: 30)
                        Image(systemName: "lock.fill").foregroundColor(.white)
                    }
                    .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Background \(backgroundName)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    BackgroundThemesView(quoteManager: QuoteManager())
}
