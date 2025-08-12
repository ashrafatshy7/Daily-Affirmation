import SwiftUI

// MARK: - Settings (Redesigned)
// A friendlier, modern settings experience that focuses on inline controls,
// collapsible sections, and clear, scannable actions. Avoids the previous
// card grid and deep navigation by surfacing the most important controls.

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

struct SettingsView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss
    @State private var showSubscription = false

    // Disclosure controls
    @State private var isNotificationsExpanded = true
    @State private var isAppearanceExpanded = false
    @State private var isFavoritesExpanded = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    header

                    // Quick toggles section
                    quickActions

                    // Notifications
                    SectionCard(title: quoteManager.localizedString("daily_notifications"), subtitle: "When and how often you get reminders", isExpanded: $isNotificationsExpanded) {
                        notificationsContent
                    }

                    // Premium card
                    premiumCard

                    // Appearance / Font
                    SectionCard(title: quoteManager.localizedString("font_size"), subtitle: "Make text easier to read", isExpanded: $isAppearanceExpanded) {
                        appearanceContent
                    }

                    // Favorites
                    SectionCard(title: quoteManager.localizedString("loved_quotes"), subtitle: "Manage your saved quotes", isExpanded: $isFavoritesExpanded) {
                        lovedQuotesContent
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(quoteManager.localizedString("settings"))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Tune your experience in seconds")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Circle())
            }
            .accessibilityIdentifier("close_settings_button")
        }
    }

    // MARK: - Quick Actions
    private var quickActions: some View {
        EmptyView()
    }

    // MARK: - Notifications Content
    private var notificationsContent: some View {
        VStack(spacing: 16) {
            // Daily notifications toggle
            HStack(spacing: 12) {
                Image(systemName: "bell.fill")
                    .foregroundColor(.orange)
                    .frame(width: 20)
                Text(quoteManager.localizedString("daily_notifications"))
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Toggle("", isOn: $quoteManager.dailyNotifications)
                    .labelsHidden()
                    .tint(.orange)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            
            // Mode picker
            VStack(alignment: .leading, spacing: 8) {
                Text(quoteManager.localizedString("notification_mode"))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                ModeSegmentedControl(
                    selection: $quoteManager.notificationMode,
                    hasTimeRangeAccess: quoteManager.hasTimeRangeAccess,
                    onRequireSubscription: { showSubscription = true }
                ) { mode in
                    Text(mode.displayName(using: quoteManager))
                }
                .onChange(of: quoteManager.notificationMode) { _ in
                    // Haptic
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }

            // Time configuration
            Group {
                if quoteManager.notificationMode == .single {
                    TimeInlineRow(
                        title: quoteManager.localizedString("notification_time"),
                        time: $quoteManager.singleNotificationTime
                    )
                } else {
                    VStack(spacing: 12) {
                        TimeInlineRow(
                            title: quoteManager.localizedString("start_time"),
                            time: $quoteManager.startTime
                        )
                        TimeInlineRow(
                            title: quoteManager.localizedString("end_time"),
                            time: $quoteManager.endTime
                        )
                        NotificationStepper(
                            title: quoteManager.localizedString("notification_count"),
                            value: $quoteManager.notificationCount,
                            range: 1...quoteManager.maxNotificationsAllowed
                        )
                        HelperText(text: "Maximum \(quoteManager.maxNotificationsAllowed) notifications allowed for this time range")
                            .opacity(quoteManager.isValidTimeRange ? 1 : 0)
                        if !quoteManager.isValidTimeRange {
                            WarningText(text: "Start time and end time cannot be the same")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Appearance Content
    private var appearanceContent: some View {
        VStack(spacing: 16) {
            ForEach(QuoteManager.FontSize.allCases, id: \.self) { size in
                SelectableRow(
                    title: size.displayName(using: quoteManager),
                    isSelected: quoteManager.fontSize == size
                ) {
                    quoteManager.fontSize = size
                }
            }
        }
    }

    // MARK: - Loved Quotes Content
    private var lovedQuotesContent: some View {
        VStack(spacing: 12) {
            if quoteManager.lovedQuotes.isEmpty {
                EmptyFavorites()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("You have \(quoteManager.lovedQuotes.count) favorites")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(quoteManager.lovedQuotesArray, id: \.self) { quote in
                                Text(quote)
                                    .lineLimit(3)
                                    .font(.footnote)
                                    .foregroundColor(.primary)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(UIColor.secondarySystemBackground))
                                    )
                            }
                        }
                    }
                }
            }
            NavigationLink(destination: LovedQuotesDetailView(quoteManager: quoteManager)) {
                PrimaryButton(title: "Manage favorites", systemImage: "heart.text.square.fill")
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Premium Card
    private var premiumCard: some View {
        Button {
            showSubscription = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    Text("Premium")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                Text("Unlock time-range notifications and more themes.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reusable Components (Settings)

private struct SectionCard<Content: View>: View {
    let title: String
    let subtitle: String
    @Binding var isExpanded: Bool
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            if isExpanded {
                Divider().padding(.horizontal, 16)
                VStack(alignment: .leading, spacing: 16) {
                    content
                }
                .padding(16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }
}

private struct IconToggle: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool
    let tint: Color

    var body: some View {
        Button {
            isOn.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(tint.opacity(0.15)).frame(width: 36, height: 36)
                    Image(systemName: systemImage).foregroundColor(tint)
                }
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer(minLength: 0)
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(tint)
                    .allowsHitTesting(false)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct IconButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(tint.opacity(0.15)).frame(width: 36, height: 36)
                    Image(systemName: systemImage).foregroundColor(tint)
                }
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ModeSegmentedControl<Label: View>: View {
    @Binding var selection: QuoteManager.NotificationMode
    let hasTimeRangeAccess: Bool
    let onRequireSubscription: () -> Void
    let label: (QuoteManager.NotificationMode) -> Label

    var body: some View {
        HStack(spacing: 8) {
            ForEach(QuoteManager.NotificationMode.allCases, id: \.self) { mode in
                Button {
                    if mode == .range && !hasTimeRangeAccess {
                        onRequireSubscription()
                    } else {
                        selection = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        label(mode)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(selection == mode ? .white : .primary)
                        if mode == .range && !hasTimeRangeAccess {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundColor(selection == mode ? .white.opacity(0.9) : .secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selection == mode ? Color.accentColor : Color(UIColor.secondarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: selection == mode ? 0 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct TimeInlineRow: View {
    let title: String
    @Binding var time: Date
    @State private var isExpanded = false
    @State private var selectedHour: Int = 9
    @State private var selectedMinute: Int = 0
    
    private let hours = Array(0...23)
    private let minutes = Array(0...59)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.secondary)
                
            VStack(spacing: 0) {
                // Time display button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.accentColor)
                        Text(DateFormatter.timeFormatter.string(from: time))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: isExpanded ? 12 : 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                }
                .buttonStyle(.plain)
                
                // Inline time picker
                if isExpanded {
                    VStack(spacing: 16) {
                        Divider()
                            .padding(.horizontal, 12)
                        
                        HStack(spacing: 0) {
                            // Hour Picker
                            Picker("Hour", selection: $selectedHour) {
                                ForEach(hours, id: \.self) { hour in
                                    Text(String(format: "%02d", hour))
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                        .tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 70, height: 120)
                            .clipped()
                            
                            Text(":")
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            // Minute Picker
                            Picker("Minute", selection: $selectedMinute) {
                                ForEach(minutes, id: \.self) { minute in
                                    Text(String(format: "%02d", minute))
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                        .tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 70, height: 120)
                            .clipped()
                        }
                        .onChange(of: selectedHour) { _ in updateTime() }
                        .onChange(of: selectedMinute) { _ in updateTime() }
                    }
                    .padding(.bottom, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.secondarySystemBackground))
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .onAppear {
            let calendar = Calendar.current
            selectedHour = calendar.component(.hour, from: time)
            selectedMinute = calendar.component(.minute, from: time)
        }
    }
    
    private func updateTime() {
        let calendar = Calendar.current
        if let newTime = calendar.date(bySettingHour: selectedHour, minute: selectedMinute, second: 0, of: Date()) {
            time = newTime
        }
    }
}

private struct NotificationStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.secondary)
            HStack(spacing: 12) {
                Stepper(value: $value, in: range) {
                    Text("\(value)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
        }
    }
}

private struct HelperText: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundColor(.secondary)
            Text(text)
                .font(.footnote)
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

private struct WarningText: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text(text)
                .font(.footnote)
                .foregroundColor(.orange)
            Spacer()
        }
    }
}

private struct PermissionHint: View {
    @State private var showAlert = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "gearshape")
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 6) {
                Text("Make sure notifications are allowed in iOS Settings")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Button("Open iOS Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.footnote.weight(.semibold))
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

private struct SelectableRow: View {
    let title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .foregroundColor(isSelected ? .white : .primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color(UIColor.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PrimaryButton: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
            Text(title)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(Color.accentColor)
        )
    }
}

private struct EmptyFavorites: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart")
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text("No favorites yet")
                    .font(.subheadline.weight(.semibold))
                Text("Tap the heart on any quote to save it here.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

// MARK: - Loved Quotes Detail (kept; used by navigation)
struct LovedQuotesDetailView: View {
    @ObservedObject var quoteManager: QuoteManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Minimal header
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 36, height: 36)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Circle())
                }
                Spacer()
                Text("Loved Quotes")
                    .font(.headline)
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if quoteManager.lovedQuotes.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "heart")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No loved quotes yet")
                        .font(.title3.weight(.semibold))
                    Text("Tap the heart button on quotes you love to see them here!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Spacer()
                }
            } else {
                List {
                    ForEach(quoteManager.lovedQuotesArray, id: \.self) { quote in
                        HStack(alignment: .top, spacing: 12) {
                            Text(quote)
                                .font(.body)
                                .foregroundColor(.primary)
                            Spacer()
                            Button {
                                quoteManager.toggleLoveQuote(quote)
                            } label: {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
    }
}


#Preview {
    SettingsView(quoteManager: QuoteManager())
}
