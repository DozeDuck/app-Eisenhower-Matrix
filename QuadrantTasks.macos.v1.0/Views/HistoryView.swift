//
//  HistoryView.swift
//  QuadrantTasks (macOS)
//
//  历史任务(已完成任务)管理:
//   - 列出全部已完成任务,按更新时间倒序
//   - 可按象限筛选
//   - 多选删除(⌘ 或 Shift 多选,或勾选 checkbox)
//   - 批量清理:删除选中 / 删除 X 天前 / 删除全部
//   - 单条恢复(标为未完成)或永久删除
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// 取出全部任务,内存中过滤已完成项(SwiftData 的 #Predicate 对 Bool 直接读
    /// 在某些版本上不稳定,内存过滤更可靠且数据量通常不大)
    @Query(sort: \TaskItem.updatedAt, order: .reverse) private var allTasks: [TaskItem]

    @State private var selectedIDs: Set<UUID> = []
    @State private var filterQuadrant: Quadrant? = nil
    @State private var pendingDelete: PendingDelete? = nil

    // MARK: - 派生数据

    private var completedAll: [TaskItem] {
        allTasks.filter { $0.isCompleted }
    }

    private var displayedTasks: [TaskItem] {
        if let q = filterQuadrant {
            return completedAll.filter { $0.quadrant == q }
        }
        return completedAll
    }

    private var statsByQuadrant: [(Quadrant, Int)] {
        Quadrant.allCases.map { q in
            (q, completedAll.filter { $0.quadrant == q }.count)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            filterBar
            Divider()
            content
            Divider()
            footer
        }
        .background(Color(NSColor.windowBackgroundColor))
        .alert(item: $pendingDelete) { item in
            Alert(
                title: Text(item.title),
                message: Text(item.message),
                primaryButton: .destructive(Text("删除")) {
                    performDelete(item.action)
                },
                secondaryButton: .cancel()
            )
        }
    }

    // MARK: - 顶部标题

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("历史任务")
                    .font(.title2.bold())
                Text("\(completedAll.count) 项已完成 · 共占用 \(allTasks.count) 条记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("完成") { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - 筛选条

    private var filterBar: some View {
        HStack(spacing: 10) {
            Picker("筛选", selection: $filterQuadrant) {
                Text("全部象限").tag(Optional<Quadrant>.none)
                Divider()
                ForEach(Quadrant.allCases) { q in
                    HStack {
                        Image(systemName: q.iconName)
                            .foregroundStyle(q.color)
                        Text("\(q.title) (\(statsByQuadrant.first(where: { $0.0 == q })?.1 ?? 0))")
                    }
                    .tag(Optional(q))
                }
            }
            .pickerStyle(.menu)
            .frame(width: 220)
            .labelsHidden()

            if !selectedIDs.isEmpty {
                Text("已选 \(selectedIDs.count) 项")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("清除选择") {
                    selectedIDs.removeAll()
                }
                .buttonStyle(.borderless)
            }

            Spacer()

            // 批量删除选中
            if !selectedIDs.isEmpty {
                Button(role: .destructive) {
                    pendingDelete = PendingDelete(
                        action: .selected,
                        title: "删除选中的 \(selectedIDs.count) 项?",
                        message: "删除后无法恢复。"
                    )
                } label: {
                    Label("删除选中", systemImage: "trash")
                }
            }

            // 清理菜单
            Menu {
                Button("删除 7 天前的已完成项") {
                    pendingDelete = PendingDelete(
                        action: .olderThan(days: 7),
                        title: "删除 7 天前的已完成任务?",
                        message: countMessage(forDaysAgo: 7)
                    )
                }
                Button("删除 30 天前的已完成项") {
                    pendingDelete = PendingDelete(
                        action: .olderThan(days: 30),
                        title: "删除 30 天前的已完成任务?",
                        message: countMessage(forDaysAgo: 30)
                    )
                }
                Divider()
                Button("删除全部已完成项", role: .destructive) {
                    pendingDelete = PendingDelete(
                        action: .all,
                        title: "删除全部 \(completedAll.count) 项已完成任务?",
                        message: "此操作无法撤销。"
                    )
                }
            } label: {
                Label("清理", systemImage: "wand.and.sparkles")
            }
            .menuStyle(.button)
            .disabled(completedAll.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - 主列表

    @ViewBuilder
    private var content: some View {
        if displayedTasks.isEmpty {
            ContentUnavailableView(
                completedAll.isEmpty ? "还没有已完成的任务" : "当前筛选无匹配",
                systemImage: "tray",
                description: Text(completedAll.isEmpty
                                  ? "完成任务后会显示在这里"
                                  : "试试切换到其他象限")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(selection: $selectedIDs) {
                ForEach(displayedTasks) { task in
                    HistoryRow(
                        task: task,
                        onRestore: { restore(task) },
                        onDelete: {
                            pendingDelete = PendingDelete(
                                action: .single(task.id),
                                title: "删除「\(task.title)」?",
                                message: "删除后无法恢复。"
                            )
                        }
                    )
                    .tag(task.id)
                }
            }
            .listStyle(.inset)
        }
    }

    // MARK: - 底部提示

    private var footer: some View {
        HStack {
            Text("💡 按住 ⌘ 多选,Shift 范围选择;右键查看更多操作")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    // MARK: - 操作

    private func restore(_ task: TaskItem) {
        TaskViewModel(modelContext: modelContext).toggleComplete(task)
        selectedIDs.remove(task.id)
    }

    private func performDelete(_ action: DeleteAction) {
        let vm = TaskViewModel(modelContext: modelContext)
        switch action {
        case .single(let id):
            if let task = completedAll.first(where: { $0.id == id }) {
                vm.delete(task)
            }
            selectedIDs.remove(id)

        case .selected:
            let toDelete = completedAll.filter { selectedIDs.contains($0.id) }
            for task in toDelete { vm.delete(task) }
            selectedIDs.removeAll()

        case .olderThan(let days):
            let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            for task in completedAll where task.updatedAt < cutoff {
                vm.delete(task)
            }

        case .all:
            for task in completedAll { vm.delete(task) }
            selectedIDs.removeAll()
        }
    }

    private func countMessage(forDaysAgo days: Int) -> String {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let count = completedAll.filter { $0.updatedAt < cutoff }.count
        return "将删除 \(count) 项 \(days) 天前完成的任务,无法撤销。"
    }
}

// MARK: - 单行视图

private struct HistoryRow: View {
    let task: TaskItem
    let onRestore: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: task.quadrant.iconName)
                .foregroundStyle(task.quadrant.color)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .strikethrough()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(task.quadrant.title)
                    Text("·")
                    Text("完成于 \(task.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }

            Spacer()

            Button {
                onRestore()
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .buttonStyle(.borderless)
            .help("恢复为未完成")

            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
            .help("永久删除")
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("恢复为未完成", action: onRestore)
            Button("永久删除", role: .destructive, action: onDelete)
        }
    }
}

// MARK: - 删除动作

private enum DeleteAction {
    case single(UUID)
    case selected
    case olderThan(days: Int)
    case all
}

private struct PendingDelete: Identifiable {
    let id = UUID()
    let action: DeleteAction
    let title: String
    let message: String
}
