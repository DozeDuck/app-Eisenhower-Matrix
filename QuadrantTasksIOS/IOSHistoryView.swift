import SwiftUI
import SwiftData

struct IOSHistoryView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \TaskItem.updatedAt, order: .reverse)
    private var allTasks: [TaskItem]

    private var completedTasks: [TaskItem] {
        allTasks.filter { $0.isCompleted }
    }

    var body: some View {
        List {
            if completedTasks.isEmpty {
                ContentUnavailableView(
                    "还没有已完成任务",
                    systemImage: "checkmark.circle",
                    description: Text("完成的任务会显示在这里。")
                )
            } else {
                ForEach(completedTasks) { task in
                    IOSTaskRowView(
                        task: task,
                        showQuadrant: true,
                        onToggleComplete: {
                            TaskViewModel(modelContext: modelContext).toggleComplete(task)
                        }
                    ) {
                        IOSTaskDetailView(task: task)
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            TaskViewModel(modelContext: modelContext).toggleComplete(task)
                        } label: {
                            Label("恢复", systemImage: "arrow.uturn.backward")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            TaskViewModel(modelContext: modelContext).delete(task)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("已完成")
    }
}
