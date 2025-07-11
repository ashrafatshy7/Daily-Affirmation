import SwiftUI

struct SettingsView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    @State private var showPrivacyPolicy = false
    @State private var showStartTimePicker = false
    @State private var showEndTimePicker = false
    @State private var showSingleTimePicker = false
    
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
                        NotificationSettingsView(
                            quoteManager: quoteManager,
                            showStartTimePicker: $showStartTimePicker,
                            showEndTimePicker: $showEndTimePicker,
                            showSingleTimePicker: $showSingleTimePicker
                        )
                    
                    
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
            TimePickerModal(selectedTime: $quoteManager.startTime, isPresented: $showStartTimePicker, quoteManager: quoteManager, title: "Start Time", isStartTime: true)
                .presentationDetents([.height(350)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEndTimePicker) {
            TimePickerModal(selectedTime: $quoteManager.endTime, isPresented: $showEndTimePicker, quoteManager: quoteManager, title: "End Time", isStartTime: false)
                .presentationDetents([.height(350)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSingleTimePicker) {
            TimePickerModal(selectedTime: $quoteManager.singleNotificationTime, isPresented: $showSingleTimePicker, quoteManager: quoteManager, title: "Notification Time", isStartTime: true)
                .presentationDetents([.height(350)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
                .preferredColorScheme(.light)
        }
    }
}

struct NotificationSettingsView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Binding var showStartTimePicker: Bool
    @Binding var showEndTimePicker: Bool
    @Binding var showSingleTimePicker: Bool
    
    var body: some View {
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
                    // Notification Mode Selection
                    NotificationModeSection(quoteManager: quoteManager)
                    
                    if quoteManager.notificationMode == .single {
                        // Single Notification Time
                        SingleTimeSection(quoteManager: quoteManager, showSingleTimePicker: $showSingleTimePicker)
                    } else {
                        // Range Mode Settings
                        RangeModeSection(
                            quoteManager: quoteManager,
                            showStartTimePicker: $showStartTimePicker,
                            showEndTimePicker: $showEndTimePicker
                        )
                    }
                }
            }
        }
    }
}

struct NotificationModeSection: View {
    @ObservedObject var quoteManager: QuoteManager
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(quoteManager.localizedString("notification_mode"))
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                Spacer()
            }
            .padding(.horizontal, 24)
            
            HStack(spacing: 12) {
                ForEach(QuoteManager.NotificationMode.allCases, id: \.self) { mode in
                    Button(action: {
                        quoteManager.notificationMode = mode
                    }) {
                        Text(mode.displayName(using: quoteManager))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(quoteManager.notificationMode == mode ? .white : .black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(quoteManager.notificationMode == mode ? 
                                          Color(red: 0.659, green: 0.902, blue: 0.812) : 
                                          Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                quoteManager.notificationMode == mode ? 
                                                Color(red: 0.659, green: 0.902, blue: 0.812) : 
                                                Color.secondary.opacity(0.3), 
                                                lineWidth: 2
                                            )
                                    )
                                    .shadow(
                                        color: quoteManager.notificationMode == mode ? 
                                        Color(red: 0.659, green: 0.902, blue: 0.812).opacity(0.3) : 
                                        Color.clear,
                                        radius: 4,
                                        x: 0,
                                        y: 2
                                    )
                            )
                    }
                    .animation(.easeInOut(duration: 0.2), value: quoteManager.notificationMode)
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

struct SingleTimeSection: View {
    @ObservedObject var quoteManager: QuoteManager
    @Binding var showSingleTimePicker: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(quoteManager.localizedString("notification_time"))
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                Spacer()
            }
            .padding(.horizontal, 24)
            
            Button(action: {
                showSingleTimePicker = true
            }) {
                HStack {
                    Text(DateFormatter.timeFormatter.string(from: quoteManager.singleNotificationTime))
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
    }
}

struct RangeModeSection: View {
    @ObservedObject var quoteManager: QuoteManager
    @Binding var showStartTimePicker: Bool
    @Binding var showEndTimePicker: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            // Start Time
            TimePickerSection(
                title: quoteManager.localizedString("start_time"),
                time: quoteManager.startTime,
                showPicker: $showStartTimePicker
            )
            
            // End Time  
            TimePickerSection(
                title: quoteManager.localizedString("end_time"),
                time: quoteManager.endTime,
                showPicker: $showEndTimePicker
            )
            
            // Notification Count
            NotificationCountSection(quoteManager: quoteManager)
            
            // Helper text and validation
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

struct TimePickerSection: View {
    let title: String
    let time: Date
    @Binding var showPicker: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                Spacer()
            }
            .padding(.horizontal, 24)
            
            Button(action: {
                showPicker = true
            }) {
                HStack {
                    Text(DateFormatter.timeFormatter.string(from: time))
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
    }
}

struct NotificationCountSection: View {
    @ObservedObject var quoteManager: QuoteManager
    
    var body: some View {
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
    }
}

struct TimePickerModal: View {
    @Binding var selectedTime: Date
    @Binding var isPresented: Bool
    let quoteManager: QuoteManager
    let title: String
    let isStartTime: Bool
    
    @State private var selectedHour: Int = 9
    @State private var selectedMinute: Int = 0
    
    private var availableHours: [Int] {
        if isStartTime {
            return Array(0...23)
        } else {
            // For end time, available hours are from start time to 23, then from 0 to 0 (next day)
            let startHour = Calendar.current.component(.hour, from: quoteManager.startTime)
            
            // Create range from start hour to 23, then add 0 at the end for next day
            var hours = Array(startHour...23)
            hours.append(0) // Add 00:00 next day
            return hours
        }
    }
    
    private var availableMinutes: [Int] {
        if isStartTime {
            return Array(0...59)
        } else {
            let startHour = Calendar.current.component(.hour, from: quoteManager.startTime)
            let startMinute = Calendar.current.component(.minute, from: quoteManager.startTime)
            
            if selectedHour == startHour {
                // Same hour as start time, minutes must be > start minute
                return Array((startMinute + 1)...59)
            } else {
                // Different hour, all minutes available
                return Array(0...59)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
                .padding(.top, 10)
            
            HStack(spacing: 0) {
                // Hour picker
                Picker("Hour", selection: $selectedHour) {
                    ForEach(availableHours, id: \.self) { hour in
                        Text(String(format: "%02d", hour))
                            .tag(hour)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 80)
                .clipped()
                
                Text(":")
                    .font(.title)
                    .foregroundColor(.black)
                
                // Minute picker
                Picker("Minute", selection: $selectedMinute) {
                    ForEach(availableMinutes, id: \.self) { minute in
                        Text(String(format: "%02d", minute))
                            .tag(minute)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(width: 80)
                .clipped()
            }
            .colorScheme(.light)
            .onChange(of: selectedHour) { _ in
                // Adjust selected minute if it's no longer valid
                if !availableMinutes.contains(selectedMinute) {
                    selectedMinute = availableMinutes.first ?? 0
                }
            }
            
            Button(action: {
                // Create new date with selected time
                let calendar = Calendar.current
                let newDate = calendar.date(bySettingHour: selectedHour, minute: selectedMinute, second: 0, of: selectedTime) ?? selectedTime
                selectedTime = newDate
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
        .onAppear {
            // Initialize with current selected time
            let calendar = Calendar.current
            selectedHour = calendar.component(.hour, from: selectedTime)
            selectedMinute = calendar.component(.minute, from: selectedTime)
            
            // Ensure selected values are valid
            if !availableHours.contains(selectedHour) {
                selectedHour = availableHours.first ?? 0
            }
            if !availableMinutes.contains(selectedMinute) {
                selectedMinute = availableMinutes.first ?? 0
            }
        }
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
