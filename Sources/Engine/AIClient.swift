import Foundation

/// AI 配置（OpenAI 兼容接口：Kimi / 百炼 / OpenAI / OpenRouter / 自建 vLLM）
struct AIConfig: Codable, Equatable {
    var baseUrl: String
    var model: String
    var apiKey: String
    var maxTokens: Int

    static let empty = AIConfig(baseUrl: "", model: "", apiKey: "", maxTokens: 2048)
    static func preset(_ name: String) -> AIConfig {
        switch name {
        case "Kimi": return .init(baseUrl: "https://api.moonshot.cn/v1", model: "moonshot-v1-8k", apiKey: "", maxTokens: 2048)
        case "百炼": return .init(baseUrl: "https://dashscope.aliyuncs.com/compatible-mode/v1", model: "qwen-plus", apiKey: "", maxTokens: 2048)
        case "OpenAI": return .init(baseUrl: "https://api.openai.com/v1", model: "gpt-4o-mini", apiKey: "", maxTokens: 2048)
        case "OpenRouter": return .init(baseUrl: "https://openrouter.ai/api/v1", model: "meta-llama/llama-3.1-8b-instruct:free", apiKey: "", maxTokens: 2048)
        default: return .empty
        }
    }
}

final class AIClient {
    struct Msg { let role: String; let content: String }

    /// 一次 chat completion（OpenAI 兼容 /chat/completions）
    func chat(_ config: AIConfig, messages: [Msg], completion: @escaping (Result<String, Error>) -> Void) {
        let base = config.baseUrl.hasSuffix("/") ? config.baseUrl : config.baseUrl + "/"
        guard let baseURL = URL(string: base) else {
            completion(.failure(AIError.badURL)); return
        }
        let url = baseURL.appendingPathComponent("chat/completions")
        post(url: url, config: config, messages: messages, completion: completion)
    }

    private enum AIError: Error { case badURL, badResponse, http(Int) }

    private func post(url: URL, config: AIConfig, messages: [Msg], completion: @escaping (Result<String, Error>) -> Void) {
        struct ReqBody: Encodable { let model: String; let messages: [ReqMsg]; let max_tokens: Int }
        struct ReqMsg: Encodable { let role: String; let content: String }
        let body = ReqBody(model: config.model,
                           messages: messages.map { ReqMsg(role: $0.role, content: $0.content) },
                           max_tokens: config.maxTokens)
        var req = URLRequest(url: url, timeoutInterval: 60)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !config.apiKey.isEmpty { req.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization") }
        req.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(with: req) { data, resp, err in
            if let err { completion(.failure(err)); return }
            guard let http = resp as? HTTPURLResponse else { completion(.failure(AIError.badResponse)); return }
            guard http.statusCode == 200 else {
                let detail = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                completion(.failure(AIError.http(http.statusCode)))
                _ = detail
                return
            }
            guard let data,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = obj["choices"] as? [[String: Any]],
                  let msg = choices.first?["message"] as? [String: Any],
                  let content = msg["content"] as? String else {
                completion(.failure(AIError.badResponse)); return
            }
            completion(.success(content))
        }.resume()
    }
}
