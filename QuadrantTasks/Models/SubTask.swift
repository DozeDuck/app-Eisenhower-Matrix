//
//  SubTask.swift
//  QuadrantTasks
//
//  子任务模型。一个 TaskItem 可以包含多个 SubTask。
//  子任务使用 progress 表示完成度：0.0 = 未开始，1.0 = 完成。
//

import Foundation
import SwiftData

@Model
final class SubTask {

    // MARK: - 字段

    /// 唯一标识
    var id: UUID

    /// 子任务标题
    var title: String

    /// 子任务进度 0.0...1.0；progress >= 1.0 视为完成
    var progress: Double

    /// 同一父任务下的排序
    var sortIndex: Int

    /// 创建时间
    var createdAt: Date

    /// 更新时间
    var updatedAt: Date

    /// 父任务
    var parent: TaskItem?

    // MARK: - 计算属性

    /// 归一化进度，防止 UI 或未来代码写入超出范围的数值
    var normalizedProgress: Double {
        min(max(progress, 0.0), 1.0)
    }

    /// 是否完成。子任务没有单独的 isCompleted 字段，progress >= 1.0 即完成
    var isCompleted: Bool {
        normalizedProgress >= 1.0
    }

    /// UI 展示用百分比
    var progressPercent: Int {
        Int((normalizedProgress * 100).rounded())
    }

    // MARK: - 初始化

    init(
        id: UUID = UUID(),
        title: String = "",
        progress: Double = 0.0,
        sortIndex: Int = 0,
        parent: TaskItem? = nil
    ) {
        self.id = id
        self.title = title
        self.progress = min(max(progress, 0.0), 1.0)
        self.sortIndex = sortIndex
        self.parent = parent

        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }
}
