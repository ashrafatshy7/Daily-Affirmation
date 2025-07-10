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
    @State private var cardOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: quoteManager.isDarkMode ? [
                        Color(red: 0.278, green: 0.573, blue: 0.573),
                        Color(red: 0.278, green: 0.573, blue: 0.573)
                    ] : [
                        Color(red: 0.4, green: 0.8, blue: 0.8),
                        Color(red: 0.3, green: 0.7, blue: 0.7)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    // Settings button
                    HStack {
                        Spacer()
                        Button(action: {
                            showSettings.toggle()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .accessibilityIdentifier("settings_button")
                        .accessibilityLabel("Settings")
                        .accessibilityHint("Open settings")
                        .padding(.trailing)
                    }
                    
                    Spacer()
                    
                    // Quote card
                    VStack(spacing: 30) {
                        Text(quoteManager.currentQuote)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(quoteManager.isDarkMode ? .white : .primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 40)
                            .scaleEffect(quoteManager.fontSize.multiplier)
                            .accessibilityIdentifier("quote_text")
                            .accessibilityLabel("Daily quote")
                            .accessibilityValue(quoteManager.currentQuote)
                        
                        Text(quoteManager.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(quoteManager.isDarkMode ? .white.opacity(0.7) : .secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 250)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(quoteManager.isDarkMode ? Color(red: 0.176, green: 0.216, blue: 0.282) : Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 30)
                    .offset(cardOffset)
                    .rotationEffect(.degrees(cardRotation))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                cardOffset = value.translation
                                // For RTL, reverse the rotation to match swipe direction
                                if quoteManager.selectedLanguage.isRTL {
                                    cardRotation = -Double(value.translation.width / 10)
                                } else {
                                    cardRotation = Double(value.translation.width / 10)
                                }
                            }
                            .onEnded { value in
                                withAnimation(.spring()) {
                                    if abs(value.translation.width) > 100 {
                                        if quoteManager.selectedLanguage.isRTL {
                                            // RTL: swipe right = next, swipe left = previous
                                            if value.translation.width > 0 {
                                                quoteManager.nextQuote()
                                            } else {
                                                quoteManager.previousQuote()
                                            }
                                        } else {
                                            // LTR: swipe right = previous, swipe left = next
                                            if value.translation.width > 0 {
                                                quoteManager.previousQuote()
                                            } else {
                                                quoteManager.nextQuote()
                                            }
                                        }
                                    }
                                    cardOffset = .zero
                                    cardRotation = 0
                                }
                            }
                    )
                    
                    Spacer()
                    
                    // Bottom controls
                    HStack {
                        Button(action: {
                            withAnimation(.spring()) {
                                quoteManager.previousQuote()
                            }
                        }) {
                            HStack {
                                if quoteManager.selectedLanguage.isRTL {
                                    Text(quoteManager.localizedString("prev"))
                                    Image(systemName: "chevron.right")
                                } else {
                                    Image(systemName: "chevron.left")
                                    Text(quoteManager.localizedString("prev"))
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                        }
                        .accessibilityIdentifier("prev_button")
                        .accessibilityLabel("Previous")
                        .accessibilityHint("Go to previous quote")
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                quoteManager.nextQuote()
                            }
                        }) {
                            HStack {
                                if quoteManager.selectedLanguage.isRTL {
                                    Image(systemName: "chevron.left")
                                    Text(quoteManager.localizedString("next"))
                                } else {
                                    Text(quoteManager.localizedString("next"))
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                        }
                        .accessibilityIdentifier("next_button")
                        .accessibilityLabel("Next")
                        .accessibilityHint("Go to next quote")
                        
                        Spacer()
                        
                        Button(action: {
                            shareQuote()
                        }) {
                            HStack {
                                if quoteManager.selectedLanguage.isRTL {
                                    Text(quoteManager.localizedString("share"))
                                    Image(systemName: "square.and.arrow.up")
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                    Text(quoteManager.localizedString("share"))
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                        }
                        .accessibilityIdentifier("share_button")
                        .accessibilityLabel("Share")
                        .accessibilityHint("Share current quote")
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 50)
                }
            }
        }
        .preferredColorScheme(quoteManager.isDarkMode ? .dark : .light)
        .animation(.easeInOut(duration: 0.3), value: quoteManager.isDarkMode)
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
