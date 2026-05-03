//
//  tricorderApp.swift
//  tricorder Watch App
//
//  Created by Julian Visser on 01.10.2024.
//

import SwiftUI
import HealthKit
import OSLog
import WorkoutCore
import WatchWorkout

private let watchAppLogger = Logger(subsystem: "com.julianvisser.tricorder", category: "WatchApp")

@main
struct TricorderWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.workoutManager, appDelegate.workoutManager)
                .task { try? await appDelegate.workoutManager.requestAuthorization() }
        }
    }
}

/// Receives the workout configuration forwarded by the iPhone when it calls
/// HKHealthStore.startWatchApp(toHandle:). This is the only entry point
/// that can't be modelled as a SwiftUI lifecycle event.
@MainActor
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    let workoutManager = WatchWorkoutManager()

    // Called by the system on an arbitrary thread; hop to MainActor before
    // touching workoutManager.
    nonisolated func handle(_ workoutConfiguration: HKWorkoutConfiguration) {
        // Extract Sendable values before crossing the concurrency boundary.
        let activityType = workoutConfiguration.activityType
        let locationType = workoutConfiguration.locationType
        watchAppLogger.info("Received workout configuration from iPhone (activityType: \(activityType.rawValue))")
        Task { @MainActor [weak self] in
            let config = HKWorkoutConfiguration()
            config.activityType = activityType
            config.locationType = locationType
            try? await self?.workoutManager.startWorkout(with: config)
        }
    }
}
