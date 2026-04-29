//
//  tricorderApp.swift
//  tricorder
//
//  Created by Julian Visser on 01.10.2024.
//

import SwiftUI

@main
struct TricorderApp: App {
    @State private var workoutManager = PhoneWorkoutManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(workoutManager)
                .task { try? await workoutManager.requestAuthorization() }
        }
    }
}
