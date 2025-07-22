//
//  ContentView.swift
//  testClaudeCLIxCode
//
//  Created by Ashraf Atshy on 07/07/2025.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var quoteManager = QuoteManager()
    @State private var showSettings = false
    @State private var showCustomizeOptions = false
    @State private var currentScreenOffset: CGFloat = 0
    @State private var swipeIndicatorOpacity: Double = 1.0
    @State private var showSwipeIndicator: Bool = true
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragValue: CGFloat = 0
    @State private var hasTriggeredSwipe: Bool = false
    @State private var swipeDirection: SwipeDirection = .none
    @State private var showNotificationPermission = false
    
    enum SwipeDirection {
        case none, up, down
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            
            ZStack {
                // One swipeable stack per index
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
                                
                                if showSwipeIndicator && abs(value.translation.height) > 10 {
                                    showSwipeIndicator = false
                                }
                                
                                let minimumSwipeDistance: CGFloat = 80
                                let currentDrag = value.translation.height
                                
                                if !hasTriggeredSwipe && abs(currentDrag) > minimumSwipeDistance {
                                    if currentDrag < -minimumSwipeDistance && swipeDirection != .up {
                                        swipeDirection = .up
                                        hasTriggeredSwipe = true
                                    } else if currentDrag > minimumSwipeDistance && swipeDirection != .down {
                                        swipeDirection = .down
                                        hasTriggeredSwipe = true
                                    }
                                }
                            }
                            .onEnded { value in
                                if hasTriggeredSwipe {
                                    if swipeDirection == .up {
                                        withAnimation(.easeOut(duration: 0.4)) {
                                            dragOffset = -screenHeight
                                        }
                                    } else if swipeDirection == .down {
                                        withAnimation(.easeOut(duration: 0.4)) {
                                            dragOffset = screenHeight
                                        }
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        if swipeDirection == .up {
                                            quoteManager.nextQuote()
                                        } else if swipeDirection == .down {
                                            quoteManager.previousQuote()
                                        }
                                        
                                        dragOffset = 0
                                        hasTriggeredSwipe = false
                                        swipeDirection = .none
                                        lastDragValue = 0
                                    }
                                } else {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        dragOffset = 0
                                    }
                                    hasTriggeredSwipe = false
                                    swipeDirection = .none
                                    lastDragValue = 0
                                }
                            }
                    )
                } else {
                    // Fallback on earlier versions
                }
                
                // Fixed top navigation bar overlay
                VStack {
                    HStack {
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
                        
                        Spacer()
                        
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
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 50)
                    .padding(.bottom, 10)
                    
                    Spacer()
                }
                .zIndex(10)
                
                // Fixed bottom buttons overlay
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            showCustomizeOptions.toggle()
                        }) {
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
                        
                        Button(action: {
                            let currentQuote = quoteManager.currentQuote
                            quoteManager.toggleLoveQuote(currentQuote)
                        }) {
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
                
                // Fixed swipe indicator overlay
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
                        .opacity(showSwipeIndicator ? 1 : 0)
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
                // Clear notification badge when main content appears
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
            showNotificationPermission ?
            NotificationPermissionView(
                quoteManager: quoteManager,
                isPresented: $showNotificationPermission
            ) : nil
        )
    }
    
    private func shareQuote() {
        let shareSuffix = quoteManager.localizedString("share_suffix")
        let text = "\(quoteManager.currentQuote)\n\n\(shareSuffix)"
        
        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad && !ProcessInfo.processInfo.environment.keys.contains("XCTestConfigurationFilePath") {
            if let popoverController = activityViewController.popoverPresentationController {
                let sourceView = rootViewController.view ?? window
                popoverController.sourceView = sourceView
                popoverController.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
                popoverController.delegate = makePopoverDelegate()
            }
        }
        
        DispatchQueue.main.async {
            if rootViewController.presentedViewController == nil {
                rootViewController.present(activityViewController, animated: true, completion: nil)
            }
        }
    }
    
    private func makePopoverDelegate() -> UIPopoverPresentationControllerDelegate {
        return PopoverDelegate()
    }
    
    private func checkFirstLaunch() {
        let hasShownPermission = UserDefaults.standard.bool(forKey: "hasShownNotificationPermission")
        if !hasShownPermission {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showNotificationPermission = true
            }
        }
    }
}

// MARK: - Gradient + Text as one swipeable card
struct QuoteCardWithGradientView: View {
    @ObservedObject var quoteManager: QuoteManager
    let screenIndex: Int
    let dragOffset: CGFloat
    
    private var displayQuote: String {
        if screenIndex == -1 {
            return quoteManager.getPreviewQuote(offset: -1)
        } else if screenIndex == 1 {
            return quoteManager.getPreviewQuote(offset: 1)
        } else {
            return quoteManager.currentQuote
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let parallaxMultiplier: CGFloat = 0.5
            let backgroundOffset = dragOffset * parallaxMultiplier
            
            ZStack {
                Image(quoteManager.selectedBackgroundImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height + abs(dragOffset * parallaxMultiplier))
                    .offset(y: backgroundOffset)
                    .clipped()
                    .ignoresSafeArea(.all)
                    .allowsHitTesting(false)

            VStack {
                Spacer()

                Text(displayQuote)
                  .font(.system(size: 32, weight: .semibold))
                  .multilineTextAlignment(.center)
                  .lineLimit(nil)
                  .fixedSize(horizontal: false, vertical: true)
                  .frame(maxWidth: UIScreen.main.bounds.width - 40)
                  .padding(.horizontal, 20)
                  .foregroundColor(.black)
                  .lineSpacing(8)
                  .scaleEffect(quoteManager.fontSize.multiplier)
                  .shadow(color: .white.opacity(0.8), radius: 2, x: 0, y: 1)
                  .accessibilityElement(children: .ignore)
                                     .accessibilityIdentifier(
                                         screenIndex == 0
                                             ? "quote_text"
                                             : "quote_text_preview_\(screenIndex)"
                                     )
                                     .accessibilityLabel("Daily quote")
                                                         .accessibilityValue(displayQuote)
                                                         .accessibility(addTraits: .isStaticText)
                  

                Spacer()


                Spacer().frame(height: 50)
            }
            .padding(.horizontal, 20)
            .padding(.top, 120)
            .padding(.bottom, 140)
            }
        }

    }
}

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
