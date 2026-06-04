//
//  QuadrantTasksIOSApp.swift
//  QuadrantTasksIOS
//

import SwiftUI
import SwiftData

@main
struct IOSQuadrantTasksApp: App {

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TaskItem.self,
            SubTask.self
        ])

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [config]
            )
        } catch {
            fatalError("无法创建 iOS ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            IOSRootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
