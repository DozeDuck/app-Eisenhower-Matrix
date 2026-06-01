//
//  TaskViewModel.swift
//  QuadrantTasks
//
//  封装任务的业务逻辑(增删改查 + 通知同步)。
//  View 通过此层调用,不直接操作 ModelContext,便于测试和后续扩展。
//
//  注:SwiftData 的 @Query 让 View 已经能直接读取数据,所以这里更多
//  承担"写入 + 副作用"的职责(例如通知调度)。
//

import Foundation
import SwiftData

@Observable
final class TaskViewModel {

    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - 创建

    @discardableResult
    func addTask(
        title: String,
        notes: String = "",
        quadrant: Quadrant,
        dueDate: Date? = nil,
        notificationEnabled: Bool = false
    ) -> TaskItem {
        let task = TaskItem(
            title: title,
            notes: notes,
            quadrant: quadrant,
            dueDate: dueDate,
            notificationEnabled: notificationEnabled
        )
        modelContext.insert(task)
        save()

        if task.notificationEnabled, task.dueDate != nil {
            NotificationService.shared.scheduleIfPossible(for: task)
        }
        return task
    }

    // MARK: - 修改

    func update(_ task: TaskItem) {
        task.updatedAt = Date()
        save()

        // 截止日期/提醒可能改变 -> 重置通知
        NotificationService.shared.cancelNotification(for: task)
        if task.notificationEnabled, task.dueDate != nil, !task.isCompleted {
            NotificationService.shared.scheduleIfPossible(for: task)
        }
    }

    func toggleComplete(_ task: TaskItem) {
        task.isCompleted.toggle()
        task.updatedAt = Date()
        if task.isCompleted {
            NotificationService.shared.cancelNotification(for: task)
        }
        save()
    }

    func move(_ task: TaskItem, to quadrant: Quadrant) {
        guard task.quadrant != quadrant else { return }
        task.quadrant = quadrant
        task.updatedAt = Date()
        save()
    }

    // MARK: - 删除

    func delete(_ task: TaskItem) {
        NotificationService.shared.cancelNotification(for: task)
        modelContext.delete(task)
        save()
    }

    // MARK: - 持久化

    private func save() {
        do {
            try modelContext.save()
        } catch {
            // 真实项目可换成日志框架/上报
            print("⚠️ SwiftData 保存失败: \(error)")
        }
    }
}
