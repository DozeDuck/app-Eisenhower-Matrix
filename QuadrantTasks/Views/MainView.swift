//
//  MainView.swift
//  QuadrantTasks (macOS)
//
//  v2 改动:
//   - 移除外层 ScrollView,改用 Grid 平铺四个象限,各占窗口 1/4
//     -> 每个 QuadrantPanel 拿到确定的高度,内部 ScrollView 才会真正滚动
//     -> 窗口尺寸变化时,四个面板自适应跟随
//   - 增加"历史"工具栏按钮 -> 弹出 HistoryView 管理已完成任务
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppCommands.self) private var commands

    @Query(sort: \TaskItem.updatedAt, order: .reverse) private var allTasks: [TaskItem]

    @State private var selectedTaskID: UUID?
    @State private var inspectorPresented: Bool = false
    @State private var showingHistory: Bool = false

    private var selectedTask: TaskItem? {
        guard let id = selectedTaskID else { return nil }
        return allTasks.first(where: { $0.id == id })
    }

    private var totalPending: Int {
        allTasks.filter { !$0.isCompleted }.count
    }

    var body: some View {
        @Bindable var commands = commands

        // Grid 直接铺满窗口,不再套 ScrollView。
        Grid(horizontalSpacing: 14, verticalSpacing: 14) {
            GridRow {
                QuadrantPanel(quadrant: .importantUrgent,
                              selectedTaskID: $selectedTaskID)
                QuadrantPanel(quadrant: .importantNotUrgent,
                              selectedTaskID: $selectedTaskID)
            }
            GridRow {
                QuadrantPanel(quadrant: .notImportantUrgent,
                              selectedTaskID: $selectedTaskID)
                QuadrantPanel(quadrant: .notImportantNotUrgent,
                              selectedTaskID: $selectedTaskID)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .navigationTitle("干点正事儿")
        .navigationSubtitle("\(totalPending) 项未完成")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    showingHistory = true
                } label: {
                    Label("历史", systemImage: "clock.arrow.circlepath")
                }
                .help("查看并管理已完成的任务  ⇧⌘Y")
                .keyboardShortcut("y", modifiers: [.command, .shift])

                Toggle(isOn: $commands.showCompleted) {
                    Label("已完成", systemImage: "checkmark.circle")
                }
                .help("在每个象限内显示已完成项  ⇧⌘H")

                Menu {
                    Picker("排序", selection: $commands.sortOption) {
                        ForEach(AppCommands.SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    Label("排序", systemImage: "arrow.up.arrow.down")
                }

                Button {
                    inspectorPresented.toggle()
                } label: {
                    Label("详情", systemImage: "sidebar.trailing")
                }
                .help("打开/关闭右侧详情面板")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    commands.requestNewTask(in: .importantUrgent)
                } label: {
                    Label("新建任务", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
                .help("新建任务  ⌘N")
            }
        }
        .sheet(isPresented: $commands.isAddingTask) {
            AddTaskView(defaultQuadrant: commands.addingTaskQuadrant)
                .frame(minWidth: 480, minHeight: 460)
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView()
                .frame(minWidth: 640, idealWidth: 760, minHeight: 480, idealHeight: 560)
        }
        .inspector(isPresented: $inspectorPresented) {
            Group {
                if let task = selectedTask {
                    TaskDetailView(task: task)
                } else {
                    ContentUnavailableView(
                        "未选择任务",
                        systemImage: "square.dashed",
                        description: Text("点击任意任务以查看详情")
                    )
                }
            }
            .inspectorColumnWidth(min: 300, ideal: 360, max: 500)
        }
        .onChange(of: selectedTaskID) { _, newValue in
            if newValue != nil { inspectorPresented = true }
        }
    }
}
