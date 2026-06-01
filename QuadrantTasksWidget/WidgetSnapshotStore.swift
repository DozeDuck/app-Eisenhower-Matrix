import Foundation

struct QuadrantWidgetTask: Codable, Identifiable {
    let id: String
    let title: String
    let dueDateText: String?
    let isOverdue: Bool
}

struct QuadrantWidgetSnapshot: Codable {
    let quadrantRaw: Int
    let title: String
    let subtitle: String
    let iconName: String
    let colorHex: String
    let pendingCount: Int
    let tasks: [QuadrantWidgetTask]
}

struct QuadrantWidgetPayload: Codable {
    let updatedAt: Date
    let snapshots: [QuadrantWidgetSnapshot]
}

enum WidgetSnapshotStore {
    static let payloadKey = "quadrant.widget.payload.v1"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConfig.groupID)
    }

    static func save(_ payload: QuadrantWidgetPayload) {
        guard let data = try? JSONEncoder().encode(payload) else {
            print("⚠️ Widget payload 编码失败")
            return
        }

        defaults?.set(data, forKey: payloadKey)
    }

    static func load() -> QuadrantWidgetPayload? {
        guard let data = defaults?.data(forKey: payloadKey) else {
            return nil
        }

        return try? JSONDecoder().decode(QuadrantWidgetPayload.self, from: data)
    }
}
