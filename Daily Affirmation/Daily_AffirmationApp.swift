//
//  Daily_AffirmationApp.swift
//  Daily Affirmation
//
//  Created by Ashraf Atshy on 08/07/2025.
//

import SwiftUI

@main
struct Daily_AffirmationApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Initialize subscription manager
                    Task {
                        await subscriptionManager.checkSubscriptionStatus()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .resetOnboarding)) { _ in
                    showingOnboarding = true
                }
                .fullScreenCover(isPresented: $showingOnboarding) {
                    OnboardingView()
                }
        }
    }
}
