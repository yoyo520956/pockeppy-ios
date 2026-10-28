import Foundation

/// 运行历史记录（持久化为 Codable JSON）
struct RunRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var fileName: String
    var codePreview: String
    var output: String
    var date: Date = Date()
    var success: Bool
    var durationMs: Int
}
