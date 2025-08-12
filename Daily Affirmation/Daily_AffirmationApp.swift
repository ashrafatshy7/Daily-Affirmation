//
//  Daily_AffirmationApp.swift
//  Daily Affirmation
//
//  Created by Ashraf Atshy on 08/07/2025.
//

import SwiftUI
import UIKit
import UserNotifications
import WidgetKit

@main
struct Daily_AffirmationApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var quoteManager = QuoteManager()
    @State private var showingOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(quoteManager)
                .onAppear {
                    // Initialize subscription manager
                    Task {
                        await subscriptionManager.checkSubscriptionStatus()
                    }
                    // Clear notification badge when app opens
                    clearNotificationBadge()
                    
                    // Check if we should request app rating
                    quoteManager.checkAndRequestRatingOnAppLaunch()
                    
                    // Reload widgets when app launches to sync latest data
                    print("📱 App: Reloading widgets...")
                    WidgetCenter.shared.reloadAllTimelines()
                    print("📱 App: Widget reload triggered")
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onReceive(NotificationCenter.default.publisher(for: .resetOnboarding)) { _ in
                    showingOnboarding = true
                }
                .fullScreenCover(isPresented: $showingOnboarding) {
                    OnboardingView()
                        .environmentObject(quoteManager)
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        // Clear badge when app becomes active (e.g., returning from background)
                        clearNotificationBadge()
                    }
                }
        }
    }
    
    // MARK: - Deep Link Handling
    private func handleDeepLink(_ url: URL) {
        // Check if this is our dailyaffirmation scheme
        guard url.scheme == "dailyaffirmation" else {
            return
        }
        
        // Check if this is a quote deep link
        guard url.host == "quote" else {
            return
        }
        
        // Parse the quote text from URL parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let textItem = queryItems.first(where: { $0.name == "text" }),
              let encodedText = textItem.value,
              let decodedText = encodedText.removingPercentEncoding else {
            return
        }
        
        // Set the specific quote in the quote manager
        quoteManager.setSpecificQuote(decodedText)
    }
    
    // MARK: - Notification Badge Management
    private func clearNotificationBadge() {
        // Clear the app icon badge
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // Clear delivered notifications from notification center
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
