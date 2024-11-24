//
//  RecordingManager.swift
//  tricorder
//
//  Created by Julian Visser on 01.11.2024.
//

import Foundation
import HealthKit
import SwiftUICore
import os

@MainActor
class RecordingManager: ObservableObject {
    let eventManager = EventManager.shared

    var motionManager = MotionManager()
    var distanceManager = ObservableValueManager<DistanceValue>()
    var heartRateManager = ObservableValueManager<HeartRateValue>()

    var workoutManager = WorkoutManager()
    var nearbyInteractionManager = NearbyInteractionManager()
    var connectivityManager = ConnectivityManager()

    @Published var recordingState: HKWorkoutSessionState = .notStarted

    @Published var startDate: Date?

    #if os(watchOS)
        var coreMotionManager = CoreMotionManager()
        var monitoringManager = MonitoringManager()
    #endif

    init() {
        Logger.shared.debug("called on Thread \(Thread.current)")

        Task {
            Logger.shared.debug(
                "task called on Thread \(Thread.current)"
            )

            await registerListeners()
        }
    }
}

extension RecordingManager {
    func setRecordingState(newState: HKWorkoutSessionState) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        self.recordingState = newState
    }

    func setStartDate(_ date: Date) {
        Logger.shared.debug("with: \(date) on called on Thread \(Thread.current)")

        self.startDate = date
    }

    func reset() async {
        Logger.shared.debug("called on Thread \(Thread.current)")

        recordingState = .notStarted
        startDate = nil

        distanceManager.reset()
        heartRateManager.reset()
        motionManager.reset()

        await connectivityManager.reset()

        resetRest()
    }
}

// MARK: -  Shared handlers
//
extension RecordingManager {
    @Sendable
    nonisolated func handleReceivedDistance(_ data: Sendable) throws {
        Logger.shared.debug("called on Thread \(Thread.current)")
        Task {
            await distanceManager.update(data: data)
        }
    }
}

// MARK: -  Shared functions
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
