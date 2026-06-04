//
//  ColorVisionMode.swift
//  QuadrantTasks
//
//  颜色视觉模式。用于普通模式与色盲友好模式切换。
//  这里只保存 enum 与 Environment，不直接依赖 AppGroupConfig，方便 macOS/iOS 共享。
//

import SwiftUI

enum ColorVisionMode: String, CaseIterable, Identifiable, Codable {
    case standard = "standard"
    case colorBlindSafe = "colorBlindSafe"

    static let storageKey = "color.vision.mode"

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .standard:
            return "标准配色"
        case .colorBlindSafe:
            return "色盲友好配色"
        }
    }

    var shortTitle: String {
        switch self {
        case .standard:
            return "标准"
        case .colorBlindSafe:
            return "色盲友好"
        }
    }

    var explanation: String {
        switch self {
        case .standard:
            return "使用默认象限颜色。"
        case .colorBlindSafe:
            return "使用更适合常见色觉障碍区分的高对比配色，并保留图标作为辅助识别。"
        }
    }
}

// MARK: - SwiftUI Environment

private struct ColorVisionModeEnvironmentKey: EnvironmentKey {
    static let defaultValue: ColorVisionMode = .standard
}

extension EnvironmentValues {
    var colorVisionMode: ColorVisionMode {
        get {
            self[ColorVisionModeEnvironmentKey.self]
        }
        set {
            self[ColorVisionModeEnvironmentKey.self] = newValue
        }
    }
}

extension Notification.Name {
    static let colorVisionModeDidChange = Notification.Name("colorVisionModeDidChange")
}
