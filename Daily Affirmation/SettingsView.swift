import SwiftUI

struct SettingsView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    @State private var showPrivacyPolicy = false
    @State private var showTimePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header - Fixed at top
                HStack {
                    Text(quoteManager.localizedString("settings"))
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
                .padding(.bottom, 10)
                .background(quoteManager.isDarkMode ? Color(red: 0.176, green: 0.216, blue: 0.282) : Color(.systemBackground))
                
                // Settings content - Scrollable
                ScrollView {
                    VStack(spacing: 30) {
                    // Dark Mode Toggle
                    HStack {
                        Text(quoteManager.localizedString("dark_mode"))
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
                            Text(quoteManager.localizedString("daily_notifications"))
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
                                    Text(quoteManager.localizedString("notification_time"))
                                        .font(.subheadline)
                                        .foregroundColor(quoteManager.isDarkMode ? .white.opacity(0.8) : .secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 30)
                                
                                Button(action: {
                                    showTimePicker = true
                                }) {
                                    HStack {
                                        Text(DateFormatter.timeFormatter.string(from: quoteManager.notificationTime))
                                            .font(.headline)
                                            .foregroundColor(quoteManager.isDarkMode ? .white : .primary)
                                        Spacer()
                                        Image(systemName: "clock")
                                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.8))
                                    }
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 15)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .padding(.horizontal, 30)
                            }
                        }
                    }
                    
                    // Language Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text(quoteManager.localizedString("language"))
                                .font(.headline)
                                .foregroundColor(quoteManager.isDarkMode ? .white : .primary)
                            Spacer()
                        }
                        .padding(.horizontal, 30)
                        
                        VStack(spacing: 10) {
                            ForEach(QuoteManager.AppLanguage.allCases, id: \.self) { language in
                                Button(action: {
                                    quoteManager.selectedLanguage = language
                                }) {
                                    HStack {
                                        Text(language.displayName)
                                            .font(.headline)
                                            .foregroundColor(quoteManager.selectedLanguage == language ? .white : (quoteManager.isDarkMode ? .white : .primary))
                                        Spacer()
                                    }
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 15)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(quoteManager.selectedLanguage == language ? 
                                                  Color(red: 0.4, green: 0.8, blue: 0.8) : 
                                                  Color.clear)
                                    )
                                }
                                .padding(.horizontal, 30)
                            }
                        }
                    }
                    
                    // Font Size Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text(quoteManager.localizedString("font_size"))
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
                                        Text(size.displayName(using: quoteManager))
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
                            Text(quoteManager.localizedString("privacy_policy"))
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
                    .padding(.top, 20)
                }
            }
            .background(quoteManager.isDarkMode ? Color(red: 0.176, green: 0.216, blue: 0.282) : Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .preferredColorScheme(quoteManager.isDarkMode ? .dark : .light)
        .sheet(isPresented: $showTimePicker) {
            TimePickerModal(selectedTime: $quoteManager.notificationTime, isPresented: $showTimePicker, isDarkMode: quoteManager.isDarkMode, quoteManager: quoteManager)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
                .preferredColorScheme(quoteManager.isDarkMode ? .dark : .light)
        }
    }
}

struct TimePickerModal: View {
    @Binding var selectedTime: Date
    @Binding var isPresented: Bool
    let isDarkMode: Bool
    let quoteManager: QuoteManager
    
    var body: some View {
        VStack(spacing: 20) {
            DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .colorScheme(isDarkMode ? .dark : .light)
            
            Button(action: {
                isPresented = false
            }) {
                Text(quoteManager.localizedString("done"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color(red: 0.4, green: 0.8, blue: 0.8))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
        .background(isDarkMode ? Color(red: 0.176, green: 0.216, blue: 0.282) : Color(.systemBackground))
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    SettingsView(quoteManager: QuoteManager())
}
