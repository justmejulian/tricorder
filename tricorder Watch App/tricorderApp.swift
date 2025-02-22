//
//  tricorderApp.swift
//  tricorder Watch App
//
//  Created by Julian Visser on 01.10.2024.
//

import SwiftData
import SwiftUI

@main
struct tricorder_Watch_AppApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let eventManager = EventManager.shared
    private let recordingManager: RecordingManager
    private let database: Database

    init() {
        do {
            let schema = Schema([PersistedDatabaseModel.self])
            self.database = Database(modelContainer: try ModelContainer(for: schema))

            // database.clear()

            self.recordingManager = RecordingManager(modelContainer: database.getModelContainer())

        } catch {
            fatalError("Could not create Database")
        }
    }

    @SceneBuilder var body: some Scene {
        WindowGroup {
            PagingView()
                .environmentObject(recordingManager)
        }
    }
}
