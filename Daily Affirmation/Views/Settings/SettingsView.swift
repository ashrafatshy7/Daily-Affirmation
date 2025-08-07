import SwiftUI

struct SettingsView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    @State private var showSubscription = false
    
    var body: some View {
        NavigationView {
            ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.98, green: 0.99, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Modern Header
                ZStack {
                    // Header gradient background
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.8, blue: 0.8).opacity(0.1),
                                    Color(red: 0.5, green: 0.7, blue: 0.9).opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)
                    
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(quoteManager.localizedString("settings"))
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                
                                Text("Personalize your experience")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                dismiss()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                                    
                                    Image(systemName: "xmark")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black.opacity(0.7))
                                }
                            }
                            .accessibilityIdentifier("close_settings_button")
                            .accessibilityLabel("Close settings")
                            .accessibility(addTraits: .isButton)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                
                // Settings content - Scrollable
                ScrollView {
                    VStack(spacing: 16) {
                        // Notifications Section
                        NavigationLink(destination: NotificationSettingsDetailView(quoteManager: quoteManager)) {
                            SettingsCard(
                                icon: "bell.fill",
                                title: quoteManager.localizedString("daily_notifications"),
                                subtitle: quoteManager.dailyNotifications ? "Enabled" : "Disabled",
                                iconColor: Color(red: 1.0, green: 0.584, blue: 0.0)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier("notifications_section")
                        .accessibility(addTraits: .isButton)
                        
                        // Premium Features Section
                        Button(action: {
                            showSubscription.toggle()
                        }) {
                            SettingsCard(
                                icon: "crown.fill",
                                title: "Premium Features",
                                subtitle: "Unlock Time Range notifications",
                                iconColor: Color(red: 1.0, green: 0.7, blue: 0.0)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier("premium_section")
                        .accessibility(addTraits: .isButton)
                        
                        // Display Section
                        NavigationLink(destination: DisplaySettingsView(quoteManager: quoteManager)) {
                            SettingsCard(
                                icon: "textformat.size",
                                title: quoteManager.localizedString("font_size"),
                                subtitle: quoteManager.fontSize.displayName(using: quoteManager),
                                iconColor: Color(red: 0.0, green: 0.478, blue: 1.0)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier("display_section")
                        .accessibility(addTraits: .isButton)
                        
                        // Loved Quotes Section
                        NavigationLink(destination: LovedQuotesDetailView(quoteManager: quoteManager)) {
                            SettingsCard(
                                icon: "heart.fill",
                                title: quoteManager.localizedString("loved_quotes"),
                                subtitle: "Your favorites",
                                iconColor: Color.red
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityIdentifier("loved_quotes_section")
                        .accessibility(addTraits: .isButton)
                        
                        
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
        .sheet(isPresented: $showSubscription) {
            SubscriptionView()
        }
        }
    }
}

struct SettingsCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black.opacity(0.4))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
        .contentShape(Rectangle())
    }
}

struct NotificationSettingsDetailView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    @State private var showStartTimePicker = false
    @State private var showEndTimePicker = false
    @State private var showSingleTimePicker = false
    @State private var showSettingsAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.4, green: 0.8, blue: 0.8))
                }
                
                Text(quoteManager.localizedString("daily_notifications"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .background(Color.white)
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Notification Toggle
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
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showStartTimePicker) {
            if #available(iOS 16.0, *) {
                TimePickerModal(selectedTime: $quoteManager.startTime, isPresented: $showStartTimePicker, quoteManager: quoteManager, title: "Start Time", isStartTime: true)
                    .presentationDetents([.height(350)])
                    .presentationDragIndicator(.visible)
            } else {
                // Fallback on earlier versions
            }
        }
        .sheet(isPresented: $showEndTimePicker) {
            if #available(iOS 16.0, *) {
                TimePickerModal(selectedTime: $quoteManager.endTime, isPresented: $showEndTimePicker, quoteManager: quoteManager, title: "End Time", isStartTime: false)
                    .presentationDetents([.height(350)])
                    .presentationDragIndicator(.visible)
            } else {
                // Fallback on earlier versions
            }
        }
        .sheet(isPresented: $showSingleTimePicker) {
            if #available(iOS 16.0, *) {
                TimePickerModal(selectedTime: $quoteManager.singleNotificationTime, isPresented: $showSingleTimePicker, quoteManager: quoteManager, title: "Notification Time", isStartTime: true)
                    .presentationDetents([.height(350)])
                    .presentationDragIndicator(.visible)
            } else {
                // Fallback on earlier versions
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .notificationPermissionDenied)) { _ in
            showSettingsAlert = true
        }
        .overlay(
            showSettingsAlert ? 
            SettingsRequiredAlert(
                isPresented: $showSettingsAlert,
                onOpenSettings: {
                    openAppSettings()
                    showSettingsAlert = false
                },
                onCancel: {
                    showSettingsAlert = false
                }
            ) : nil
        )
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

struct NotificationModeSection: View {
    @ObservedObject var quoteManager: QuoteManager
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingSubscriptionView = false
    
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
                        if mode == .range && !quoteManager.hasTimeRangeAccess {
                            showingSubscriptionView = true
                        } else {
                            quoteManager.notificationMode = mode
                        }
                    }) {
                        HStack {
                            Text(mode.displayName(using: quoteManager))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(
                                    (mode == .range && !quoteManager.hasTimeRangeAccess) ? .gray :
                                    (quoteManager.notificationMode == mode ? .white : .black)
                                )
                            
                            if mode == .range && !quoteManager.hasTimeRangeAccess {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    (mode == .range && !quoteManager.hasTimeRangeAccess) ? Color.gray.opacity(0.1) :
                                    (quoteManager.notificationMode == mode ? Color(red: 0.659, green: 0.902, blue: 0.812) : Color.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(
                                            (mode == .range && !quoteManager.hasTimeRangeAccess) ? Color.gray.opacity(0.3) :
                                            (quoteManager.notificationMode == mode ? Color(red: 0.659, green: 0.902, blue: 0.812) : Color.secondary.opacity(0.3)), 
                                            lineWidth: 2
                                        )
                                )
                                .shadow(
                                    color: (mode == .range && !quoteManager.hasTimeRangeAccess) ? Color.clear :
                                    (quoteManager.notificationMode == mode ? Color(red: 0.659, green: 0.902, blue: 0.812).opacity(0.3) : Color.clear),
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                        )
                    }
                    .disabled(mode == .range && !quoteManager.hasTimeRangeAccess ? false : false) // Keep clickable for subscription
                    .animation(.easeInOut(duration: 0.2), value: quoteManager.notificationMode)
                }
            }
            .padding(.horizontal, 24)
            .sheet(isPresented: $showingSubscriptionView) {
                SubscriptionView()
            }
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

struct DisplaySettingsView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.98, green: 0.99, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Modern Header
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.478, blue: 1.0).opacity(0.1),
                                    Color(red: 0.0, green: 0.278, blue: 0.8).opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Button(action: {
                                dismiss()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                                    
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black.opacity(0.7))
                                }
                            }
                            .accessibilityLabel("Back")
                            
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 4) {
                                Text("Font Size")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                
                                Text("Text readability")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 44, height: 44)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
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
                                        
                                        if quoteManager.fontSize == size {
                                            Image(systemName: "checkmark")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(quoteManager.fontSize == size ? 
                                                  Color(red: 0.659, green: 0.902, blue: 0.812) : 
                                                  Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(quoteManager.fontSize == size ? 
                                                            Color.clear : 
                                                            Color.secondary.opacity(0.3), 
                                                            lineWidth: 1)
                                            )
                                    )
                                }
                                .accessibilityLabel(size.displayName(using: quoteManager))
                                .accessibilityIdentifier("font_size_\(size.rawValue)")
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        }
        .navigationBarHidden(true)
    }
}

struct LovedQuotesDetailView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.98, green: 0.99, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Modern Header
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.red.opacity(0.1),
                                    Color.red.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Button(action: {
                                dismiss()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                                    
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.black.opacity(0.7))
                                }
                            }
                            .accessibilityLabel("Back")
                            
                            Spacer()
                            
                            VStack(alignment: .center, spacing: 4) {
                                Text("Loved Quotes")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.black)
                                
                                Text("Your favorites")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 44, height: 44)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            
            // Content
            if quoteManager.lovedQuotes.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "heart")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("No loved quotes yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    
                    Text("Tap the heart button on quotes you love to see them here!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(quoteManager.lovedQuotesArray, id: \.self) { quote in
                            HStack(alignment: .top, spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(quote)
                                        .font(.body)
                                        .foregroundColor(.black)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(nil)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    quoteManager.toggleLoveQuote(quote)
                                }) {
                                    Image(systemName: "heart.fill")
                                        .font(.title3)
                                        .foregroundColor(.red)
                                }
                                .accessibilityLabel("Remove from loved quotes")
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        }
        .navigationBarHidden(true)
    }
}

struct LovedQuotesSection: View {
    @ObservedObject var quoteManager: QuoteManager
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(quoteManager.localizedString("loved_quotes"))
                    .font(.headline)
                    .foregroundColor(.black)
                    .accessibilityLabel("Loved Quotes")
                
                Spacer()
                
                Text("\(quoteManager.lovedQuotes.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(.horizontal, 24)
            
            if !quoteManager.lovedQuotes.isEmpty {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text(isExpanded ? "Hide Loved Quotes" : "Show Loved Quotes")
                            .font(.headline)
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 24)
                
                if isExpanded {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(quoteManager.lovedQuotesArray, id: \.self) { quote in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(quote)
                                            .font(.body)
                                            .foregroundColor(.black)
                                            .multilineTextAlignment(.leading)
                                            .lineLimit(3)
                                        
                                        Spacer()
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        quoteManager.toggleLoveQuote(quote)
                                    }) {
                                        Image(systemName: "heart.fill")
                                            .font(.title3)
                                            .foregroundColor(.red)
                                    }
                                    .accessibilityLabel("Remove from loved quotes")
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .frame(maxHeight: 200)
                    .animation(.easeInOut(duration: 0.3), value: isExpanded)
                }
            } else {
                Text("No loved quotes yet. Tap the heart button on quotes you love!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondary.opacity(0.1))
                    )
                    .padding(.horizontal, 24)
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
