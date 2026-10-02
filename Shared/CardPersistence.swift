import Foundation

/// 通过 App Group 在 App 与 Widget（以及 Live Activity）之间共享卡片数据。
/// 纯读写、可在后台线程使用，Widget 的 TimelineProvider 也可安全调用。
enum CardPersistence {
    /// 改成你自己的 App Group ID（需在开发者后台开启 App Groups 后保持一致）。
    static let appGroupID = "group.com.example.LiveUp"
    static let key = "reminder_cards_v1"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func load() -> [ReminderCard] {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ReminderCard].self, from: data) else {
            return []
        }
        return decoded
    }

    static func save(_ cards: [ReminderCard]) {
        if let data = try? JSONEncoder().encode(cards) {
            defaults.set(data, forKey: key)
        }
    }

    /// 最新一张未完成的卡片（供锁屏小组件展示）。
    static func latestCard() -> ReminderCard? {
        load().first { !$0.isDone }
    }
}
