//
//  RecordingManager.swift
//  tricorder
//
//  Created by Julian Visser on 01.11.2024.
//

import Foundation
import HealthKit
import OSLog
import SwiftData
import SwiftUICore

@MainActor
class RecordingManager: ObservableObject {
    let eventManager = EventManager.shared

    let modelContainer: ModelContainer

    let classifierManager = ClassifierManager()

    // todo are these on main thread?
    var workoutManager = WorkoutManager()
    var nearbyInteractionManager = NearbyInteractionManager()
    var connectivityManager = ConnectivityManager()

    @Published var recordingState: HKWorkoutSessionState = .notStarted

    @Published var startDate: Date?

    #if os(watchOS)
        var coreMotionManager = CoreMotionManager()
        var monitoringManager = MonitoringManager()
    #endif

    init(modelContainer: ModelContainer) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        self.modelContainer = modelContainer

        Task {
            Logger.shared.debug(
                "task called on Thread \(Thread.current)"
            )

            await registerListeners()
        }
    }
}

// MARK: -  Shared functions
//
extension RecordingManager {
    func setRecordingState(newState: HKWorkoutSessionState) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        self.recordingState = newState
    }

    func getRecordingState() -> HKWorkoutSessionState {
        return recordingState
    }

    func setStartDate(_ date: Date) {
        Logger.shared.debug("with: \(date) on called on Thread \(Thread.current)")

        self.startDate = date
    }

    func reset() async {
        Logger.shared.debug("called on Thread \(Thread.current)")

        recordingState = .notStarted
        startDate = nil

        await classifierManager.reset()

        await connectivityManager.reset()

        resetRest()
    }
}

// MARK: -  Shared handlers
//
extension RecordingManager {
}

// MARK: -  RecordingManagerError
//
enum RecordingManagerError: Error {
    case invalidData
    case noKey
    case startWorkout
    case startUpdates
}
