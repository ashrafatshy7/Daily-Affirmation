import WidgetKit
import SwiftUI

// MARK: - Timeline Provider
struct AffirmationProvider: TimelineProvider {
    func placeholder(in context: Context) -> AffirmationEntry {
        AffirmationEntry(
            date: Date(),
            quote: "I honor my intrinsic worth",
            isPinned: false,
            backgroundImage: "background"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (AffirmationEntry) -> ()) {
        let entry = SharedQuoteManager.shared.getCurrentEntry()
        let widgetEntry = AffirmationEntry(
            date: entry.date,
            quote: entry.quote,
            isPinned: entry.isPinned,
            backgroundImage: entry.backgroundImage
        )
        completion(widgetEntry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AffirmationEntry>) -> ()) {
        let currentEntry = SharedQuoteManager.shared.getCurrentEntry()
        let entry = AffirmationEntry(
            date: currentEntry.date,
            quote: currentEntry.quote,
            isPinned: currentEntry.isPinned,
            backgroundImage: currentEntry.backgroundImage
        )
        
        let timeline: Timeline<AffirmationEntry>
        
        if currentEntry.isPinned {
            // If pinned, update less frequently but still allow updates when reloadTimelines is called
            let calendar = Calendar.current
            let nextUpdate = calendar.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        } else {
            // If not pinned, update daily at midnight
            let calendar = Calendar.current
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
            let nextMidnight = calendar.startOfDay(for: tomorrow)
            
            timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        }
        
        completion(timeline)
    }
}

// MARK: - Timeline Entry
struct AffirmationEntry: TimelineEntry {
    let date: Date
    let quote: String
    let isPinned: Bool
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
    }
}

// MARK: - Medium Widget (4x2)
struct MediumWidgetView: View {
    let entry: AffirmationEntry
    
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
            
            // Pin indicator in top-right corner
            if entry.isPinned {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "pin.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(red: 0.659, green: 0.902, blue: 0.812))
                            .padding(8)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 8)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Large Widget (4x4)
struct LargeWidgetView: View {
    let entry: AffirmationEntry
    
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
            
            // Pin indicator in top-right corner
            if entry.isPinned {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "pin.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.659, green: 0.902, blue: 0.812))
                            .padding(10)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                    Spacer()
                }
            }
        }
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
        .description("Get inspired with daily affirmations. Pin your favorites to keep them displayed.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    Daily_Affirmation_Widgets()
} timeline: {
    AffirmationEntry(date: .now, quote: "I honor my intrinsic worth", isPinned: false, backgroundImage: "background")
    AffirmationEntry(date: .now, quote: "I embrace my inherent dignity", isPinned: true, backgroundImage: "background")
}

#Preview(as: .systemMedium) {
    Daily_Affirmation_Widgets()
} timeline: {
    AffirmationEntry(date: .now, quote: "I trust my value is constant", isPinned: false, backgroundImage: "background")
    AffirmationEntry(date: .now, quote: "I respect myself wholeheartedly", isPinned: true, backgroundImage: "background")
}

#Preview(as: .systemLarge) {
    Daily_Affirmation_Widgets()
} timeline: {
    AffirmationEntry(date: .now, quote: "I am worthy of good things", isPinned: false, backgroundImage: "background")
    AffirmationEntry(date: .now, quote: "I celebrate my own value", isPinned: true, backgroundImage: "background")
}