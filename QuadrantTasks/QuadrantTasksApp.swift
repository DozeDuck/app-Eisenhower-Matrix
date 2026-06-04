//
//  QuadrantTasksApp.swift
//  QuadrantTasks (macOS)
//
//  Mac 版入口。和 iOS 版的差异:
//   - 设置窗口最小尺寸
//   - 注入 AppCommands(用于菜单栏命令与主视图通信)
//   - 替换/扩展系统菜单(File → 新建任务、View → 显示已完成、Help)
//

import SwiftUI
import SwiftData

@main
struct QuadrantTasksApp: App {

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TaskItem.self,
            SubTask.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("无法创建 ModelContainer: \(error)")
        }
    }()

    /// 跨视图共享的命令状态(菜单栏 → 主视图)
    @State private var commands = AppCommands()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(commands)
                .frame(minWidth: 880, minHeight: 600)
        }
        .modelContainer(sharedModelContainer)
        // macOS 窗口风格:统一标题栏
        .windowToolbarStyle(.unified)
        // 菜单栏自定义
        .commands {

            // File → 新建任务  (⌘N)
            CommandGroup(replacing: .newItem) {
                Button("新建任务…") {
                    commands.requestNewTask(in: .importantUrgent)
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            // View → 显示已完成任务  (⇧⌘H)
            CommandGroup(after: .toolbar) {
                Toggle("显示已完成任务", isOn: $commands.showCompleted)
                    .keyboardShortcut("h", modifiers: [.command, .shift])
                Divider()
                Picker("默认排序", selection: $commands.sortOption) {
                    ForEach(AppCommands.SortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }

            // Help → 替换为我们自己的链接
            CommandGroup(replacing: .help) {
                Link("干点正事儿介绍",
                     destination: URL(string: "https://zh.wikipedia.org/wiki/%E6%97%B6%E9%97%B4%E7%AE%A1%E7%90%86")!)
            }
        }
    }
}
