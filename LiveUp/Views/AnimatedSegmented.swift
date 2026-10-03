import SwiftUI

/// 带滑动高亮动画的分段选择控件：选中的一格会有一个胶囊滑块滑过去，
/// 配合文字加粗与变色，一眼可辨当前选中项。
struct AnimatedSegmented: View {
    let options: [String]
    @Binding var selection: Int
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options.indices, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        selection = i
                    }
                } label: {
                    Text(options[i])
                        .font(.subheadline.weight(selection == i ? .semibold : .regular))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if selection == i {
                                Capsule()
                                    .fill(Color.accentColor)
                                    .matchedGeometryEffect(id: "selected", in: ns)
                            }
                        }
                        .foregroundStyle(selection == i ? Color.white : Color.primary)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(Color.secondary.opacity(0.12)))
    }
}
