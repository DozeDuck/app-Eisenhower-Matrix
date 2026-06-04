//
//  IOSQuadrantCardView.swift
//  QuadrantTasksIOS
//
//  首页列表模式下的象限卡片。
//  接入：色盲模式、任务进度、时间状态、逾期标识。
//

import SwiftUI

struct IOSQuadrantCardView: View {
    let quadrant: Quadrant
    let tasks: [TaskItem]

    @Environment(\.colorVisionMode) private var colorVisionMode

    private var quadrantColor: Color {
        quadrant.color(for: colorVisionMode)
    }

    private var overdueCount: Int {
        tasks.filter(\.isOverdue).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if tasks.isEmpty {
                emptyState
            } else {
                taskPreview
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(quadrantColor.opacity(0.22), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(alignment: .top) {
            Image(systemName: quadrant.iconName)
                .font(.title2)
                .foregroundStyle(quadrantColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(quadrant.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(quadrant.actionTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text("\(tasks.count)")
                    .font(.headline)
                    .foregroundStyle(quadrantColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(quadrantColor.opacity(0.15))
                    )

                if overdueCount > 0 {
                    Label("\(overdueCount)", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColorPalette.overdueColor(for: colorVisionMode))
                }
            }
        }
    }

    private var emptyState: some View {
        Text("暂无未完成任务")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.vertical, 4)
    }

    private var taskPreview: some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(Array(tasks.prefix(3))) { task in
                taskPreviewRow(task)
            }

            if tasks.count > 3 {
                Text("还有 \(tasks.count - 3) 项任务")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
    }

    private func taskPreviewRow(_ task: TaskItem) -> some View {
        HStack(alignment: .center, spacing: 8) {
            statusDot(for: task)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(task.timeStatusText)
                        .font(.caption2)
                        .foregroundStyle(task.isOverdue ? AppColorPalette.overdueColor(for: colorVisionMode) : .secondary)

                    if task.hasSubtasks {
                        Label("\(task.sortedSubtasks.filter(\.isCompleted).count)/\(task.sortedSubtasks.count)", systemImage: "checklist")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 8)

            TaskProgressBadgeView(task: task, compact: true)
        }
        .padding(.vertical, 2)
    }

    private func statusDot(for task: TaskItem) -> some View {
        Circle()
            .fill(task.isOverdue ? AppColorPalette.overdueColor(for: colorVisionMode) : quadrantColor.opacity(0.75))
            .frame(width: 7, height: 7)
            .overlay {
                if task.isOverdue {
                    Circle()
                        .stroke(AppColorPalette.overdueColor(for: colorVisionMode).opacity(0.4), lineWidth: 3)
                }
            }
    }
}
