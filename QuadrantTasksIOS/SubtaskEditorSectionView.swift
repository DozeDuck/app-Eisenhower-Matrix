//
//  SubtaskEditorSectionView.swift
//  QuadrantTasksIOS
//
//  任务详情页中的子任务编辑区域。
//  所有写操作都通过 TaskViewModel，保证 SwiftData 保存与 Widget 刷新。
//

import SwiftUI
import SwiftData

struct SubtaskEditorSectionView: View {
    @Bindable var task: TaskItem

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorVisionMode) private var colorVisionMode

    @State private var newSubtaskTitle = ""
    @State private var showingDeleteAllAlert = false

    private var tintColor: Color {
        task.quadrant.color(for: colorVisionMode)
    }

    private var trimmedNewTitle: String {
        newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                progressSummary

                if task.sortedSubtasks.isEmpty {
                    emptyState
                } else {
                    subtaskList
                }

                addSubtaskRow

                if !task.sortedSubtasks.isEmpty {
                    deleteAllButton
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("子任务")
        } footer: {
            Text("有子任务时，主任务进度会根据所有子任务的平均进度自动计算。")
        }
        .alert("删除全部子任务？", isPresented: $showingDeleteAllAlert) {
            Button("删除", role: .destructive) {
                TaskViewModel(modelContext: modelContext)
                    .deleteAllSubtasks(from: task)
            }

            Button("取消", role: .cancel) { }
        } message: {
            Text("删除后无法恢复。主任务将重新使用手动进度条。")
        }
    }

    private var progressSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("子任务进度", systemImage: "checklist")
                    .font(.subheadline.weight(.medium))

                Spacer()

                Text("\(task.progressPercent)%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(tintColor)
            }

            ProgressView(value: task.progressFraction)
                .tint(tintColor)

            if !task.sortedSubtasks.isEmpty {
                Text("\(completedSubtaskCount) / \(task.sortedSubtasks.count) 个子任务已完成")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var completedSubtaskCount: Int {
        task.sortedSubtasks.filter(\.isCompleted).count
    }

    private var emptyState: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "list.bullet.indent")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("还没有子任务")
                    .font(.subheadline.weight(.medium))

                Text("如果一个任务包含多个步骤，可以在这里拆分为子任务。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var subtaskList: some View {
        VStack(spacing: 10) {
            ForEach(task.sortedSubtasks) { subtask in
                SubtaskEditableRow(
                    subtask: subtask,
                    tintColor: tintColor,
                    onDelete: {
                        TaskViewModel(modelContext: modelContext)
                            .deleteSubtask(subtask, from: task)
                    }
                )
            }
        }
    }

    private var addSubtaskRow: some View {
        HStack(spacing: 8) {
            TextField("添加子任务", text: $newSubtaskTitle)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .onSubmit {
                    addSubtask()
                }

            Button {
                addSubtask()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .disabled(trimmedNewTitle.isEmpty)
            .foregroundStyle(trimmedNewTitle.isEmpty ? .secondary : tintColor)
            .accessibilityLabel("添加子任务")
        }
    }

    private var deleteAllButton: some View {
        Button(role: .destructive) {
            showingDeleteAllAlert = true
        } label: {
            Label("删除全部子任务", systemImage: "trash")
                .font(.caption)
        }
        .buttonStyle(.plain)
    }

    private func addSubtask() {
        guard !trimmedNewTitle.isEmpty else {
            return
        }

        TaskViewModel(modelContext: modelContext)
            .addSubtask(to: task, title: trimmedNewTitle)

        newSubtaskTitle = ""
    }
}

// MARK: - 子任务单行编辑

private struct SubtaskEditableRow: View {
    @Bindable var subtask: SubTask

    let tintColor: Color
    let onDelete: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var draftProgress: Double = 0.0
    @State private var isEditingProgress = false

    private var titleBinding: Binding<String> {
        Binding(
            get: {
                subtask.title
            },
            set: { newValue in
                TaskViewModel(modelContext: modelContext)
                    .updateSubtaskTitle(subtask, title: newValue)
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            topRow

            HStack(spacing: 10) {
                Slider(
                    value: Binding(
                        get: { draftProgress },
                        set: { draftProgress = min(max($0, 0.0), 1.0) }
                    ),
                    in: 0...1,
                    step: 0.01,
                    onEditingChanged: { editing in
                        isEditingProgress = editing

                        if !editing {
                            commitProgress()
                        }
                    }
                )
                .tint(tintColor)

                Text("\(Int((draftProgress * 100).rounded()))%")
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(tintColor)
                    .frame(width: 42, alignment: .trailing)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(subtask.isCompleted ? tintColor.opacity(0.35) : Color.clear, lineWidth: 1)
        )
        .onAppear {
            draftProgress = subtask.normalizedProgress
        }
        .onChange(of: subtask.progress) { _, newValue in
            guard !isEditingProgress else { return }
            draftProgress = min(max(newValue, 0.0), 1.0)
        }
    }

    private var topRow: some View {
        HStack(spacing: 8) {
            Button {
                TaskViewModel(modelContext: modelContext)
                    .toggleSubtaskComplete(subtask)

                draftProgress = subtask.isCompleted ? 0.0 : 1.0
            } label: {
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(subtask.isCompleted ? tintColor : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(subtask.isCompleted ? "标记子任务为未完成" : "标记子任务为完成")

            TextField("子任务标题", text: titleBinding)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .strikethrough(subtask.isCompleted)
                .foregroundStyle(subtask.isCompleted ? .secondary : .primary)

            Spacer()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("删除子任务")
        }
    }

    private func commitProgress() {
        TaskViewModel(modelContext: modelContext)
            .updateSubtaskProgress(subtask, progress: draftProgress)
    }
}
