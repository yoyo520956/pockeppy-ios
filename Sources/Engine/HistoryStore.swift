import Foundation

/// 运行历史持久化：Documents/run_history.json（上限 200 条）
final class HistoryStore {
    static let shared = HistoryStore()

    private var url: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("pockeppy_history.json")
    }

    private let queue = DispatchQueue(label: "pockeppy.history", qos: .utility)

    func load() -> [RunRecord] {
        queue.sync {
            guard let data = try? Data(contentsOf: url) else { return [] }
            return (try? JSONDecoder().decode([RunRecord].self, from: data)) ?? []
        }
    }

    func add(_ record: RunRecord) {
        queue.async {
            var all = (try? JSONDecoder().decode([RunRecord].self, from: (try? Data(contentsOf: self.url)) ?? Data())) ?? []
            all.insert(record, at: 0)
            if all.count > 200 { all = Array(all.prefix(200)) }
            let data = (try? JSONEncoder().encode(all)) ?? Data()
            try? data.write(to: self.url, options: .atomic)
        }
    }

    func clear() {
        queue.async { try? FileManager.default.removeItem(at: self.url) }
    }
}
