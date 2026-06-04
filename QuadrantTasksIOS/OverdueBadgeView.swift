//
//  OverdueBadgeView.swift
//  QuadrantTasksIOS
//
//  逾期任务标识。
//  使用高对比强调色 + 图标 + 文案，不只依赖颜色表达状态。
//

import SwiftUI

struct OverdueBadgeView: View {
    let task: TaskItem
    var compact: Bool = false

    @Environment(\.colorVisionMode) private var colorVisionMode

    private var overdueDays: Int? {
        TaskTimeStatusFormatter.overdueDays(for: task)
    }

    private var overdueColor: Color {
        AppColorPalette.overdueColor(for: colorVisionMode)
    }

    var body: some View {
        if let overdueDays {
            Label {
                Text(compact ? "\(overdueDays)天逾期" : "已逾期 \(overdueDays) 天")
                    .font(.caption2.weight(.semibold))
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2.weight(.bold))
            }
            .foregroundStyle(overdueColor)
            .padding(.horizontal, compact ? 6 : 8)
            .padding(.vertical, compact ? 3 : 4)
            .background(
                Capsule()
                    .fill(overdueColor.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(overdueColor.opacity(0.35), lineWidth: 1)
            )
            .accessibilityLabel("任务已逾期 \(overdueDays) 天")
        }
    }
}

// MARK: - 逾期行高亮修饰器

struct OverdueHighlightModifier: ViewModifier {
    let task: TaskItem

    @Environment(\.colorVisionMode) private var colorVisionMode

    private var isOverdue: Bool {
        task.isOverdue
    }

    private var overdueColor: Color {
        AppColorPalette.overdueColor(for: colorVisionMode)
    }

    func body(content: Content) -> some View {
        content
            .padding(.leading, isOverdue ? 8 : 0)
            .overlay(alignment: .leading) {
                if isOverdue {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(overdueColor)
                        .frame(width: 4)
                        .padding(.vertical, 6)
                }
            }
            .background {
                if isOverdue {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(overdueColor.opacity(0.06))
                }
            }
            .overlay {
                if isOverdue {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(overdueColor.opacity(0.22), lineWidth: 1)
                }
            }
    }
}

extension View {
    func overdueHighlight(for task: TaskItem) -> some View {
        modifier(OverdueHighlightModifier(task: task))
    }
}
