import SwiftUI

struct ContentView: View {
    @EnvironmentObject var app: AppState
    @State private var tab: Int = 0

    var body: some View {
        ZStack(alignment: .top) {
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
                SettingsView()
                    .tabItem { Label("设置", systemImage: "gearshape") }
                    .tag(3)
            }
            if app.showToast {
                ToastBanner(text: app.toastMessage)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: app.showToast)
    }
}

struct ToastBanner: View {
    let text: String
    var body: some View {
        HStack {
            Image(systemName: "circle.checkmark.fill")
                .foregroundStyle(.green)
            Text(text)
                .font(.footnote)
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }
}
