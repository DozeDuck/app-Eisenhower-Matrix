//
//  IOSAddTaskView.swift
//  QuadrantTasksIOS
//
//  iOS 新建任务页。
//  支持：截止日期、本地提醒、创建时添加子任务。
//

import SwiftUI
import SwiftData

struct IOSAddTaskView: View {
    let defaultQuadrant: Quadrant

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorVisionMode) private var colorVisionMode

    @State private var title = ""
    @State private var notes = ""
    @State private var quadrant: Quadrant
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(60 * 60)
    @State private var notificationEnabled = false

    @State private var subtaskDrafts: [DraftSubtask] = []
    @State private var newSubtaskTitle = ""

    init(defaultQuadrant: Quadrant) {
        self.defaultQuadrant = defaultQuadrant
        _quadrant = State(initialValue: defaultQuadrant)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedNewSubtaskTitle: String {
        newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var quadrantColor: Color {
        quadrant.color(for: colorVisionMode)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("任务标题", text: $title)

                    TextField("备注", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("分类") {
                    Picker("所属象限", selection: $quadrant) {
                        ForEach(Quadrant.allCases) { quadrant in
                            Label(quadrant.title, systemImage: quadrant.iconName)
                                .tag(quadrant)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Label(quadrant.actionTitle, systemImage: quadrant.iconName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(quadrantColor)

                        Text(quadrant.explanation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("截止日期") {
                    Toggle("设置截止日期", isOn: $hasDueDate.animation())

                    if hasDueDate {
                        DatePicker("截止时间", selection: $dueDate)
                        Toggle("到时提醒", isOn: $notificationEnabled)
                    }
                }

                Section {
                    if subtaskDrafts.isEmpty {
                        Text("可以把一个大任务拆成多个子任务，保存后在详情页继续调整进度。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach($subtaskDrafts) { $draft in
                            HStack(spacing: 8) {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)

                                TextField("子任务标题", text: $draft.title)
                            }
                        }
                        .onDelete(perform: deleteDraftSubtasks)
                    }

                    HStack(spacing: 8) {
                        TextField("添加子任务", text: $newSubtaskTitle)
                            .submitLabel(.done)
                            .onSubmit {
                                addDraftSubtask()
                            }

                        Button {
                            addDraftSubtask()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .disabled(trimmedNewSubtaskTitle.isEmpty)
                    }
                } header: {
                    Text("子任务")
                } footer: {
                    if !subtaskDrafts.isEmpty {
                        Text("保存后，主任务进度会根据子任务进度自动计算。")
                    }
                }
            }
            .navigationTitle("新建任务")
            .navigationBarTitleDisplayMode(.inline)
            .tint(quadrantColor)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTask()
                    }
                    .disabled(trimmedTitle.isEmpty)
                }
            }
        }
    }

    private func addDraftSubtask() {
        guard !trimmedNewSubtaskTitle.isEmpty else {
            return
        }

        subtaskDrafts.append(
            DraftSubtask(title: trimmedNewSubtaskTitle)
        )

        newSubtaskTitle = ""
    }

    private func deleteDraftSubtasks(at offsets: IndexSet) {
        subtaskDrafts.remove(atOffsets: offsets)
    }

    private func saveTask() {
        let subtaskTitles = subtaskDrafts
            .map { $0.title.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        TaskViewModel(modelContext: modelContext).addTask(
            title: trimmedTitle,
            notes: notes,
            quadrant: quadrant,
            dueDate: hasDueDate ? dueDate : nil,
            notificationEnabled: hasDueDate && notificationEnabled,
            manualProgress: 0.0,
            subtaskTitles: subtaskTitles
        )

        dismiss()
    }
}

// MARK: - 新建任务时的临时子任务

private struct DraftSubtask: Identifiable {
    let id = UUID()
    var title: String
}
