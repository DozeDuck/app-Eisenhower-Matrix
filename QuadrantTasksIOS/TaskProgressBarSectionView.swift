//
//  TaskProgressBarSectionView.swift
//  QuadrantTasksIOS
//
//  任务详情页中的进度区域。
//  无子任务时显示主任务手动进度条；有子任务时显示只读综合进度。
//

import SwiftUI
import SwiftData

struct TaskProgressBarSectionView: View {
    @Bindable var task: TaskItem

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorVisionMode) private var colorVisionMode

    @State private var draftProgress: Double = 0.0
    @State private var isEditingProgress = false

    private var tintColor: Color {
        task.quadrant.color(for: colorVisionMode)
    }

    var body: some View {
        Section("完成进度") {
            VStack(alignment: .leading, spacing: 12) {
                summaryRow

                ProgressView(value: task.progressFraction)
                    .tint(tintColor)

                if task.hasSubtasks {
                    subtaskManagedNotice
                } else {
                    manualProgressSlider
                    quickProgressButtons
                }

                if task.progressPercent == 100 && !task.isCompleted {
                    completionHint
                }
            }
            .padding(.vertical, 4)
        }
        .onAppear {
            draftProgress = task.normalizedManualProgress
        }
        .onChange(of: task.manualProgress) { _, newValue in
            guard !isEditingProgress else { return }
            draftProgress = min(max(newValue, 0.0), 1.0)
        }
    }

    private var summaryRow: some View {
        HStack {
            Label("当前进度", systemImage: task.hasSubtasks ? "checklist" : "slider.horizontal.3")
                .font(.subheadline.weight(.medium))

            Spacer()

            Text("\(task.progressPercent)%")
                .font(.headline.monospacedDigit())
                .foregroundStyle(tintColor)
        }
    }

    private var manualProgressSlider: some View {
        VStack(alignment: .leading, spacing: 6) {
            Slider(
                value: Binding(
                    get: { draftProgress },
                    set: { draftProgress = min(max($0, 0.0), 1.0) }
                ),
                in: 0...1,
                step: 0.01,
                onEditingChanged: { editing in
                    isEditingProgress = editing

                    if !editing {
                        commitManualProgress()
                    }
                }
            )
            .tint(tintColor)

            Text("拖动进度条记录阶段性进展。进度达到 100% 后，仍需要你手动勾选任务完成。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var quickProgressButtons: some View {
        HStack(spacing: 8) {
            quickButton("0%", value: 0.0)
            quickButton("25%", value: 0.25)
            quickButton("50%", value: 0.5)
            quickButton("75%", value: 0.75)
            quickButton("100%", value: 1.0)
        }
    }

    private func quickButton(_ title: String, value: Double) -> some View {
        Button {
            draftProgress = value
            commitManualProgress()
        } label: {
            Text(title)
                .font(.caption2.weight(.semibold))
                .monospacedDigit()
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(tintColor.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(tintColor)
    }

    private var subtaskManagedNotice: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("该任务包含 \(task.subtasks.count) 个子任务", systemImage: "list.bullet.indent")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("主任务进度由子任务进度自动计算。如需调整进度，请修改下方每个子任务的完成度。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var completionHint: some View {
        Label("进度已达到 100%。如任务确实完成，请点击完成按钮进行归档。", systemImage: "info.circle")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }

    private func commitManualProgress() {
        TaskViewModel(modelContext: modelContext)
            .updateManualProgress(task, progress: draftProgress)
    }
}
