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
        guard let python = py else {
            let msg = "〔PocketPy〕Python 引擎尚未随包携带（v0.2 将嵌入 CPython 3.13）。\n当前可正常使用：编辑器 / 文件管理 / 运行历史 / 设置。\n代码预览：\n\n\(code.prefix(400))"
            DispatchQueue.main.async {
                completion(RunResult(output: msg, success: false,
                                      durationMs: Int(Date().timeIntervalSince(start) * 1000)))
            }
            return
        }
        // 把用户代码写入临时文件，交给 python 解释器执行
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("pockeppy_run\(UUID().uuidString).py")
        do {
            try code.write(to: tmp, atomically: true, encoding: .utf8)
        } catch {
            DispatchQueue.main.async {
                completion(RunResult(output: "无法写入临时文件：\(error)", success: false,
                                      durationMs: Int(Date().timeIntervalSince(start) * 1000)))
            }
            return
        }
        let proc = Process()
        proc.executableURL = python
        proc.arguments = ["-u", tmp.path]
        let outPipe = Pipe(); let errPipe = Pipe()
        proc.standardOutput = outPipe; proc.standardError = errPipe
        var env = ProcessInfo.processInfo.environment
        env["PYTHONUNBUFFERED"] = "1"
        proc.environment = env
        do {
            try proc.run()
        } catch {
            DispatchQueue.main.async {
                completion(RunResult(output: "引擎启动失败：\(error)", success: false,
                                      durationMs: Int(Date().timeIntervalSince(start) * 1000)))
            }
            return
        }
        // 注意：Process 回调内不能同步 wait，这里用读至 EOF 的简单方式
        DispatchQueue.global(qos: .userInitiated).async {
            let stdoutData = outPipe.fileHandleForReading.readDataToEndOfFile()
            proc.waitUntilExit()
            let stderrData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let so = String(data: stdoutData, encoding: .utf8) ?? ""
            let se = String(data: stderrData, encoding: .utf8) ?? ""
            try? FileManager.default.removeItem(at: tmp)
            var combined = so
            if !se.isEmpty { combined += (combined.isEmpty ? "" : "\n") + se }
            if combined.isEmpty { combined = "（无输出）" }
            let success = proc.terminationStatus == 0
            let dur = Int(Date().timeIntervalSince(start) * 1000)
            DispatchQueue.main.async {
                completion(RunResult(output: combined, success: success, durationMs: dur))
            }
        }
    }

}
