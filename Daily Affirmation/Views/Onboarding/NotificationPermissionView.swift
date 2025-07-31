import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Binding var isPresented: Bool
    @State private var showSettingsAlert = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.opacity(0.4)
                    .ignoresSafeArea(.all)
                    .onTapGesture {
                        // Allow dismissing by tapping outside
                        dismissWithoutPermission()
                    }
                
                // Main content
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.659, green: 0.902, blue: 0.812))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "bell.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }
                    
                    // Title and description
                    VStack(spacing: 16) {
                        Text(quoteManager.localizedString("enable_notifications_title"))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                        
                        Text(quoteManager.localizedString("enable_notifications_description"))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    .padding(.horizontal, 20)
                    
                    // Buttons
                    VStack(spacing: 12) {
                        // Allow button
                        Button(action: {
                            requestNotificationPermission()
                        }) {
                            Text(quoteManager.localizedString("allow_notifications"))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.659, green: 0.902, blue: 0.812))
                                .cornerRadius(16)
                        }
                        .accessibilityIdentifier("allow_notifications_button")
                        
                        // Don't allow button
                        Button(action: {
                            dismissWithoutPermission()
                        }) {
                            Text(quoteManager.localizedString("not_now"))
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .accessibilityIdentifier("not_now_button")
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, 40)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .preferredColorScheme(.light)
        .alert("Settings Required", isPresented: $showSettingsAlert) {
            Button("Open Settings") {
                openAppSettings()
                isPresented = false
            }
            Button("Cancel", role: .cancel) {
                isPresented = false
            }
        } message: {
            Text("To enable notifications, please allow them in Settings > Notifications > ThinkUp")
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission error: \(error)")
                    isPresented = false
                    return
                }
                
                if granted {
                    // Permission granted - enable notifications and set default time
                    quoteManager.dailyNotifications = true
                    quoteManager.notificationMode = .single
                    
                    // Set default time to 9:00 AM
                    let calendar = Calendar.current
                    let now = Date()
                    if let defaultTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) {
                        quoteManager.singleNotificationTime = defaultTime
                    }
                    
                    // Mark first launch as completed
                    UserDefaults.standard.set(true, forKey: "hasShownNotificationPermission")
                    isPresented = false
                } else {
                    // Permission denied - keep notifications off
                    quoteManager.dailyNotifications = false
                    
                    // Mark first launch as completed
                    UserDefaults.standard.set(true, forKey: "hasShownNotificationPermission")
                    isPresented = false
                }
            }
        }
    }
    
    private func dismissWithoutPermission() {
        // User dismissed without allowing - keep notifications off
        quoteManager.dailyNotifications = false
        
        // Mark first launch as completed
        UserDefaults.standard.set(true, forKey: "hasShownNotificationPermission")
        isPresented = false
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

struct SettingsRequiredAlert: View {
    @Binding var isPresented: Bool
    let onOpenSettings: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.opacity(0.4)
                    .ignoresSafeArea(.all)
                    .onTapGesture {
                        onCancel()
                    }
                
                // Alert content
                VStack(spacing: 20) {
                    // Icon
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color(red: 0.659, green: 0.902, blue: 0.812))
                    
                    // Title and message
                    VStack(spacing: 12) {
                        Text("Settings Required")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Text("To enable notifications, please allow them in Settings > Notifications > ThinkUp")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    .padding(.horizontal, 16)
                    
                    // Buttons
                    VStack(spacing: 12) {
                        Button(action: onOpenSettings) {
                            Text("Open Settings")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(red: 0.659, green: 0.902, blue: 0.812))
                                .cornerRadius(12)
                        }
                        
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
                )
                .padding(.horizontal, 40)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    NotificationPermissionView(
        quoteManager: QuoteManager(),
        isPresented: .constant(true)
    )
}
