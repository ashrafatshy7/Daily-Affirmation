import SwiftUI

struct ContentView: View {
    @StateObject private var quoteManager = QuoteManager()
    @State private var showSettings = false
    @State private var showCustomizeOptions = false
    @State private var showNotificationPermission = false
    @State private var swipeIndicatorOpacity: Double = 1.0
    @State private var showSwipeIndicator = true
    @State private var dragOffset: CGFloat = 0
    @State private var hasTriggeredSwipe = false
    @State private var swipeDirection: SwipeDirection = .none

    enum SwipeDirection { case none, up, down }

    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height

            ZStack {
                if #available(iOS 16.0, *) {
                    ZStack {
                        ForEach(-1...1, id: \.self) { screenIndex in
                            QuoteCardWithGradientView(
                                quoteManager: quoteManager,
                                screenIndex: screenIndex,
                                dragOffset: dragOffset
                            )
                            .frame(width: geometry.size.width, height: screenHeight)
                            .offset(y: CGFloat(screenIndex) * screenHeight + dragOffset)
                        }
                    }
                    .clipped()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .defersSystemGestures(on: .vertical)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.height
                                if showSwipeIndicator && abs(dragOffset) > 10 {
                                    showSwipeIndicator = false
                                }
                                let threshold: CGFloat = 80
                                if !hasTriggeredSwipe && abs(dragOffset) > threshold {
                                    swipeDirection = dragOffset < 0 ? .up : .down
                                    hasTriggeredSwipe = true
                                }
                            }
                            .onEnded { _ in
                                if hasTriggeredSwipe {
                                    let target = swipeDirection == .up ? -screenHeight : screenHeight
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        dragOffset = target
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        if swipeDirection == .up {
                                            quoteManager.nextQuote()
                                        } else {
                                            quoteManager.previousQuote()
                                        }
                                        dragOffset = 0
                                        hasTriggeredSwipe = false
                                        swipeDirection = .none
                                    }
                                } else {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        dragOffset = 0
                                    }
                                    hasTriggeredSwipe = false
                                    swipeDirection = .none
                                }
                            }
                    )
                }

                // Top bar
                VStack {
                    HStack {
                        Button {
                            showSettings.toggle()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.black)
                                .padding(12)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
                        }
                        .accessibilityIdentifier("settings_button")

                        Spacer()

                        if #available(iOS 16.0, *) {
                            ShareLink(
                                item: "\(quoteManager.currentQuote)\n\n\(quoteManager.localizedString("share_suffix"))"
                            ) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title2)
                                    .foregroundColor(.black)
                                    .padding(12)
                                    .background(Color.white.opacity(0.9))
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
                            }
                            .accessibilityIdentifier("share_button")
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 50)
                    .padding(.bottom, 10)

                    Spacer()
                }
                .zIndex(10)

                // Bottom bar
                VStack {
                    Spacer()
                    HStack {
                        Button {
                            showCustomizeOptions.toggle()
                        } label: {
                            Image(systemName: "paintbrush.fill")
                                .font(.title2)
                                .foregroundColor(.black.opacity(0.6))
                                .padding(12)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
                        }
                        .accessibilityIdentifier("customize_button")

                        Spacer()

                        Button {
                            let current = quoteManager.currentQuote
                            quoteManager.toggleLoveQuote(current)
                        } label: {
                            Image(systemName: quoteManager.isQuoteLoved(quoteManager.currentQuote) ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(quoteManager.isQuoteLoved(quoteManager.currentQuote) ? .red : .black.opacity(0.6))
                                .padding(12)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
                        }
                        .accessibilityIdentifier("love_button")
                        
                        // Pin button
                        Button {
                            let current = quoteManager.currentQuote
                            if SharedQuoteManager.shared.isPinned() && SharedQuoteManager.shared.getPinnedQuote() == current {
                                SharedQuoteManager.shared.unpinQuote()
                            } else {
                                SharedQuoteManager.shared.pinQuote(current)
                            }
                        } label: {
                            let currentQuote = quoteManager.currentQuote
                            let isCurrentPinned = SharedQuoteManager.shared.isPinned() && SharedQuoteManager.shared.getPinnedQuote() == currentQuote
                            
                            Image(systemName: isCurrentPinned ? "pin.fill" : "pin")
                                .font(.title2)
                                .foregroundColor(isCurrentPinned ? Color(red: 0.659, green: 0.902, blue: 0.812) : .black.opacity(0.6))
                                .padding(12)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
                        }
                        .accessibilityIdentifier("pin_button")
                        .accessibilityLabel("Pin quote")
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
                .zIndex(10)

                // Swipe indicator
                if showSwipeIndicator {
                    VStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "chevron.up")
                                .font(.title2)
                                .foregroundColor(.black.opacity(0.6))
                                .opacity(swipeIndicatorOpacity)

                            Text(quoteManager.localizedString("swipe_up_next"))
                                .font(.caption)
                                .foregroundColor(.black.opacity(0.6))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.8))
                                        .blur(radius: 0.5)
                                )
                        }
                        .padding(.bottom, 80)
                    }
                }
            }
            .onAppear {
                swipeIndicatorOpacity = 0.7
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    showSwipeIndicator = false
                }
                checkFirstLaunch()
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
        .preferredColorScheme(.light)
        .ignoresSafeArea(.all)
        .sheet(isPresented: $showSettings) {
            SettingsView(quoteManager: quoteManager)
        }
        .sheet(isPresented: $showCustomizeOptions) {
            CustomizeOptionsView(quoteManager: quoteManager)
        }
        .overlay(
            showNotificationPermission
                ? NotificationPermissionView(quoteManager: quoteManager, isPresented: $showNotificationPermission)
                : nil
        )
    }

    private func checkFirstLaunch() {
        if !UserDefaults.standard.bool(forKey: "hasShownNotificationPermission") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showNotificationPermission = true
            }
        }
    }
}

struct QuoteCardWithGradientView: View {
    @ObservedObject var quoteManager: QuoteManager
    let screenIndex: Int
    let dragOffset: CGFloat

    private var displayQuote: String {
        switch screenIndex {
        case -1: return quoteManager.getPreviewQuote(offset: -1)
        case 1:  return quoteManager.getPreviewQuote(offset: 1)
        default: return quoteManager.currentQuote
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(quoteManager.selectedBackgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea(.all)

                VStack {
                    Spacer()
                    Text(displayQuote)
                        .font(.system(size: 32, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .lineSpacing(8)
                        .scaleEffect(quoteManager.fontSize.multiplier)
                        .shadow(color: .white.opacity(0.8), radius: 2, x: 0, y: 1)
                        .accessibilityElement(children: .ignore)
                        .accessibilityIdentifier(
                            screenIndex == 0 ? "quote_text" : "quote_text_preview_\(screenIndex)"
                        )
                        .accessibilityLabel("Daily quote")
                        .accessibilityValue(displayQuote)
                        .accessibility(addTraits: .isStaticText)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

#Preview {
    ContentView()
}
