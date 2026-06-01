//
//  NotificationService.swift
//  QuadrantTasks
//
//  本地通知封装。基于 UserNotifications,无需后端。
//
//  使用方式:
//      NotificationService.shared.scheduleIfPossible(for: task)
//      NotificationService.shared.cancelNotification(for: task)
//
//  首次调度时会自动向用户请求授权。
//

import Foundation
import UserNotifications

final class NotificationService {

    static let shared = NotificationService()
    private init() {}

    // MARK: - 授权

    /// 请求通知授权(已授权则直接 true,已拒绝则 false)
    func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    DispatchQueue.main.async { completion(granted) }
                }
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async { completion(true) }
            case .denied:
                DispatchQueue.main.async { completion(false) }
            @unknown default:
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    // MARK: - 调度

    /// 尝试为任务调度通知;若未授权会先请求授权。
    func scheduleIfPossible(for task: TaskItem) {
        requestAuthorizationIfNeeded { [weak self] granted in
            guard granted else { return }
            self?.scheduleNotification(for: task)
        }
    }

    /// 实际调度(假设已授权)。
    private func scheduleNotification(for task: TaskItem) {
        guard let dueDate = task.dueDate, dueDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = task.title
        content.body  = "【\(task.quadrant.title)】任务到期提醒"
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: dueDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ 通知调度失败: \(error)")
            }
        }
    }

    // MARK: - 取消

    func cancelNotification(for task: TaskItem) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }
}
