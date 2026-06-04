//
//  IOSTaskDetailView.swift
//  QuadrantTasksIOS
//
//  任务详情 / 编辑页。
//  接入：时间状态、进度条、子任务编辑、逾期标识。
//

import SwiftUI
import SwiftData

struct IOSTaskDetailView: View {
    @Bindable var task: TaskItem

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorVisionMode) private var colorVisionMode

    @State private var hasDueDate: Bool
    @State private var showingDeleteAlert = false

    init(task: TaskItem) {
        self.task = task
        _hasDueDate = State(initialValue: task.dueDate != nil)
    }

    private var quadrantColor: Color {
        task.quadrant.color(for: colorVisionMode)
    }

    var body: some View {
        Form {
            headerSection

            Section("基本信息") {
                TextField("任务标题", text: $task.title)

                TextField("备注", text: $task.notes, axis: .vertical)
                    .lineLimit(3...8)
            }

            Section("分类") {
                Picker("所属象限", selection: $task.quadrant) {
                    ForEach(Quadrant.allCases) { quadrant in
                        Label(quadrant.title, systemImage: quadrant.iconName)
                            .tag(quadrant)
                    }
                }
            }

            Section("截止日期") {
                Toggle("设置截止日期", isOn: $hasDueDate.animation())
                    .onChange(of: hasDueDate) { _, newValue in
                        if newValue {
                            task.dueDate = task.dueDate ?? Date().addingTimeInterval(60 * 60)
                        } else {
                            task.dueDate = nil
                            task.notificationEnabled = false
                        }

                        persist()
                    }

                if hasDueDate {
                    DatePicker(
                        "截止时间",
                        selection: Binding(
                            get: {
                                task.dueDate ?? Date().addingTimeInterval(60 * 60)
                            },
                            set: {
                                task.dueDate = $0
                                persist()
                            }
                        )
                    )

                    Toggle("到时提醒", isOn: $task.notificationEnabled)
                }
            }

            TaskProgressBarSectionView(task: task)

            SubtaskEditorSectionView(task: task)

            Section("状态") {
                Toggle("已完成", isOn: $task.isCompleted)

                LabeledContent("时间状态") {
                    Text(task.timeStatusText)
                        .foregroundStyle(task.isOverdue ? AppColorPalette.overdueColor(for: colorVisionMode) : .secondary)
                }

                if task.isOverdue {
                    OverdueBadgeView(task: task)
                }
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

                if let completedAt = task.completedAt {
                    LabeledContent(
                        "完成时间",
                        value: completedAt.formatted(date: .abbreviated, time: .shortened)
                    )
                }
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
        .tint(quadrantColor)
        .onChange(of: task.title) { _, _ in persist() }
        .onChange(of: task.notes) { _, _ in persist() }
        .onChange(of: task.quadrantRaw) { _, _ in persist() }
        .onChange(of: task.dueDate) { _, _ in persist() }
        .onChange(of: task.isCompleted) { _, _ in persist() }
        .onChange(of: task.notificationEnabled) { _, _ in persist() }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("删除", role: .destructive) {
                TaskViewModel(modelContext: modelContext).delete(task)
                dismiss()
            }

            Button("取消", role: .cancel) { }
        } message: {
            Text("删除后无法恢复。")
        }
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: task.quadrant.iconName)
                        .font(.title2)
                        .foregroundStyle(quadrantColor)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.quadrant.actionTitle)
                            .font(.headline)

                        Text(task.quadrant.explanation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                HStack(spacing: 8) {
                    Label(task.timeStatusText, systemImage: task.isOverdue ? "clock.badge.exclamationmark" : "clock")
                        .font(.caption)
                        .foregroundStyle(task.isOverdue ? AppColorPalette.overdueColor(for: colorVisionMode) : .secondary)

                    Spacer()

                    TaskProgressBadgeView(task: task)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func persist() {
        TaskViewModel(modelContext: modelContext).update(task)
    }
}
