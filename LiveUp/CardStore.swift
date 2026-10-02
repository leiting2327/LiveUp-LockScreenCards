import Foundation
import ActivityKit

/// App 内的卡片仓库：负责 UI 状态、持久化、Live Activity 起止与自动移除。
final class CardStore: ObservableObject {
    static let shared = CardStore()

    @Published private(set) var cards: [ReminderCard] = []

    private var autoEndTasks: [UUID: Task<Void, Never>] = [:]

    private init() {
        cards = CardPersistence.load()
        // 重启时为尚未完成的卡片恢复锁屏 Live Activity
        for card in cards where !card.isDone {
            startLiveActivity(for: card)
            scheduleAutoEndIfNeeded(card)
        }
    }

    // MARK: - 增删

    func addCard(_ card: ReminderCard, pinToLockScreen: Bool = true) {
        cards.insert(card, at: 0)
        persist()
        if pinToLockScreen { startLiveActivity(for: card) }
        scheduleAutoEndIfNeeded(card)
    }

    /// “用完取下”：标记完成，短暂展示后移除，并结束锁屏 Live Activity。
    func markDone(_ id: UUID) {
        guard let idx = cards.firstIndex(where: { $0.id == id }) else { return }
        cards[idx].isDone = true
        persist()
        endLiveActivity(for: id)
        autoEndTasks[id]?.cancel()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.cards.removeAll { $0.id == id }
            self.persist()
        }
    }

    func removeCard(_ id: UUID) {
        cards.removeAll { $0.id == id }
        persist()
        endLiveActivity(for: id)
        autoEndTasks[id]?.cancel()
    }

    // MARK: - Live Activity

    private func startLiveActivity(for card: ReminderCard) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = CardActivityAttributes(cardID: card.id.uuidString)
        let contentState = CardActivityAttributes.ContentState(
            title: card.title, detail: card.detail, emoji: card.emoji)
        do {
            _ = try Activity<CardActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil)
        } catch {
            // 例如未开启“实时活动”授权，忽略即可
        }
    }

    private func endLiveActivity(for id: UUID) {
        let idString = id.uuidString
        Task {
            for activity in Activity<CardActivityAttributes>.activities
                where activity.attributes.cardID == idString {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    private func scheduleAutoEndIfNeeded(_ card: ReminderCard) {
        guard let minutes = card.autoRemoveAfterMinutes, minutes > 0 else { return }
        autoEndTasks[card.id] = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(minutes) * 60_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.markDone(card.id) }
        }
    }

    // MARK: - 持久化

    private func persist() {
        CardPersistence.save(cards)
    }
}
