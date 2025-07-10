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
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showSwipeIndicator = false
                                }
                            }
                            
                            // Immediate quote switching based on scroll direction
                            let currentDrag = value.translation.height
                            let dragDifference = currentDrag - lastDragValue
                            let minimumScrollDistance: CGFloat = 50
                            
                            if abs(currentDrag) > minimumScrollDistance {
                                if currentDrag < -minimumScrollDistance && dragDifference < 0 {
                                    // Swiping up = next quote
                                    quoteManager.nextQuote()
                                    lastDragValue = currentDrag
                                } else if currentDrag > minimumScrollDistance && dragDifference > 0 {
                                    // Swiping down = previous quote
                                    quoteManager.previousQuote()
                                    lastDragValue = currentDrag
                                }
                            }
                        }
                        .onEnded { value in
                            // Simple reset without animations or delays
                            dragOffset = 0
                            lastDragValue = 0
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
                // Start pulsing animation for swipe indicator
                withAnimation {
                    swipeIndicatorOpacity = 0.3
                }
                // Auto-hide after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSwipeIndicator = false
                    }
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
        guard !quoteManager.quotes.isEmpty else { return quoteManager.currentQuote }
        
        let displayIndex: Int
        if screenIndex == -1 {
            // Previous screen
            displayIndex = quoteManager.currentIndex > 0 ? 
                quoteManager.currentIndex - 1 : 
                quoteManager.quotes.count - 1
        } else if screenIndex == 1 {
            // Next screen
            displayIndex = (quoteManager.currentIndex + 1) % quoteManager.quotes.count
        } else {
            // Current screen
            displayIndex = quoteManager.currentIndex
        }
        
        return quoteManager.quotes[displayIndex]
    }
    
    private var displayIndex: Int {
        guard !quoteManager.quotes.isEmpty else { return 1 }
        
        if screenIndex == -1 {
            return quoteManager.currentIndex > 0 ? 
                quoteManager.currentIndex : 
                quoteManager.quotes.count
        } else if screenIndex == 1 {
            return (quoteManager.currentIndex + 2) > quoteManager.quotes.count ? 
                1 : 
                quoteManager.currentIndex + 2
        } else {
            return quoteManager.currentIndex + 1
        }
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
                            .scaleEffect(swipeIndicatorOpacity)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: swipeIndicatorOpacity
                            )
                        
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
                    .animation(.easeInOut(duration: 0.3), value: showSwipeIndicator)
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
