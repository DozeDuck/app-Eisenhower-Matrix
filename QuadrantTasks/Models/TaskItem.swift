//
//  TaskItem.swift
//  QuadrantTasks
//
//  任务数据模型 —— 使用 SwiftData @Model 持久化到本地 SQLite。
//

import Foundation
import SwiftData

@Model
final class TaskItem {

    // MARK: - 字段

    /// 唯一标识，同时作为通知 ID
    var id: UUID

    /// 任务标题，必填
    var title: String

    /// 任务备注，可选，允许多行
    var notes: String

    /// 所属象限 —— 用 Int 原始值存储，通过 computed property 暴露 enum
    var quadrantRaw: Int

    /// 截止日期，可选
    var dueDate: Date?

    /// 是否完成
    var isCompleted: Bool

    /// 完成时间。isCompleted 变为 true 时设置；恢复未完成时清空
    var completedAt: Date?

    /// 是否启用本地通知
    var notificationEnabled: Bool

    /// 手动进度 0.0...1.0，仅当任务没有子任务时生效
    var manualProgress: Double

    /// 创建时间
    var createdAt: Date

    /// 最后更新时间
    var updatedAt: Date

    /// 子任务。删除主任务时级联删除子任务
    @Relationship(deleteRule: .cascade, inverse: \SubTask.parent)
    var subtasks: [SubTask]

    // MARK: - 计算属性

    /// 对外暴露的象限枚举，包装 quadrantRaw
    var quadrant: Quadrant {
        get {
            Quadrant(rawValue: quadrantRaw) ?? .importantUrgent
        }
        set {
            quadrantRaw = newValue.rawValue
        }
    }

    /// 是否有子任务
    var hasSubtasks: Bool {
        !subtasks.isEmpty
    }

    /// 排序后的子任务
    var sortedSubtasks: [SubTask] {
        subtasks.sorted {
            if $0.sortIndex == $1.sortIndex {
                return $0.createdAt < $1.createdAt
            }
            return $0.sortIndex < $1.sortIndex
        }
    }

    /// 归一化手动进度
    var normalizedManualProgress: Double {
        min(max(manualProgress, 0.0), 1.0)
    }

    /// 综合完成度 0.0...1.0
    ///
    /// 规则：
    /// - 已完成任务固定为 1.0
    /// - 有子任务时，取所有子任务 progress 的平均值
    /// - 没有子任务时，使用 manualProgress
    var progressFraction: Double {
        if isCompleted {
            return 1.0
        }

        if hasSubtasks {
            let total = subtasks.reduce(0.0) { partialResult, subtask in
                partialResult + subtask.normalizedProgress
            }
            return total / Double(subtasks.count)
        }

        return normalizedManualProgress
    }

    /// UI 展示用百分比 0...100
    var progressPercent: Int {
        Int((progressFraction * 100).rounded())
    }

    /// 是否已逾期。
    ///
    /// 这里按自然日判断：
    /// - 截止日期早于今天，才算逾期；
    /// - 截止日期是今天，即使具体时间已过，也仍显示为“今天截止”。
    var isOverdue: Bool {
        guard let dueDate, !isCompleted else {
            return false
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dueDay = calendar.startOfDay(for: dueDate)

        return dueDay < today
    }

    /// 是否今天截止
    var isDueToday: Bool {
        guard let dueDate, !isCompleted else {
            return false
        }

        let calendar = Calendar.current
        return calendar.isDate(dueDate, inSameDayAs: Date())
    }

    // MARK: - 初始化

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        quadrant: Quadrant = .importantUrgent,
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        notificationEnabled: Bool = false,
        manualProgress: Double = 0.0,
        subtasks: [SubTask] = []
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.quadrantRaw = quadrant.rawValue
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.notificationEnabled = notificationEnabled
        self.manualProgress = min(max(manualProgress, 0.0), 1.0)
        self.subtasks = subtasks

        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }
}
