import SwiftUI

struct SettingsView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    @State private var showPrivacyPolicy = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(quoteManager.isDarkMode ? .white : .primary)
                    
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
                
                // Settings content
                VStack(spacing: 30) {
                    // Dark Mode Toggle
                    HStack {
                        Text("Dark Mode")
                            .font(.headline)
                            .foregroundColor(quoteManager.isDarkMode ? .white : .primary)
                        
                        Spacer()
                        
                        Toggle("", isOn: $quoteManager.isDarkMode)
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.4, green: 0.8, blue: 0.8)))
                            .animation(.easeInOut(duration: 0.3), value: quoteManager.isDarkMode)
                    }
                    .padding(.horizontal, 30)
                    
                    // Daily Notifications Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Daily Notifications")
                                .font(.headline)
                                .foregroundColor(quoteManager.isDarkMode ? .white : .primary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $quoteManager.dailyNotifications)
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.4, green: 0.8, blue: 0.8)))
                        }
                        .padding(.horizontal, 30)
                        
                        if quoteManager.dailyNotifications {
                            VStack(spacing: 10) {
                                HStack {
                                    Text("Notification Time")
                                        .font(.subheadline)
                                        .foregroundColor(quoteManager.isDarkMode ? .white.opacity(0.8) : .secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 30)
                                
                                DatePicker("", selection: $quoteManager.notificationTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(WheelDatePickerStyle())
                                    .labelsHidden()
                                    .frame(height: 120)
                                    .padding(.horizontal, 30)
                                    .colorScheme(quoteManager.isDarkMode ? .dark : .light)
                            }
                        }
                    }
                    
                    // Font Size Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Font Size")
                                .font(.headline)
                                .foregroundColor(quoteManager.isDarkMode ? .white : .primary)
                            Spacer()
                        }
                        .padding(.horizontal, 30)
                        
                        VStack(spacing: 10) {
                            ForEach(QuoteManager.FontSize.allCases, id: \.self) { size in
                                Button(action: {
                                    quoteManager.fontSize = size
                                }) {
                                    HStack {
                                        Text(size.displayName)
                                            .font(.headline)
                                            .foregroundColor(quoteManager.fontSize == size ? .white : (quoteManager.isDarkMode ? .white : .primary))
                                        Spacer()
                                    }
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 15)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(quoteManager.fontSize == size ? 
                                                  Color(red: 0.4, green: 0.8, blue: 0.8) : 
                                                  Color.clear)
                                    )
                                }
                                .padding(.horizontal, 30)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Privacy Policy Button
                    Button(action: {
                        showPrivacyPolicy.toggle()
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.secondary)
                            Text("Privacy Policy")
                                .font(.headline)
                                .foregroundColor(quoteManager.isDarkMode ? .white : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
                .padding(.top, 30)
            }
            .background(quoteManager.isDarkMode ? Color(red: 0.176, green: 0.216, blue: 0.282) : Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .preferredColorScheme(quoteManager.isDarkMode ? .dark : .light)
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
                .preferredColorScheme(quoteManager.isDarkMode ? .dark : .light)
        }
    }
}

#Preview {
    SettingsView(quoteManager: QuoteManager())
}