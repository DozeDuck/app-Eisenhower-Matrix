import SwiftUI

struct IOSRootView: View {
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
    }
}
