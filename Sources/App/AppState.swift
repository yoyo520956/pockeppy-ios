import SwiftUI
import UIKit

@MainActor
final class AppState: ObservableObject {
    // MARK: 文件 / 编辑
    @Published var openFile: FileItem?
    @Published var code: String = "print('Hello, PocketPy!')"
    @Published private(set) var codeRev: Int = 0

    // MARK: 运行
    @Published var lastOutput: String = ""
    @Published var isRunning: Bool = false
    @Published var history: [RunRecord] = []

    // MARK: AI
    @Published var aiConfig: AIConfig

    let documentsDir: URL
    private let store = HistoryStore()

    init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.documentsDir = dir
        self.history = store.load()
        self.aiConfig = AppState.loadAIConfig()
    }

    var fileName: String { openFile?.name ?? "untitled.py" }

    // MARK: - 引擎状态透传
    var isEngineReady: Bool { PyEngine.shared.isEngineReady }
    var engineStatusText: String { PyEngine.shared.engineStatusText }

    // MARK: - 编辑同步（WebKit 输入 → 状态；状态 → WebKit 走 codeRev）
    func syncEditorText(_ t: String) {
        guard t != code else { return }
        code = t
    }
    func externalSet(_ t: String, fileName: String? = nil) {
        code = t
        codeRev += 1
        if let n = fileName { openFile = FileItem(name: n, url: documentsDir.appendingPathComponent(n)) }
    }

    // MARK: - 文件
    func startNew() {
        openFile = nil
        let n = "untitled-\(Date().timeIntervalSince1970.prefix(4)).py"
        externalSet("# \(n)\n\ndef main():\n    print('Hello, PocketPy!')\n\nif __name__ == '__main__':\n    main()\n", fileName: n)
    }

    func importSnippet(_ t: Snippet) {
        externalSet(t.code, fileName: t.name.lowercased().replacingOccurrences(of: " ", with: "-") + ".py")
    }

    func copyCode() {
        UIPasteboard.general.string = code
    }

    func saveCurrent() {
        let name = openFile?.name ?? "untitled.py"
        try? code.write(to: documentsDir.appendingPathComponent(name), atomically: true, encoding: .utf8)
        openFile = FileItem(name: name, url: documentsDir.appendingPathComponent(name))
    }

    func deleteFile(_ f: FileItem) {
        try? FileManager.default.removeItem(at: f.url)
    }

    func resetHistory() {
        history.removeAll()
        store.save(history)
    }

    // MARK: - 运行
    func run() {
        guard !isRunning else { return }
        isRunning = true
        lastOutput = "⏳ 运行中…"
        PyEngine.shared.run(code: code) { [weak self] result in
            guard let self else { return }
            self.isRunning = false
            self.lastOutput = result.output
            let rec = RunRecord(fileName: self.openFile?.name ?? "编辑器代码",
                                 codePreview: String(self.code.prefix(120)),
                                 output: String(result.output.prefix(500)),
                                 success: result.success,
                                 durationMs: result.durationMs)
            self.history.insert(rec, at: 0)
            if self.history.count > 200 { self.history = Array(self.history.prefix(200)) }
            self.store.save(self.history)
        }
    }

    // MARK: - AI 配置（UserDefaults 持久化）
    /// 预设只改 endpoint/model，保留已填的 API Key
    func applyAIPreset(_ name: String) {
        guard name != "自定义" else { return }
        var cfg = AIConfig.preset(name)
        cfg.apiKey = aiConfig.apiKey
        aiConfig = cfg
        AppState.saveAIConfig(aiConfig)
    }

    static func loadAIConfig() -> AIConfig {
        let d = UserDefaults.standard
        return AIConfig(baseUrl: d.string(forKey: "ppy.ai.base") ?? "",
                        model: d.string(forKey: "ppy.ai.model") ?? "",
                        apiKey: d.string(forKey: "ppy.ai.key") ?? "",
                        maxTokens: d.object(forKey: "ppy.ai.max") as? Int ?? 2048)
    }
    static func saveAIConfig(_ c: AIConfig) {
        let d = UserDefaults.standard
        d.set(c.baseUrl, forKey: "ppy.ai.base")
        d.set(c.model, forKey: "ppy.ai.model")
        d.set(c.apiKey, forKey: "ppy.ai.key")
        d.set(c.maxTokens, forKey: "ppy.ai.max")
    }
}

struct FileItem: Identifiable, Hashable {
    let name: String
    let url: URL
    var id: String { url.lastPathComponent }
    var content: String {
        (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }
}
