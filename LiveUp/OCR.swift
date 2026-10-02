import Foundation
import Vision

/// 用 Vision 框架识别截图 / 照片中的文字（对应视频里的“截个屏也能识别”）。
enum OCR {

    static func recognizeText(in data: Data) -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans", "en-US"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(data: data, options: [:])
        try? handler.perform([request])

        return (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
}
