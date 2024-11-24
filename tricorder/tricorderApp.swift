//
//  tricorderApp.swift
//  tricorder
//
//  Created by Julian Visser on 01.10.2024.
//

import SwiftData
import SwiftUI

@main
struct tricorderApp: App {
    private let eventManager = EventManager.shared
    private let recordingManager: RecordingManager
    private let database: Database

    init() {
        do {
            let schema = Schema([
                RecordingDatabaseModel.self
            ])
            self.database = Database(modelContainer: try ModelContainer(for: schema))

            self.recordingManager = RecordingManager(modelContainer: database.getModelContainer())

        } catch {
            fatalError("Could not create Database")
        }
    }

    var body: some Scene {
        WindowGroup {
            if UIDevice.current.userInterfaceIdiom == .phone {
                StartView()
                    .environmentObject(recordingManager)
            } else {
                // todo maybe show list
                Text("Cannot Start Workouts from iPad")
            }
        }
    }
}
