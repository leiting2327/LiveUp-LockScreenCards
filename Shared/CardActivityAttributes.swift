import Foundation
import ActivityKit

/// Live Activity 的 Attributes：用于把一张卡片"钉"到锁屏 / 灵动岛上。
/// 该类型必须同时编译进 App 和 Widget Extension 两个 target。
struct CardActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var title: String
        public var detail: String?
        public var emoji: String
    }

    public var cardID: String
}
