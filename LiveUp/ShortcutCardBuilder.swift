import AppIntents
import Foundation

/// 快捷指令“创建活动”Intent。
/// 视频里的自动化只需要两步：收到信息时 → LiveUp「创建卡片（文字）」，短信内容自动识别。
struct CreateCardFromTextIntent: AppIntent {
    static var title: LocalizedStringResource = "创建锁屏卡片（文字）"
    static var description = IntentDescription(
        "把取件码、验证码或任意文字钉到 iPhone 锁屏上。短信内容会自动识别。",
        categoryName: "锁屏卡片"
    )
    static var openAppWhenRun = false

    @Parameter(title: "内容", description: "短信内容或任意文字")
    var text: String

    @Parameter(title: "自动移除（分钟）", description: "填 0 表示保留直到手动移除")
    var autoRemoveMinutes: Int?

    func perform() async throws -> some IntentResult {
        let parsed = SMSParser.parse(text)
        let minutes = (autoRemoveMinutes ?? 0) > 0 ? autoRemoveMinutes : nil
        let card = ReminderCard(
            title: parsed.title,
            detail: parsed.detail,
            emoji: parsed.emoji,
            kind: .text,
            autoRemoveAfterMinutes: minutes
        )
        await MainActor.run { CardStore.shared.addCard(card) }
        return .result()
    }
}

/// 截屏 / 照片识别建卡（对应“没有短信？截个屏也能识别”）。
struct CreateCardFromImageIntent: AppIntent {
    static var title: LocalizedStringResource = "创建锁屏卡片（截图/照片）"
    static var description = IntentDescription(
        "识别截图或照片中的文字，钉到锁屏。",
        categoryName: "锁屏卡片"
    )
    static var openAppWhenRun = false

    @Parameter(title: "图片")
    var image: IntentFile

    func perform() async throws -> some IntentResult {
        let recognized = OCR.recognizeText(in: image.data)
        let parsed = SMSParser.parse(recognized.isEmpty ? "照片卡片" : recognized)
        let card = ReminderCard(
            title: parsed.title,
            detail: parsed.detail,
            emoji: parsed.emoji,
            kind: .photo
        )
        await MainActor.run { CardStore.shared.addCard(card) }
        return .result()
    }
}
