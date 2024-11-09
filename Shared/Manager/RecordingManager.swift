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

    var statisticsManager = StatisticsManager()
    var motionManager = MotionManager()
    var distanceManager = DistanceManager()

    var workoutManager = WorkoutManager()
    var nearbyInteractionManager = NearbyInteractionManager()
    var connectivityManager = ConnectivityManager()

    @Published var recordingState: HKWorkoutSessionState = .notStarted

    @Published var startDate: Date?

    #if os(watchOS)
        var sensorManager = SensorManager()
        @Published var successMotionUpdateSendCount: Int = 0
    #endif

    init() {
        Logger.shared.debug("RecordingManager \(#function) called on Thread \(Thread.current)")

        Task {
            Logger.shared.debug(
                "RecordingManager \(#function) taks called on Thread \(Thread.current)"
            )

            await registerListeners()
        }
    }
}

extension RecordingManager {
    func setRecordingState(newState: HKWorkoutSessionState) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        self.recordingState = newState
    }

    func setStartDate(_ date: Date) {
        Logger.shared.debug("\(#function) with: \(date) on called on Thread \(Thread.current)")

        self.startDate = date
    }

    func reset() {
        Logger.shared.debug("RecordingManager \(#function) called on Thread \(Thread.current)")

        recordingState = .notStarted
        startDate = nil

        distanceManager.reset()
        statisticsManager.reset()
        motionManager.reset()

        resetRest()
    }
}

extension RecordingManager {
    @Sendable
    nonisolated func getSendDataObject(_ data: Sendable) throws -> SendDataObjectManager.DataObject
    {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        guard let data = data as? Data else {
            throw RecordingManagerError.invalidData
        }

        return try SendDataObjectManager().decode(data)
    }

    @Sendable
    nonisolated func handleReceivedDistance(_ data: Sendable) throws {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        guard let distance = data as? Double else {
            Logger.shared.error("\(#function): Invalid data type")
            return
        }

        Task {
            await distanceManager.setDistance(distance)
        }
    }

}

enum RecordingManagerError: Error {
    case invalidData
    case noKey
}
