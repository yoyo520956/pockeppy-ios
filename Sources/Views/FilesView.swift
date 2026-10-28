import SwiftUI

struct FilesView: View {
    @EnvironmentObject var app: AppState
    @State private var refresh = 0
    @State private var showNew = false
    @State private var newName = "untitled.py"

    private func pyFiles() -> [URL] {
        _ = refresh
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: app.documentsDir, includingPropertiesForKeys: nil) else { return [] }
        return items
            .filter { $0.pathExtension == "py" || $0.pathExtension == "txt" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    var body: some View {
        NavigationStack {
            List {
                let files = pyFiles()
                if files.isEmpty {
                    Text("还没有脚本文件\n点右上角 + 新建一个 .py")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                ForEach(files, id: \.self) { url in
                    Button {
                        let content = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
                        app.openFile = FileItem(name: url.lastPathComponent, url: url)
                        app.externalSet(content, fileName: url.lastPathComponent)
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left.forwardslash.chevron.right")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(url.lastPathComponent)
                                if let size = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int {
                                    Text("\(size) B · UTF-8")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            if let f = files.first(where: { $0 == url }) { app.deleteFile(f) }
                            refresh += 1
                        } label: { Label("删除", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle("脚本文件")
            .toolbar {
                Button { showNew = true } label: { Image(systemName: "plus") }
            }
            .sheet(isPresented: $showNew) {
                NavigationStack {
                    Form {
                        TextField("文件名（含 .py）", text: $newName)
                    }
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("创建") {
                                let clean = newName.hasSuffix(".py") ? newName : newName + ".py"
                                let url = app.documentsDir.appendingPathComponent(clean)
                                if !FileManager.default.fileExists(atPath: url.path) {
                                    try? "# 新建脚本\nprint('hi')\n".write(to: url, atomically: true, encoding: .utf8)
                                }
                                app.openFile = FileItem(name: clean, url: url)
                                app.externalSet("# \(clean)\n\ndef main():\n    print('Hello from PocketPy')\n\nif __name__ == '__main__':\n    main()\n", fileName: clean)
                                showNew = false
                                refresh += 1
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("取消") { showNew = false }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
}
