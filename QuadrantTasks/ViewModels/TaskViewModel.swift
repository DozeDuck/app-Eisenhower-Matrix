//
//  TaskViewModel.swift
//  QuadrantTasks
//
//  封装任务的业务逻辑(增删改查 + 通知同步 + 进度/子任务管理)。
//  View 通过此层调用,不直接操作 ModelContext,便于测试和后续扩展。
//
//  注:SwiftData 的 @Query 让 View 已经能直接读取数据,所以这里更多
//  承担"写入 + 副作用"的职责(例如通知调度、Widget 刷新)。
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
        addTask(
            title: title,
            notes: notes,
            quadrant: quadrant,
            dueDate: dueDate,
            notificationEnabled: notificationEnabled,
            manualProgress: 0.0,
            subtaskTitles: []
        )
    }

    /// 创建任务。
    ///
    /// 新增参数：
    /// - manualProgress：无子任务时使用的手动进度。
    /// - subtaskTitles：创建任务时一并创建的子任务标题列表。
    ///
    /// 注意：
    /// - 保留上方旧签名，避免破坏现有调用点。
    /// - 有子任务时，主任务进度由子任务平均计算，manualProgress 暂不参与展示。
    @discardableResult
    func addTask(
        title: String,
        notes: String = "",
        quadrant: Quadrant,
        dueDate: Date? = nil,
        notificationEnabled: Bool = false,
        manualProgress: Double = 0.0,
        subtaskTitles: [String] = []
    ) -> TaskItem {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        let task = TaskItem(
            title: trimmedTitle,
            notes: notes,
            quadrant: quadrant,
            dueDate: dueDate,
            notificationEnabled: dueDate != nil && notificationEnabled,
            manualProgress: clampedProgress(manualProgress)
        )

        modelContext.insert(task)

        let cleanedSubtaskTitles = subtaskTitles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        for (index, subtaskTitle) in cleanedSubtaskTitles.enumerated() {
            let subtask = SubTask(
                title: subtaskTitle,
                progress: 0.0,
                sortIndex: index
            )

            modelContext.insert(subtask)
            task.subtasks.append(subtask)
        }

        normalizeSubtaskOrder(for: task)
        maintainCompletionMetadata(for: task)
        save()

        syncNotification(for: task)

        return task
    }

    // MARK: - 修改任务基础信息

    /// 保存任务修改。
    ///
    /// 用于详情页中直接绑定 task.title / task.notes / task.dueDate / task.isCompleted 等字段后的统一持久化。
    /// 这里会自动维护 completedAt，并重排本地通知。
    func update(_ task: TaskItem) {
        task.title = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
        task.manualProgress = clampedProgress(task.manualProgress)
        task.updatedAt = Date()

        maintainCompletionMetadata(for: task)
        normalizeSubtaskOrder(for: task)

        save()
        syncNotification(for: task)
    }

    func move(_ task: TaskItem, to quadrant: Quadrant) {
        guard task.quadrant != quadrant else {
            return
        }

        task.quadrant = quadrant
        task.updatedAt = Date()

        save()
    }

    // MARK: - 完成状态

    func toggleComplete(_ task: TaskItem) {
        setCompleted(!task.isCompleted, for: task)
    }

    func setCompleted(_ isCompleted: Bool, for task: TaskItem) {
        guard task.isCompleted != isCompleted else {
            return
        }

        task.isCompleted = isCompleted
        task.updatedAt = Date()

        maintainCompletionMetadata(for: task)

        if task.isCompleted {
            NotificationService.shared.cancelNotification(for: task)
        }

        save()

        if !task.isCompleted {
            syncNotification(for: task)
        }
    }

    /// 维护完成时间。
    ///
    /// 规则：
    /// - isCompleted == true 且 completedAt 为空：设置为当前时间。
    /// - isCompleted == false：清空 completedAt。
    private func maintainCompletionMetadata(for task: TaskItem) {
        if task.isCompleted {
            if task.completedAt == nil {
                task.completedAt = Date()
            }
        } else {
            task.completedAt = nil
        }
    }

    // MARK: - 主任务手动进度

    /// 更新主任务手动进度。
    ///
    /// 仅当任务没有子任务时生效。
    /// 如果任务有子任务，主进度由子任务平均计算，这里不会改 manualProgress。
    ///
    /// 注意：进度达到 100% 不会自动把任务标记为完成。
    /// isCompleted 仍然是唯一权威完成标志。
    func updateManualProgress(
        _ task: TaskItem,
        progress: Double
    ) {
        guard !task.hasSubtasks else {
            return
        }

        task.manualProgress = clampedProgress(progress)
        task.updatedAt = Date()

        save()
    }

    /// 将无子任务任务的手动进度重置为 0。
    func resetManualProgress(_ task: TaskItem) {
        guard !task.hasSubtasks else {
            return
        }

        task.manualProgress = 0.0
        task.updatedAt = Date()

        save()
    }

    // MARK: - 子任务：新增

    @discardableResult
    func addSubtask(
        to task: TaskItem,
        title: String
    ) -> SubTask? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            return nil
        }

        let nextIndex = nextSubtaskSortIndex(for: task)

        let subtask = SubTask(
            title: trimmedTitle,
            progress: 0.0,
            sortIndex: nextIndex
        )

        modelContext.insert(subtask)
        task.subtasks.append(subtask)

        task.updatedAt = Date()
        normalizeSubtaskOrder(for: task)

        save()

        return subtask
    }

    func addSubtasks(
        to task: TaskItem,
        titles: [String]
    ) {
        let cleanedTitles = titles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !cleanedTitles.isEmpty else {
            return
        }

        var nextIndex = nextSubtaskSortIndex(for: task)

        for title in cleanedTitles {
            let subtask = SubTask(
                title: title,
                progress: 0.0,
                sortIndex: nextIndex
            )

            nextIndex += 1

            modelContext.insert(subtask)
            task.subtasks.append(subtask)
        }

        task.updatedAt = Date()
        normalizeSubtaskOrder(for: task)

        save()
    }

    // MARK: - 子任务：修改

    func updateSubtaskTitle(
        _ subtask: SubTask,
        title: String
    ) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard subtask.title != trimmedTitle else {
            return
        }

        subtask.title = trimmedTitle
        subtask.updatedAt = Date()

        if let parent = subtask.parent {
            parent.updatedAt = Date()
        }

        save()
    }

    func updateSubtaskProgress(
        _ subtask: SubTask,
        progress: Double
    ) {
        let newProgress = clampedProgress(progress)

        guard subtask.progress != newProgress else {
            return
        }

        subtask.progress = newProgress
        subtask.updatedAt = Date()

        if let parent = subtask.parent {
            parent.updatedAt = Date()
        }

        save()
    }

    func toggleSubtaskComplete(_ subtask: SubTask) {
        let newProgress = subtask.isCompleted ? 0.0 : 1.0
        updateSubtaskProgress(subtask, progress: newProgress)
    }

    func setSubtaskCompleted(
        _ isCompleted: Bool,
        for subtask: SubTask
    ) {
        updateSubtaskProgress(
            subtask,
            progress: isCompleted ? 1.0 : 0.0
        )
    }

    /// 用于详情页中直接绑定子任务 title/progress 后统一保存。
    func updateSubtask(_ subtask: SubTask) {
        subtask.title = subtask.title.trimmingCharacters(in: .whitespacesAndNewlines)
        subtask.progress = clampedProgress(subtask.progress)
        subtask.updatedAt = Date()

        if let parent = subtask.parent {
            parent.updatedAt = Date()
            normalizeSubtaskOrder(for: parent)
        }

        save()
    }

    // MARK: - 子任务：排序

    /// 根据传入的子任务顺序重写 sortIndex。
    ///
    /// UI 层如果使用 List.onMove，可以先得到新的 orderedSubtasks，
    /// 再调用这个方法。
    func reorderSubtasks(
        for task: TaskItem,
        orderedSubtasks: [SubTask]
    ) {
        guard !orderedSubtasks.isEmpty else {
            return
        }

        for (index, subtask) in orderedSubtasks.enumerated() {
            subtask.sortIndex = index
            subtask.updatedAt = Date()
        }

        task.updatedAt = Date()

        save()
    }

    /// 按当前 sortIndex 重新压缩为 0,1,2...
    func normalizeSubtasks(for task: TaskItem) {
        normalizeSubtaskOrder(for: task)
        task.updatedAt = Date()
        save()
    }

    // MARK: - 子任务：删除

    func deleteSubtask(
        _ subtask: SubTask
    ) {
        let parent = subtask.parent

        if let parent {
            parent.subtasks.removeAll { item in
                item.id == subtask.id
            }

            parent.updatedAt = Date()
            normalizeSubtaskOrder(for: parent)
        }

        modelContext.delete(subtask)

        save()
    }

    func deleteSubtask(
        _ subtask: SubTask,
        from task: TaskItem
    ) {
        task.subtasks.removeAll { item in
            item.id == subtask.id
        }

        task.updatedAt = Date()
        normalizeSubtaskOrder(for: task)

        modelContext.delete(subtask)

        save()
    }

    func deleteAllSubtasks(from task: TaskItem) {
        guard !task.subtasks.isEmpty else {
            return
        }

        for subtask in task.subtasks {
            modelContext.delete(subtask)
        }

        task.subtasks.removeAll()
        task.updatedAt = Date()

        save()
    }

    // MARK: - 删除任务

    func delete(_ task: TaskItem) {
        NotificationService.shared.cancelNotification(for: task)
        modelContext.delete(task)
        save()
    }

    // MARK: - 通知同步

    /// 根据当前任务状态同步本地通知。
    ///
    /// 规则：
    /// - 先取消旧通知；
    /// - 如果任务未完成、开启提醒、存在未来 dueDate，则重新调度。
    private func syncNotification(for task: TaskItem) {
        NotificationService.shared.cancelNotification(for: task)

        guard !task.isCompleted else {
            return
        }

        guard task.notificationEnabled else {
            return
        }

        guard task.dueDate != nil else {
            return
        }

        NotificationService.shared.scheduleIfPossible(for: task)
    }

    // MARK: - 子任务辅助方法

    private func nextSubtaskSortIndex(for task: TaskItem) -> Int {
        let maxIndex = task.subtasks
            .map(\.sortIndex)
            .max() ?? -1

        return maxIndex + 1
    }

    private func normalizeSubtaskOrder(for task: TaskItem) {
        let sorted = task.sortedSubtasks

        for (index, subtask) in sorted.enumerated() {
            subtask.sortIndex = index
        }
    }

    // MARK: - 进度辅助方法

    private func clampedProgress(_ value: Double) -> Double {
        min(max(value, 0.0), 1.0)
    }

    // MARK: - 持久化

    private func save() {
        do {
            try modelContext.save()

            #if os(iOS)
            WidgetDataService.refreshSnapshot(context: modelContext)
            #endif
        } catch {
            // 真实项目可换成日志框架/上报
            print("⚠️ SwiftData 保存失败: \(error)")
        }
    }
}
