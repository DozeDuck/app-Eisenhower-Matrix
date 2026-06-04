//
//  TaskTimeStatusFormatter.swift
//  QuadrantTasksIOS
//
//  任务时间状态文案：今天加入、已加入 X 天、剩 X 天、今天截止、已逾期 X 天、耗时 X 天完成。
//

import Foundation

enum TaskTimeStatusFormatter {

    static func statusText(
        for task: TaskItem,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        if task.isCompleted {
            let completedDate = task.completedAt ?? task.updatedAt
            let spentDays = naturalDayDistance(
                from: task.createdAt,
                to: completedDate,
                calendar: calendar
            )

            if spentDays <= 0 {
                return "当天完成"
            } else {
                return "耗时 \(spentDays) 天完成"
            }
        }

        if let dueDate = task.dueDate {
            let remainingDays = naturalDayDistance(
                from: now,
                to: dueDate,
                calendar: calendar
            )

            if remainingDays > 0 {
                return "剩 \(remainingDays) 天"
            } else if remainingDays == 0 {
                return "今天截止"
            } else {
                return "已逾期 \(-remainingDays) 天"
            }
        }

        let joinedDays = naturalDayDistance(
            from: task.createdAt,
            to: now,
            calendar: calendar
        )

        if joinedDays <= 0 {
            return "今天加入"
        } else {
            return "已加入 \(joinedDays) 天"
        }
    }

    static func overdueDays(
        for task: TaskItem,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int? {
        guard let dueDate = task.dueDate, !task.isCompleted else {
            return nil
        }

        let remainingDays = naturalDayDistance(
            from: now,
            to: dueDate,
            calendar: calendar
        )

        guard remainingDays < 0 else {
            return nil
        }

        return -remainingDays
    }

    static func isCompletedToday(
        _ task: TaskItem,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard task.isCompleted else {
            return false
        }

        let completedDate = task.completedAt ?? task.updatedAt
        return calendar.isDate(completedDate, inSameDayAs: now)
    }

    static func isDueToday(
        _ task: TaskItem,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard let dueDate = task.dueDate, !task.isCompleted else {
            return false
        }

        return calendar.isDate(dueDate, inSameDayAs: now)
    }

    static func isDueBeforeToday(
        _ task: TaskItem,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        guard let dueDate = task.dueDate, !task.isCompleted else {
            return false
        }

        let today = calendar.startOfDay(for: now)
        let dueDay = calendar.startOfDay(for: dueDate)

        return dueDay < today
    }

    /// 按自然日计算距离，忽略时分秒。
    ///
    /// 例如：
    /// - 今天到今天 = 0
    /// - 今天到明天 = 1
    /// - 今天到昨天 = -1
    private static func naturalDayDistance(
        from start: Date,
        to end: Date,
        calendar: Calendar
    ) -> Int {
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)

        return calendar.dateComponents(
            [.day],
            from: startDay,
            to: endDay
        ).day ?? 0
    }
}

extension TaskItem {
    var timeStatusText: String {
        TaskTimeStatusFormatter.statusText(for: self)
    }
}
