//
//  RecordingManager.swift
//  tricorder
//
//  Created by Julian Visser on 01.11.2024.
//

import Foundation
import HealthKit
import SwiftData
import SwiftUICore
import OSLog

@MainActor
class RecordingManager: ObservableObject {
    let eventManager = EventManager.shared

    let modelContainer: ModelContainer

    var motionManager = MotionManager()
    var distanceManager = ObservableValueManager<DistanceValue>()
    var heartRateManager = ObservableValueManager<StatisticValue>()

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
}

// MARK: -  Shared functions
//
extension RecordingManager {
    func updateObservableManagers(sensor: Sensor) {
        switch sensor {
        case .motion(let name, _, let batch):
            motionManager.update(
                sensorName: name,
                newValues: batch
            )

        case .statistic(_, _, let batch):
            heartRateManager.update(batch)

        default:
            // todo throw error
            Logger.shared.info("Did not hanlde: \(String(describing: sensor))")
        }
    }
}

// MARK: -  RecordingManagerError
//
enum RecordingManagerError: Error {
    case invalidData
    case noKey
    case startWorkout
    case startUpdates
}
