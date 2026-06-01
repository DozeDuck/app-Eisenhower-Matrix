import Foundation

enum IOSTaskSortOption: String, CaseIterable, Identifiable {
    case createdDesc = "创建时间：新到旧"
    case createdAsc = "创建时间：旧到新"
    case dueAsc = "截止日期：近到远"

    var id: String {
        rawValue
    }
}
