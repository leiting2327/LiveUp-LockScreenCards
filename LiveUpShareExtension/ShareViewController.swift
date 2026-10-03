import UIKit
import UniformTypeIdentifiers

/// 分享扩展：在任何 App 里对截图/图片点“分享 → 添加到 LiveUp”，
/// 即可一键识别文字并保存为锁屏卡片。
class ShareViewController: UIViewController {

    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        handleInput()
    }

    private func setupUI() {
        statusLabel.text = "正在识别截图…"
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func handleInput() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = extensionItem.attachments?.first else {
            finish(withMessage: "没有收到图片")
            return
        }
        let imageType = UTType.image.identifier
        guard provider.hasItemConformingToTypeIdentifier(imageType) else {
            finish(withMessage: "请分享一张截图或图片")
            return
        }

        provider.loadItem(forTypeIdentifier: imageType, options: nil) { [weak self] item, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if error != nil {
                    self.finish(withMessage: "读取图片失败")
                    return
                }
                var data: Data?
                if let url = item as? URL { data = try? Data(contentsOf: url) }
                else if let img = item as? UIImage { data = img.pngData() }
                else if let d = item as? Data { data = d }

                guard let data = data else {
                    self.finish(withMessage: "读取图片失败")
                    return
                }
                self.saveCard(fromImage: data)
                self.finish(withMessage: "已添加到 LiveUp ✅")
            }
        }
    }

    /// 识别截图文字并写入 App Group；打开 App 后会自动钉到锁屏。
    private func saveCard(fromImage data: Data) {
        let recognized = OCR.recognizeText(in: data)
        let parsed = SMSParser.parse(recognized.isEmpty ? "照片卡片" : recognized)
        let card = ReminderCard(
            title: parsed.title,
            detail: parsed.detail,
            emoji: parsed.emoji,
            kind: .photo
        )
        var cards = CardPersistence.load()
        cards.insert(card, at: 0)
        CardPersistence.save(cards)
    }

    private func finish(withMessage message: String) {
        statusLabel.text = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}
