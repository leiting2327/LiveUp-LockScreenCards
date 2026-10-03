import Foundation

/// 从 GitHub Releases 拉取最新构建信息，用于 App 内“自动更新”检查。
struct AppUpdateInfo: Decodable {
    let tagName: String
    let name: String
    let body: String?
    let assets: [Asset]

    struct Asset: Decodable {
        let name: String
        let browserDownloadURL: String

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case assets
    }

    /// 最新一个 .ipa 的下载直链。
    var ipaURL: String? {
        assets.first { $0.name.hasSuffix(".ipa") }?.browserDownloadURL
    }
}

enum UpdateChecker {
    static let repo = "leiting2327/LiveUp-LockScreenCards"

    private static var url: URL {
        URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!
    }

    /// 异步获取最新 Release；失败返回 nil。
    static func latest() async -> AppUpdateInfo? {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return try? JSONDecoder().decode(AppUpdateInfo.self, from: data)
        } catch {
            return nil
        }
    }
}
