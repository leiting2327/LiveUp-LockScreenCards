# LiveUp — 锁屏备忘卡片（iOS 17+）

复刻抖音上宣传的 **LiveUp**（App ID 6465078562）核心功能：把"要记的事"（取件码、验证码、停车位、登机口、手写便签等）**钉到 iPhone 锁屏**，抬手即看，用完自动取下。

> 这不是原版 LiveUp，而是一套按同样功能思路实现的开源工程，供你自行构建 IPA。

---

## 一、为什么这里没有直接给出 .ipa

真正的原生 iOS 应用（IPA）**必须在装有 Xcode 的 macOS 上编译并签名**：

- 需要 **Xcode + iOS SDK**（含 WidgetKit / Live Activities / App Intents 框架）
- 需要 **Apple Developer 账号签名**（`Developer` 免费账号也可，仅 7 天有效）才能安装到 iPhone

当前（Linux）环境既没有 Xcode，也没有 iOS SDK 和签名证书，**无法在本地直接产出可安装的原生 IPA**。所以交付的是**完整、可归档成 IPA 的 Xcode 工程**。下面的步骤在任何一台 Mac 上 10 分钟就能打出 IPA。

---

## 二、构建为 IPA 的步骤（需一台 Mac）

### 1. 生成 Xcode 工程（二选一）

**方式 A：用 XcodeGen（推荐，一条命令生成）**

```bash
brew install xcodegen
cd LiveUp
xcodegen generate   # 生成 LiveUp.xcodeproj
```

**方式 B：手工建工程** —— 若不用 XcodeGen，可在 Xcode 里 `File > New > Project > iOS > App`（SwiftUI、Bundle ID `com.example.LiveUp`），把 `LiveUp/`、`Shared/` 加入 App target，把 `LiveUpWidget/`、`Shared/` 加入新建的 Widget Extension target，并按 `project.yml` 配置 entitlements 与 App Group。

### 2. 签名与 App Group

- 打开 `LiveUp.xcodeproj`，在 **Signing & Capabilities** 里：
  - 两个 target 都勾选 **App Groups**，并加入 `group.com.example.LiveUp`（与代码里的 `CardPersistence.appGroupID` 一致）
  - 选择你的开发团队（免费 Apple ID 即可，签名后 7 天需重装一次）
- 如需改 Bundle ID，请同步修改 `project.yml`、`CardPersistence.appGroupID` 和两个 entitlements。

### 3. 添加 App 图标（可选）

在 `LiveUp/Assets.xcassets/AppIcon.appiconset` 放入 1024×1024 的 `AppIcon.png`。缺图标也能编译，只是安装后是空白图标。

### 4. 归档并导出 IPA

```bash
# Xcode 中：选择任意 iOS 设备 (Any iOS Device) 作为运行目标
# 菜单 Product > Archive，等归档完成
# Window > Organizer > 选中刚归档的版本 > Distribute App
#   选 Development / Ad Hoc（或 App Store Connect 发布）
#   选择签名方式后即可导出 .ipa
```

### 5. 安装到自己的 iPhone（无付费账号场景）

导出的 Development IPA 可直接用 **Xcode 设备窗口**安装；或拖入 **Sideloadly / AltStore / 爱思助手** 用你自己的 Apple ID 重签名安装。注意：免费证书签名的 App 7 天后需重签。

---

## 三、使用方式（对照抖音视频）

| 视频里的功能 | 本工程实现 |
|---|---|
| 短信一到，卡片自动上锁屏（快捷指令自动化只需两步） | `CreateCardFromTextIntent`：快捷指令里加 **「收到信息时」→「LiveUp 创建锁屏卡片（文字）」→ 输入=快捷指令输入**，短信内容由 App 自动识别 |
| 不用写一条规则 / 换短信不用重写 | 识别逻辑内置在 `SMSParser.swift`（取件码 / 验证码 / 货架号） |
| 截个屏也能识别 | `CreateCardFromImageIntent` + 应用内"截图"Tab，用 Vision OCR 识别 |
| 说一句话就建好一张卡 | 应用内"语音"Tab + `VoiceTranscriber.swift`（语音转文字） |
| 用完自动从锁屏取下 | Live Activity 由 `CardStore` 管理，可设自动移除时长，或点"完成"立即取下 |
| 抬手就能看到 | `CardLiveActivity`（锁屏实时活动横幅）+ `LockScreenCardWidget`（锁屏小组件） |

> 需在 **系统设置 → 实时活动** 中开启本 App 的实时活动权限。

---

## 四、工程结构

```
LiveUp/
├── project.yml                  # XcodeGen 配置
├── Shared/                      # App 与 Widget 共享
│   ├── Card.swift               #   卡片数据模型
│   ├── CardPersistence.swift    #   App Group 持久化
│   └── CardActivityAttributes.swift  #   Live Activity 类型
├── LiveUp/                      # App target
│   ├── LiveUpApp.swift
│   ├── CardStore.swift          #   状态 + Live Activity 起止 + 自动移除
│   ├── SMSParser.swift          #   取件码/验证码识别
│   ├── OCR.swift                #   截图文字识别
│   ├── VoiceTranscriber.swift   #   语音转文字
│   ├── ShortcutCardBuilder.swift#   快捷指令 Intent（文字/截图）
│   ├── Views/                   #   列表 + 新建卡片界面
│   ├── Info.plist / LiveUp.entitlements
├── LiveUpWidget/                # Widget Extension target
│   ├── LiveUpWidgetBundle.swift
│   ├── CardLiveActivity.swift   #   锁屏实时活动卡片
│   ├── LockScreenWidget.swift   #   锁屏小组件
│   └── Info.plist / LiveUpWidget.entitlements
└── README_BUILD_IPA.md
```

## 五、验证说明

- 本工程在 Linux 沙箱完成，**未经 Xcode 编译验证**；代码按 iOS 17 / Swift 5 官方 API 编写。
- 首次在 Xcode 构建如遇签名报错，先到 Signing & Capabilities 选择团队即可。
- 已知依赖：需 iOS 17 及以上（`ContentUnavailableView`、Live Activities 等均为 iOS 17 API）。
