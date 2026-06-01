//
//  MacTaskRow.swift
//  QuadrantTasks (macOS)
//
//  Mac 风格任务行。和 iOS 版的区别:
//   - 完成圈是真正的可点击 Button(单击切换完成状态)
//   - 整行点击 = 选中(高亮),不导航,而是更新 Inspector
//   - 鼠标悬停高亮(.help / .onHover 可后续扩展)
//

import SwiftUI

struct MacTaskRow: View {
    let task: TaskItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleComplete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            // 可点击的完成圈(单独按钮,不触发整行选中)
            Button(action: onToggleComplete) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : task.quadrant.color)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .help(task.isCompleted ? "标为未完成" : "标为已完成")

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if !task.notes.isEmpty || task.dueDate != nil || task.notificationEnabled {
                    HStack(spacing: 10) {
                        if !task.notes.isEmpty {
                            Image(systemName: "note.text")
                                .foregroundStyle(.secondary)
                        }
                        if let due = task.dueDate {
                            HStack(spacing: 3) {
                                Image(systemName: "calendar")
                                Text(due.formatted(date: .abbreviated, time: .shortened))
                            }
                            .foregroundStyle(task.isOverdue ? .red : .secondary)
                        }
                        if task.notificationEnabled {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                    .font(.caption2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(rowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovering = $0 }
    }

    private var rowBackground: Color {
        if isSelected {
            return Color.accentColor.opacity(0.18)
        } else if isHovering {
            return Color.primary.opacity(0.05)
        } else {
            return .clear
        }
    }
}
