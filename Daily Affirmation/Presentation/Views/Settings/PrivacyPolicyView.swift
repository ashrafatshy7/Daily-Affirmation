import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Text("Privacy Policy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.8))
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 25) {
                        // Introduction
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Introduction")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Welcome to Daily Affirmation. We are committed to protecting your privacy and ensuring you have a positive experience while using our app. This Privacy Policy explains how we collect, use, and protect your information when you use our mobile application.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Information We Collect
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Information We Collect")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Daily Affirmation is designed with privacy in mind. We collect minimal information:")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• App Preferences: Your theme settings (light/dark mode), font size preferences, and notification settings are stored locally on your device")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text("• Notification Data: If you enable notifications, we store your preferred notification time locally on your device")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text("• Subscription Status: Information about your premium subscription status is stored locally on your device for offline access")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text("• No Personal Data: We do not collect names, email addresses, phone numbers, or any personally identifiable information")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text("• No Usage Tracking: We do not track your app usage, reading habits, or behavior within the app")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // How We Use Your Information
                        VStack(alignment: .leading, spacing: 10) {
                            Text("How We Use Your Information")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("The limited information we collect is used solely to:")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• Provide you with a personalized app experience")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text("• Remember your preferences between app sessions")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Text("• Send you daily inspiration notifications (if enabled)")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Data Security
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Data Security")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("All your preferences and settings are stored locally on your device using iOS's secure storage mechanisms. We do not transmit any personal data to external servers.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Third-Party Services
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Third-Party Services")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Daily Affirmation does not integrate with any third-party analytics, advertising, or tracking services. Your data stays on your device.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // In-App Purchases
                        VStack(alignment: .leading, spacing: 10) {
                            Text("In-App Purchases")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Daily Affirmation offers premium subscription features. All purchases are processed through Apple's App Store and are subject to Apple's terms and conditions. All sales are final and no refunds are provided by the developer. For refund requests, please contact Apple Support directly.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Contact Information
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Contact Us")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("If you have any questions about this Privacy Policy, please contact us at ashrafatshy7@gmail.com")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        // Last Updated
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Last Updated")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("This Privacy Policy was last updated on July 12, 2025.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 50)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .preferredColorScheme(nil)
    }
}

#Preview {
    PrivacyPolicyView()
}
