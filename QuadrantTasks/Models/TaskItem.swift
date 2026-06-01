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

    /// 唯一标识(同时作为通知 ID)
    var id: UUID

    /// 任务标题(必填)
    var title: String

    /// 任务备注(可选,允许多行)
    var notes: String

    /// 所属象限 —— 用 Int 原始值存储,通过 computed property 暴露 enum
    var quadrantRaw: Int

    /// 截止日期(可选)
    var dueDate: Date?

    /// 是否完成
    var isCompleted: Bool

    /// 是否启用本地通知
    var notificationEnabled: Bool

    /// 创建时间
    var createdAt: Date

    /// 最后更新时间
    var updatedAt: Date

    // MARK: - 计算属性

    /// 对外暴露的象限枚举(包装 quadrantRaw)
    var quadrant: Quadrant {
        get { Quadrant(rawValue: quadrantRaw) ?? .importantUrgent }
        set { quadrantRaw = newValue.rawValue }
    }

    /// 是否已逾期(未完成 + 截止日期已过)
    var isOverdue: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        return due < Date()
    }

    // MARK: - 初始化

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        quadrant: Quadrant = .importantUrgent,
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        notificationEnabled: Bool = false
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.quadrantRaw = quadrant.rawValue
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.notificationEnabled = notificationEnabled
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }
}
