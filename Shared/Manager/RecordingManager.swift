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
        // Logger.shared.debug("creating RecordingManager on Thread \(Thread.current)")

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
        self.recordingState = newState
    }

    func getRecordingState() -> HKWorkoutSessionState {
        return recordingState
    }

    func setStartDate(_ date: Date) {
        self.startDate = date
    }

    func reset() async {
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
enum RecordingManagerError: LocalizedError {
    case invalidData
    case noKey
    case startWorkout
    case startUpdates

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "The recorded data is invalid or corrupted."
        case .noKey:
            return "A required encryption key is missing."
        case .startWorkout:
            return "Failed to start the workout session."
        case .startUpdates:
            return "Failed to start sensor updates."
        }
    }
}
