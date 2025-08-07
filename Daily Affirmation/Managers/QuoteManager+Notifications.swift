import Foundation
import UserNotifications

// MARK: - Notification Management
extension QuoteManager {
    
    // MARK: - Notification Time Calculation
    func calculateNotificationTimes() -> [Date] {
        let calendar = Calendar.current
        
        // Get minutes since midnight for both times
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        var endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        // Handle cross-midnight scenarios (e.g., 10 PM to 6 AM)
        if endMinutes < startMinutes {
            endMinutes += 24 * 60 // Add 24 hours
        }
        
        let totalMinutes = endMinutes - startMinutes
        
        // Validation: ensure there's at least a 1-minute difference
        if totalMinutes < 1 {
            // Return start time as single notification if times are equal
            return [startTime]
        }
        
        // Limit notification count to maximum allowed by the app
        let count = min(max(1, notificationCount), maxNotificationsAllowed)
        
        var notificationTimes: [Date] = []
        
        if count == 1 {
            // Single notification at center of range
            guard totalMinutes > 0 else {
                // If no time range, use start time
                if let startTime = createDateFromMinutes(startMinutes, using: calendar) {
                    notificationTimes.append(startTime)
                }
                return notificationTimes
            }
            let centerMinutes = startMinutes + totalMinutes / 2
            if let notificationTime = createDateFromMinutes(centerMinutes, using: calendar) {
                notificationTimes.append(notificationTime)
            }
        } else {
            // Multiple notifications distributed evenly with improved algorithm
            let actualCount = min(count, totalMinutes + 1)
            
            if actualCount == 1 {
                // Single notification in the middle of range
                guard totalMinutes > 0 else {
                    // If no time range, use start time
                    if let startTime = createDateFromMinutes(startMinutes, using: calendar) {
                        notificationTimes.append(startTime)
                    }
                    return notificationTimes
                }
                let middleMinutes = startMinutes + totalMinutes / 2
                if let notificationTime = createDateFromMinutes(middleMinutes, using: calendar) {
                    notificationTimes.append(notificationTime)
                }
            } else if actualCount == 2 {
                // Two notifications: start and end
                if let startTime = createDateFromMinutes(startMinutes, using: calendar) {
                    notificationTimes.append(startTime)
                }
                if let endTime = createDateFromMinutes(endMinutes, using: calendar) {
                    notificationTimes.append(endTime)
                }
            } else {
                // Multiple notifications with guaranteed unique times
                var usedMinutes: Set<Int> = []
                
                // Always include start time
                usedMinutes.insert(startMinutes)
                if let startTime = createDateFromMinutes(startMinutes, using: calendar) {
                    notificationTimes.append(startTime)
                }
                
                // Always include end time
                usedMinutes.insert(endMinutes)
                if let endTime = createDateFromMinutes(endMinutes, using: calendar) {
                    notificationTimes.append(endTime)
                }
                
                // Distribute remaining notifications evenly in between
                let remainingCount = actualCount - 2
                if remainingCount > 0 && actualCount > 1 && totalMinutes > 0 {
                    // Calculate step size for even distribution
                    let step = Double(totalMinutes) / Double(actualCount - 1)
                    
                    // Validate step calculation
                    guard !step.isNaN && !step.isInfinite else {
                        // If step calculation fails, fall back to start and end times only
                        return notificationTimes.sorted()
                    }
                    
                    for i in 1..<(actualCount - 1) {
                        let targetMinutes = Double(startMinutes) + (Double(i) * step)
                        
                        // Safely convert targetMinutes to Int
                        var candidateMinute = targetMinutes.safeInt(fallback: startMinutes)
                        
                        // Skip if conversion failed or value is out of range
                        guard candidateMinute >= startMinutes && candidateMinute <= endMinutes else {
                            continue
                        }
                        
                        // Ensure uniqueness by adjusting if needed
                        while usedMinutes.contains(candidateMinute) {
                            candidateMinute += 1
                            if candidateMinute > endMinutes {
                                candidateMinute = max(startMinutes, (targetMinutes - 1).safeInt(fallback: startMinutes))
                                while usedMinutes.contains(candidateMinute) && candidateMinute > startMinutes {
                                    candidateMinute -= 1
                                }
                            }
                        }
                        
                        // Only add if within valid range and unique
                        if candidateMinute >= startMinutes && candidateMinute <= endMinutes && !usedMinutes.contains(candidateMinute) {
                            usedMinutes.insert(candidateMinute)
                            if let notificationTime = createDateFromMinutes(candidateMinute, using: calendar) {
                                notificationTimes.append(notificationTime)
                            }
                        }
                    }
                }
            }
        }
        
        // Sort by time - duplicates are already prevented by the improved algorithm
        return notificationTimes.sorted()
    }
    
    private func createDateFromMinutes(_ minutes: Int, using calendar: Calendar) -> Date? {
        let adjustedMinutes = minutes % (24 * 60) // Handle overflow past midnight
        let hours = adjustedMinutes / 60
        let mins = adjustedMinutes % 60
        
        let now = Date()
        return calendar.date(bySettingHour: hours, minute: mins, second: 0, of: now)
    }
    
    // MARK: - Immediate Notification Helpers
    private func getTodaysRemainingNotificationTimes() -> [Date] {
        let allNotificationTimes = calculateNotificationTimes()
        let now = Date()
        let calendar = Calendar.current
        
        // Filter times that are still pending today
        return allNotificationTimes.filter { notificationTime in
            // Create today's version of this notification time
            let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: notificationTime)
            
            guard let todaysNotificationTime = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                                           minute: timeComponents.minute ?? 0,
                                                           second: 0,
                                                           of: calendar.date(from: todayComponents) ?? now) else {
                return false
            }
            
            // Only include times that are in the future (haven't passed yet today)
            return todaysNotificationTime > now
        }
    }
    
    private func scheduleImmediateNotifications() {
        let remainingTimes = getTodaysRemainingNotificationTimes()
        let now = Date()
        let calendar = Calendar.current
        
        for (index, notificationTime) in remainingTimes.enumerated() {
            // Create today's version of this notification time
            let todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: notificationTime)
            
            guard let todaysNotificationTime = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                                           minute: timeComponents.minute ?? 0,
                                                           second: 0,
                                                           of: calendar.date(from: todayComponents) ?? now) else {
                continue
            }
            
            // Calculate time interval from now to the notification time
            let timeInterval = todaysNotificationTime.timeIntervalSince(now)
            
            // Only schedule if it's in the future (should always be true due to filtering)
            if timeInterval > 0 {
                let content = UNMutableNotificationContent()
                content.title = "ThinkUp"
                content.body = getRandomQuote()
                content.sound = .default
                content.badge = 1
                content.categoryIdentifier = "DAILY_AFFIRMATION"
                
                // Use time interval trigger for immediate scheduling
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                
                // Create unique identifier for today's immediate notifications
                let timeString = String(format: "%02d_%02d", timeComponents.hour ?? 0, timeComponents.minute ?? 0)
                let identifier = "dailyInspiration_today_\(timeString)_\(index)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling immediate notification \(identifier): \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - Notification Permission and Scheduling
    func checkNotificationPermissionBeforeEnabling(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                completion(true)
            case .denied:
                completion(false)
            case .notDetermined:
                // Request permission
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    completion(granted)
                }
            default:
                completion(false)
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error requesting notification permission: \(error)")
                    self?.dailyNotifications = false
                } else if granted {
                    self?.scheduleNotification()
                } else {
                    self?.dailyNotifications = false
                }
            }
        }
    }
    
    func checkNotificationPermissionAndSchedule() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    self?.scheduleNotification()
                case .denied:
                    self?.dailyNotifications = false
                case .notDetermined:
                    self?.requestNotificationPermission()
                default:
                    self?.dailyNotifications = false
                }
            }
        }
    }
    
    func scheduleNotification() {
        cancelNotifications()
        
        guard dailyNotifications, !quotes.isEmpty else {
            print("Cannot schedule: notifications disabled or no quotes")
            return
        }
        
        // Check if user has access to time range mode
        if notificationMode == .range && !hasTimeRangeAccess {
            print("Time range mode requires subscription, switching to single mode")
            notificationMode = .single
            return
        }
        
        let calendar = Calendar.current
        
        if notificationMode == .single {
            // Schedule single daily notification
            let content = UNMutableNotificationContent()
            content.title = "ThinkUp"
            content.body = getRandomQuote()
            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "DAILY_AFFIRMATION"
            
            let components = calendar.dateComponents([.hour, .minute], from: singleNotificationTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let identifier = "dailyInspiration_single_\(components.hour ?? 0)_\(components.minute ?? 0)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling single notification \(identifier): \(error)")
                }
            }
        } else {
            // Schedule range-based notifications with hybrid approach
            let notificationTimes = calculateNotificationTimes()
            let remainingTodayTimes = getTodaysRemainingNotificationTimes()
            
            // Check if we have any remaining times today
            if remainingTodayTimes.isEmpty {
                // No remaining times today, schedule normal recurring notifications
                for (index, notificationTime) in notificationTimes.enumerated() {
                    let content = UNMutableNotificationContent()
                    content.title = "ThinkUp"
                    content.body = getRandomQuote()
                    content.sound = .default
                    content.badge = 1
                    content.categoryIdentifier = "DAILY_AFFIRMATION"
                    
                    let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                    
                    let identifier = "dailyInspiration_range_\(components.hour ?? 0)_\(components.minute ?? 0)_\(index)"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("Error scheduling range notification \(identifier): \(error)")
                        }
                    }
                }
            } else {
                // We have remaining times today, use hybrid approach with conflict prevention
                let remainingTodayTimes = getTodaysRemainingNotificationTimes()
                let remainingTimeComponents = Set(remainingTodayTimes.map { 
                    calendar.dateComponents([.hour, .minute], from: $0)
                })
                
                // 1. Schedule immediate notifications for today's remaining times
                scheduleImmediateNotifications()
                
                // 2. Schedule recurring notifications for ALL times EXCEPT those with immediate notifications
                for (index, notificationTime) in notificationTimes.enumerated() {
                    let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
                    
                    // Skip this time if it has an immediate notification scheduled for today
                    let hasImmediateNotification = remainingTimeComponents.contains { timeComp in
                        timeComp.hour == components.hour && timeComp.minute == components.minute
                    }
                    
                    if !hasImmediateNotification {
                        // This time has already passed today, safe to schedule recurring notification
                        let content = UNMutableNotificationContent()
                        content.title = "ThinkUp"
                        content.body = getRandomQuote()
                        content.sound = .default
                        content.badge = 1
                        content.categoryIdentifier = "DAILY_AFFIRMATION"
                        
                        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                        
                        let identifier = "dailyInspiration_range_\(components.hour ?? 0)_\(components.minute ?? 0)_\(index)"
                        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                        
                        UNUserNotificationCenter.current().add(request) { error in
                            if let error = error {
                                print("Error scheduling range notification \(identifier): \(error)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func cancelNotifications() {
        // Cancel all existing daily inspiration notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToCancel = requests
                .filter { $0.identifier.hasPrefix("dailyInspiration") }
                .map { $0.identifier }
            
            if !identifiersToCancel.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
                // Also remove delivered notifications
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiersToCancel)
            }
        }
    }
    
    private func getDailyQuote() -> String {
        guard !quotes.isEmpty else { return "Stay inspired!" }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: today) ?? 1
        
        let dailyIndex = (dayOfYear - 1) % quotes.count
        return quotes[dailyIndex]
    }
    
    private func getRandomQuote() -> String {
        ensureQuoteBagInitialized()
        
        if let selectedQuote = quoteBag.selectRandomQuote() {
            return selectedQuote.text
        }
        
        // Fallback to old method if quote bag fails
        var allAvailableQuotes: [String] = []
        
        // Add regular quotes
        if !quotes.isEmpty {
            allAvailableQuotes.append(contentsOf: quotes)
        }
        
        // Add personal quotes if enabled and available
        if includePersonalQuotes {
            let activePersonal = activePersonalQuotes.map { $0.displayText }
            allAvailableQuotes.append(contentsOf: activePersonal)
        }
        
        guard !allAvailableQuotes.isEmpty else { return "Stay inspired!" }
        return allAvailableQuotes.randomElement() ?? "Stay inspired!"
    }
    
    var formattedNotificationTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let startTimeStr = formatter.string(from: startTime)
        let endTimeStr = formatter.string(from: endTime)
        return "\(startTimeStr) - \(endTimeStr)"
    }
    
    var formattedNotificationCount: String {
        return "\(notificationCount)"
    }
    
    var isValidTimeRange: Bool {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        // Consider it valid if there's a difference (handles cross-midnight)
        return startMinutes != endMinutes
    }
    
    var maxNotificationsAllowed: Int {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        var endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        // Handle cross-midnight scenarios
        if endMinutes < startMinutes {
            endMinutes += 24 * 60
        }
        
        let totalMinutes = endMinutes - startMinutes
        
        // Maximum notifications based on time range (total minutes + 1 to include both start and end)
        let timeBasedMax = max(1, totalMinutes + 1)
        
        // Apply hard cap of 10 notifications maximum regardless of time range
        return min(timeBasedMax, 10)
    }
    
    // MARK: - Time Adjustment
    func adjustEndTimeIfNeeded() {
        // Only adjust if we're in range mode
        guard notificationMode == .range else { return }
        
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        // If start time is >= end time, set end time to start time + 1 minute
        if startMinutes >= endMinutes {
            let newEndMinutes = startMinutes + 1
            let newEndHour = newEndMinutes / 60
            let newEndMinute = newEndMinutes % 60
            
            // Handle the case where adding 1 minute goes to next day (24:00 -> 00:00)
            if newEndHour >= 24 {
                // Set to 00:00 next day
                endTime = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: endTime) ?? endTime
            } else {
                // Set to calculated time same day
                endTime = calendar.date(bySettingHour: newEndHour, minute: newEndMinute, second: 0, of: endTime) ?? endTime
            }
        }
    }
    
    // MARK: - Notification Count Adjustment
    func adjustNotificationCountIfNeeded() {
        // Only adjust if we're in range mode
        guard notificationMode == .range else { return }
        
        let maxAllowed = maxNotificationsAllowed
        
        // If current count exceeds the new maximum, reduce it to the maximum
        if notificationCount > maxAllowed {
            notificationCount = maxAllowed
        }
        // If current count is less than or equal to maximum, don't change it
    }
}