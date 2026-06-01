import SwiftUI

struct IOSQuadrantCardView: View {
    let quadrant: Quadrant
    let tasks: [TaskItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: quadrant.iconName)
                    .font(.title2)
                    .foregroundStyle(quadrant.color)

                VStack(alignment: .leading, spacing: 3) {
                    Text(quadrant.title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(quadrant.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(tasks.count)")
                    .font(.headline)
                    .foregroundStyle(quadrant.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(quadrant.color.opacity(0.15))
                    )
            }

            if tasks.isEmpty {
                Text("暂无未完成任务")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(tasks.prefix(3))) { task in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(task.isOverdue ? Color.red : quadrant.color.opacity(0.7))
                                .frame(width: 7, height: 7)

                            Text(task.title)
                                .font(.subheadline)
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(quadrant.color.opacity(0.25), lineWidth: 1)
        )
    }
}
