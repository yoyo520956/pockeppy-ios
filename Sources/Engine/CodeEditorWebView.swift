import UIKit
import WebKit

/// WebKit 代码编辑器：语法高亮 + 行号 + 与 SwiftUI 状态双向同步
final class CodeEditorWebView: UIView, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {
    private let web: WKWebView
    private let contentCtrl = WKContentController()
    var onContentChange: ((String) -> Void)?
    var onReady: (() -> Void)?
    private var pendingText: String = ""

    override init(frame: CGRect) {
        let cfg = WKWebViewConfiguration()
        cfg.contentController = contentCtrl
        super.init(frame: frame)
        contentCtrl.add(self, name: "code")
        web = WKWebView(frame: .zero, configuration: cfg)
        web.navigationDelegate = self
        web.uiDelegate = self
        web.isOpaque = false
        web.backgroundColor = UIColor(red: 0.05, green: 0.07, blue: 0.11, alpha: 1.0)
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.scrollView.backgroundColor = .clear
        web.translatesAutoresizingMaskIntoConstraints = false
        addSubview(web)
        NSLayoutConstraint.activate([
            web.leadingAnchor.constraint(equalTo: leadingAnchor),
            web.trailingAnchor.constraint(equalTo: trailingAnchor),
            web.topAnchor.constraint(equalTo: topAnchor),
            web.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        loadEditor()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    private func loadEditor() {
        if let url = Bundle.main.url(forResource: "editor", withExtension: "html", subdirectory: "web"),
           let html = try? String(contentsOf: url, encoding: .utf8) {
            web.loadHTMLString(html, baseURL: URL(string: "ppy://local/"))
        } else {
            web.loadHTMLString("<html><body style='background:#0d1117;color:#e6edf3;font-family:monospace'><pre>编辑器资源缺失（web/editor.html）</pre></body></html>", baseURL: nil)
        }
    }

    // MARK: - JS → Swift
    func userContentController(_ ucc: WKUserContentController, didReceive message: WKUserContentMessage) {
        guard let body = message.body as? String,
              let data = body.data(using: .utf8),
              let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return }
        switch dict["type"] as? String {
        case "ready":
            if !pendingText.isEmpty {
                setAll(pendingText, fileName: lastFileName)
                pendingText = ""
            }
            onReady?()
        case "change":
            if let t = dict["text"] as? String { onContentChange?(t) }
        default: break
        }
    }

    // MARK: - Swift → JS
    private var lastFileName = "untitled.py"
    private var ready = false
    func setAll(_ text: String, fileName: String? = nil) {
        pendingText = text
        if let name = fileName { lastFileName = name }
        guard ready else { return }
        web.evaluateJavaScript("setAll(\(Self.jsLit(text)))")
        if let name = fileName { web.evaluateJavaScript("setFileName(\(Self.jsLit(name)))") }
    }
    func setFileName(_ name: String) {
        lastFileName = name
        web.evaluateJavaScript("setFileName(\(Self.jsLit(name)))")
    }

    /// 把 Swift String 编码成 JS 字符串字面量（JSON 转义）
    static func jsLit(_ s: String) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: [s]),
              let json = String(data: data, encoding: .utf8) else { return "\"\"" }
        // JSONSerialization 输出数组形式: ["..."] → 取第一个元素
        var t = json
        if t.hasPrefix("[") && t.hasSuffix("]") { t.removeFirst(); t.removeLast() }
        return t
    }

    // MARK: - WKNavigationDelegate
    func webViewDidFinishLoading(_ webView: WKWebView) {
        ready = true
    }

    // MARK: - WKUIDelegate（新标签/弹窗降级）
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? { nil }
}
