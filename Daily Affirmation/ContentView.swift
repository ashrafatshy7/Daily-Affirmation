//
//  ContentView.swift
//  testClaudeCLIxCode
//
//  Created by Ashraf Atshy on 07/07/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var quoteManager = QuoteManager()
    @State private var showSettings = false
    @State private var currentScreenOffset: CGFloat = 0
    @State private var swipeIndicatorOpacity: Double = 1.0
    @State private var showSwipeIndicator: Bool = true
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragValue: CGFloat = 0
    @State private var hasTriggeredSwipe: Bool = false
    @State private var swipeDirection: SwipeDirection = .none
    
    enum SwipeDirection {
        case none, up, down
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            
            ZStack {
                // Full-screen background and content
                ZStack {
                    ForEach(-1...1, id: \.self) { screenIndex in
                        QuoteScreenWithBackgroundView(
                            quoteManager: quoteManager,
                            screenIndex: screenIndex,
                            showSwipeIndicator: showSwipeIndicator && screenIndex == 0,
                            swipeIndicatorOpacity: swipeIndicatorOpacity
                        )
                        .frame(width: geometry.size.width, height: screenHeight)
                        .offset(y: CGFloat(screenIndex) * screenHeight + dragOffset)
                    }
                }
                .clipped()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle()) // Makes entire area tappable/swipeable
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.height
                            
                            // Hide swipe indicator when user starts swiping
                            if showSwipeIndicator && abs(value.translation.height) > 10 {
                                showSwipeIndicator = false
                            }
                            
                            // Detect swipe direction and trigger quote change only once
                            let minimumSwipeDistance: CGFloat = 80
                            let currentDrag = value.translation.height
                            
                            if !hasTriggeredSwipe && abs(currentDrag) > minimumSwipeDistance {
                                if currentDrag < -minimumSwipeDistance && swipeDirection != .up {
                                    // Swiping up = next quote
                                    swipeDirection = .up
                                    hasTriggeredSwipe = true
                                    quoteManager.nextQuote()
                                } else if currentDrag > minimumSwipeDistance && swipeDirection != .down {
                                    // Swiping down = previous quote
                                    swipeDirection = .down
                                    hasTriggeredSwipe = true
                                    quoteManager.previousQuote()
                                }
                            }
                        }
                        .onEnded { value in
                            let minimumSwipeDistance: CGFloat = 80
                            let currentDrag = value.translation.height
                            
                            if hasTriggeredSwipe {
                                // Complete the screen transition
                                if swipeDirection == .up {
                                    // Slide current screen up completely, next screen slides up
                                    withAnimation(.easeOut(duration: 0.4)) {
                                        dragOffset = -screenHeight
                                    }
                                } else if swipeDirection == .down {
                                    // Slide current screen down completely, previous screen slides down
                                    withAnimation(.easeOut(duration: 0.4)) {
                                        dragOffset = screenHeight
                                    }
                                }
                                
                                // Reset positions after animation completes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    dragOffset = 0
                                    hasTriggeredSwipe = false
                                    swipeDirection = .none
                                    lastDragValue = 0
                                }
                            } else {
                                // No swipe triggered, snap back to center
                                withAnimation(.easeOut(duration: 0.3)) {
                                    dragOffset = 0
                                }
                                hasTriggeredSwipe = false
                                swipeDirection = .none
                                lastDragValue = 0
                            }
                        }
                )
                
                // Fixed top navigation bar overlay
                VStack {
                    HStack {
                        // Settings button
                        Button(action: {
                            showSettings.toggle()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.black)
                                .padding(12)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
                        }
                        .accessibilityIdentifier("settings_button")
                        .accessibilityLabel("Settings")
                        .accessibilityHint("Open settings")
                        
                        Spacer()
                        
                        // Share button
                        Button(action: {
                            shareQuote()
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                                .foregroundColor(.black)
                                .padding(12)
                                .background(Color.white.opacity(0.9))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
                        }
                        .accessibilityIdentifier("share_button")
                        .accessibilityLabel("Share")
                        .accessibilityHint("Share current quote")
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 50) // Add extra padding to account for status bar
                    .padding(.bottom, 10)
                    
                    Spacer() // Push navigation to top
                }
                .zIndex(10) // Ensure buttons stay on top
            }
            .onAppear {
                // Set initial opacity for swipe indicator
                swipeIndicatorOpacity = 0.7
                // Auto-hide after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    showSwipeIndicator = false
                }
            }
        }
        .preferredColorScheme(.light)
        .environment(\.layoutDirection, quoteManager.selectedLanguage.isRTL ? .rightToLeft : .leftToRight)
        .ignoresSafeArea(.all) // Ensure the entire view ignores safe areas
        .sheet(isPresented: $showSettings) {
            SettingsView(quoteManager: quoteManager)
                .environment(\.layoutDirection, quoteManager.selectedLanguage.isRTL ? .rightToLeft : .leftToRight)
        }
    }
    
    private func shareQuote() {
        let shareSuffix = quoteManager.localizedString("share_suffix")
        let text = "\(quoteManager.currentQuote)\n\n\(shareSuffix)"

        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        // Get the window scene and root view controller with proper validation
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        // Configure popover presentation for iPad only if not in test environment
        if UIDevice.current.userInterfaceIdiom == .pad && !ProcessInfo.processInfo.environment.keys.contains("XCTestConfigurationFilePath") {
            if let popoverController = activityViewController.popoverPresentationController {
                // Ensure we have a valid source view
                let sourceView = rootViewController.view ?? window
                popoverController.sourceView = sourceView
                popoverController.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
                
                // Add delegate to handle popover dismissal
                popoverController.delegate = makePopoverDelegate()
            }
        }
        
        // Present with proper error handling
        DispatchQueue.main.async {
            if rootViewController.presentedViewController == nil {
                rootViewController.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
    
    private func makePopoverDelegate() -> UIPopoverPresentationControllerDelegate {
        return PopoverDelegate()
    }
}

struct QuoteScreenWithBackgroundView: View {
    @ObservedObject var quoteManager: QuoteManager
    let screenIndex: Int
    let showSwipeIndicator: Bool
    let swipeIndicatorOpacity: Double
    
    private var displayQuote: String {
        // Show different quotes based on screen index for visual swapping
        if screenIndex == -1 {
            // Previous screen - show previous quote
            return quoteManager.getPreviewQuote(offset: -1)
        } else if screenIndex == 1 {
            // Next screen - show next quote
            return quoteManager.getPreviewQuote(offset: 1)
        } else {
            // Current screen - show current quote
            return quoteManager.currentQuote
        }
    }
    
    private var displayIndex: Int {
        // Since we're using history system, we don't need complex indexing
        return 1
    }
    
    var body: some View {
        ZStack {
            // Background gradient (part of swipeable content)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.659, green: 0.902, blue: 0.812), // #A8E6CF
                    Color(red: 1.0, green: 0.827, blue: 0.647),   // #FFD3A5
                    Color(red: 1.0, green: 0.659, blue: 0.659)    // #FFA8A8
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all)
            
            // Content overlay
            VStack {
                Spacer()
                
                // Quote display area
                VStack(spacing: 40) {
                    // Main quote text
                    Text(displayQuote)
                        .font(.system(size: 32, weight: .semibold, design: .default))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .padding(.horizontal, 40)
                        .scaleEffect(quoteManager.fontSize.multiplier)
                        .shadow(color: .white.opacity(0.8), radius: 2, x: 0, y: 1)
                        .accessibilityIdentifier("quote_text")
                        .accessibilityLabel("Daily quote")
                        .accessibilityValue(displayQuote)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Swipe indicator (only on current screen)
                if showSwipeIndicator {
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
                    .opacity(showSwipeIndicator ? 1 : 0)
                }
                
                Spacer().frame(height: 50)
            }
        }
    }
}

// Helper class to handle popover presentation
private class PopoverDelegate: NSObject, UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return true
    }
}

#Preview {
    ContentView()
}
