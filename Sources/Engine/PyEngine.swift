import Foundation

/// Python 引擎：内嵌 CPython 3.14（libpython 静态链接 + pyhome stdlib）
/// 启动即 bootstrap；执行走串行队列（CPython 非线程安全调用）
final class PyEngine {
    static let shared = PyEngine()

    private(set) var ready = false
    private(set) var versionText = ""
    private var booted = false
    private let runQueue = DispatchQueue(label: "pockeppy.run", qos: .userInitiated)

    struct RunResult {
        let output: String
        let success: Bool
        let durationMs: Int
    }

    var isEngineReady: Bool { ready }
    var engineStatusText: String {
        ready ? "CPython \(versionText) · 已就绪" : "未嵌入（等待 v0.2 CI 交叉编译 CPython）"
    }

    /// App 启动时调用（幂等）
    func bootstrap() {
        guard !booted else { return }
        booted = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            // CPython iOS framework 模式：Python.framework 随 bundle 携带，
            // 解释器自动在 main bundle 里定位 stdlib；home 传 nil 不干预。
            let ok = ppy_init(nil)
            if ok {
                self.versionText = String(cString: ppy_version())
                DispatchQueue.main.async {
                    self.ready = true
                }
            }
        }
    }

    func run(code: String, completion: @escaping (RunResult) -> Void) {
        let start = Date()
        guard ready else {
            let msg = "[PocketPy] Python 引擎未就绪（当前构建未携带 pyhome；v0.2 经 CI 交叉编译 CPython 3.14 后此处真跑代码）。\n\n代码预览：\n\(String(code.prefix(400)))"
            DispatchQueue.main.async {
                completion(RunResult(output: msg, success: false, durationMs: 0))
            }
            return
        }
        runQueue.async { [weak self] in
            guard let self else { return }
            guard let cbuf = ppy_run(code) else {
                DispatchQueue.main.async {
                    completion(self.fallbackResult(msg: "引擎返回空", start: start))
                }
                return
            }
            var out = ""
            var ok = false
            if let data = cbuf.data(using: .utf8),
               let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
                var acc = obj["stdout"] as? String ?? ""
                if let e = obj["stderr"] as? String, !e.isEmpty {
                    acc += (acc.isEmpty ? "" : "\n") + e
                }
                if let tb = obj["tb"] as? String, !tb.isEmpty {
                    acc += (acc.isEmpty ? "" : "\n") + tb
                }
                out = acc
                ok = obj["ok"] as? Bool ?? false
            }
            ppy_free(cbuf)
            let dur = Int(Date().timeIntervalSince(start) * 1000)
            DispatchQueue.main.async {
                completion(RunResult(output: out.isEmpty ? "（无输出）" : out, success: ok, durationMs: dur))
            }
        }
    }

    private func fallbackResult(msg: String, start: Date) -> RunResult {
        RunResult(output: msg, success: false, durationMs: Int(Date().timeIntervalSince(start) * 1000))
    }
}
