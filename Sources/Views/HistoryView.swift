import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var app: AppState

    var body: some View {
        NavigationStack {
            Group {
                if app.history.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("暂无运行记录")
                            .font(.headline)
                        Text("在编辑器里点「运行」后，这里会记录每次结果（最多 200 条）")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(app.history) { record in
                            Row(record: record)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("运行历史")
            .toolbar {
                if !app.history.isEmpty {
                    Button("清空") {
                        app.history = []
                        HistoryStore.shared.clear()
                        app.toast("历史已清空")
                    }
                }
            }
        }
    }

    private struct Row: View {
        let record: RunRecord
        @EnvironmentObject var app: AppState
        @State private var expanded = false

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(record.success ? .green : .red)
                    Text(record.fileName)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text(record.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(record.durationMs)ms")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                if expanded {
                    Text(record.output)
                        .font(.caption.monospaced())
                        .lineLimit(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { expanded.toggle() }
        }
    }
}
