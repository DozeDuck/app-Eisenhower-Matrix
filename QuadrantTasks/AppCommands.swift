//
//  AppCommands.swift
//  QuadrantTasks (macOS)
//
//  跨视图共享的小型状态容器,用于:
//   - 菜单栏命令(⌘N)触发新建任务表单
//   - 全局切换"显示已完成"
//   - 全局排序选项
//
//  使用 @Observable + @Environment 注入到 MainView。
//

import SwiftUI

@Observable
final class AppCommands {

    /// 当前是否正在显示"新建任务"表单
    var isAddingTask: Bool = false

    /// 新建任务时默认所属象限
    var addingTaskQuadrant: Quadrant = .importantUrgent

    /// 是否在每个面板里显示已完成任务
    var showCompleted: Bool = false

    /// 全局排序选项
    var sortOption: SortOption = .createdDesc

    /// 触发"新建任务"流程(由菜单/工具栏调用)
    func requestNewTask(in quadrant: Quadrant) {
        addingTaskQuadrant = quadrant
        isAddingTask = true
    }

    enum SortOption: String, CaseIterable, Identifiable {
        case createdDesc = "创建时间(新→旧)"
        case createdAsc  = "创建时间(旧→新)"
        case dueAsc      = "截止日期(近→远)"
        var id: String { rawValue }
    }
}
