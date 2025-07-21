//
//  Daily_AffirmationApp.swift
//  Daily Affirmation
//
//  Created by Ashraf Atshy on 08/07/2025.
//

import SwiftUI
import UIKit
import UserNotifications

@main
struct Daily_AffirmationApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Initialize subscription manager
                    Task {
                        await subscriptionManager.checkSubscriptionStatus()
                    }
                    // Clear notification badge when app opens
                    clearNotificationBadge()
                }
                .onReceive(NotificationCenter.default.publisher(for: .resetOnboarding)) { _ in
                    showingOnboarding = true
                }
                .fullScreenCover(isPresented: $showingOnboarding) {
                    OnboardingView()
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        // Clear badge when app becomes active (e.g., returning from background)
                        clearNotificationBadge()
                    }
                }
        }
    }
    
    // MARK: - Notification Badge Management
    private func clearNotificationBadge() {
        // Clear the app icon badge
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // Clear delivered notifications from notification center
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
