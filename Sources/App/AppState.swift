import Foundation
import SwiftUI

/// 全局应用状态
final class AppState: ObservableObject {
    @Published var code: String
    @Published var currentFileName: String?
    @Published var lastOutput: String
    @Published var isRunning: Bool = false
    @Published var history: [RunRecord]
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""

    let documentsDir: URL
    let engine = PyEngine.shared

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        documentsDir = docs
        let stored = HistoryStore.shared.load()
        self.history = stored
        self.lastOutput = "〔PocketPy〕就绪。写点代码然后点「运行」吧。\n（v0.1 预览版：引擎 v0.2 携带 CPython 后真跑代码）"
        let starter = Self.defaultStarter()
        self.code = starter
        self.currentFileName = nil
    }

    private static func defaultStarter() -> String {
        """
        # PocketPy 示例
import sys, platform, math

def fib(n):
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a

print("Python 就绪，前10个斐波那契：")
print([fib(i) for i in range(10)])
print("圆周率 ≈", round(math.pi, 10))
"""
    }

    /// 弹出轻提示（2.5 秒自动消失）
    func toast(_ message: String) {
        toastMessage = message
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.showToast = false
        }
    }

    func saveCode(to fileName: String) -> URL? {
        let url = documentsDir.appendingPathComponent(fileName)
        do {
            try code.write(to: url, atomically: true, encoding: .utf8)
            currentFileName = fileName
            return url
        } catch {
            toast("保存失败：\(error.localizedDescription)")
            return nil
        }
    }

    func loadFile(_ url: URL) {
        do {
            code = try String(contentsOf: url, encoding: .utf8)
            currentFileName = url.lastPathComponent
            toast("已打开 \(url.lastPathComponent)")
        } catch {
            toast("打开失败：\(error.localizedDescription)")
        }
    }

    func listFiles() -> [URL] {
        let exts: Set<String> = ["py", "txt", "md", "json"]
        let items = (try? FileManager.default.contentsOfDirectory(
            at: documentsDir, includingPropertiesForKeys: [.isRegularFileKey])) ?? []
        return items
            .filter { exts.contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    func deleteFile(_ url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            if currentFileName == url.lastPathComponent { currentFileName = nil }
            toast("已删除 \(url.lastPathComponent)")
        } catch {
            toast("删除失败")
        }
    }

    func newFile(named name: String) -> Bool {
        let url = documentsDir.appendingPathComponent(name)
        guard !FileManager.default.fileExists(atPath: url.path) else {
            toast("文件已存在：\(name)"); return false
        }
        do {
            try "# \(name)\n".write(to: url, atomically: true, encoding: .utf8)
            loadFile(url)
            return true
        } catch {
            toast("创建失败"); return false
        }
    }

    func runCode() {
        guard !isRunning else { return }
        isRunning = true
        let snapshot = code
        let name = currentFileName ?? "未命名"
        engine.run(code: snapshot) { [weak self] result in
            guard let self else { return }
            self.isRunning = false
            self.lastOutput = result.output
            let record = RunRecord(id: UUID(), fileName: name,
                                   codePreview: String(snapshot.prefix(120)),
                                   output: String(result.output.prefix(2000)),
                                   date: Date(), success: result.success,
                                   durationMs: result.durationMs)
            HistoryStore.shared.add(record)
            self.history = [record] + self.history
        }
    }

    func clearConsole() {
        lastOutput = "（已清空）"
    }
}
