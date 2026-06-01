//
//  AddTaskView.swift
//  QuadrantTasks (macOS)
//
//  以 sheet 形式呈现。和 iOS 版的差异:
//   - 工具栏 placement 改成 .cancellationAction / .confirmationAction
//     (跨平台语义占位符,iOS 与 macOS 都能正确显示)
//   - 显式 frame,Mac sheet 需要尺寸
//   - 用 Picker(.menu) 替代 NavigationLink 风格
//   - ⌘Return = 保存,Esc = 取消(系统自动)
//

import SwiftUI
import SwiftData

struct AddTaskView: View {
    let defaultQuadrant: Quadrant

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var quadrant: Quadrant
    @State private var hasDueDate = false
    @State private var dueDate = Date().addingTimeInterval(60 * 60)
    @State private var notificationEnabled = false

    init(defaultQuadrant: Quadrant) {
        self.defaultQuadrant = defaultQuadrant
        _quadrant = State(initialValue: defaultQuadrant)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 顶部条形
            HStack {
                Text("新建任务")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Divider()

            Form {
                Section("基本信息") {
                    TextField("任务标题", text: $title)
                        .textFieldStyle(.roundedBorder)
                    TextField("备注(可选)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.roundedBorder)
                }

                Section("分类") {
                    Picker("所属象限", selection: $quadrant) {
                        ForEach(Quadrant.allCases) { q in
                            Label(q.title, systemImage: q.iconName).tag(q)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("截止日期") {
                    Toggle("设置截止日期", isOn: $hasDueDate.animation())
                    if hasDueDate {
                        DatePicker("截止时间", selection: $dueDate)
                            .datePickerStyle(.compact)
                        Toggle("到时提醒", isOn: $notificationEnabled)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)

            Divider()

            // 底部按钮条:Mac 习惯把 Cancel/OK 放窗口右下角
            HStack {
                Spacer()
                Button("取消") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("保存") { saveTask() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(trimmedTitle.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
    }

    private func saveTask() {
        TaskViewModel(modelContext: modelContext).addTask(
            title: trimmedTitle,
            notes: notes,
            quadrant: quadrant,
            dueDate: hasDueDate ? dueDate : nil,
            notificationEnabled: hasDueDate && notificationEnabled
        )
        dismiss()
    }
}
