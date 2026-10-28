import SwiftUI

/// 深色控制台输出面板
struct ConsoleView: View {
    let text: String
    let running: Bool
    @State private var scrolledToBottom = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(running ? Color.orange : Color.green)
                    .frame(width: 7, height: 7)
                Text(running ? "正在运行…" : "输出")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            ScrollViewReader { proxy in
                ScrollView {
                    Text(text)
                        .font(.system(size: 12.5, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .id("console_bottom")
                }
                .onAppear {
                    withAnimation { proxy.scrollTo("console_bottom", anchor: .bottom) }
                }
                .onChange(of: text) { _ in
                    withAnimation { proxy.scrollTo("console_bottom", anchor: .bottom) }
                }
            }
        }
        .background(Color.black.opacity(0.55))
    }
}
