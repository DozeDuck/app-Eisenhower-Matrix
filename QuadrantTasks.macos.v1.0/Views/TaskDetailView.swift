//
//  TaskDetailView.swift
//  QuadrantTasks (macOS)
//
//  以右侧 Inspector 形式展示。和 iOS 版的差异:
//   - 不再有导航栏标题与删除底部按钮区,改用紧凑 Form
//   - 删除按钮置于顶部,符合 Mac 的"主操作显眼"习惯
//   - 字段变更通过 onChange 即时持久化,无需保存按钮
//

import SwiftUI
import SwiftData

struct TaskDetailView: View {
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
        VStack(spacing: 0) {
            header

            Form {
                Section("标题") {
                    TextField("任务标题", text: $task.title)
                        .textFieldStyle(.roundedBorder)
                }

                Section("备注") {
                    TextField("添加备注", text: $task.notes, axis: .vertical)
                        .lineLimit(3...8)
                        .textFieldStyle(.roundedBorder)
                }

                Section("分类") {
                    Picker("所属象限", selection: $task.quadrant) {
                        ForEach(Quadrant.allCases) { q in
                            Label(q.title, systemImage: q.iconName).tag(q)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("截止日期") {
                    Toggle("设置截止日期", isOn: $hasDueDate.animation())
                        .onChange(of: hasDueDate) { _, newValue in
                            if newValue {
                                task.dueDate = task.dueDate ?? Date().addingTimeInterval(3600)
                            } else {
                                task.dueDate = nil
                                task.notificationEnabled = false
                            }
                        }
                    if hasDueDate {
                        DatePicker(
                            "截止时间",
                            selection: Binding(
                                get: { task.dueDate ?? Date() },
                                set: { task.dueDate = $0 }
                            )
                        )
                        .datePickerStyle(.compact)
                        Toggle("到时提醒", isOn: $task.notificationEnabled)
                    }
                }

                Section("状态") {
                    Toggle("已完成", isOn: $task.isCompleted)
                }

                Section("信息") {
                    LabeledContent("创建时间",
                        value: task.createdAt.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("更新时间",
                        value: task.updatedAt.formatted(date: .abbreviated, time: .shortened))
                }
                .font(.callout)
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
        // 字段变化即时持久化(含通知重排)
        .onChange(of: task.title)               { _, _ in persist() }
        .onChange(of: task.notes)               { _, _ in persist() }
        .onChange(of: task.quadrantRaw)         { _, _ in persist() }
        .onChange(of: task.dueDate)             { _, _ in persist() }
        .onChange(of: task.isCompleted)         { _, _ in persist() }
        .onChange(of: task.notificationEnabled) { _, _ in persist() }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("删除", role: .destructive) {
                TaskViewModel(modelContext: modelContext).delete(task)
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("删除后无法恢复。")
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: task.quadrant.iconName)
                .foregroundStyle(task.quadrant.color)
            Text("任务详情")
                .font(.headline)
            Spacer()
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("删除任务")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(task.quadrant.color.opacity(0.08))
    }

    private func persist() {
        TaskViewModel(modelContext: modelContext).update(task)
    }
}
