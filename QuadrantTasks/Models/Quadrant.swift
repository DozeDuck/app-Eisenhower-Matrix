//
//  Quadrant.swift
//  QuadrantTasks
//
//  四象限定义。用 enum + Int 原始值方便存入 SwiftData。
//  附带 UI 元信息，方便各 View 直接读取。
//

import SwiftUI

enum Quadrant: Int, Codable, CaseIterable, Identifiable, Hashable {
    case importantUrgent = 0
    case importantNotUrgent = 1
    case notImportantUrgent = 2
    case notImportantNotUrgent = 3

    var id: Int {
        rawValue
    }

    /// 卡片主标题
    var title: String {
        switch self {
        case .importantUrgent:
            return "重要且紧急"

        case .importantNotUrgent:
            return "重要但不紧急"

        case .notImportantUrgent:
            return "不重要但紧急"

        case .notImportantNotUrgent:
            return "不重要也不紧急"
        }
    }

    /// 原始四象限副标题
    var subtitle: String {
        switch self {
        case .importantUrgent:
            return "立即处理"

        case .importantNotUrgent:
            return "计划推进"

        case .notImportantUrgent:
            return "快速清理"

        case .notImportantNotUrgent:
            return "减少干扰"
        }
    }

    /// 更偏行动导向的标题，用于新版 UI
    var actionTitle: String {
        switch self {
        case .importantUrgent:
            return "立即处理"

        case .importantNotUrgent:
            return "计划推进"

        case .notImportantUrgent:
            return "快速处理"

        case .notImportantNotUrgent:
            return "减少干扰"
        }
    }

    /// 详情页解释文案
    var explanation: String {
        switch self {
        case .importantUrgent:
            return "需要立即处理。例：今天必须完成的工作、紧急会议、马上要交的材料。"

        case .importantNotUrgent:
            return "需要计划并持续推进。例：学习计划、长期职业目标、健身、项目准备。"

        case .notImportantUrgent:
            return "可快速处理、委托或减少干扰。例：临时通知、部分邮件、别人突然的小请求。"

        case .notImportantNotUrgent:
            return "可删除、延后或限制时间。例：低价值杂事、无目的浏览、容易分散注意力的事情。"
        }
    }

    /// 保留旧属性，避免现有 macOS / iOS 代码大面积报错。
    /// 默认返回标准配色。
    var color: Color {
        color(for: .standard)
    }

    /// 根据颜色视觉模式返回象限颜色。
    func color(for mode: ColorVisionMode) -> Color {
        AppColorPalette.quadrantColor(for: self, mode: mode)
    }

    /// 根据颜色视觉模式返回 hex，主要用于 Widget snapshot。
    func colorHex(for mode: ColorVisionMode) -> String {
        AppColorPalette.quadrantColorHex(for: self, mode: mode)
    }

    /// SF Symbols 图标名。四个象限保持不同图标，作为颜色之外的冗余信号。
    var iconName: String {
        switch self {
        case .importantUrgent:
            return "exclamationmark.triangle.fill"

        case .importantNotUrgent:
            return "target"

        case .notImportantUrgent:
            return "bell.badge.fill"

        case .notImportantNotUrgent:
            return "tray.fill"
        }
    }
}
