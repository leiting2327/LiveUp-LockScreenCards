import SwiftUI
import PhotosUI
import AVFoundation
import UIKit

struct CreateCardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: CardStore
    @AppStorage("defaultAutoRemoveMinutes") private var defaultAutoRemoveMinutes = 0

    enum Mode: String, CaseIterable, Identifiable {
        case text = "文字"
        case photo = "截图"
        case voice = "语音"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .text

    // 文字
    @State private var text = ""

    // 截图 / 照片
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var recognizedText = ""
    @State private var isOCRWorking = false

    // 语音
    @State private var recorder: AVAudioRecorder?
    @State private var isRecording = false
    @State private var isTranscribing = false
    @State private var voiceText = ""
    @State private var tempAudioURL: URL?

    // 通用
    @State private var autoRemove = 0
    @State private var showEmptyAlert = false
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("方式", selection: $mode) {
                        ForEach(Mode.allCases) { Text($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                }

                switch mode {
                case .text: textSection
                case .photo: photoSection
                case .voice: voiceSection
                }

                Section("自动移除") {
                    Picker("多久后自动取下锁屏", selection: $autoRemove) {
                        Text("保留直到手动移除").tag(0)
                        Text("30 分钟后").tag(30)
                        Text("1 小时后").tag(60)
                        Text("4 小时后").tag(240)
                        Text("明天早上").tag(720)
                    }
                }
            }
            .navigationTitle("新建锁屏卡片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    // 永远可点：内容为空时自动用剪贴板，实在没有就弹提示
                    Button("创建") { create() }
                }
            }
            .alert("还没有可创建的内容", isPresented: $showEmptyAlert) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text("请在输入框填写要记的事，或先复制一条取件码/验证码短信。")
            }
            .task(id: pickedPhoto) {
                guard let pickedPhoto else { return }
                if let data = try? await pickedPhoto.loadTransferable(type: Data.self) {
                    isOCRWorking = true
                    recognizedText = OCR.recognizeText(in: data)
                    isOCRWorking = false
                }
            }
            .task {
                _ = await VoiceTranscriber.requestAuthorization()
            }
            .onAppear {
                // 用设置里的默认自动移除时长
                autoRemove = defaultAutoRemoveMinutes
                // 自动识别剪贴板里的取件码/验证码
                if text.isEmpty, let s = UIPasteboard.general.string,
                   SMSParser.containsCode(s) {
                    text = s
                }
            }
            .onDisappear {
                recorder?.stop()
            }
        }
    }

    // MARK: - 文字

    private var textSection: some View {
        Section("输入要记的事（会自动识别取件码/验证码）") {
            TextEditor(text: $text)
                .frame(minHeight: 90)
        }
    }

    // MARK: - 截图

    private var photoSection: some View {
        Section("选择截图或照片（自动识别文字）") {
            PhotosPicker(selection: $pickedPhoto, matching: .images) {
                Label("选择图片", systemImage: "photo.on.rectangle")
            }
            if isOCRWorking {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("正在识别文字…").font(.caption).foregroundStyle(.secondary)
                }
            } else if !recognizedText.isEmpty {
                Text(recognizedText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 语音

    private var voiceSection: some View {
        Section("说一句话就建好一张卡") {
            HStack {
                Button {
                    isRecording ? stopRecording() : startRecording()
                } label: {
                    Label(isRecording ? "停止" : "开始录音", systemImage: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(isRecording ? .red : .accentColor)
            }

            if isRecording {
                Text("正在录音…").font(.caption).foregroundStyle(.secondary)
            }
            if isTranscribing {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("正在转成文字…").font(.caption).foregroundStyle(.secondary)
                }
            }
            if !voiceText.isEmpty {
                Text(voiceText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 动作

    private var canCreate: Bool {
        switch mode {
        case .text: return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .photo: return !recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .voice: return !voiceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func create() {
        let minutes = autoRemove > 0 ? autoRemove : nil

        switch mode {
        case .text:
            // 内容为空时自动尝试剪贴板里的取件码/验证码
            var content = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if content.isEmpty, let s = UIPasteboard.general.string,
               SMSParser.containsCode(s) {
                content = s
                text = s
            }
            if content.isEmpty {
                showEmptyAlert = true
                return
            }
            let parsed = SMSParser.parse(content)
            store.addCard(ReminderCard(
                title: parsed.title, detail: parsed.detail, emoji: parsed.emoji,
                kind: .text, autoRemoveAfterMinutes: minutes))
        case .photo:
            let content = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
            if content.isEmpty {
                showEmptyAlert = true
                return
            }
            let parsed = SMSParser.parse(content)
            store.addCard(ReminderCard(
                title: parsed.title, detail: parsed.detail, emoji: parsed.emoji,
                kind: .photo, autoRemoveAfterMinutes: minutes))
        case .voice:
            let content = voiceText.trimmingCharacters(in: .whitespacesAndNewlines)
            if content.isEmpty {
                showEmptyAlert = true
                return
            }
            store.addCard(ReminderCard(
                title: content, detail: nil, emoji: "🎤",
                kind: .voice, autoRemoveAfterMinutes: minutes))
        }
        dismiss()
    }

    // MARK: - 录音

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            return
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("voice_\(UUID().uuidString).m4a")
        tempAudioURL = url
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        recorder = try? AVAudioRecorder(url: url, settings: settings)
        recorder?.record()
        isRecording = true
    }

    private func stopRecording() {
        recorder?.stop()
        isRecording = false
        guard let url = tempAudioURL else { return }
        Task {
            isTranscribing = true
            voiceText = (try? await VoiceTranscriber.transcribe(audioURL: url)) ?? ""
            isTranscribing = false
        }
    }
}
