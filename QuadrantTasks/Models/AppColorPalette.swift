//
//  AppColorPalette.swift
//  QuadrantTasks
//
//  统一管理 App 内关键颜色。
//  普通模式保留原有象限色；色盲友好模式使用更高区分度的配色。
//

import SwiftUI

enum AppColorPalette {

    // MARK: - 象限颜色

    static func quadrantColor(
        for quadrant: Quadrant,
        mode: ColorVisionMode
    ) -> Color {
        switch mode {
        case .standard:
            return standardColor(for: quadrant)

        case .colorBlindSafe:
            return colorBlindSafeColor(for: quadrant)
        }
    }

    static func quadrantColorHex(
        for quadrant: Quadrant,
        mode: ColorVisionMode
    ) -> String {
        switch mode {
        case .standard:
            return standardColorHex(for: quadrant)

        case .colorBlindSafe:
            return colorBlindSafeColorHex(for: quadrant)
        }
    }

    // MARK: - 逾期强调色

    static func overdueColor(for mode: ColorVisionMode) -> Color {
        switch mode {
        case .standard:
            // 洋红色，与红、蓝、黄、紫灰都保持区分
            return Color(red: 0.90, green: 0.19, blue: 0.55)

        case .colorBlindSafe:
            // 深色强调，配合 warning icon 和文字，不只依赖颜色
            return Color(red: 0.07, green: 0.09, blue: 0.15)
        }
    }

    static func overdueColorHex(for mode: ColorVisionMode) -> String {
        switch mode {
        case .standard:
            return "#E5318C"
        case .colorBlindSafe:
            return "#111827"
        }
    }

    // MARK: - 普通模式

    private static func standardColor(for quadrant: Quadrant) -> Color {
        switch quadrant {
        case .importantUrgent:
            return Color(red: 0.93, green: 0.32, blue: 0.32)

        case .importantNotUrgent:
            return Color(red: 0.22, green: 0.55, blue: 0.92)

        case .notImportantUrgent:
            return Color(red: 0.96, green: 0.70, blue: 0.20)

        case .notImportantNotUrgent:
            return Color(red: 0.55, green: 0.55, blue: 0.62)
        }
    }

    private static func standardColorHex(for quadrant: Quadrant) -> String {
        switch quadrant {
        case .importantUrgent:
            return "#EE5252"

        case .importantNotUrgent:
            return "#388CEB"

        case .notImportantUrgent:
            return "#F5B333"

        case .notImportantNotUrgent:
            return "#8C8C9E"
        }
    }

    // MARK: - 色盲友好模式

    private static func colorBlindSafeColor(for quadrant: Quadrant) -> Color {
        switch quadrant {
        case .importantUrgent:
            // Vermillion
            return Color(red: 0.84, green: 0.37, blue: 0.00)

        case .importantNotUrgent:
            // Blue
            return Color(red: 0.00, green: 0.45, blue: 0.70)

        case .notImportantUrgent:
            // Orange
            return Color(red: 0.90, green: 0.62, blue: 0.00)

        case .notImportantNotUrgent:
            // Bluish green
            return Color(red: 0.00, green: 0.62, blue: 0.45)
        }
    }

    private static func colorBlindSafeColorHex(for quadrant: Quadrant) -> String {
        switch quadrant {
        case .importantUrgent:
            return "#D55E00"

        case .importantNotUrgent:
            return "#0072B2"

        case .notImportantUrgent:
            return "#E69F00"

        case .notImportantNotUrgent:
            return "#009E73"
        }
    }
}
