import Foundation

/// 一张要"钉到锁屏"的备忘卡片。
struct ReminderCard: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var detail: String?
    var emoji: String
    var kind: Kind
    var createdAt: Date
    /// 多少分钟后自动从锁屏取下；nil 表示一直保留到手动移除。
    var autoRemoveAfterMinutes: Int?
    var isDone: Bool

    enum Kind: String, Codable {
        case text
        case photo
        case voice
    }

    init(
        id: UUID = UUID(),
        title: String,
        detail: String? = nil,
        emoji: String = "📌",
        kind: Kind = .text,
        createdAt: Date = Date(),
        autoRemoveAfterMinutes: Int? = nil,
        isDone: Bool = false
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.emoji = emoji
        self.kind = kind
        self.createdAt = createdAt
        self.autoRemoveAfterMinutes = autoRemoveAfterMinutes
        self.isDone = isDone
    }
}
