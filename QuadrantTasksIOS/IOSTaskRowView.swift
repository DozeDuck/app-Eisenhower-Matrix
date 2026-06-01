import SwiftUI

struct IOSTaskRowView<Destination: View>: View {
    let task: TaskItem
    let showQuadrant: Bool
    let onToggleComplete: () -> Void
    let destination: Destination

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

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                onToggleComplete()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : task.quadrant.color)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? "标记为未完成" : "标记为已完成")

            NavigationLink {
                destination
            } label: {
                HStack(alignment: .center, spacing: 8) {
                    rowText

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }

    private var rowText: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(task.title)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(2)
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)

            if !task.notes.isEmpty {
                Text(task.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 8) {
                if let dueDate = task.dueDate {
                    Label(
                        dueDate.formatted(date: .abbreviated, time: .shortened),
                        systemImage: "calendar"
                    )
                    .foregroundStyle(task.isOverdue ? .red : .secondary)
                }

                if task.notificationEnabled {
                    Label("提醒", systemImage: "bell.fill")
                        .foregroundStyle(.orange)
                }
            }
            .font(.caption2)

            if showQuadrant {
                Text(task.quadrant.title)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(task.quadrant.color.opacity(0.15))
                    )
                    .foregroundStyle(task.quadrant.color)
            }
        }
    }
}
