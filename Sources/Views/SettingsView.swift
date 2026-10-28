import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var app: AppState
    @State private var base = ""
    @State private var model = ""
    @State private var key = ""
    @State private var testing = false
    @State private var testResult = ""

    var body: some View {
        List {
            Section("Python 引擎") {
                InfoRow(title: "CPython", value: app.engineStatusText)
                Button("立即尝试初始化引擎") {
                    PyEngine.shared.bootstrap()
                }
                .font(.caption)
                .disabled(app.isEngineReady)
            }

            Section("AI 接口（OpenAI 兼容）") {
                TextField("API Endpoint", text: $base, prompt: Text("https://api.moonshot.cn/v1"))
                    .font(.caption)
                    .keyboardType(.URL)
                TextField("模型名", text: $model, prompt: Text("moonshot-v1-8k / gpt-4o-mini / qwen-plus"))
                    .font(.caption)
                SecureField("API Key（仅存本机 UserDefaults）", text: $key)
                    .font(.caption)
                HStack(spacing: 12) {
                    Menu {
                        ForEach(["Kimi", "百炼", "OpenAI", "OpenRouter"], id: \.self) { p in
                            Button(p) {
                                let c = AIConfig.preset(p)
                                base = c.baseUrl; model = c.model
                            }
                        }
                    } label: {
                        Label("快速预设", systemImage: "wand.and.stars")
                    }
                    Button("保存并测试") { saveAndTest() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(testing)
                    if testing { ProgressView().controlSize(.small) }
                }
                .controlSize(.small)
                if !testResult.isEmpty {
                    Text(testResult)
                        .font(.caption2)
                        .foregroundStyle(testResult.hasPrefix("✓") ? .green : .red)
                }
            }

            Section("数据") {
                InfoRow(title: "沙盒目录", value: app.documentsDir.path)
                InfoRow(title: "历史记录", value: "\(app.history.count) 条")
                Button("清空历史") {
                    app.resetHistory()
                }
                .font(.caption)
                .foregroundStyle(.red)
                .disabled(app.history.isEmpty)
            }

            Section("关于") {
                InfoRow(title: "版本", value: Self.appVersion())
                InfoRow(title: "口袋 Python 工作站", value: "对标 Python IDE · 无付费墙")
            }
        }
        .navigationTitle("设置")
        .onAppear {
            base = app.aiConfig.baseUrl
            model = app.aiConfig.model
            key = app.aiConfig.apiKey
        }
    }

    private func saveAndTest() {
        var cfg = app.aiConfig
        cfg.baseUrl = base
        cfg.model = model
        cfg.apiKey = key
        app.aiConfig = cfg
        AppState.saveAIConfig(cfg)
        testResult = ""
        testing = true
        AIClient().chat(cfg, messages: [AIClient.Msg(role: "user", content: "只回复两个字：正常")]) { result in
            DispatchQueue.main.async {
                testing = false
                switch result {
                case .success(let t):
                    testResult = "✓ 连接成功：\(String(t.prefix(40)))"
                case .failure(let e):
                    testResult = "✗ \(e.localizedDescription)"
                }
            }
        }
    }

    static func appVersion() -> String {
        let b = Bundle.main.infoDictionary
        let m = (b?["CFBundleShortVersionString"] as? String) ?? "0.1"
        let p = (b?["CFBundleVersion"] as? String) ?? "?"
        return "\(m) (\(p))"
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
            Spacer()
            Text(value)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
    }
}
