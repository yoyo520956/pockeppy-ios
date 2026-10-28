import SwiftUI

struct EditorView: View {
    @EnvironmentObject var app: AppState
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 文件名行
            HStack {
                Image(systemName: "chevron.left.forwardslash.circle")
                    .foregroundStyle(.orange)
                Text(app.currentFileName ?? "untitled.py")
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Spacer()
                Button {
                    let url = app.saveCode(to: app.currentFileName ?? "untitled.py")
                    if url != nil { app.toast("已保存 \(url!.lastPathComponent)") }
                } label: {
                    Label("保存", systemImage: "square.and.arrow.down")
                }
                .font(.footnote)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.thinMaterial)

            // 代码编辑区
            TextEditor(text: $app.code)
                .font(.system(size: 14, design: .monospaced))
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .keyboardType(.asciiCapable)
                .focused($focused)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 10)
                .frame(maxHeight: .infinity)
                .background(Color.black.opacity(0.25))

            // 工具栏
            HStack(spacing: 10) {
                Button {
                    app.runCode()
                } label: {
                    Label(app.isRunning ? "运行中…" : "运行", systemImage: app.isRunning ? "hourglass" : "play.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(app.isRunning)

                Button {
                    app.code = ""; focused = true
                } label: {
                    Label("清空", systemImage: "trash")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    app.clearConsole()
                } label: {
                    Image(systemName: "terminal")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.thinMaterial)

            // 控制台输出
            ConsoleView(text: app.lastOutput, running: app.isRunning)
                .frame(height: 160)
        }
    }
}
