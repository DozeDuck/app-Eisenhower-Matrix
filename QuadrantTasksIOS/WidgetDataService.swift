import Foundation
import SwiftData
import WidgetKit

enum WidgetDataService {
    static func refreshSnapshot(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<TaskItem>(
                sortBy: [
                    SortDescriptor(\.updatedAt, order: .reverse)
                ]
            )

            let allTasks = try context.fetch(descriptor)
            let snapshots = Quadrant.allCases.map { quadrant in
                makeSnapshot(for: quadrant, from: allTasks)
            }

            let payload = QuadrantWidgetPayload(
                updatedAt: Date(),
                snapshots: snapshots
            )

            WidgetSnapshotStore.save(payload)

            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("⚠️ 刷新 Widget 快照失败: \(error)")
        }
    }

    private static func makeSnapshot(
        for quadrant: Quadrant,
        from allTasks: [TaskItem]
    ) -> QuadrantWidgetSnapshot {
        let pendingTasks = allTasks
            .filter { $0.quadrant == quadrant && !$0.isCompleted }
            .sorted {
                let lhs = $0.dueDate ?? .distantFuture
                let rhs = $1.dueDate ?? .distantFuture

                if lhs == rhs {
                    return $0.updatedAt > $1.updatedAt
                }

                return lhs < rhs
            }

        let previewTasks = pendingTasks.prefix(4).map { task in
            QuadrantWidgetTask(
                id: task.id.uuidString,
                title: task.title,
                dueDateText: task.dueDate?.formatted(date: .abbreviated, time: .omitted),
                isOverdue: task.isOverdue
            )
        }

        return QuadrantWidgetSnapshot(
            quadrantRaw: quadrant.rawValue,
            title: quadrant.title,
            subtitle: quadrant.subtitle,
            iconName: quadrant.iconName,
            colorHex: colorHex(for: quadrant),
            pendingCount: pendingTasks.count,
            tasks: Array(previewTasks)
        )
    }

    private static func colorHex(for quadrant: Quadrant) -> String {
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
}
