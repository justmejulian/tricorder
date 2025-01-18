//
//  RecordingManager+watchOs.swift
//
//  Created by Julian Visser on 01.11.2024.
//

import Foundation
import HealthKit
import OSLog

// todo can this be bigger?
let MAXCHUNKSIZE = 300

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

        await eventManager.register(
            key: .collectedSensorValues,
            handleData: self.handleSensorUpdate
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
    func start() async throws {
        Logger.shared.info("Starting Recording")

        await reset()

        let settings = try await getSettings()

        try await startNearbyInteraction()

        try await startWorkout(settings: settings)
    }

    func startWorkout() async throws {
        try await startWorkout(settings: nil)
    }

    func startWorkout(settings: Settings?) async throws {
        do {
            let recordingStart = try await workoutManager.startWorkout()

            // CoreMotion requires a running workout
            try await coreMotionManager.startUpdates(
                recordingStart: recordingStart,
                settings: settings
            )
        } catch {
            Logger.shared.error("Failed to start startWorkout: \(error)")
            throw RecordingManagerError.startWorkout
        }
    }

    func startNearbyInteraction() async throws {
        try await initNIDiscoveryToken()
        await nearbyInteractionManager.start()
    }

    func initNIDiscoveryToken() async throws {
        Logger.shared.debug("Initalizing NIDiscovery Token")

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

    func clearAllFromDatabase() async throws {
        let handler = PersistedDataHandler(modelContainer: modelContainer)
        try await handler.clear()
    }
}

// MARK: -  RecordingManager Handlers
//
extension RecordingManager {
    @Sendable
    nonisolated func handleCompanionStartedRecording(_ data: Sendable) throws {
        Task {
            try await start()
        }
    }

    @Sendable
    nonisolated func handleSessionStateChange(_ data: Sendable) throws {
        guard let change = data as? SessionStateChange else {
            Logger.shared.error("\(#function): Invalid data type")
            return
        }

        Task {
            await setRecordingState(newState: change.newState)
        }

        if change.newState == .running {
            Logger.shared.debug("Session started")

            Task {
                let startDate = await workoutManager.getStartDate()

                if let startDateData = try? JSONEncoder().encode(startDate) {
                    try await workoutManager.sendCodable(key: "startDate", data: startDateData)
                }
            }
        }

        if change.newState == .stopped {
            Logger.shared.debug("Session stopped")
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

        let dataObject = try SendDataObjectManager().decode(data)

        switch dataObject.key {
        case "recordingState":
            let recordingObject = await RecordingObject(
                recordingState: self.recordingState.rawValue,
                startTime: self.workoutManager.getStartDate()?.timeIntervalSince1970
            )
            return try JSONEncoder().encode(recordingObject)

        default:
            throw RecordingManagerError.noKey
        }
    }

    @Sendable
    nonisolated func handleReceivedWorkoutData(_ data: Sendable) throws {

        let dataObject = try SendDataObjectManager().decode(data)

        switch dataObject.key {
        default:
            Logger.shared.error("\(#function): Unknown dataObject key: \(dataObject.key)")
        }

    }

    @Sendable
    nonisolated func handleSensorUpdate(_ data: Sendable) {

        let sensor = data as! Sensor

        let archive = archiveSendableArray(
            sensor.chunked(into: MAXCHUNKSIZE)
        )

        if archive.isEmpty {
            fatalError("\(#function): No data to send")
        }

        Task {
            do {
                await classifierManager.update(sensor)
                try await sendSensorUpdate(archive)
                await monitoringManager.addUpdateSendSuccess(true)
            } catch {
                Logger.shared.error("\(#function): Failed to send data: \(error)")
                await monitoringManager.addUpdateSendSuccess(false)

                do {
                    try await PersistedDataHandler(modelContainer: modelContainer).add(
                        dataArray: archive
                    )
                } catch {
                    fatalError("Failed to persist data")
                }
            }
        }
    }

    @Sendable
    nonisolated func handleReceivedDistance(_ data: Sendable) throws {

        Task {
            guard let newValues = data as? DistanceValue else {
                Logger.shared.error("\(#function): Invalid data type")
                return
            }

            await classifierManager.update(
                Sensor.distance(
                    .distance,
                    recordingStartDate: Date(),
                    values: [newValues]
                )
            )
        }
    }
}
// MARK: -  RecordingManager nonisolated functions
//
extension RecordingManager {
    nonisolated func getSettings() async throws -> Settings? {

        guard let data = await sendGetSettings() else {
            return nil
        }

        let settings = try? JSONDecoder().decode(Settings.self, from: data)
        return settings
    }

    nonisolated func sendGetSettings() async -> Data? {
        do {
            return try await connectivityManager.sendData(
                key: "settings",
                data: try JSONEncoder().encode("")
            ) as Data?
        } catch {
            Logger.shared.error("Failed to send get settings: \(error)")
            return nil
        }
    }

    nonisolated func sendSensorUpdate(_ archive: [Data]) async throws {
        try await connectivityManager.sendDataArray(
            key: "sensorUpdate",
            dataArray: archive
        ) as Void
    }

    nonisolated func sendFile(_ archive: [Data]) async throws {

        Logger.shared.debug("combining files \(archive.count)")
        let fileMerger = FileMerger()
        let combinedData = try fileMerger.prepareForTransfer(archive)
        Logger.shared.debug("compressed size \(combinedData.count)")

        try await connectivityManager.sendDataAsFile(
            combinedData as Data
        ) as Void
    }

    nonisolated func archiveSendable(_ data: Codable) throws -> Data {
        return try JSONEncoder().encode(data)
    }

    nonisolated func archiveSendableArray(_ data: [Codable]) -> [Data] {

        do {
            return try data.map(archiveSendable(_:))
        } catch {
            Logger.shared.error("Failed to encode data: \(error)")
            return []
        }
    }

}
