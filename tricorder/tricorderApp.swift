//
//  tricorderApp.swift
//  tricorder
//
//  Created by Julian Visser on 01.10.2024.
//

import SwiftUI

@main
struct tricorderApp: App {
    private let workoutManager = WorkoutManager.shared

    var body: some Scene {
        WindowGroup {
            if UIDevice.current.userInterfaceIdiom == .phone {
                StartView()
                    .environmentObject(workoutManager)
            } else {
                // todo maybe show list
                Text("Cannot Start Workouts from iPad")
            }
        }
    }
}
