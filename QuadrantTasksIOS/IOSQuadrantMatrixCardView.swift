import SwiftUI

struct IOSQuadrantMatrixCardView: View {
    let quadrant: Quadrant
    let tasks: [TaskItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            topBar

            VStack(alignment: .leading, spacing: 2) {
                Text(quadrant.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(quadrant.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Divider()

            taskPreview

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(quadrant.color.opacity(0.25), lineWidth: 1)
        )
    }

    private var topBar: some View {
        HStack {
            Image(systemName: quadrant.iconName)
                .font(.headline)
                .foregroundStyle(quadrant.color)

            Spacer()

            Text("\(tasks.count)")
                .font(.subheadline.bold())
                .foregroundStyle(quadrant.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(quadrant.color.opacity(0.15))
                )
        }
    }

    @ViewBuilder
    private var taskPreview: some View {
        if tasks.isEmpty {
            Text("暂无任务")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        } else {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(Array(tasks.prefix(2))) { task in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(task.isOverdue ? Color.red : quadrant.color.opacity(0.75))
                            .frame(width: 5, height: 5)

                        Text(task.title)
                            .font(.caption2)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }

                if tasks.count > 2 {
                    Text("还有 \(tasks.count - 2) 项")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
