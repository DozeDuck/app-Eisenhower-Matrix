//
//  IOSQuadrantMatrixCardView.swift
//  QuadrantTasksIOS
//

import SwiftUI

struct IOSQuadrantMatrixCardView: View {
    let quadrant: Quadrant
    let tasks: [TaskItem]

    @Environment(\.colorVisionMode) private var colorVisionMode
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var quadrantColor: Color {
        quadrant.color(for: colorVisionMode)
    }

    private var overdueCount: Int {
        tasks.filter(\.isOverdue).count
    }

    private var titleFont: Font {
        horizontalSizeClass == .regular
        ? .headline.weight(.semibold)
        : .subheadline.weight(.semibold)
    }

    private var actionFont: Font {
        horizontalSizeClass == .regular
        ? .caption.weight(.medium)
        : .caption2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            topBar

            VStack(alignment: .leading, spacing: 2) {
                Text(quadrant.title)
                    .font(titleFont)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(quadrant.actionTitle)
                    .font(actionFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Divider()

            taskPreviewArea
        }
        .padding(horizontalSizeClass == .regular ? 14 : 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(quadrantColor.opacity(0.25), lineWidth: 1)
        )
    }

    private var topBar: some View {
        HStack {
            Image(systemName: quadrant.iconName)
                .font(horizontalSizeClass == .regular ? .title3 : .headline)
                .foregroundStyle(quadrantColor)

            Spacer()

            HStack(spacing: 6) {
                if overdueCount > 0 {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.caption)
                        .foregroundStyle(AppColorPalette.overdueColor(for: colorVisionMode))
                }

                Text("\(tasks.count)")
                    .font(.subheadline.bold())
                    .foregroundStyle(quadrantColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(quadrantColor.opacity(0.15))
                    )
            }
        }
    }

    @ViewBuilder
    private var taskPreviewArea: some View {
        if tasks.isEmpty {
            Text("暂无任务")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: horizontalSizeClass == .regular ? 9 : 7) {
                    ForEach(tasks) { task in
                        taskPreviewRow(task)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func taskPreviewRow(_ task: TaskItem) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Circle()
                .fill(task.isOverdue ? AppColorPalette.overdueColor(for: colorVisionMode) : quadrantColor.opacity(0.75))
                .frame(width: 5, height: 5)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(horizontalSizeClass == .regular ? .caption : .caption2)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(task.timeStatusText)
                        .font(.system(size: horizontalSizeClass == .regular ? 10 : 9))
                        .foregroundStyle(task.isOverdue ? AppColorPalette.overdueColor(for: colorVisionMode) : .secondary)
                        .lineLimit(1)

                    Text("·")
                        .font(.system(size: horizontalSizeClass == .regular ? 10 : 9))
                        .foregroundStyle(.secondary)

                    Text("\(task.progressPercent)%")
                        .font(.system(size: horizontalSizeClass == .regular ? 10 : 9).monospacedDigit())
                        .foregroundStyle(quadrantColor)
                }
            }
        }
    }
}
