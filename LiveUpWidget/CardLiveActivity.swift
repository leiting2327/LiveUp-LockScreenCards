import ActivityKit
import WidgetKit
import SwiftUI

/// 把卡片“钉”到锁屏的 Live Activity。
/// iOS 17 下实时活动会以横幅卡片形态显示在锁屏底部，抬手即可看到。
struct CardLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CardActivityAttributes.self) { context in
            LockScreenCardView(state: context.state)
                .activityBackgroundTint(.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.state.emoji)
                        .font(.largeTitle)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.title)
                            .font(.headline)
                        if let d = context.state.detail {
                            Text(d)
                                .font(.caption)
                                .lineLimit(2)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("轻点卡片可移除")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Text(context.state.emoji)
            } compactTrailing: {
                Text(String(context.state.title.prefix(2)))
                    .font(.caption2)
            } minimal: {
                Text(context.state.emoji)
            }
        }
    }
}

/// 锁屏上的卡片外观。
struct LockScreenCardView: View {
    let state: CardActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            Text(state.emoji)
                .font(.system(size: 34))
            VStack(alignment: .leading, spacing: 2) {
                Text(state.title)
                    .font(.headline)
                if let d = state.detail {
                    Text(d)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding()
    }
}
