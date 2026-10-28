import SwiftUI

struct AIChatMsg: Identifiable {
    let id = UUID()
    let role: String   // "user" | "assistant"
    let text: String
}

struct AIAssistantView: View {
    @EnvironmentObject var app: AppState
    @State private var messages: [AIChatMsg] = []
    @State private var draft = ""
    @State private var busy = false
    @State private var lastError = ""

    private let client = AIClient()

    var body: some View {
        NavigationStack {
            content
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            banner
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { m in
                            bubble(m).id(m.id)
                        }
                        if busy {
                            HStack { ProgressView(); Text("AI 思考中…").font(.caption).foregroundStyle(.secondary) }
                                .id("loading")
                        }
                    }
                    .padding(12)
                }
                .onChange(of: messages.count) { _ in
                    proxy.scrollTo(messages.last?.id ?? UUID(), anchor: .bottom)
                }
            }
            HStack(spacing: 8) {
                TextField("问 AI 写代码 / 解释 / 修 bug…", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.roundedBorder)
                Button { send() } label: {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(draft.isEmpty || busy)
            }
            .padding(8)
            Divider()
            HStack(spacing: 12) {
                Button("修这段代码", systemImage: "wrench.and.screwdriver") { fixCurrentCode() }
                Menu {
                    ForEach(["Kimi", "百炼", "OpenAI", "OpenRouter", "自定义"], id: \.self) { p in
                        Button(p) { app.applyAIPreset(p) }
                    }
                } label: { Label("接口", systemImage: "gear") }
                Spacer()
                if !app.aiConfig.baseUrl.isEmpty {
                    Text(app.aiConfig.model).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            .controlSize(.small)
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
        }
        .navigationTitle("AI 助手")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: String.self) { _ in EmptyView() }
    }

    @ViewBuilder
    private var banner: some View {
        if app.aiConfig.apiKey.isEmpty || app.aiConfig.baseUrl.isEmpty {
            HStack {
                Image(systemName: "key.horizontal")
                Text("在「设置 → AI 接口」填 endpoint / 模型 / Key（支持任意 OpenAI 兼容 API）")
                    .font(.caption)
                Spacer()
            }
            .padding(8)
            .background(Color.orange.opacity(0.12))
        }
    }

    private func bubble(_ m: AIChatMsg) -> some View {
        HStack {
            if m.role == "user" { Spacer(minLength: 40) }
            Text(m.text)
                .textSelection(.enabled)
                .font(m.role == "assistant" && m.text.hasPrefix("```") ? .system(.footnote, design: .monospaced) : .body)
                .padding(10)
                .background(m.role == "user" ? Color.orange.opacity(0.9) : Color.gray.opacity(0.18))
                .foregroundStyle(m.role == "user" ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            if m.role == "assistant" { Spacer(minLength: 40) }
        }
    }

    private func send() {
        guard !draft.isEmpty else { return }
        let userText = draft
        draft = ""
        messages.append(AIChatMsg(role: "user", text: userText))
        lastError = ""
        busy = true
        var ctx: [AIClient.Msg] = [
            AIClient.Msg(role: "system", content: "你是 PocketPy 的 Python 编程助手。回答用简体中文，代码给完整可运行示例，优先标准库。"),
        ]
        ctx.append(contentsOf: messages.suffix(8).compactMap { m in
            m.role == "user" ? AIClient.Msg(role: "user", content: m.text) : AIClient.Msg(role: "assistant", content: m.text)
        })
        client.chat(app.aiConfig, messages: ctx) { result in
            DispatchQueue.main.async {
                busy = false
                switch result {
                case .success(let text):
                    messages.append(AIChatMsg(role: "assistant", text: text))
                case .failure(let err):
                    lastError = "调用失败：\(err.localizedDescription)"
                    messages.append(AIChatMsg(role: "assistant", text: lastError))
                }
            }
        }
    }

    private func fixCurrentCode() {
        lastError = ""
        busy = true
        let prompt = """
        请修复并说明下面这段 Python 代码的问题（语法/逻辑/性能），先给修复后的完整代码，再逐条说明改动原因：

        ```python
        \(app.code)
        ```
        """
        messages.append(AIChatMsg(role: "user", text: prompt))
        var ctx: [AIClient.Msg] = [
            AIClient.Msg(role: "system", content: "你是 PocketPy 的 Python 编程助手，擅长定位与修复代码缺陷。"),
            AIClient.Msg(role: "user", content: prompt),
        ]
        client.chat(app.aiConfig, messages: ctx) { result in
            DispatchQueue.main.async {
                busy = false
                switch result {
                case .success(let text):
                    messages.append(AIChatMsg(role: "assistant", text: text))
                case .failure(let err):
                    lastError = "调用失败：\(err.localizedDescription)"
                    messages.append(AIChatMsg(role: "assistant", text: lastError))
                }
            }
        }
    }
}
