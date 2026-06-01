import SwiftUI
import SwiftData

struct IOSTaskDetailView: View {
    @Bindable var task: TaskItem

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var hasDueDate: Bool
    @State private var showingDeleteAlert = false

    init(task: TaskItem) {
        self.task = task
        _hasDueDate = State(initialValue: task.dueDate != nil)
    }

    var body: some View {
        Form {
            Section("任务内容") {
                TextField("任务标题", text: $task.title)

                TextField("备注，可选", text: $task.notes, axis: .vertical)
                    .lineLimit(3...8)
            }

            Section("分类") {
                Picker("所属象限", selection: $task.quadrantRaw) {
                    ForEach(Quadrant.allCases) { q in
                        Label(q.title, systemImage: q.iconName)
                            .tag(q.rawValue)
                    }
                }
            }

            Section("截止日期与提醒") {
                Toggle("设置截止日期", isOn: $hasDueDate.animation())

                if hasDueDate {
                    DatePicker(
                        "截止时间",
                        selection: Binding(
                            get: {
                                task.dueDate ?? Date().addingTimeInterval(3600)
                            },
                            set: {
                                task.dueDate = $0
                                persist()
                            }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    Toggle("到时提醒", isOn: $task.notificationEnabled)
                }
            }

            Section("状态") {
                Toggle("已完成", isOn: $task.isCompleted)
            }

            Section("信息") {
                LabeledContent(
                    "创建时间",
                    value: task.createdAt.formatted(date: .abbreviated, time: .shortened)
                )

                LabeledContent(
                    "更新时间",
                    value: task.updatedAt.formatted(date: .abbreviated, time: .shortened)
                )
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("删除任务", systemImage: "trash")
                }
            }
        }
        .navigationTitle("任务详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") {
                    persist()
                    dismiss()
                }
            }
        }
        .alert("删除任务？", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteTask()
            }
        } message: {
            Text("删除后无法恢复。")
        }
        .onChange(of: hasDueDate) { _, newValue in
            if newValue {
                task.dueDate = task.dueDate ?? Date().addingTimeInterval(3600)
            } else {
                task.dueDate = nil
                task.notificationEnabled = false
            }
            persist()
        }
        .onChange(of: task.title) { _, _ in persist() }
        .onChange(of: task.notes) { _, _ in persist() }
        .onChange(of: task.quadrantRaw) { _, _ in persist() }
        .onChange(of: task.notificationEnabled) { _, _ in persist() }
        .onChange(of: task.isCompleted) { _, _ in persist() }
        .onDisappear {
            persist()
        }
    }

    private func persist() {
        task.updatedAt = Date()
        TaskViewModel(modelContext: modelContext).update(task)
    }

    private func deleteTask() {
        TaskViewModel(modelContext: modelContext).delete(task)
        dismiss()
    }
}
