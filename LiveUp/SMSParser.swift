import Foundation

/// 从短信 / 文本中识别“取件码”“验证码”等信息，生成适合钉锁屏的卡片内容。
enum SMSParser {

    struct Parsed {
        let title: String
        let detail: String?
        let emoji: String
    }

    static func parse(_ raw: String) -> Parsed {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // 取件码：例如 “【菜鸟驿站】您的取件码为 12-3-4567”
        if let code = firstMatch(pattern: #"取件码[:：]?\s*([0-9A-Za-z\-]{2,12})"#, in: trimmed) {
            return Parsed(title: "取件码 \(code)", detail: trimmed, emoji: "📦")
        }
        // 验证码：例如 “验证码：123456，5分钟内有效”
        if let code = firstMatch(pattern: #"(验证码|校验码)[:：]?\s*(\d{4,8})"#, in: trimmed) {
            return Parsed(title: "验证码 \(code)", detail: trimmed, emoji: "🔐")
        }
        // 常见的驿站取件码形态：货架号-层-编号，如 12-3-4567
        if let code = firstMatch(pattern: #"(\d{1,2}-\d{1,2}-\d{2,5})"#, in: trimmed) {
            return Parsed(title: "取件码 \(code)", detail: trimmed, emoji: "📦")
        }
        // 兜底：用第一行作为标题
        let firstLine = trimmed.components(separatedBy: .newlines).first ?? trimmed
        let title = String(firstLine.prefix(30))
        return Parsed(title: title, detail: trimmed, emoji: "💬")
    }

    /// 文本里是否含可识别的取件码/验证码（供剪贴板自动识别用）。
    static func containsCode(_ raw: String) -> Bool {
        firstMatch(pattern: #"(取件码|验证码|校验码|\d{1,2}-\d{1,2}-\d{2,5})"#, in: raw) != nil
    }

    private static func firstMatch(pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > 1,
              let r = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[r])
    }
}
