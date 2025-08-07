import WidgetKit
import SwiftUI

// MARK: - Timeline Provider
struct AffirmationProvider: TimelineProvider {
    func placeholder(in context: Context) -> AffirmationEntry {
        AffirmationEntry(
            date: Date(),
            quote: "I honor my intrinsic worth",
            backgroundImage: "background"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (AffirmationEntry) -> ()) {
        print("🔶 WIDGET: getSnapshot called - context: \(context)")
        let entry = SharedQuoteManager.shared.getCurrentEntry()
        let widgetEntry = AffirmationEntry(
            date: entry.date,
            quote: entry.quote,
            backgroundImage: entry.backgroundImage
        )
        print("🔶 WIDGET: getSnapshot created entry - quote: '\(widgetEntry.quote)'")
        completion(widgetEntry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AffirmationEntry>) -> ()) {
        print("🔶 WIDGET: getTimeline called - context: \(context)")
        print("🔶 WIDGET: Current time: \(Date())")
        
        let currentEntry = SharedQuoteManager.shared.getCurrentEntry()
        let entry = AffirmationEntry(
            date: currentEntry.date,
            quote: currentEntry.quote,
            backgroundImage: currentEntry.backgroundImage
        )
        
        print("🔶 WIDGET: getTimeline created entry - quote: '\(entry.quote)'")
        
        let timeline: Timeline<AffirmationEntry>
        
        // Update every 5 minutes for debugging
        let calendar = Calendar.current
        let nextUpdate = calendar.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
        timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        print("🔶 WIDGET: Created timeline - next update: \(nextUpdate)")
        
        completion(timeline)
    }
}

// MARK: - Timeline Entry
struct AffirmationEntry: TimelineEntry {
    let date: Date
    let quote: String
    let backgroundImage: String
}

// MARK: - Widget Entry View
struct AffirmationWidgetEntryView: View {
    var entry: AffirmationProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack {
            // Background Image for iOS < 17.0 only
            if #unavailable(iOS 17.0) {
                GeometryReader { geometry in
                    Image(entry.backgroundImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                .ignoresSafeArea(.all)
            }
            
            // Content based on widget size
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                MediumWidgetView(entry: entry)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
    }
}

// MARK: - Small Widget (2x2)
struct SmallWidgetView: View {
    let entry: AffirmationEntry
    
    private var widgetURL: URL? {
        guard let encodedQuote = entry.quote.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "dailyaffirmation://quote?text=\(encodedQuote)")
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            Text(entry.quote)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                .padding(.horizontal, 12)
            
            Spacer()
        }
        .widgetURL(widgetURL)
    }
}

// MARK: - Medium Widget (4x2)
struct MediumWidgetView: View {
    let entry: AffirmationEntry
    
    private var widgetURL: URL? {
        guard let encodedQuote = entry.quote.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "dailyaffirmation://quote?text=\(encodedQuote)")
    }
    
    var body: some View {
        ZStack {
            // Centered quote text
            VStack {
                Spacer()
                
                Text(entry.quote)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 20)
                
                Spacer()
            }
            
        }
        .widgetURL(widgetURL)
    }
}

// MARK: - Large Widget (4x4)
struct LargeWidgetView: View {
    let entry: AffirmationEntry
    
    private var widgetURL: URL? {
        guard let encodedQuote = entry.quote.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "dailyaffirmation://quote?text=\(encodedQuote)")
    }
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                
                // Inspirational icon
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                
                // Quote text
                Text(entry.quote)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.7), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                
                Spacer()
                
                // Bottom inspirational element
                Text("Daily Inspiration")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 0.5)
                    .padding(.bottom, 16)
            }
            
        }
        .widgetURL(widgetURL)
    }
}

// MARK: - Widget Configuration
struct Daily_Affirmation_Widgets: Widget {
    let kind: String = "Daily_Affirmation_Widgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AffirmationProvider()) { entry in
            if #available(iOS 17.0, *) {
                AffirmationWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Image(entry.backgroundImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
            } else {
                AffirmationWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Daily Affirmation")
        .description("Get inspired with daily affirmations.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    Daily_Affirmation_Widgets()
} timeline: {
    AffirmationEntry(date: .now, quote: "I honor my intrinsic worth", backgroundImage: "background")
    AffirmationEntry(date: .now, quote: "I embrace my inherent dignity", backgroundImage: "background")
}

#Preview(as: .systemMedium) {
    Daily_Affirmation_Widgets()
} timeline: {
    AffirmationEntry(date: .now, quote: "I trust my value is constant", backgroundImage: "background")
    AffirmationEntry(date: .now, quote: "I respect myself wholeheartedly", backgroundImage: "background")
}

#Preview(as: .systemLarge) {
    Daily_Affirmation_Widgets()
} timeline: {
    AffirmationEntry(date: .now, quote: "I am worthy of good things", backgroundImage: "background")
    AffirmationEntry(date: .now, quote: "I celebrate my own value", backgroundImage: "background")
}