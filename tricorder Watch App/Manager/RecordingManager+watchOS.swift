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
            key: .companionStartedRecording,
            handleData: self.handleCompanionStartedRecording
        )

        await eventManager.register(
            key: .collectedStatistics,
            handleData: self.handleCollectedStatistics
        )

        await eventManager.register(
            key: .collectedMotionValues,
            handleData: self.handleCollecteMotionValues
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
        successMotionUpdateSendCount = 0
    }
}

// MARK: -  RecordingManager functions
//
extension RecordingManager {
    func startRecording(workoutConfiguration: HKWorkoutConfiguration) async {
        Logger.shared.info("Starting Recording")

        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        reset()

        do {
            try await workoutManager.startWorkout(
                workoutConfiguration: workoutConfiguration
            )

        } catch {
            Logger.shared.error("Failed to start startWorkout: \(error)")
        }

        await initNIDiscoveryToken()
        await nearbyInteractionManager.start()

        do {
            try await sensorManager.startUpdates()
        } catch {
            Logger.shared.error("Failed to start Motion Updates: \(error)")
        }
    }

    func initNIDiscoveryToken() async {
        Logger.shared.info("Init NIDiscovery Token")
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        do {
            let discoveryToken =
                try await nearbyInteractionManager.getDiscoveryToken()
            guard
                let partnerDiscoveryToken = try await connectivityManager.sendCodable(
                    key: "discoveryToken",
                    data: discoveryToken
                )
            else {
                throw NearbyInteractionManagerError.noDiscoveryTokenAvailable
            }

            try await self.nearbyInteractionManager.setDiscoveryToken(partnerDiscoveryToken)
        } catch {
            Logger.shared.error("Could not initNIDiscoveryToken: \(error)")
        }
    }

    func addToSuccessMotionUpdateSendCount(_ count: Int) {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        successMotionUpdateSendCount += count
    }
}

// MARK: -  RecordingManager Handlers
//
extension RecordingManager {
    @Sendable
    nonisolated func handleCompanionStartedRecording(_ data: Sendable) throws {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

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
        }

        if change.newState == .running {
            Task {
                let startDate = await workoutManager.getStartDate()

                if let startDateData = try? JSONEncoder().encode(startDate) {
                    try await workoutManager.sendCodable(key: "startDate", data: startDateData)
                }

            }
        }

        if change.newState == .stopped {
            Logger.shared.info("\(#function): Session stopped")

            Task {
                do {
                    await sensorManager.stopUpdates()
                    await nearbyInteractionManager.stop()

                    // todo finish sync
                    // maybe use a HKWorkoutSessionState

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
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        let dataObject = try getSendDataObject(data)

        switch dataObject.key {
        default:
            Logger.shared.error("\(#function): Unknown dataObject key: \(dataObject.key)")
        }

    }

    @Sendable
    nonisolated func handleReceivedWorkoutData(_ data: Sendable) throws {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        let dataObject = try getSendDataObject(data)

        switch dataObject.key {
        default:
            Logger.shared.error("\(#function): Unknown dataObject key: \(dataObject.key)")
        }

    }

    @Sendable
    nonisolated func handleCollecteMotionValues(_ data: Sendable) throws {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        // todo: maybe move this stuff into motionManager
        guard let values = data as? [MotionValue] else {
            Logger.shared.error("\(#function): Invalid data type")
            return
        }
        Task {
            await motionManager.updateMotionValues(values)

            do {
                let archivedUpdates = try archiveSendable(values)

                try await connectivityManager.sendCodable(
                    key: "motionUpdate",
                    data: archivedUpdates
                ) as Void

                await addToSuccessMotionUpdateSendCount(values.count)
            } catch {
                Logger.shared.error("\(#function): Failed to send data: \(error)")
            }

        }
    }

    @Sendable
    nonisolated func handleCollectedStatistics(_ data: Sendable) throws {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        guard let statistics = data as? HKStatistics else {
            Logger.shared.error("\(#function): Invalid data type")
            return
        }

        Task {
            await statisticsManager.updateForStatistics(statistics)

            do {
                let archivedStatistics = try archiveNSObject(statistics)
                try await workoutManager.sendCodable(key: "statistics", data: archivedStatistics)
            } catch {
                Logger.shared.error("\(#function): Failed to send data: \(error)")
            }
        }

    }

    nonisolated func archiveNSObject(_ data: NSObject) throws -> Data {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        return try NSKeyedArchiver.archivedData(
            withRootObject: data,
            requiringSecureCoding: true
        )
    }

    nonisolated func archiveSendable(_ data: Encodable) throws -> Data {
        Logger.shared.debug("\(#function) called on Thread \(Thread.current)")

        return try JSONEncoder().encode(data)
    }
}
