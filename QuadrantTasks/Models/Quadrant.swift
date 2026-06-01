//
//  Quadrant.swift
//  QuadrantTasks
//
//  四象限定义。用 enum + Int 原始值方便存入 SwiftData。
//  附带 UI 元信息(标题/副标题/颜色/图标)，方便各 View 直接读取。
//

import SwiftUI

enum Quadrant: Int, Codable, CaseIterable, Identifiable, Hashable {
    case importantUrgent      = 0   // 重要且紧急
    case importantNotUrgent   = 1   // 重要但不紧急
    case notImportantUrgent   = 2   // 不重要但紧急
    case notImportantNotUrgent = 3  // 不重要也不紧急

    var id: Int { rawValue }

    /// 卡片主标题
    var title: String {
        switch self {
        case .importantUrgent:       return "重要且紧急"
        case .importantNotUrgent:    return "重要但不紧急"
        case .notImportantUrgent:    return "不重要但紧急"
        case .notImportantNotUrgent: return "不重要也不紧急"
        }
    }

    /// 卡片副标题(简短行动建议)
    var subtitle: String {
        switch self {
        case .importantUrgent:       return "立即处理"
        case .importantNotUrgent:    return "计划推进"
        case .notImportantUrgent:    return "委托或快速处理"
        case .notImportantNotUrgent: return "删除或延后"
        }
    }

    /// 详情页解释文案
    var explanation: String {
        switch self {
        case .importantUrgent:
            return "需要立即处理。例:今天必须完成的工作、紧急会议、马上要交的材料。"
        case .importantNotUrgent:
            return "需要计划并持续推进。例:学习计划、长期职业目标、健身、项目准备。"
        case .notImportantUrgent:
            return "可委托、快速处理或减少干扰。例:临时通知、部分邮件、别人突然的小请求。"
        case .notImportantNotUrgent:
            return "可删除、延后或限制时间。例:刷短视频、无目的浏览网页、低价值杂事。"
        }
    }

    /// 主题色(同时适配深浅色模式,色值经过柔化处理,不刺眼)
    var color: Color {
        switch self {
        case .importantUrgent:
            return Color(red: 0.93, green: 0.32, blue: 0.32)   // 橙红
        case .importantNotUrgent:
            return Color(red: 0.22, green: 0.55, blue: 0.92)   // 蓝
        case .notImportantUrgent:
            return Color(red: 0.96, green: 0.70, blue: 0.20)   // 琥珀黄
        case .notImportantNotUrgent:
            return Color(red: 0.55, green: 0.55, blue: 0.62)   // 紫灰
        }
    }

    /// SF Symbols 图标名
    var iconName: String {
        switch self {
        case .importantUrgent:       return "exclamationmark.triangle.fill"
        case .importantNotUrgent:    return "target"
        case .notImportantUrgent:    return "bell.badge.fill"
        case .notImportantNotUrgent: return "tray.fill"
        }
    }
}
