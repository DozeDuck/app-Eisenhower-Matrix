import SwiftUI
import SwiftData

struct IOSQuadrantsHomeView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \TaskItem.updatedAt, order: .reverse)
    private var allTasks: [TaskItem]

    @AppStorage(IOSHomeLayoutStyle.storageKey)
    private var layoutStyleRaw = IOSHomeLayoutStyle.list.rawValue

    @State private var showingAddTask = false

    private let matrixColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var layoutStyle: IOSHomeLayoutStyle {
        IOSHomeLayoutStyle(rawValue: layoutStyleRaw) ?? .list
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                switch layoutStyle {
                case .list:
                    listLayout

                case .matrix:
                    matrixLayout
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("森豪威尔矩阵")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                layoutToggleButton

                Button {
                    showingAddTask = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("新建任务")
            }
        }
        .sheet(isPresented: $showingAddTask) {
            IOSAddTaskView(defaultQuadrant: .importantUrgent)
        }
        .onAppear {
            #if os(iOS)
            WidgetDataService.refreshSnapshot(context: modelContext)
            #endif
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今天应该先做什么？")
                .font(.title2.bold())

            Text("把任务按重要性和紧急性分类，先处理真正关键的事情。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Label(
                    "\(allTasks.filter { !$0.isCompleted }.count) 项未完成",
                    systemImage: "circle"
                )

                Text("·")

                Label(
                    layoutStyle.title,
                    systemImage: layoutStyle.systemImage
                )
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var layoutToggleButton: some View {
        Button {
            toggleLayoutStyle()
        } label: {
            Image(systemName: layoutStyle == .list ? "square.grid.2x2" : "rectangle.grid.1x2")
                .font(.title3)
        }
        .accessibilityLabel(layoutStyle == .list ? "切换为四象限矩阵" : "切换为一列列表")
        .help(layoutStyle == .list ? "切换为四象限矩阵" : "切换为一列列表")
    }

    private var listLayout: some View {
        VStack(spacing: 16) {
            ForEach(Quadrant.allCases) { quadrant in
                NavigationLink {
                    IOSQuadrantDetailView(quadrant: quadrant)
                } label: {
                    IOSQuadrantCardView(
                        quadrant: quadrant,
                        tasks: pendingTasks(for: quadrant)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var matrixLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("四象限视图")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            LazyVGrid(columns: matrixColumns, spacing: 12) {
                ForEach(Quadrant.allCases) { quadrant in
                    NavigationLink {
                        IOSQuadrantDetailView(quadrant: quadrant)
                    } label: {
                        IOSQuadrantMatrixCardView(
                            quadrant: quadrant,
                            tasks: pendingTasks(for: quadrant)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("提示：点击任一象限进入任务列表。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
    }

    private func toggleLayoutStyle() {
        withAnimation(.easeInOut(duration: 0.2)) {
            switch layoutStyle {
            case .list:
                layoutStyleRaw = IOSHomeLayoutStyle.matrix.rawValue

            case .matrix:
                layoutStyleRaw = IOSHomeLayoutStyle.list.rawValue
            }
        }
    }

    private func pendingTasks(for quadrant: Quadrant) -> [TaskItem] {
        allTasks
            .filter { $0.quadrant == quadrant && !$0.isCompleted }
            .sorted {
                let lhs = $0.dueDate ?? .distantFuture
                let rhs = $1.dueDate ?? .distantFuture

                if lhs == rhs {
                    return $0.updatedAt > $1.updatedAt
                }

                return lhs < rhs
            }
    }
}
