import Foundation
import Speech

/// 语音转文字（对应视频里的“说一句话就建好一张卡”）。
enum VoiceTranscriber {

    enum VoiceError: LocalizedError {
        case unavailable
        var errorDescription: String? { "语音识别当前不可用，请检查授权或稍后再试。" }
    }

    /// 请求语音识别授权。
    static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status == .authorized)
            }
        }
    }

    /// 把一段录音文件转成文字。
    static func transcribe(audioURL: URL) async throws -> String {
        try await withCheckedThrowingContinuation { cont in
            let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
            guard let recognizer, recognizer.isAvailable else {
                cont.resume(throwing: VoiceError.unavailable)
                return
            }
            let request = SFSpeechURLRecognitionRequest(url: audioURL)
            request.shouldReportPartialResults = false
            recognizer.recognitionTask(with: request) { result, error in
                if let result, result.isFinal {
                    cont.resume(returning: result.bestTranscription.formattedString)
                } else if let error {
                    cont.resume(throwing: error)
                }
            }
        }
    }
}
