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

    @MainActor
    var workoutManager = WorkoutManager()

    var nearbyInteractionManager = NearbyInteractionManager()
    var statisticsManager = StatisticsManager()

    @Published var heartRate: Double = 0
    @Published var elapsedTimeInterval: TimeInterval = 0
    @Published var recordingState: HKWorkoutSessionState = .notStarted

    #if os(watchOS)
        var motionManager = MotionManager()
    #endif

    init() {
        Task {
            await registerListeners()
        }
    }

    func setElapsedTimeInterval(elapsedTime: WorkoutElapsedTime) {

        if recordingState == .running {

            let currentElapsedTime =
                elapsedTime.timeInterval
                + Date().timeIntervalSince(elapsedTime.date)

            self.elapsedTimeInterval = currentElapsedTime

            return
        }

        self.elapsedTimeInterval = 0
    }

    func setHeartRate(heartRate: Double) {
        self.heartRate = heartRate
    }

    func setRecordingState(newState: HKWorkoutSessionState) {
        self.recordingState = newState
    }

    func reset() {
        recordingState = .notStarted
        heartRate = 0
        elapsedTimeInterval = 0

        resetRest()
    }
}

extension RecordingManager {
    func sendData(key: String, data: Data) async {
        do {
            let dataObject = try DataObjectManager().encode(
                key: key, data: data)
            await workoutManager.sendData(dataObject, retryCount: 0)
        } catch {
            Logger.shared.error("Could not encode data for key : \(key)")
        }
    }

    func sendNIDiscoveryToken() async {
        if nearbyInteractionManager.didSendDiscoveryToken {
            return
        }

        do {
            let discoveryToken =
                try nearbyInteractionManager.getDiscoveryToken()
            await sendData(key: "discoveryToken", data: discoveryToken)

            // todo: use setter
            nearbyInteractionManager.didSendDiscoveryToken = true
        } catch {
            Logger.shared.error("Could not send discovery token: \(error)")
        }
    }

    func handleNIReceiveDiscoveryToken(_ data: Data) {
        Task {
            await sendNIDiscoveryToken()
            nearbyInteractionManager.didReceiveDiscoveryToken(data)
        }
    }
}
