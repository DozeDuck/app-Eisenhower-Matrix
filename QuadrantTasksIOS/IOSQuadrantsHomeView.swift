//
//  IOSQuadrantsHomeView.swift
//  QuadrantTasksIOS
//

import SwiftUI
import SwiftData

struct IOSQuadrantsHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorVisionMode) private var colorVisionMode

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
        IOSHomeLayoutStyle(rawValue: layoutStyleRaw) ?? .matrix
    }

    private var pendingCount: Int {
        allTasks.filter { !$0.isCompleted }.count
    }

    private var overdueCount: Int {
        allTasks.filter { $0.isOverdue }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                quadrantSummaryStrip

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
        .navigationTitle(AppInfo.displayName)
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
                .environment(\.colorVisionMode, colorVisionMode)
        }
        .onAppear {
            refreshWidgetSnapshot()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今天先做什么？")
                .font(.title2.bold())

            Text("从最值得投入的一件事开始，用四象限方法整理任务优先级。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Label("\(pendingCount) 项未完成", systemImage: "circle")

                Text("·")

                Label("四象限矩阵", systemImage: "square.grid.2x2")

                if colorVisionMode == .colorBlindSafe {
                    Text("·")
                    Label("色盲友好", systemImage: "eye")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quadrantSummaryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Quadrant.allCases) { quadrant in
                    let count = pendingTasks(for: quadrant).count

                    summaryIconPill(
                        systemImage: quadrant.iconName,
                        value: count,
                        color: quadrant.color(for: colorVisionMode),
                        accessibilityLabel: "\(quadrant.title)，\(count) 项"
                    )
                }

                overdueTextPill
            }
            .padding(.vertical, 1)
        }
    }

    private func summaryIconPill(
        systemImage: String,
        value: Int,
        color: Color,
        accessibilityLabel: String
    ) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))

            Text("\(value)")
                .font(.caption.weight(.bold))
                .monospacedDigit()
        }
        .foregroundStyle(color)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(color.opacity(0.13))
        )
        .accessibilityLabel(accessibilityLabel)
    }

    private var overdueTextPill: some View {
        let color = AppColorPalette.overdueColor(for: colorVisionMode)

        return HStack(spacing: 6) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.caption.weight(.semibold))

            Text("逾期")
                .font(.caption.weight(.semibold))

            Text("\(overdueCount)")
                .font(.caption.weight(.bold))
                .monospacedDigit()
        }
        .foregroundStyle(color)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(color.opacity(0.13))
        )
        .accessibilityLabel("逾期任务，\(overdueCount) 项")
    }

    private var layoutToggleButton: some View {
        Button {
            toggleLayoutStyle()
        } label: {
            Image(systemName: layoutStyle == .list ? "square.grid.2x2" : "rectangle.grid.1x2")
                .font(.title3)
        }
        .accessibilityLabel(layoutStyle == .list ? "切换为四象限矩阵" : "切换为一列列表")
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
            LazyVGrid(columns: matrixColumns, spacing: 12) {
                ForEach(Quadrant.allCases) { quadrant in
                    NavigationLink {
                        IOSQuadrantDetailView(quadrant: quadrant)
                    } label: {
                        IOSQuadrantMatrixCardView(
                            quadrant: quadrant,
                            tasks: pendingTasks(for: quadrant)
                        )
                        .frame(height: 190)
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

    private func refreshWidgetSnapshot() {
        #if os(iOS)
        WidgetDataService.refreshSnapshot(context: modelContext)
        #endif
    }
}
