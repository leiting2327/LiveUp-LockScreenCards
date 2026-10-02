import WidgetKit
import SwiftUI

/// 锁屏小组件（替代方案）：在锁屏时间下方显示最新一张卡片。
struct LockScreenCardWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockScreenCardWidget", provider: Provider()) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("锁屏卡片")
        .description("在锁屏小组件上显示你最新钉上去的卡片。")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

struct CardEntry: TimelineEntry {
    let date: Date
    let card: ReminderCard?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> CardEntry {
        CardEntry(date: Date(), card: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (CardEntry) -> Void) {
        completion(CardEntry(date: Date(), card: CardPersistence.latestCard()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CardEntry>) -> Void) {
        let card = CardPersistence.latestCard()
        completion(Timeline(entries: [CardEntry(date: Date(), card: card)], policy: .atEnd))
    }
}

struct LockScreenWidgetView: View {
    let entry: CardEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.card?.title ?? "未钉卡片")
                    .font(.headline)
                    .lineLimit(1)
                if let d = entry.card?.detail {
                    Text(d)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
        case .accessoryInline:
            Text("\(entry.card?.emoji ?? "📌") \(entry.card?.title ?? "未钉卡片")")
        case .accessoryCircular:
            Text(entry.card?.emoji ?? "📌")
                .font(.title2)
        default:
            EmptyView()
        }
    }
}
