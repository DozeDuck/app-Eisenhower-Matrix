//
//  IOSQuadrantDetailView.swift
//  QuadrantTasksIOS
//
//  单象限任务列表页。
//  接入色盲模式颜色、逾期标识、进度徽章和新版任务行。
//

import SwiftUI
import SwiftData

struct IOSQuadrantDetailView: View {
    let quadrant: Quadrant

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorVisionMode) private var colorVisionMode

    @Query(sort: \TaskItem.updatedAt, order: .reverse)
    private var allTasks: [TaskItem]

    @State private var showingAddTask = false
    @State private var sortOption: IOSTaskSortOption = .createdDesc
    @State private var showCompleted = false

    private var quadrantColor: Color {
        quadrant.color(for: colorVisionMode)
    }

    private var pendingTasks: [TaskItem] {
        sorted(
            allTasks.filter {
                $0.quadrant == quadrant && !$0.isCompleted
            }
        )
    }

    private var completedTasks: [TaskItem] {
        sorted(
            allTasks.filter {
                $0.quadrant == quadrant && $0.isCompleted
            }
        )
    }

    private var overdueCount: Int {
        pendingTasks.filter(\.isOverdue).count
    }

    private var averageProgress: Int {
        guard !pendingTasks.isEmpty else {
            return 0
        }

        let total = pendingTasks.reduce(0.0) { partialResult, task in
            partialResult + task.progressFraction
        }

        return Int(((total / Double(pendingTasks.count)) * 100).rounded())
    }

    var body: some View {
        List {
            headerSection

            Section("显示与排序") {
                Picker("排序", selection: $sortOption) {
                    ForEach(IOSTaskSortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }

                Toggle("显示已完成", isOn: $showCompleted)
            }

            Section("未完成") {
                if pendingTasks.isEmpty {
                    ContentUnavailableView(
                        "暂无任务",
                        systemImage: "checkmark.circle",
                        description: Text("这个象限暂时没有未完成任务。")
                    )
                } else {
                    ForEach(pendingTasks) { task in
                        taskRow(task, restoreStyle: false)
                    }
                }
            }

            if showCompleted {
                Section("已完成") {
                    if completedTasks.isEmpty {
                        Text("暂无已完成任务")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(completedTasks) { task in
                            taskRow(task, restoreStyle: true)
                        }
                    }
                }
            }
        }
        .navigationTitle(quadrant.actionTitle)
        .tint(quadrantColor)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddTask = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("新建任务")
            }
        }
        .sheet(isPresented: $showingAddTask) {
            IOSAddTaskView(defaultQuadrant: quadrant)
        }
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: quadrant.iconName)
                        .font(.title2)
                        .foregroundStyle(quadrantColor)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(quadrant.title)
                            .font(.headline)

                        Text(quadrant.explanation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                HStack(spacing: 10) {
                    summaryPill(
                        title: "未完成",
                        value: pendingTasks.count,
                        systemImage: "circle",
                        color: quadrantColor
                    )

                    summaryPill(
                        title: "逾期",
                        value: overdueCount,
                        systemImage: "exclamationmark.triangle.fill",
                        color: AppColorPalette.overdueColor(for: colorVisionMode)
                    )

                    summaryPill(
                        title: "进度",
                        valueText: "\(averageProgress)%",
                        systemImage: "chart.pie",
                        color: quadrantColor
                    )
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(quadrantColor.opacity(0.08))
    }

    private func summaryPill(
        title: String,
        value: Int,
        systemImage: String,
        color: Color
    ) -> some View {
        summaryPill(
            title: title,
            valueText: "\(value)",
            systemImage: systemImage,
            color: color
        )
    }

    private func summaryPill(
        title: String,
        valueText: String,
        systemImage: String,
        color: Color
    ) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption2)

            Text(title)
                .font(.caption2)

            Text(valueText)
                .font(.caption2.weight(.bold))
                .monospacedDigit()
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.12))
        )
    }

    private func taskRow(
        _ task: TaskItem,
        restoreStyle: Bool
    ) -> some View {
        IOSTaskRowView(
            task: task,
            showQuadrant: false,
            onToggleComplete: {
                toggleComplete(task)
            }
        ) {
            IOSTaskDetailView(task: task)
        }
        .swipeActions(edge: .leading) {
            Button {
                toggleComplete(task)
            } label: {
                Label(
                    restoreStyle ? "恢复" : "完成",
                    systemImage: restoreStyle ? "arrow.uturn.backward" : "checkmark"
                )
            }
            .tint(restoreStyle ? .blue : .green)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                delete(task)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(task.isCompleted ? "标为未完成" : "标为已完成") {
                toggleComplete(task)
            }

            Divider()

            moveMenu(for: task)

            Divider()

            Button("删除", role: .destructive) {
                delete(task)
            }
        }
    }

    @ViewBuilder
    private func moveMenu(for task: TaskItem) -> some View {
        Menu("移动到") {
            ForEach(Quadrant.allCases.filter { $0 != task.quadrant }) { targetQuadrant in
                Button {
                    move(task, to: targetQuadrant)
                } label: {
                    Label(targetQuadrant.title, systemImage: targetQuadrant.iconName)
                }
            }
        }
    }

    private func sorted(_ tasks: [TaskItem]) -> [TaskItem] {
        switch sortOption {
        case .createdDesc:
            return tasks.sorted {
                $0.createdAt > $1.createdAt
            }

        case .createdAsc:
            return tasks.sorted {
                $0.createdAt < $1.createdAt
            }

        case .dueAsc:
            return tasks.sorted {
                let lhs = $0.dueDate ?? .distantFuture
                let rhs = $1.dueDate ?? .distantFuture

                if lhs == rhs {
                    return $0.updatedAt > $1.updatedAt
                }

                return lhs < rhs
            }
        }
    }

    private func toggleComplete(_ task: TaskItem) {
        TaskViewModel(modelContext: modelContext).toggleComplete(task)
    }

    private func delete(_ task: TaskItem) {
        TaskViewModel(modelContext: modelContext).delete(task)
    }

    private func move(_ task: TaskItem, to quadrant: Quadrant) {
        TaskViewModel(modelContext: modelContext).move(task, to: quadrant)
    }
}
