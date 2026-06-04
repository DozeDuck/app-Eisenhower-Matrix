//
//  IOSRootView.swift
//  QuadrantTasksIOS
//

import SwiftUI
import SwiftData

struct IOSRootView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var colorVisionModeRaw = ColorVisionMode.standard.rawValue

    private var colorVisionMode: ColorVisionMode {
        ColorVisionMode(rawValue: colorVisionModeRaw) ?? .standard
    }

    private var appGroupDefaults: UserDefaults {
        UserDefaults(suiteName: AppGroupConfig.groupID) ?? .standard
    }

    var body: some View {
        TabView {
            NavigationStack {
                IOSQuadrantsHomeView()
            }
            .tabItem {
                Label("四象限", systemImage: "square.grid.2x2")
            }

            NavigationStack {
                IOSHistoryView()
            }
            .tabItem {
                Label("已完成", systemImage: "checkmark.circle")
            }

            NavigationStack {
                IOSSettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gearshape")
            }
        }
        .environment(\.colorVisionMode, colorVisionMode)
        .id(colorVisionModeRaw)
        .onAppear {
            loadColorVisionMode()
            refreshWidgetSnapshot()
        }
        .onReceive(NotificationCenter.default.publisher(for: .colorVisionModeDidChange)) { _ in
            loadColorVisionMode()
            refreshWidgetSnapshot()
        }
    }

    private func loadColorVisionMode() {
        let storedRaw = appGroupDefaults.string(forKey: ColorVisionMode.storageKey)
            ?? ColorVisionMode.standard.rawValue

        if colorVisionModeRaw != storedRaw {
            colorVisionModeRaw = storedRaw
        }
    }

    private func refreshWidgetSnapshot() {
        #if os(iOS)
        WidgetDataService.refreshSnapshot(context: modelContext)
        #endif
    }
}
