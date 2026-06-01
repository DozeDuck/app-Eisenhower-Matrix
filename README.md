# QuadrantTasks (macOS 版)

基于艾森豪威尔矩阵的 Mac 桌面任务管理工具。
SwiftUI + SwiftData + MVVM,macOS 14+。

## 与 iOS 版的关系

数据层完全复用 —— 这是按"原生 Mac 体验"重新设计 UI 的版本,不是简单移植。

| 共享 | 重写 |
|---|---|
| `Quadrant.swift` | `QuadrantTasksApp.swift`(窗口/菜单) |
| `TaskItem.swift` | `MainView.swift`(替代 HomeView) |
| `TaskViewModel.swift` | `QuadrantPanel.swift` |
| `NotificationService.swift` | `MacTaskRow.swift` |
| | `AddTaskView.swift`(适配工具栏) |
| | `TaskDetailView.swift`(适配 Inspector) |

## Mac 版的核心交互

- **2×2 永远在视线里** —— 四个象限作为面板同时展开,屏幕足够大不再需要"先看预览再点开"
- **右侧 Inspector** —— 点击任意任务即弹出详情面板,可即时编辑,无需离开主视图
- **拖拽迁移** —— 在任意面板按住任务行拖到其他面板,自动改变所属象限
- **键盘友好**
  - `⌘N` 新建任务
  - `⇧⌘H` 显示/隐藏已完成
  - `⌘W` 关闭窗口
  - `Esc` 关闭表单
  - `⌘Return` 在新建表单中保存
- **右键菜单** —— 标完成、移动到其他象限、删除
- **菜单栏命令** —— File、View、Help 自定义条目

## 在 Xcode 中创建并运行

1. Xcode → **File → New → Project → macOS → App**
2. 配置:
   - Product Name: `QuadrantTasks`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData**(或 None)
   - Minimum Deployments: **macOS 14.0**
3. 删除 Xcode 默认生成的 `QuadrantTasksApp.swift` 和 `ContentView.swift`
4. 把本目录下所有 `.swift` 文件按目录结构拖入 Xcode 项目(勾选 Copy items if needed,Target 勾选 QuadrantTasks)
5. **Signing & Capabilities**:Team 选择你的 Apple ID(免费即可,本机调试不签名也行)
6. 按 ▶︎ Run

### 关于沙盒与通知

- macOS App 默认带 App Sandbox。SwiftData 数据会写入沙盒容器,无需额外设置。
- 第一次添加带提醒的任务时,系统会弹出通知授权弹窗;授权后即可。
- 如果通知不弹出,确认 **系统设置 → 通知** 中 QuadrantTasks 是开启状态。

## 与 iOS 项目合并为多平台项目(可选)

如果想用一个 Xcode 工程同时构建 iOS + Mac:

1. 在 Xcode iOS 项目中:File → New → Target → **macOS App**
2. 让 Models / ViewModels / Services 同时勾选两个 Target(在每个文件的 Target Membership 里勾)
3. View 层根据平台条件编译:
   ```swift
   #if os(iOS)
       HomeView()
   #else
       MainView()
   #endif
   ```
4. 调整工具栏 placement 为跨平台语义占位符(`.cancellationAction`、`.confirmationAction`、`.primaryAction`)

## 后续可扩展

| 功能 | 实现要点 |
|---|---|
| **菜单栏常驻图标** | `MenuBarExtra` Scene,显示重要且紧急前 3 条 |
| **iCloud 同步** | ModelConfiguration 加 `cloudKitDatabase: .private` |
| **多窗口** | `WindowGroup(for: Quadrant.self)`,可单独打开一个象限 |
| **Spotlight 集成** | CoreSpotlight,任务可被系统搜索 |
| **快捷指令** | AppIntent + 自动化(在 Mac 上也能用) |
| **Stage Manager 友好** | 当前已是普通 WindowGroup,本就兼容 |
