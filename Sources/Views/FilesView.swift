import SwiftUI

struct FilesView: View {
    @EnvironmentObject var app: AppState
    @State private var refresh = 0
    @State private var newName = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("我的 Python 文件")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button {
                    let _ = app.listFiles()
                    refresh += 1
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                }
                Button {
                    newSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }
            }
            .padding(14)

            List {
                Section {
                    ForEach(app.listFiles(), id: \.self) { url in
                        row(for: url)
                    }
                    .onDelete { indexSet in
                        let files = app.listFiles()
                        for i in indexSet {
                            guard i < files.count else { continue }
                            app.deleteFile(files[i])
                        }
                        refresh += 1
                    }
                } header: {
                    Text("Documents（沙盒）").font(.caption).foregroundStyle(.secondary)
                } footer: {
                    Text("点按打开到编辑器；左滑删除；支持 .py .txt .md .json")
                        .font(.caption2)
                }
            }
            .listStyle(.insetGrouped)
        }
        .sheet(isPresented: $newSheet) {
            NewFileSheet { name in
                if app.newFile(named: name) { refresh += 1 }
            }
        }
        .id(refresh)
    }

    @State private var newSheet = false

    private func row(for url: URL) -> some View {
        HStack {
            Image(systemName: "chevron.left.forwardslash.square")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.subheadline.weight(.medium))
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize
                if let size {
                    Text("\(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { app.loadFile(url) }
    }
}

struct NewFileSheet: View {
    @State private var name = "new_script.py"
    @Environment(\.dismiss) private var dismiss
    let onCreate: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("文件名（.py）", text: $name)
                    .font(.system(.body, design: .monospaced))
            }
            .navigationTitle("新建文件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        var n = name.trimmingCharacters(in: .whitespaces)
                        if n.isEmpty { n = "new_script.py" }
                        if !n.hasSuffix(".py") && !n.hasSuffix(".txt") && !n.hasSuffix(".md") && !n.hasSuffix(".json") {
                            n += ".py"
                        }
                        onCreate(n)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
