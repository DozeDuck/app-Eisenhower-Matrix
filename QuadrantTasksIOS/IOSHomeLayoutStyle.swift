import Foundation

enum IOSHomeLayoutStyle: String, CaseIterable, Identifiable {
    case list = "list"
    case matrix = "matrix"

    static let storageKey = "ios.home.layout.style"

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .list:
            return "一列列表"
        case .matrix:
            return "四象限矩阵"
        }
    }

    var subtitle: String {
        switch self {
        case .list:
            return "更适合阅读任务预览"
        case .matrix:
            return "更适合按轻重缓急整理正事"
        }
    }

    var systemImage: String {
        switch self {
        case .list:
            return "rectangle.grid.1x2"
        case .matrix:
            return "square.grid.2x2"
        }
    }
}
