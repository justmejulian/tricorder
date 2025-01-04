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
        usePhone = true
        monitoringManager.reset()
    }
}

// MARK: -  RecordingManager functions
//
extension RecordingManager {
    func startRecording() async throws {
        try await self.startRecording(withPhone: true)
    }

    func startRecording(withPhone: Bool) async throws {
        Logger.shared.info("Starting Recording, with Phone: \(withPhone)")

        await reset()

        self.usePhone = withPhone

        let recordingStart = try await startWorkout()

        if withPhone {
            try await startRecordingWithPhone(recordingStart: recordingStart)
            return
        }

        try await startUpdates(recordingStart: recordingStart, settings: nil)
    }

    func startRecordingWithPhone(recordingStart: Date) async throws {
        // Force SessionStateChange
        workoutManager.handleSessionSateChange(
            SessionStateChange(
                newState: .running,
                date: recordingStart
            )
        )

        let settings = try await getSettings()

        Logger.shared.debug("Settings: \(String(describing: settings))")

        try await initNIDiscoveryToken()
        await nearbyInteractionManager.start()

        try await startUpdates(recordingStart: recordingStart, settings: settings)
    }

    func startWorkout() async throws -> Date {
        do {
            return try await workoutManager.startWorkout()
        } catch {
            Logger.shared.error("Failed to start startWorkout: \(error)")
            throw RecordingManagerError.startWorkout
        }
    }

    func startUpdates(recordingStart: Date, settings: Settings?) async throws {
        do {
            try await coreMotionManager.startUpdates(
                recordingStart: recordingStart,
                settings: settings
            )
        } catch {
            Logger.shared.error("Failed to start Motion Updates: \(error)")
            throw RecordingManagerError.startWorkout
        }
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
            try await startRecording()
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

    nonisolated func persistData(_ dataArray: [Data]) async {
        do {
            try await PersistedDataHandler(modelContainer: modelContainer).add(
                dataArray: dataArray
            )
        } catch {
            fatalError("Failed to persist data")
        }
    }

    @Sendable
    nonisolated func handleSensorUpdate(_ data: Sendable) {
        Task {
            let sensor = data as! Sensor

            await classifierManager.update(sensor)

            let archive = archiveSendableArray(
                sensor.chunked(into: MAXCHUNKSIZE)
            )

            // No need to send
            if !(await usePhone) {
                await monitoringManager.addUpdateSendSuccess(false)
                await persistData(archive)
                return
            }

            if archive.isEmpty {
                fatalError("\(#function): No data to send")
            }

            do {
                try await sendSensorUpdate(archive)
                await monitoringManager.addUpdateSendSuccess(true)
            } catch {
                Logger.shared.error("\(#function): Failed to send data: \(error)")
                await monitoringManager.addUpdateSendSuccess(false)
                await persistData(archive)

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
    nonisolated func getSettings() async throws -> Settings {

        guard let data = try await sendGetSettings() else {
            throw RecordingManagerError.invalidData
        }

        let settings = try JSONDecoder().decode(Settings.self, from: data)
        return settings
    }

    nonisolated func sendGetSettings() async throws -> Data? {
        return try await connectivityManager.sendData(
            key: "settings",
            data: try JSONEncoder().encode("")
        ) as Data?
    }

    nonisolated func sendSensorUpdate(_ archive: [Data]) async throws {
        try await connectivityManager.sendDataArray(
            key: "sensorUpdate",
            dataArray: archive
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
