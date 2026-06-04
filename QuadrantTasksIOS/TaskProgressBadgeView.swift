//
//  TaskProgressBadgeView.swift
//  QuadrantTasksIOS
//
//  任务进度小徽章。用于任务行、象限卡片、今日页面。
//  主视图中只展示简洁百分比，不放完整 Slider。
//

import SwiftUI

struct TaskProgressBadgeView: View {
    let task: TaskItem
    var compact: Bool = false

    @Environment(\.colorVisionMode) private var colorVisionMode

    private var progress: Double {
        task.progressFraction
    }

    private var percentText: String {
        "\(task.progressPercent)%"
    }

    /// 关键修复：
    /// 不再让已完成任务固定为绿色。
    /// 已完成任务仍使用所属象限颜色，这样色盲模式下也会同步变化。
    private var tintColor: Color {
        task.quadrant.color(for: colorVisionMode)
    }

    var body: some View {
        HStack(spacing: compact ? 4 : 6) {
            progressRing

            if !compact {
                Text(percentText)
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(tintColor)
            }
        }
        .padding(.horizontal, compact ? 5 : 7)
        .padding(.vertical, compact ? 3 : 4)
        .background(
            Capsule()
                .fill(tintColor.opacity(task.isCompleted ? 0.16 : 0.12))
        )
        .overlay(
            Capsule()
                .stroke(tintColor.opacity(task.isCompleted ? 0.25 : 0.0), lineWidth: 1)
        )
        .accessibilityLabel("完成进度 \(percentText)")
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(tintColor.opacity(0.22), lineWidth: compact ? 2 : 2.5)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    tintColor,
                    style: StrokeStyle(
                        lineWidth: compact ? 2 : 2.5,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            if compact {
                if task.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(tintColor)
                } else {
                    Text("\(task.progressPercent)")
                        .font(.system(size: 7, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(tintColor)
                }
            }
        }
        .frame(width: compact ? 20 : 24, height: compact ? 20 : 24)
    }
}
