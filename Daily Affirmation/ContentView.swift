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
    @State private var verticalOffset: CGFloat = 0
    @State private var swipeIndicatorOpacity: Double = 1.0
    @State private var showSwipeIndicator: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.659, green: 0.902, blue: 0.812), // #A8E6CF
                        Color(red: 1.0, green: 0.827, blue: 0.647),   // #FFD3A5
                        Color(red: 1.0, green: 0.659, blue: 0.659)    // #FFA8A8
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack {
                    // Top navigation bar
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
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Progress indicator
                    HStack {
                        Spacer()
                        Text("\(quoteManager.currentIndex + 1) / \(quoteManager.quotes.count)")
                            .font(.caption)
                            .foregroundColor(.black.opacity(0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.6))
                                    .blur(radius: 0.5)
                            )
                        Spacer()
                    }
                    .padding(.bottom, 20)
                    .accessibilityLabel("Quote \(quoteManager.currentIndex + 1) of \(quoteManager.quotes.count)")
                    
                    // Quote display area
                    VStack(spacing: 40) {
                        // Main quote text
                        Text(quoteManager.currentQuote)
                            .font(.system(size: 32, weight: .semibold, design: .default))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .padding(.horizontal, 40)
                            .scaleEffect(quoteManager.fontSize.multiplier)
                            .shadow(color: .white.opacity(0.8), radius: 2, x: 0, y: 1)
                            .accessibilityIdentifier("quote_text")
                            .accessibilityLabel("Daily quote")
                            .accessibilityValue(quoteManager.currentQuote)
                        
                        // Date
                        Text(quoteManager.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.7))
                                    .blur(radius: 0.5)
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .offset(y: verticalOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                verticalOffset = value.translation.height
                                // Hide swipe indicator when user starts swiping
                                if showSwipeIndicator && abs(value.translation.height) > 10 {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        showSwipeIndicator = false
                                    }
                                }
                            }
                            .onEnded { value in
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    // Check if swipe distance is sufficient (reduced threshold)
                                    if abs(value.translation.height) > 80 {
                                        if value.translation.height < 0 {
                                            // Swipe up = next quote
                                            quoteManager.nextQuote()
                                        } else {
                                            // Swipe down = previous quote
                                            quoteManager.previousQuote()
                                        }
                                    }
                                    verticalOffset = 0
                                }
                            }
                    )
                    
                    Spacer()
                    
                    // Swipe indicator
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
                        .onAppear {
                            // Start pulsing animation
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
                    
                    Spacer().frame(height: 50)
                }
            }
        }
        .preferredColorScheme(.light)
        .environment(\.layoutDirection, quoteManager.selectedLanguage.isRTL ? .rightToLeft : .leftToRight)
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
