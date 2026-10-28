import SwiftUI

struct EditorView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                toolbar
                EditorRepresentable(app: app)
                Divider()
                ConsoleView(app: app)
            }
            .navigationTitle(app.fileName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var toolbar: some View {
        HStack(spacing: 4) {
            Button { app.run() } label: {
                Label("运行", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.small)
            if app.isRunning { ProgressView().controlSize(.small) }

            Button { app.saveCurrent() } label: {
                Label("保存", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Menu {
                ForEach(Snippets.all) { t in
                    Button { app.importSnippet(t) } label: {
                        Label(t.name, systemImage: "wrench.and.screwdriver")
                    }
                }
            } label: {
                Label("模板", systemImage: "square.stack.3d.up")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button { app.startNew() } label: {
                Label("新建", systemImage: "plus.circle")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Spacer()

            ShareLink(item: "import …\n\n" + app.code) {
                Label("分享", systemImage: "square.and.arrow.up")
            }
            .controlSize(.small)

            Button { app.copyCode() } label: {
                Label("复制", systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            NavigationLink { AIAssistantView() } label: {
                Label("AI", systemImage: "sparkles")
            }
            .buttonStyle(.bordered)
            .tint(.purple)
            .controlSize(.small)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.bar)
    }
}

/// SwiftUI ↔ WebKit 编辑器桥（外部改动经 codeRev 驱动，输入方向不回写避免循环）
struct EditorRepresentable: UIViewRepresentable {
    @ObservedObject var app: AppState

    init(app: AppState) { self.app = app }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> CodeEditorWebView {
        let w = CodeEditorWebView()
        w.onContentChange = { txt in app.syncEditorText(txt) }
        w.onReady = { }
        context.coordinator.lastRev = app.codeRev
        w.setAll(app.code, fileName: app.fileName)
        return w
    }

    func updateUIView(_ uiView: CodeEditorWebView, context: Context) {
        if context.coordinator.lastRev != app.codeRev {
            context.coordinator.lastRev = app.codeRev
            uiView.setAll(app.code, fileName: app.fileName)
        }
    }

    final class Coordinator { var lastRev = -1 }
}
