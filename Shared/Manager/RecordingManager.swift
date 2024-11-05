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

    // todo move these background threads
    var nearbyInteractionManager = NearbyInteractionManager()
    var statisticsManager = StatisticsManager()

    @Published var recordingState: HKWorkoutSessionState = .notStarted
    
    @Published var startDate: Date?

    #if os(watchOS)
        var motionManager = MotionManager()
    #endif

    init() {
        Task {
            await registerListeners()
        }
    }

    func setRecordingState(newState: HKWorkoutSessionState) {
        self.recordingState = newState
    }

    func setStartDate(_ date: Date) {
        self.startDate = date
    }

    func reset() {
        recordingState = .notStarted
        startDate = nil

        resetRest()
    }
}

extension RecordingManager {
    func sendData(key: String, data: Data) async {
        do {
            let dataObject = try DataObjectManager().encode(
                key: key,
                data: data
            )
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
