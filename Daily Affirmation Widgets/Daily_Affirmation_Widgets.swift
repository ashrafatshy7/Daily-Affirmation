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
        print("🔶 WIDGET: getSnapshot called")
        print("🔶 WIDGET: Context - isPreview: \(context.isPreview), displaySize: \(context.displaySize)")
        print("🔶 WIDGET: Context - family: \(context.family)")
        
        let entry = SharedQuoteManager.shared.getCurrentEntry()
        let widgetEntry = AffirmationEntry(
            date: entry.date,
            quote: entry.quote,
            backgroundImage: entry.backgroundImage
        )
        print("🔶 WIDGET: getSnapshot created entry")
        print("🔶 WIDGET: - quote: '\(widgetEntry.quote)'")
        print("🔶 WIDGET: - backgroundImage: '\(widgetEntry.backgroundImage)'")
        print("🔶 WIDGET: - date: \(widgetEntry.date)")
        
        completion(widgetEntry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AffirmationEntry>) -> ()) {
        print("🔶 WIDGET: getTimeline called")
        print("🔶 WIDGET: Context - isPreview: \(context.isPreview), displaySize: \(context.displaySize)")
        print("🔶 WIDGET: Context - family: \(context.family)")
        print("🔶 WIDGET: Current time: \(Date())")
        
        let currentEntry = SharedQuoteManager.shared.getCurrentEntry()
        let entry = AffirmationEntry(
            date: currentEntry.date,
            quote: currentEntry.quote,
            backgroundImage: currentEntry.backgroundImage
        )
        
        print("🔶 WIDGET: getTimeline created entry")
        print("🔶 WIDGET: - quote: '\(entry.quote)'")
        print("🔶 WIDGET: - backgroundImage: '\(entry.backgroundImage)'")
        print("🔶 WIDGET: - date: \(entry.date)")
        
        let timeline: Timeline<AffirmationEntry>
        
        // Update every 5 minutes for debugging, then switch to hourly updates
        let calendar = Calendar.current
        let nextUpdate = calendar.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
        timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        print("🔶 WIDGET: Created timeline with policy: .after(\(nextUpdate))")
        print("🔶 WIDGET: Timeline has \(timeline.entries.count) entries")
        
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
    
    private var backgroundImageExists: Bool {
        UIImage(named: entry.backgroundImage) != nil
    }
    
    // Always use the optimized background.png image
    private var backgroundImage: some View {
        GeometryReader { geometry in
            Image("background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .ignoresSafeArea(.all)
    }
    
    var body: some View {
        let _ = print("🔶 WIDGET VIEW: Rendering widget")
        let _ = print("🔶 WIDGET VIEW: - Device: \(UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone")")
        let _ = print("🔶 WIDGET VIEW: - family: \(family)")
        let _ = print("🔶 WIDGET VIEW: - quote: '\(entry.quote)'")
        let _ = print("🔶 WIDGET VIEW: - quote.isEmpty: \(entry.quote.isEmpty)")
        let _ = print("🔶 WIDGET VIEW: - backgroundImage: '\(entry.backgroundImage)'")
        let _ = print("🔶 WIDGET VIEW: - date: \(entry.date)")
        
        ZStack {
            // For iOS 16 and earlier, show background. iOS 17+ uses containerBackground
            if #unavailable(iOS 17.0) {
                backgroundImage
            }
            
            // Content based on widget size
            Group {
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
            .onAppear {
                print("🔶 WIDGET VIEW: Widget appeared on screen")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea(.all)
    }
}

// MARK: - Small Widget (2x2)
struct SmallWidgetView: View {
    let entry: AffirmationEntry
    
    private var backgroundImageExists: Bool {
        UIImage(named: entry.backgroundImage) != nil
    }
    
    private var widgetURL: URL? {
        guard let encodedQuote = entry.quote.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "dailyaffirmation://quote?text=\(encodedQuote)")
    }
    
    var body: some View {
        let _ = print("🔶 WIDGET VIEW: SmallWidgetView rendering")
        
        VStack {
            Spacer()
            
            Text(entry.quote.isEmpty ? "Stay inspired!" : entry.quote)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
                .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 0)
                .padding(.horizontal, 12)
            
            Spacer()
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(widgetURL)
    }
}

// MARK: - Medium Widget (4x2)
struct MediumWidgetView: View {
    let entry: AffirmationEntry
    
    private var backgroundImageExists: Bool {
        UIImage(named: entry.backgroundImage) != nil
    }
    
    private var widgetURL: URL? {
        guard let encodedQuote = entry.quote.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "dailyaffirmation://quote?text=\(encodedQuote)")
    }
    
    var body: some View {
        let _ = print("🔶 WIDGET VIEW: MediumWidgetView rendering")
        
        ZStack {
            // Centered quote text
            VStack {
                Spacer()
                
                Text(entry.quote.isEmpty ? "Stay inspired!" : entry.quote)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
                    .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 0)
                    .padding(.horizontal, 20)
                
                Spacer()
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        }
        .widgetURL(widgetURL)
    }
}

// MARK: - Large Widget (4x4)
struct LargeWidgetView: View {
    let entry: AffirmationEntry
    
    private var backgroundImageExists: Bool {
        UIImage(named: entry.backgroundImage) != nil
    }
    
    private var widgetURL: URL? {
        guard let encodedQuote = entry.quote.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "dailyaffirmation://quote?text=\(encodedQuote)")
    }
    
    var body: some View {
        let _ = print("🔶 WIDGET VIEW: LargeWidgetView rendering")
        
        ZStack {
            VStack {
                Spacer()
                
                // Inspirational icon
                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                
                // Quote text
                Text(entry.quote.isEmpty ? "Stay inspired!" : entry.quote)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
                    .shadow(color: .black.opacity(0.6), radius: 6, x: 0, y: 0)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
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
                        Image("background")
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