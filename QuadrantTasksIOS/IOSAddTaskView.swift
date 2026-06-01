import SwiftUI
import SwiftData

struct IOSAddTaskView: View {
    let defaultQuadrant: Quadrant

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var quadrant: Quadrant
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(60 * 60)
    @State private var notificationEnabled = false

    init(defaultQuadrant: Quadrant) {
        self.defaultQuadrant = defaultQuadrant
        _quadrant = State(initialValue: defaultQuadrant)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("任务内容") {
                    TextField("任务标题", text: $title)

                    TextField("备注，可选", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("分类") {
                    Picker("所属象限", selection: $quadrant) {
                        ForEach(Quadrant.allCases) { q in
                            Label(q.title, systemImage: q.iconName)
                                .tag(q)
                        }
                    }
                }

                Section("截止日期") {
                    Toggle("设置截止日期", isOn: $hasDueDate.animation())

                    if hasDueDate {
                        DatePicker(
                            "截止时间",
                            selection: $dueDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )

                        Toggle("到时提醒", isOn: $notificationEnabled)
                    }
                }
            }
            .navigationTitle("新建任务")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTask()
                    }
                    .disabled(trimmedTitle.isEmpty)
                }
            }
        }
    }

    private func saveTask() {
        TaskViewModel(modelContext: modelContext).addTask(
            title: trimmedTitle,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            quadrant: quadrant,
            dueDate: hasDueDate ? dueDate : nil,
            notificationEnabled: hasDueDate && notificationEnabled
        )

        dismiss()
    }
}
