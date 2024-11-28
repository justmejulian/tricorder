//
//  RecordingManager+watchOs.swift
//  tricorder
//
//  Created by Julian Visser on 01.11.2024.
//

import Foundation
import HealthKit
import os

// todo can this be bigger?
let MAXCHUNKSIZE = 300

extension RecordingManager {
    func registerListeners() async {
        Logger.shared.debug("called on Thread \(Thread.current)")

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
        monitoringManager.reset()
    }
}

// MARK: -  RecordingManager functions
//
extension RecordingManager {
    func startRecording() async throws {
        Logger.shared.debug("called on Thread \(Thread.current)")

        Logger.shared.info("Starting Recording")

        await reset()

        let recordingStart = try await startWorkout()

        await sendRecordingStartToCompanion(recordingStart: recordingStart)

        do {
            try await initNIDiscoveryToken()
            await nearbyInteractionManager.start()
        } catch {
            Logger.shared.error("Failed to start Nearby Interaction: \(error)")
        }

        try await startUpdates(recordingStart: recordingStart)
    }

    func startWorkout() async throws -> Date {
        do {
            return try await workoutManager.startWorkout()
        } catch {
            Logger.shared.error("Failed to start startWorkout: \(error)")
            throw RecordingManagerError.startWorkout
        }
    }

    func startUpdates(recordingStart: Date) async throws {
        do {
            try await coreMotionManager.startUpdates(recordingStart: recordingStart)
        } catch {
            Logger.shared.error("Failed to start Motion Updates: \(error)")
            throw RecordingManagerError.startWorkout
        }
    }

    func initNIDiscoveryToken() async throws {
        Logger.shared.info("Init NIDiscovery Token")
        Logger.shared.debug("called on Thread \(Thread.current)")

        let discoveryToken =
            try await nearbyInteractionManager.getDiscoveryTokenData()
        guard
            let partnerDiscoveryToken = try await connectivityManager.sendData(
                key: "discoveryToken",
                data: discoveryToken
            )
        else {
            Logger.shared.error("Did not receive a discovery token from companion.")
            throw NearbyInteractionManagerError.noDiscoveryTokenAvailable
        }

        try await self.nearbyInteractionManager.setDiscoveryToken(partnerDiscoveryToken)
    }
}

// MARK: -  RecordingManager Handlers
//
extension RecordingManager {
    @Sendable
    nonisolated func handleCompanionStartedRecording(_ data: Sendable) throws {
        Logger.shared.debug("called on Thread \(Thread.current)")

        Task {
            try await startRecording()
        }
    }

    @Sendable
    nonisolated func handleSessionStateChange(_ data: Sendable) throws {
        Logger.shared.debug("called on Thread \(Thread.current)")

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
                    await coreMotionManager.stopUpdates()
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
    nonisolated func handleReceivedData(_ data: Sendable) async throws -> Data? {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let dataObject = try SendDataObjectManager().decode(data)

        switch dataObject.key {
        case "recordingState":
            let recordingObject = await RecordingObject(
                recordingState: self.recordingState.rawValue,
                startTime: self.workoutManager.getStartDate()?.timeIntervalSince1970,
                motionDataCount: self.motionManager.count,
                statisticCount: self.heartRateManager.count
            )
            return try JSONEncoder().encode(recordingObject)

        default:
            throw RecordingManagerError.noKey
        }
    }

    @Sendable
    nonisolated func handleReceivedWorkoutData(_ data: Sendable) throws {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let dataObject = try SendDataObjectManager().decode(data)

        switch dataObject.key {
        default:
            Logger.shared.error("\(#function): Unknown dataObject key: \(dataObject.key)")
        }

    }

    @Sendable
    nonisolated func handleCollecteMotionValues(_ data: Sendable) {
        Logger.shared.debug("called on Thread \(Thread.current)")

        let motionSensor = data as! MotionSensor

        Task {
            await motionManager.update(
                sensorName: motionSensor.sensorName,
                newValues: motionSensor.batch
            )

            do {
                try await sendMotionUpdate(motionSensor)
                // todo persist on fail
                await monitoringManager.addMotioUpdateSendSuccess(true)
            } catch {
                Logger.shared.error("\(#function): Failed to archive data: \(error)")
                await monitoringManager.addMotioUpdateSendSuccess(false)
            }
        }
    }

    @Sendable
    nonisolated func handleCollectedStatistics(_ data: Sendable) throws {
        Logger.shared.debug("called on Thread \(Thread.current)")

        guard let heartRateSensor = data as? HeartRateSensor, !heartRateSensor.batch.isEmpty else {
            Logger.shared.error("\(#function): Invalid data type")
            return
        }

        guard let value = heartRateSensor.batch.first else {
            Logger.shared.error("\(#function): No heart rate values")
            return
        }

        Task {
            await heartRateManager.update(value)
            await sendHeartRate(value)
        }

    }
}
// MARK: -  RecordingManager nonisolated functions
//
extension RecordingManager {
    nonisolated func sendHeartRate(_ heartRate: HeartRateValue) async {
        do {
            // todo change to handle recording start
            let archivedStatistics = try archiveSendable(heartRate)
            // todo use connectivityManager.sendData
            try await workoutManager.sendCodable(key: "statistics", data: archivedStatistics)
        } catch {
            Logger.shared.error("\(#function): Failed to send data: \(error)")
        }
    }

    nonisolated func sendMotionUpdate(_ motionSensor: MotionSensor) async throws {
        let archiveMotionValueArrays = try archiveSendableArray(
            motionSensor.chunked(into: MAXCHUNKSIZE)
        )

        try await connectivityManager.sendDataArray(
            key: "motionUpdate",
            dataArray: archiveMotionValueArrays
        ) as Void
    }

    nonisolated func sendRecordingStartToCompanion(recordingStart: Date) async {
        do {
            try await connectivityManager.sendData(
                key: "recordingStartTimestamp",
                data: try JSONEncoder().encode(recordingStart)
            ) as Void
        } catch {
            Logger.shared.error("Failed to send recordingStart to Companion: \(error)")
        }
    }

    nonisolated func archiveSendable(_ data: Codable) throws -> Data {
        Logger.shared.debug("called on Thread \(Thread.current)")

        return try JSONEncoder().encode(data)
    }

    nonisolated func archiveSendableArray(_ data: [Codable]) throws -> [Data] {
        Logger.shared.debug("called on Thread \(Thread.current)")

        return try data.map(archiveSendable(_:))
    }

}
