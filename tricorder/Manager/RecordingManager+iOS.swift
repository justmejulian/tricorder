//
//  RecordingManager+watchOs.swift
//  tricorder
//
//  Created by Julian Visser on 01.11.2024.
//

import Foundation
import HealthKit
import os

extension RecordingManager {
    func registerListeners() async {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        await eventManager.register(
            key: .sessionStateChanged,
            handleData: self.handleSessionStateChange
        )

        await eventManager.register(
            key: .receivedData,
            handleData: self.handleReceivedData
        )

        await eventManager.register(
            key: .receivedWorkoutData,
            handleData: self.handleReceivedWorkoutData
        )

        await eventManager.register(
            key: .collectedDistance,
            handleData: self.handleReceivedDistance
        )
    }

    func resetRest() {

    }
}

// MARK: -  RecordingManager functions
//
extension RecordingManager {
    func startRecording() async {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")
        do {
            try await workoutManager.startWatchWorkout()
        } catch {
            Logger.shared.log(
                "Failed to start cycling on the paired watch."
            )
        }
    }

    func stopRecording() async {
        await workoutManager.session?.stopActivity(with: .now)
    }
}

extension RecordingManager {
    @Sendable
    nonisolated func handleSessionStateChange(_ data: Sendable) throws {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        guard let change = data as? SessionStateChange else {
            Logger.shared.error("\(#function): Invalid data type")
            return
        }

        Logger.shared.info(
            "Session state changed to \(change.newState.rawValue)"
        )

        Task {
            await setRecordingState(newState: change.newState)
            
            if change.newState == .running {
                await reset()
            }
        }
                

    }

    @Sendable
    nonisolated func handleReceivedData(_ data: Sendable) async throws -> Data? {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        let dataObject = try getSendDataObject(data)

        // todo move these keys into and enum, so I know what is possible
        switch dataObject.key {
        case "discoveryToken":
            // todo: maybe move this stuff into ios nearbyInteractionManager
            // handleReceivedDiscoveryToken -> Data
            try await nearbyInteractionManager.setDiscoveryToken(dataObject.data)
            // return iPhones DiscoveryToken
            let token = try await nearbyInteractionManager.getDiscoveryToken()

            await nearbyInteractionManager.start()
            return token

        case "motionUpdate":
            // todo: maybe move this stuff into Motion Manager
            let values = try JSONDecoder().decode([MotionValue].self, from: dataObject.data)
            await motionManager.updateMotionValues(values)
            return nil

        default:
            throw RecordingManagerError.noKey
        }
    }

    @Sendable
    nonisolated func handleReceivedWorkoutData(_ data: Sendable) throws {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        let dataObject = try getSendDataObject(data)

        // todo move these keys into and enum, so I know what is possible
        switch dataObject.key {
        case "startDate":
            if let startDate = try? JSONDecoder().decode(
                Date.self,
                from: dataObject.data
            ) {
                Task {
                    await setStartDate(startDate)
                }
            }
        case "statistics":
            if let statistics =
                try NSKeyedUnarchiver.unarchivedObject(
                    ofClass: HKStatistics.self,
                    from: dataObject.data
                )
            {
                Task {
                    await statisticsManager.updateForStatistics(statistics)
                }
            }

        default:
            Logger.shared.error("\(#function): Unknown dataObject key: \(dataObject.key)")
        }

    }
}
