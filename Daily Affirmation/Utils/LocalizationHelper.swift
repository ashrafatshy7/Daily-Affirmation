import Foundation

struct LocalizationHelper {
    static func localizedString(_ key: String) -> String {
        // Return direct English strings based on key
        switch key {
        case "settings": return "Settings"
        case "dark_mode": return "Dark Mode"
        case "daily_notifications": return "Daily Notifications"
        case "notification_time": return "Notification Time"
        case "notification_mode": return "Notification Mode"
        case "single_daily": return "Single Daily"
        case "time_range": return "Time Range"
        case "start_time": return "Start Time"
        case "end_time": return "End Time"
        case "notification_count": return "Notification Count"
        case "font_size": return "Font Size"
        case "language": return "Language"
        case "loved_quotes": return "Loved Quotes"
        case "privacy_policy": return "Privacy Policy"
        case "font_small": return "Small"
        case "font_medium": return "Medium"
        case "font_large": return "Large"
        case "english": return "English"
        case "hebrew": return "Hebrew"
        case "arabic": return "Arabic"
        case "prev": return "PREV"
        case "next": return "NEXT"
        case "share": return "SHARE"
        case "done": return "Done"
        case "swipe_up_next": return "Swipe up for next"
        case "daily_inspiration": return "ThinkUp"
        case "share_suffix": return "- Daily Inspiration"
        case "loading": return "Loading..."
        case "stay_inspired": return "Stay inspired!"
        case "enable_notifications_title": return "Stay Inspired Daily"
        case "enable_notifications_description": return "Get daily motivational quotes delivered to your device. You can customize the timing in settings."
        case "allow_notifications": return "Allow Notifications"
        case "not_now": return "Not Now"
        default: return key
        }
    }
}