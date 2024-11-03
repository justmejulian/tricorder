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
        await eventManager.register(
            key: .sessionStateChanged,
            handleData: self.handleSessionStateChange
        )

        await eventManager.register(
            key: .companionStartedRecording,
            handleData: self.handleCompanionStartedRecording
        )

        func registerListeners() async {
            await eventManager.register(
                key: .collectedStatistics,
                handleData: self.handleCollectedData
            )
        }

        await eventManager.register(
            key: .receivedData,
            handleData: self.handleReceivedData
        )
    }

    func resetRest() {

    }
}

// MARK: -  RecordingManager functions
//
extension RecordingManager {
    func startRecording(workoutConfiguration: HKWorkoutConfiguration) async {
        Logger.shared.debug("Starting Recording")
        do {
            try await workoutManager.startWorkout(
                workoutConfiguration: workoutConfiguration
            )

        } catch {
            Logger.shared.error("Failed to start startWorkout: \(error)")
        }

        // todo move the sending into init of RecordingManager
        // then start from here and resend if fails
        await sendNIDiscoveryToken()

        do {
            try await motionManager.startUpdates()
        } catch {
            Logger.shared.error("Failed to start Motion Updates: \(error)")
        }

    }
}

// MARK: -  RecordingManager Handlers
//
extension RecordingManager {
    @Sendable
    nonisolated func handleCompanionStartedRecording(_ data: Sendable) throws {
        Logger.shared.info("\(#function)")

        guard let workoutConfiguration = data as? HKWorkoutConfiguration else {
            Logger.shared.error("\(#function): Invalid data type")
            return
        }

        Task {
            await startRecording(workoutConfiguration: workoutConfiguration)
        }
    }

    @Sendable
    nonisolated func handleSessionStateChange(_ data: Sendable) throws {
        Logger.shared.info("\(#function)")

        guard let change = data as? SessionStateChange else {
            Logger.shared.error("\(#function): Invalid data type")
            return
        }

        Logger.shared.info(
            "Session state changed to \(change.newState.rawValue)"
        )

        Task {
            await setRecordingState(newState: change.newState)
        }

        if change.newState == .running {
            Task {
                let startDate = await workoutManager.getStartDate()

                if let startDateData = try? JSONEncoder().encode(startDate) {
                    await sendData(key: "startDate", data: startDateData)
                }
            }
        }

        if change.newState == .stopped {
            Logger.shared.info("\(#function): Session stopped")

            Task {
                do {
                    await motionManager.stopUpdates()
                    await nearbyInteractionManager.stop()

                    // todo finish sync

                    try await workoutManager.endWorkout(date: change.date)
                } catch {
                    Logger.shared.error(
                        "\(#function): Error ending workout: \(error)"
                    )
                }
            }
        }
    }

    @Sendable
    nonisolated func handleReceivedData(_ data: Sendable) throws {
        Logger.shared.info("\(#function) called")

        guard let data = data as? Data else {
            Logger.shared.error("\(#function): Invalid data type")
            return
        }

        let dataObject = try DataObjectManager().decode(data)

        // todo move these keys into and enum, so I know what is possible
        switch dataObject.key {
        case "discoveryToken":
            Task {
                await handleNIReceiveDiscoveryToken(dataObject.data)
            }

        default:
            Logger.shared.error("unknown dataObject key: \(dataObject.key)")
        }

    }

    @Sendable
    nonisolated func handleCollectedData(_ data: Sendable) throws {
        Logger.shared.info("\(#function)")

        guard let statistics = data as? HKStatistics else {
            Logger.shared.error("\(#function): Invalid data type")
            return
        }

        Task {
            let mostRecentStatistic =
                await statisticsManager.updateForStatistics(statistics)

            let newHeartRate = mostRecentStatistic[.heartRate] ?? 0
            await setHeartRate(heartRate: newHeartRate)
        }

        // todo send to iphone
        //            let archivedData = try? NSKeyedArchiver.archivedData(
        //                withRootObject: allStatistics, requiringSecureCoding: true)
        //            guard let archivedData = archivedData, !archivedData.isEmpty else {
        //                Logger.shared.log("Encoded cycling data is empty")
        //                return
        //            }

    }
}
