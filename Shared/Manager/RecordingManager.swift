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

    var nearbyInteractionManager = NearbyInteractionManager()
    var statisticsManager = StatisticsManager()
    var motionManager = MotionManager()

    // todo can we move to backgroudn thread?
    var workoutManager = WorkoutManager()

    @Published var recordingState: HKWorkoutSessionState = .notStarted

    @Published var startDate: Date?

    #if os(watchOS)
        // todo can we move to backgroudn thread?
        var sensorManager = SensorManager()
    #endif

    init() {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        Task {
            Logger.shared.debug("\(#function) taks called on Thread \(Thread.current)")

            await registerListeners()
        }
    }

    func setRecordingState(newState: HKWorkoutSessionState) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        self.recordingState = newState
    }

    func setStartDate(_ date: Date) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        self.startDate = date
    }

    func reset() {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        recordingState = .notStarted
        startDate = nil

        resetRest()
    }
}

extension RecordingManager {
    func sendData(key: String, data: Data) async throws {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")
        Logger.shared.debug("Data size: \(data.debugDescription)")

        let dataObject = try SendDataObjectManager().encode(
            key: key,
            data: data
        )

        try await workoutManager.sendData(dataObject, retryCount: 0)
    }

    func sendNIDiscoveryToken() async {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        if nearbyInteractionManager.didSendDiscoveryToken {
            return
        }

        do {
            let discoveryToken =
                try nearbyInteractionManager.getDiscoveryToken()
            try await sendData(key: "discoveryToken", data: discoveryToken)

            // todo: use setter
            nearbyInteractionManager.didSendDiscoveryToken = true
        } catch {
            Logger.shared.error("Could not send discovery token: \(error)")
        }
    }

    func handleNIReceiveDiscoveryToken(_ data: Data) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")
        Task {
            Logger.shared.debug("\(#function) task called on Thread \(Thread.current)")

            await sendNIDiscoveryToken()
            nearbyInteractionManager.didReceiveDiscoveryToken(data)
        }
    }
}
