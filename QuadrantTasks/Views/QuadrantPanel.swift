//
//  QuadrantPanel.swift
//  QuadrantTasks (macOS)
//
//  v2 改动:
//   - 让 VStack 显式 .frame(maxWidth: .infinity, maxHeight: .infinity)
//     -> 面板填满 Grid 给的格子(响应窗口尺寸变化)
//   - 让内部 ScrollView 也 .frame(maxHeight: .infinity)
//     -> header 之外的空间全部给 ScrollView,内容超出时真正可以滚动
//

import SwiftUI
import SwiftData

struct QuadrantPanel: View {
    let quadrant: Quadrant
    @Binding var selectedTaskID: UUID?

    @Environment(\.modelContext) private var modelContext
    @Environment(AppCommands.self) private var commands

    @Query private var allTasks: [TaskItem]

    @State private var isDropTargeted = false

    // MARK: - 过滤 & 排序

    private var pendingTasks: [TaskItem] {
        sort(allTasks.filter { $0.quadrant == quadrant && !$0.isCompleted })
    }

    private var completedTasks: [TaskItem] {
        allTasks
            .filter { $0.quadrant == quadrant && $0.isCompleted }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    private func sort(_ tasks: [TaskItem]) -> [TaskItem] {
        switch commands.sortOption {
        case .createdDesc: return tasks.sorted { $0.createdAt > $1.createdAt }
        case .createdAsc:  return tasks.sorted { $0.createdAt < $1.createdAt }
        case .dueAsc:
            return tasks.sorted {
                ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture)
            }
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            taskList
        }
        // 关键:撑满 Grid 给的格子,Grid 又撑满窗口 -> 自适应
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDropTargeted ? quadrant.color : quadrant.color.opacity(0.25),
                    lineWidth: isDropTargeted ? 2 : 1
                )
        )
        .dropDestination(for: String.self) { items, _ in
            handleDrop(items)
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.15)) {
                isDropTargeted = targeted
            }
        }
    }

    // MARK: - 子视图

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: quadrant.iconName)
                .font(.title3)
                .foregroundStyle(quadrant.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(quadrant.title)
                    .font(.headline)
                Text(quadrant.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(pendingTasks.count)")
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(quadrant.color.opacity(0.15))
                .foregroundStyle(quadrant.color)
                .clipShape(Capsule())

            Button {
                commands.requestNewTask(in: quadrant)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .help("在此象限添加任务")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(quadrant.color.opacity(0.06))
    }

    private var taskList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 1) {
                if pendingTasks.isEmpty && (!commands.showCompleted || completedTasks.isEmpty) {
                    emptyState
                } else {
                    ForEach(pendingTasks) { task in
                        row(for: task)
                    }

                    if commands.showCompleted && !completedTasks.isEmpty {
                        completedHeader
                        ForEach(completedTasks) { task in
                            row(for: task)
                        }
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        // 关键:撑满 VStack 中 header 之外的剩余空间,内容超出时滚动
        .frame(maxHeight: .infinity)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle")
                .font(.title)
                .foregroundStyle(.tertiary)
            Text("暂无任务")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("⌘N 新建,或拖入其他任务")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private var completedHeader: some View {
        HStack {
            Text("已完成 (\(completedTasks.count))")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func row(for task: TaskItem) -> some View {
        MacTaskRow(
            task: task,
            isSelected: selectedTaskID == task.id,
            onSelect: { selectedTaskID = task.id },
            onToggleComplete: { toggleComplete(task) }
        )
        .draggable(task.id.uuidString)
        .contextMenu { contextMenu(for: task) }
    }

    @ViewBuilder
    private func contextMenu(for task: TaskItem) -> some View {
        Button(task.isCompleted ? "标为未完成" : "标为已完成") {
            toggleComplete(task)
        }
        Divider()
        Menu("移动到") {
            ForEach(Quadrant.allCases.filter { $0 != task.quadrant }) { q in
                Button {
                    moveTask(task, to: q)
                } label: {
                    Label(q.title, systemImage: q.iconName)
                }
            }
        }
        Divider()
        Button("查看详情") {
            selectedTaskID = task.id
        }
        Button("删除", role: .destructive) {
            delete(task)
        }
    }

    // MARK: - 操作

    private func toggleComplete(_ task: TaskItem) {
        TaskViewModel(modelContext: modelContext).toggleComplete(task)
    }

    private func delete(_ task: TaskItem) {
        if selectedTaskID == task.id { selectedTaskID = nil }
        TaskViewModel(modelContext: modelContext).delete(task)
    }

    private func moveTask(_ task: TaskItem, to quadrant: Quadrant) {
        TaskViewModel(modelContext: modelContext).move(task, to: quadrant)
    }

    private func handleDrop(_ items: [String]) -> Bool {
        guard let first = items.first, let uuid = UUID(uuidString: first),
              let task = allTasks.first(where: { $0.id == uuid }),
              task.quadrant != quadrant
        else { return false }
        moveTask(task, to: quadrant)
        return true
    }
}
