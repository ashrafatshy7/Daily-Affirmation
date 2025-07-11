import SwiftUI

struct SettingsView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    @State private var showPrivacyPolicy = false
    @State private var showStartTimePicker = false
    @State private var showEndTimePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header - Fixed at top
                HStack {
                    Text(quoteManager.localizedString("settings"))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .accessibilityIdentifier("settings_title")
                        .accessibilityLabel("Settings")
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.8))
                    }
                    .accessibilityIdentifier("close_settings_button")
                    .accessibilityLabel("Close settings")
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .background(Color.white)
                
                // Settings content - Scrollable
                ScrollView {
                    VStack(spacing: 24) {
                    
                    // Daily Notifications Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text(quoteManager.localizedString("daily_notifications"))
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            Toggle("", isOn: $quoteManager.dailyNotifications)
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.659, green: 0.902, blue: 0.812)))
                        }
                        .padding(.horizontal, 24)
                        
                        if quoteManager.dailyNotifications {
                            VStack(spacing: 15) {
                                // Start Time
                                VStack(spacing: 10) {
                                    HStack {
                                        Text(quoteManager.localizedString("start_time"))
                                            .font(.subheadline)
                                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                                        Spacer()
                                    }
                                    .padding(.horizontal, 24)
                                    
                                    Button(action: {
                                        showStartTimePicker = true
                                    }) {
                                        HStack {
                                            Text(DateFormatter.timeFormatter.string(from: quoteManager.startTime))
                                                .font(.headline)
                                                .foregroundColor(.black)
                                            Spacer()
                                            Image(systemName: "clock")
                                                .foregroundColor(Color(red: 0.659, green: 0.902, blue: 0.812))
                                        }
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .padding(.horizontal, 24)
                                }
                                
                                // End Time
                                VStack(spacing: 10) {
                                    HStack {
                                        Text(quoteManager.localizedString("end_time"))
                                            .font(.subheadline)
                                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                                        Spacer()
                                    }
                                    .padding(.horizontal, 24)
                                    
                                    Button(action: {
                                        showEndTimePicker = true
                                    }) {
                                        HStack {
                                            Text(DateFormatter.timeFormatter.string(from: quoteManager.endTime))
                                                .font(.headline)
                                                .foregroundColor(.black)
                                            Spacer()
                                            Image(systemName: "clock")
                                                .foregroundColor(Color(red: 0.659, green: 0.902, blue: 0.812))
                                        }
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                    .padding(.horizontal, 24)
                                }
                                
                                // Notification Count
                                VStack(spacing: 10) {
                                    HStack {
                                        Text(quoteManager.localizedString("notification_count"))
                                            .font(.subheadline)
                                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                                        Spacer()
                                    }
                                    .padding(.horizontal, 24)
                                    
                                    HStack {
                                        Button(action: {
                                            if quoteManager.notificationCount > 1 {
                                                quoteManager.notificationCount -= 1
                                            }
                                        }) {
                                            Image(systemName: "minus.circle")
                                                .font(.title2)
                                                .foregroundColor(quoteManager.notificationCount > 1 ? Color(red: 0.659, green: 0.902, blue: 0.812) : .gray)
                                        }
                                        .disabled(quoteManager.notificationCount <= 1)
                                        
                                        Text("\(quoteManager.notificationCount)")
                                            .font(.headline)
                                            .foregroundColor(.black)
                                            .frame(minWidth: 40)
                                        
                                        Button(action: {
                                            if quoteManager.notificationCount < quoteManager.maxNotificationsAllowed {
                                                quoteManager.notificationCount += 1
                                            }
                                        }) {
                                            Image(systemName: "plus.circle")
                                                .font(.title2)
                                                .foregroundColor(quoteManager.notificationCount < quoteManager.maxNotificationsAllowed ? Color(red: 0.659, green: 0.902, blue: 0.812) : .gray)
                                        }
                                        .disabled(quoteManager.notificationCount >= quoteManager.maxNotificationsAllowed)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                                    .padding(.horizontal, 24)
                                }
                                
                                // Helper text showing max notifications
                                if quoteManager.isValidTimeRange {
                                    HStack {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.secondary)
                                        Text("Maximum \(quoteManager.maxNotificationsAllowed) notifications allowed for this time range")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 24)
                                }
                                
                                // Validation Message
                                if !quoteManager.isValidTimeRange {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.orange)
                                        Text("Start time and end time cannot be the same")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        }
                    }
                    
                    
                    // Font Size Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text(quoteManager.localizedString("font_size"))
                                .font(.headline)
                                .foregroundColor(.black)
                                .accessibilityLabel("Font Size")
                            Spacer()
                        }
                        .accessibilityIdentifier("font_size_section")
                        .accessibilityLabel("Font Size")
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 10) {
                            ForEach(QuoteManager.FontSize.allCases, id: \.self) { size in
                                Button(action: {
                                    quoteManager.fontSize = size
                                }) {
                                    HStack {
                                        Text(size.displayName(using: quoteManager))
                                            .font(.headline)
                                            .foregroundColor(quoteManager.fontSize == size ? .white : .black)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(quoteManager.fontSize == size ? 
                                                  Color(red: 0.659, green: 0.902, blue: 0.812) : 
                                                  Color.clear)
                                    )
                                }
                                .accessibilityLabel(size.displayName(using: quoteManager))
                                .accessibilityIdentifier("font_size_\(size.rawValue)")
                                .padding(.horizontal, 24)
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
                                .foregroundColor(.black)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 24)
                    }
                    .padding(.top, 24)
                }
            }
            .background(Color.white)
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showStartTimePicker) {
            TimePickerModal(selectedTime: $quoteManager.startTime, isPresented: $showStartTimePicker, quoteManager: quoteManager, title: "Start Time")
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEndTimePicker) {
            TimePickerModal(selectedTime: $quoteManager.endTime, isPresented: $showEndTimePicker, quoteManager: quoteManager, title: "End Time")
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
                .preferredColorScheme(.light)
        }
    }
}

struct TimePickerModal: View {
    @Binding var selectedTime: Date
    @Binding var isPresented: Bool
    let quoteManager: QuoteManager
    let title: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
                .padding(.top, 10)
            
            DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .colorScheme(.light)
            
            Button(action: {
                isPresented = false
            }) {
                Text(quoteManager.localizedString("done"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color(red: 0.659, green: 0.902, blue: 0.812))
                    .cornerRadius(20)
            }
            .padding(.horizontal, 30)
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
        .background(Color.white)
        .preferredColorScheme(.light)
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
