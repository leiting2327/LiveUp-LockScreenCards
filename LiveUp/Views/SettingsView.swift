import SwiftUI
import UIKit
import ActivityKit

/// “设置”页：默认行为、实时活动、自动获取引导、自动更新、关于。
struct SettingsView: View {
    @AppStorage("defaultAutoRemoveMinutes") private var defaultAutoRemove = 0

    @State private var updateInfo: AppUpdateInfo?
    @State private var checking = false
    @State private var checked = false

    var body: some View {
        NavigationStack {
            Form {
                Section("新建卡片默认") {
                    Picker("多久后自动取下锁屏", selection: $defaultAutoRemove) {
                        Text("保留直到手动移除").tag(0)
                        Text("30 分钟后").tag(30)
                        Text("1 小时后").tag(60)
                        Text("4 小时后").tag(240)
                        Text("明天早上").tag(720)
                    }
                }

                Section("实时活动") {
                    LabeledContent("锁屏卡片状态", value: liveActivityStatus)
                    Button("前往系统设置") { open(urlString: UIApplication.openSettingsURLString) }
                    Text("若状态为“未开启”，请在系统设置的“实时活动”里允许本 App。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("自动获取信息（快捷指令）") {
                    Text("iOS 不允许 App 直接读取短信，自动抓取取件码/验证码需借助快捷指令。按下面两步设置后，收到短信会自动识别并钉到锁屏：")
                        .font(.footnote)
                    Text("① 打开「快捷指令」→ 自动化 → 新建个人自动化 →「信息」→ 收到信息时")
                        .font(.footnote)
                    Text("② 添加操作「LiveUp 创建锁屏卡片（文字）」，把“内容”设为「快捷指令的输入」")
                        .font(.footnote)
                    Text("没有短信时，截个屏选“截图”也能自动识别文字。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("自动更新") {
                    LabeledContent("当前版本", value: currentVersion)
                    if checking {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("正在检查最新构建…").font(.footnote).foregroundStyle(.secondary)
                        }
                    } else if let info = updateInfo {
                        LabeledContent("最新构建", value: info.tagName)
                        if let url = info.ipaURL {
                            Button("前往下载最新 IPA") { open(urlString: url) }
                        }
                        if let body = info.body {
                            Text(body).font(.footnote).foregroundStyle(.secondary).lineLimit(4)
                        }
                    } else if checked {
                        Text("未能获取更新信息，请检查网络后重试。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Button("检查更新") {
                        Task { await check() }
                    }
                    Text("iOS 不允许 App 自行安装/替换自身。安装最新包请用 Sideloadly / AltStore 重签名，或改用 AltStore 以便其自动更新。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("关于") {
                    LabeledContent("版本", value: currentVersion)
                    LabeledContent("Bundle ID", value: Bundle.main.bundleIdentifier ?? "-")
                    LabeledContent("更新检查", value: UpdateChecker.repo)
                }
            }
            .navigationTitle("设置")
        }
    }

    private var currentVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.2"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(short)（构建 \(build)）"
    }

    private var liveActivityStatus: String {
        ActivityAuthorizationInfo().areActivitiesEnabled ? "已开启" : "未开启"
    }

    private func open(urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func check() async {
        checking = true
        checked = true
        updateInfo = await UpdateChecker.latest()
        checking = false
    }
}
