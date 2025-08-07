import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var quoteManager: QuoteManager
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
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Check if swipe started from bottom area (home indicator region)
                                let bottomExclusionZone = geometry.safeAreaInsets.bottom + 100
                                let isSwipeFromBottom = value.startLocation.y > screenHeight - bottomExclusionZone
                                
                                // Only process gesture if it doesn't start from bottom exclusion zone
                                if !isSwipeFromBottom {
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
                            }
                            .onEnded { value in
                                // Check if swipe started from bottom area (home indicator region)
                                let bottomExclusionZone = geometry.safeAreaInsets.bottom + 100
                                let isSwipeFromBottom = value.startLocation.y > screenHeight - bottomExclusionZone
                                
                                // Only process gesture end if it doesn't start from bottom exclusion zone
                                if !isSwipeFromBottom {
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
                                } else {
                                    // Reset state for swipes from bottom area
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

#Preview {
    ContentView()
}
