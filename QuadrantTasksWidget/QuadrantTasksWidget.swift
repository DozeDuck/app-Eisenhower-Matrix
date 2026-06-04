import WidgetKit
import SwiftUI
import AppIntents

enum WidgetQuadrant: Int, AppEnum, CaseIterable {
    case importantUrgent = 0
    case importantNotUrgent = 1
    case notImportantUrgent = 2
    case notImportantNotUrgent = 3

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "象限")
    }

    static var caseDisplayRepresentations: [WidgetQuadrant: DisplayRepresentation] {
        [
            .importantUrgent: DisplayRepresentation(title: "重要且紧急"),
            .importantNotUrgent: DisplayRepresentation(title: "重要但不紧急"),
            .notImportantUrgent: DisplayRepresentation(title: "不重要但紧急"),
            .notImportantNotUrgent: DisplayRepresentation(title: "不重要也不紧急")
        ]
    }

    var fallbackSnapshot: QuadrantWidgetSnapshot {
        switch self {
        case .importantUrgent:
            return QuadrantWidgetSnapshot(
                quadrantRaw: rawValue,
                title: "重要且紧急",
                subtitle: "立即处理",
                iconName: "exclamationmark.triangle.fill",
                colorHex: "#EE5252",
                pendingCount: 0,
                tasks: []
            )

        case .importantNotUrgent:
            return QuadrantWidgetSnapshot(
                quadrantRaw: rawValue,
                title: "重要但不紧急",
                subtitle: "计划推进",
                iconName: "target",
                colorHex: "#388CEB",
                pendingCount: 0,
                tasks: []
            )

        case .notImportantUrgent:
            return QuadrantWidgetSnapshot(
                quadrantRaw: rawValue,
                title: "不重要但紧急",
                subtitle: "委托或快速处理",
                iconName: "bell.badge.fill",
                colorHex: "#F5B333",
                pendingCount: 0,
                tasks: []
            )

        case .notImportantNotUrgent:
            return QuadrantWidgetSnapshot(
                quadrantRaw: rawValue,
                title: "不重要也不紧急",
                subtitle: "删除或延后",
                iconName: "tray.fill",
                colorHex: "#8C8C9E",
                pendingCount: 0,
                tasks: []
            )
        }
    }
}

struct SelectQuadrantIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "选择象限"
    static var description = IntentDescription("选择这个小组件要显示的任务象限。")

    @Parameter(title: "象限", default: WidgetQuadrant.importantUrgent)
    var quadrant: WidgetQuadrant

    init() { }

    init(quadrant: WidgetQuadrant) {
        self.quadrant = quadrant
    }
}

struct QuadrantWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: SelectQuadrantIntent
    let snapshot: QuadrantWidgetSnapshot
}

struct QuadrantWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> QuadrantWidgetEntry {
        QuadrantWidgetEntry(
            date: Date(),
            configuration: SelectQuadrantIntent(quadrant: .importantUrgent),
            snapshot: WidgetQuadrant.importantUrgent.fallbackSnapshot
        )
    }

    func snapshot(
        for configuration: SelectQuadrantIntent,
        in context: Context
    ) async -> QuadrantWidgetEntry {
        makeEntry(for: configuration)
    }

    func timeline(
        for configuration: SelectQuadrantIntent,
        in context: Context
    ) async -> Timeline<QuadrantWidgetEntry> {
        let entry = makeEntry(for: configuration)

        let nextRefresh = Calendar.current.date(
            byAdding: .minute,
            value: 15,
            to: Date()
        ) ?? Date().addingTimeInterval(15 * 60)

        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    private func makeEntry(for configuration: SelectQuadrantIntent) -> QuadrantWidgetEntry {
        let selected = configuration.quadrant

        let snapshot = WidgetSnapshotStore
            .load()?
            .snapshots
            .first(where: { $0.quadrantRaw == selected.rawValue })
            ?? selected.fallbackSnapshot

        return QuadrantWidgetEntry(
            date: Date(),
            configuration: configuration,
            snapshot: snapshot
        )
    }
}

struct QuadrantTasksWidgetEntryView: View {
    let entry: QuadrantWidgetProvider.Entry

    var body: some View {
        let color = Color(hex: entry.snapshot.colorHex)

        VStack(alignment: .leading, spacing: 0) {
            header(color: color)
                .frame(height: 22)

            titleBlock
                .frame(height: 34, alignment: .topLeading)
                .padding(.top, 0)

            Divider()
                .padding(.vertical, 4)

            taskPreview(color: color)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.top, 1)
        .padding(.horizontal, 4)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(color.opacity(0.12), for: .widget)
    }

    private func header(color: Color) -> some View {
        HStack(alignment: .center) {
            Image(systemName: entry.snapshot.iconName)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 22, alignment: .leading)

            Spacer()

            Text("\(entry.snapshot.pendingCount)")
                .font(.title3.bold())
                .foregroundStyle(color)
                .monospacedDigit()
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.snapshot.title)
                .font(.caption.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(entry.snapshot.subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func taskPreview(color: Color) -> some View {
        if entry.snapshot.tasks.isEmpty {
            Text("暂无任务")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 4)
        } else {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(entry.snapshot.tasks.prefix(3)) { task in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(task.isOverdue ? Color.red : color)
                            .frame(width: 5, height: 5)

                        Text(task.title)
                            .font(.caption2)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.top, 2)
        }
    }
}

struct QuadrantTasksWidget: Widget {
    let kind: String = "QuadrantTasksWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectQuadrantIntent.self,
            provider: QuadrantWidgetProvider()
        ) { entry in
            QuadrantTasksWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("干点正事儿")
        .description("选择一个象限，在桌面上快速查看未完成任务。")
        .supportedFamilies([.systemSmall])
    }
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0

        Scanner(string: cleaned).scanHexInt64(&int)

        let red: UInt64
        let green: UInt64
        let blue: UInt64

        switch cleaned.count {
        case 6:
            red = (int >> 16) & 0xFF
            green = (int >> 8) & 0xFF
            blue = int & 0xFF

        default:
            red = 120
            green = 120
            blue = 120
        }

        self.init(
            red: Double(red) / 255.0,
            green: Double(green) / 255.0,
            blue: Double(blue) / 255.0
        )
    }
}
