import SwiftUI

struct ContentView: View {
    @EnvironmentObject var app: AppState
    @State private var tab: Int = 0

    var body: some View {
        TabView(selection: $tab) {
            EditorView()
                .tabItem { Label("编辑器", systemImage: "chevron.left.forwardslash.chevron.right") }
                .tag(0)
            FilesView()
                .tabItem { Label("文件", systemImage: "folder") }
                .tag(1)
            HistoryView()
                .tabItem { Label("历史", systemImage: "clock.arrow.circlepath") }
                .tag(2)
            AIAssistantView()
                .tabItem { Label("AI", systemImage: "sparkles") }
                .tag(3)
            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape") }
                .tag(4)
        }
        .onAppear {
            PyEngine.shared.bootstrap()
        }
    }
}
