//
//  IOSTaskRowView.swift
//  QuadrantTasksIOS
//

import SwiftUI

struct IOSTaskRowView<Destination: View>: View {
    let task: TaskItem
    let showQuadrant: Bool
    let onToggleComplete: () -> Void
    let destination: Destination

    @Environment(\.colorVisionMode) private var colorVisionMode

    init(
        task: TaskItem,
        showQuadrant: Bool,
        onToggleComplete: @escaping () -> Void,
        @ViewBuilder destination: () -> Destination
    ) {
        self.task = task
        self.showQuadrant = showQuadrant
        self.onToggleComplete = onToggleComplete
        self.destination = destination()
    }

    private var quadrantColor: Color {
        task.quadrant.color(for: colorVisionMode)
    }

    private var timeStatusColor: Color {
        if task.isOverdue {
            return AppColorPalette.overdueColor(for: colorVisionMode)
        }

        return .secondary
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            completeButton

            NavigationLink {
                destination
            } label: {
                rowContent
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .overdueHighlight(for: task)
    }

    private var completeButton: some View {
        Button {
            onToggleComplete()
        } label: {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                // 关键修复：
                // 已完成状态不再固定为绿色，而是使用象限颜色。
                .foregroundStyle(quadrantColor)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(task.isCompleted ? "标记为未完成" : "标记为已完成")
    }

    private var rowContent: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                titleLine
                notesLine
                metaLine
                quadrantTagIfNeeded
            }

            Spacer(minLength: 8)

            TaskProgressBadgeView(task: task, compact: true)
        }
        .contentShape(Rectangle())
    }

    private var titleLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if task.isOverdue {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(AppColorPalette.overdueColor(for: colorVisionMode))
            }

            Text(task.title)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(2)
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)
        }
    }

    @ViewBuilder
    private var notesLine: some View {
        if !task.notes.isEmpty {
            Text(task.notes)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var metaLine: some View {
        HStack(spacing: 8) {
            Label(task.timeStatusText, systemImage: task.isOverdue ? "clock.badge.exclamationmark" : "clock")
                .foregroundStyle(timeStatusColor)

            if task.notificationEnabled {
                Label("提醒", systemImage: "bell.fill")
                    .foregroundStyle(.orange)
            }

            if task.hasSubtasks {
                Label("\(task.sortedSubtasks.filter(\.isCompleted).count)/\(task.sortedSubtasks.count)", systemImage: "checklist")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption2)
        .lineLimit(1)
    }

    @ViewBuilder
    private var quadrantTagIfNeeded: some View {
        if showQuadrant {
            HStack(spacing: 6) {
                Image(systemName: task.quadrant.iconName)

                Text(task.quadrant.title)
            }
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(quadrantColor.opacity(0.15))
            )
            .foregroundStyle(quadrantColor)
        }
    }
}
