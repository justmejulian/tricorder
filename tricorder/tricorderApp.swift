//
//  tricorderApp.swift
//  tricorder
//
//  Created by Julian Visser on 01.10.2024.
//

import SwiftUI

@main
struct tricorderApp: App {
    private let eventManager = EventManager.shared
    private let recordingManager = RecordingManager()

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
