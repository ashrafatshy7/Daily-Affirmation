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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Initialize subscription manager
                    Task {
                        await subscriptionManager.checkSubscriptionStatus()
                    }
                }
        }
    }
}
