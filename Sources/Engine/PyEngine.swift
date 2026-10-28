import Foundation

/// Python 执行引擎
/// v0.1：若 bundle 内携带 python 可执行文件（Resources/python）则用 Process 执行用户代码；
/// v0.2+ 将替换为内嵌 CPython（libpython 静态链接，进程内执行 + jedi 补全）。
final class PyEngine {
    static let shared = PyEngine()

    struct RunResult {
        let output: String
        let success: Bool
        let durationMs: Int
    }

    /// bundle 内的 python 可执行文件是否存在（v0.1 未携带 → false）
    func isEngineReady() -> Bool {
        pythonURL() != nil
    }

    private func pythonURL() -> URL? {
        Bundle.main.url(forResource: "python", withExtension: nil)
    }

    func run(code: String, completion: @escaping (RunResult) -> Void) {
        let start = Date()
        let py = pythonURL()
        if py == nil {
            // v0.1 未携带引擎 → 友好占位（v0.2 嵌入 CPython 后此分支消失，改进程内执行）
            let msg = "〔PocketPy〕Python 引擎尚未随包携带（v0.2 将嵌入 CPython 3.13，进程内真跑代码）。\n当前可正常使用：编辑器 / 文件管理 / 运行历史 / 设置。\n\n代码预览：\n\(String(code.prefix(400)))"
            DispatchQueue.main.async {
                completion(RunResult(output: msg, success: false,
                                      durationMs: Int(Date().timeIntervalSince(start) * 1000)))
            }
            return
        }
        // 注意：iOS 没有 Foundation.Process（macOS 专属），不允许从 App 起外部进程。
        // v0.2 起引擎切换为内嵌 CPython（libpython 静态链接 + Py_Initialize，进程内执行）。
        // 该分支为前向兼容桩：若 bundle 内出现 python 可执行文件也走内嵌引擎。
        let note = "〔PocketPy〕检测到 bundle 内 python 可执行文件，但 iOS 不允许从 App 派生外部进程（App Store 3.2.2 + 平台限制）。\nv0.2 将以内嵌 CPython 方式在进程内执行你的代码。\n\n代码预览：\n\(String(code.prefix(400)))"
        DispatchQueue.main.async {
            completion(RunResult(output: note, success: false,
                                  durationMs: Int(Date().timeIntervalSince(start) * 1000)))
        }
    }

}
