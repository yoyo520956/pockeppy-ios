import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        NavigationStack {
            Form {
                Section("引擎状态") {
                    LabeledContent("Python 引擎", value: app.engine.isEngineReady() ? "已就绪" : "v0.2 携带")
                    LabeledContent("历史条数", value: "\(app.history.count)")
                    HStack {
                        Text("沙盒目录")
                        Spacer()
                        Text(app.documentsDir.path)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Section("维护") {
                    Button("清空运行历史") {
                        app.history = []
                        HistoryStore.shared.clear()
                        app.toast("历史已清空")
                    }
                    .foregroundStyle(.red)
                    Button("重置示例代码") {
                        app.code = Self.sample()
                        app.toast("已恢复示例代码")
                    }
                }
                Section("关于") {
                    LabeledContent("版本", value: Self.appVersion())
                    LabeledContent("设备", value: ProcessInfo.processInfo.systemName + " " + ProcessInfo.processInfo.systemVersion)
                    Text("PocketPy · 口袋 Python 工作站\n对标 Python IDE 1.7.5 功能面，无付费墙，功能全开。\n路线图：v0.2 CPython 嵌入 → v0.3 补全/终端/SSH → v0.4 AI/小组件")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
        }
    }

    static func appVersion() -> String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "v\(v) (\(b))"
    }

    static func sample() -> String {
        return """
        # PocketPy 示例
import math
print("Hello, PocketPy!")
print("2^20 =", 2 ** 20)
        """
    }
}
