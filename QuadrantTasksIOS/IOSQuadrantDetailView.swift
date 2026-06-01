import SwiftUI
import SwiftData

struct IOSQuadrantDetailView: View {
    let quadrant: Quadrant

    @Environment(\.modelContext) private var modelContext

    @Query(sort: \TaskItem.updatedAt, order: .reverse)
    private var allTasks: [TaskItem]

    @State private var showingAddTask = false
    @State private var sortOption: IOSTaskSortOption = .createdDesc
    @State private var showCompleted = false

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

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label(quadrant.title, systemImage: quadrant.iconName)
                        .font(.headline)
                        .foregroundStyle(quadrant.color)

                    Text(quadrant.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

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
                                Label("完成", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                delete(task)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            moveMenu(for: task)
                        }
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
                                    Label("恢复", systemImage: "arrow.uturn.backward")
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(task)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                moveMenu(for: task)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(quadrant.subtitle)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddTask = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            IOSAddTaskView(defaultQuadrant: quadrant)
        }
    }

    private func sorted(_ tasks: [TaskItem]) -> [TaskItem] {
        switch sortOption {
        case .createdDesc:
            return tasks.sorted { $0.createdAt > $1.createdAt }

        case .createdAsc:
            return tasks.sorted { $0.createdAt < $1.createdAt }

        case .dueAsc:
            return tasks.sorted {
                ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture)
            }
        }
    }

    private func toggleComplete(_ task: TaskItem) {
        TaskViewModel(modelContext: modelContext).toggleComplete(task)
    }

    private func delete(_ task: TaskItem) {
        TaskViewModel(modelContext: modelContext).delete(task)
    }

    @ViewBuilder
    private func moveMenu(for task: TaskItem) -> some View {
        Button(task.isCompleted ? "标为未完成" : "标为已完成") {
            toggleComplete(task)
        }

        Menu("移动到") {
            ForEach(Quadrant.allCases.filter { $0 != task.quadrant }) { target in
                Button {
                    TaskViewModel(modelContext: modelContext).move(task, to: target)
                } label: {
                    Label(target.title, systemImage: target.iconName)
                }
            }
        }

        Button("删除", role: .destructive) {
            delete(task)
        }
    }
}
